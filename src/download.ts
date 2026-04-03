/**
 * flat-white — G-NAF + Admin Boundaries downloader.
 *
 * Downloads the G-NAF GDA2020 and Administrative Boundaries ESRI Shapefiles
 * from data.gov.au, extracts them to ./data/, and reports progress.
 *
 * Usage:
 *   node dist/download.js [--skip-download]
 *
 * Or as a module:
 *   import { download } from './download.js';
 *   await download({ version: '2026.02', outputDir: './data' });
 */

import { createWriteStream, existsSync, mkdirSync, statSync, unlinkSync } from "node:fs";
import { resolve } from "node:path";
import { pipeline } from "node:stream/promises";
import { Readable } from "node:stream";
import { execFile } from "node:child_process";
import { fileURLToPath } from "node:url";

// --- Data source configuration ---

export interface DataSource {
  name: string;
  url: string;
  extractedDir: string;
}

/**
 * Data sources for the Feb 2026 G-NAF release.
 * URLs verified via HEAD request — see memory/project_data_sources.md.
 */
export const DATA_SOURCES: DataSource[] = [
  {
    name: "G-NAF GDA2020",
    url: "https://data.gov.au/data/dataset/19432f89-dc3a-4ef3-b943-5326ef1dbecc/resource/5be5278c-fe66-459e-845a-bea553f46b4b/download/g-naf_feb26_allstates_gda2020_psv_1022.zip",
    extractedDir: "G-NAF",
  },
  {
    name: "Administrative Boundaries GDA2020",
    url: "https://data.gov.au/data/dataset/bdcf5b09-89bc-47ec-9281-6b8e9ee147aa/resource/36cc98bd-df9b-4454-9a05-c2756ee1249e/download/feb26_adminbounds_gda_2020_shp.zip",
    extractedDir: "FEB26_AdminBounds_GDA_2020_SHP",
  },
];

// --- Types ---

export interface DownloadOptions {
  /** Output directory for extracted data (default: ./data) */
  outputDir?: string;
  /** Skip download if extracted data already exists */
  skipIfExists?: boolean;
  /** G-NAF data version label (informational only) */
  version?: string;
}

export interface DownloadResult {
  source: string;
  skipped: boolean;
  bytesDownloaded: number;
  extractedTo: string;
}

// --- Progress formatting ---

export function formatBytes(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`;
  const kb = bytes / 1024;
  if (kb < 1024) return `${kb.toFixed(1)} KB`;
  const mb = kb / 1024;
  if (mb < 1024) return `${mb.toFixed(1)} MB`;
  const gb = mb / 1024;
  return `${gb.toFixed(2)} GB`;
}

export function formatSpeed(bytesPerSecond: number): string {
  const mbps = bytesPerSecond / (1024 * 1024);
  return `${mbps.toFixed(1)} MB/s`;
}

export function formatProgress(downloaded: number, total: number | null, elapsed: number): string {
  const speed = elapsed > 0 ? downloaded / elapsed : 0;
  const speedStr = formatSpeed(speed);
  const downloadedStr = formatBytes(downloaded);

  if (total && total > 0) {
    const pct = ((downloaded / total) * 100).toFixed(1);
    const totalStr = formatBytes(total);
    return `${downloadedStr} / ${totalStr} (${pct}%) ${speedStr}`;
  }
  return `${downloadedStr} ${speedStr}`;
}

// --- Retry logic ---

const DEFAULT_MAX_RETRIES = 3;
const BASE_DELAY_MS = 1000;
/** Default inactivity timeout per attempt — abort if no data received for this long. */
export const DEFAULT_STALL_TIMEOUT_MS = 60_000;

export function retryDelay(attempt: number): number {
  return BASE_DELAY_MS * Math.pow(2, attempt);
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// --- Core download ---

async function downloadFile(
  url: string,
  destPath: string,
  name: string,
  maxRetries: number = DEFAULT_MAX_RETRIES,
  stallTimeoutMs: number = DEFAULT_STALL_TIMEOUT_MS,
): Promise<number> {
  let lastError: Error | null = null;

  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    if (attempt > 0) {
      const delay = retryDelay(attempt - 1);
      console.error(`[download] Retry ${attempt}/${maxRetries} for ${name} in ${delay}ms...`);
      await sleep(delay);
    }

    const controller = new AbortController();
    let stallTimer: ReturnType<typeof setTimeout> | null = null;

    const resetStallTimer = () => {
      if (stallTimer) clearTimeout(stallTimer);
      stallTimer = setTimeout(() => {
        console.error(
          `[download] ${name}: stalled for ${stallTimeoutMs / 1000}s — aborting attempt ${attempt + 1}`,
        );
        controller.abort(
          new Error(`Download stalled: no data received for ${stallTimeoutMs / 1000}s`),
        );
      }, stallTimeoutMs);
    };

    try {
      resetStallTimer();
      const response = await fetch(url, { redirect: "follow", signal: controller.signal });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      if (!response.body) {
        throw new Error("Response has no body");
      }

      const contentLength = response.headers.get("content-length");
      const total = contentLength ? parseInt(contentLength, 10) : null;

      console.error(
        `[download] ${name}: starting download${total ? ` (${formatBytes(total)})` : ""}`,
      );

      const startTime = Date.now();
      let downloaded = 0;
      let lastProgressTime = 0;

      const progressStream = new TransformStream<Uint8Array, Uint8Array>({
        transform(chunk, controller) {
          downloaded += chunk.byteLength;
          resetStallTimer();
          const elapsed = (Date.now() - startTime) / 1000;

          // Report progress every 2 seconds
          if (elapsed - lastProgressTime >= 2) {
            lastProgressTime = elapsed;
            console.error(`[download] ${name}: ${formatProgress(downloaded, total, elapsed)}`);
          }

          controller.enqueue(chunk);
        },
      });

      const tracked = response.body.pipeThrough(progressStream);
      const nodeStream = Readable.fromWeb(tracked as import("node:stream/web").ReadableStream);
      const dest = createWriteStream(destPath);

      await pipeline(nodeStream, dest);

      if (stallTimer) clearTimeout(stallTimer);

      const elapsed = (Date.now() - startTime) / 1000;
      console.error(`[download] ${name}: complete — ${formatProgress(downloaded, total, elapsed)}`);

      return downloaded;
    } catch (err) {
      if (stallTimer) clearTimeout(stallTimer);
      lastError = err instanceof Error ? err : new Error(String(err));
      console.error(`[download] ${name}: attempt ${attempt + 1} failed — ${lastError.message}`);

      // Clean up partial file
      try {
        if (existsSync(destPath)) unlinkSync(destPath);
      } catch {
        // ignore cleanup errors
      }
    }
  }

  throw new Error(
    `Failed to download ${name} after ${maxRetries + 1} attempts: ${lastError?.message}`,
  );
}

// --- Extraction ---

function extractZip(zipPath: string, outputDir: string): Promise<void> {
  return new Promise((resolve, reject) => {
    execFile("unzip", ["-o", "-q", zipPath, "-d", outputDir], (error, _stdout, stderr) => {
      if (error) {
        reject(new Error(`Extraction failed: ${stderr || error.message}`));
        return;
      }
      resolve();
    });
  });
}

// --- Orchestrator ---

export async function download(options: DownloadOptions = {}): Promise<DownloadResult[]> {
  const outputDir = resolve(options.outputDir ?? "./data");
  const skipIfExists = options.skipIfExists ?? false;
  const version = options.version ?? "2026.02";

  console.error(`[download] G-NAF version: ${version}`);
  console.error(`[download] Output directory: ${outputDir}`);

  mkdirSync(outputDir, { recursive: true });

  const results: DownloadResult[] = [];

  for (const source of DATA_SOURCES) {
    const extractedPath = resolve(outputDir, source.extractedDir);

    // Skip if extracted directory exists and --skip-download is set
    if (skipIfExists && existsSync(extractedPath)) {
      try {
        const stat = statSync(extractedPath);
        if (stat.isDirectory()) {
          console.error(`[download] ${source.name}: skipped (${extractedPath} already exists)`);
          results.push({
            source: source.name,
            skipped: true,
            bytesDownloaded: 0,
            extractedTo: extractedPath,
          });
          continue;
        }
      } catch {
        // stat failed, proceed with download
      }
    }

    const zipFilename = source.url.split("/").pop() ?? `${source.extractedDir}.zip`;
    const zipPath = resolve(outputDir, zipFilename);

    // Download
    const bytesDownloaded = await downloadFile(source.url, zipPath, source.name);

    // Extract
    console.error(`[download] ${source.name}: extracting to ${outputDir}...`);
    await extractZip(zipPath, outputDir);

    // Verify extracted directory exists
    if (!existsSync(extractedPath) || !statSync(extractedPath).isDirectory()) {
      throw new Error(`Extraction succeeded but expected directory not found: ${extractedPath}`);
    }
    console.error(`[download] ${source.name}: extraction complete — verified ${extractedPath}`);

    // Clean up zip
    try {
      unlinkSync(zipPath);
      console.error(`[download] ${source.name}: removed zip file`);
    } catch {
      // ignore cleanup errors
    }

    results.push({
      source: source.name,
      skipped: false,
      bytesDownloaded,
      extractedTo: extractedPath,
    });
  }

  return results;
}

// --- CLI entry point ---

async function main() {
  const args = process.argv.slice(2);
  const skipIfExists = args.includes("--skip-download");
  const version = process.env.GNAF_VERSION ?? "2026.02";
  const outputDir = process.env.GNAF_DATA_PATH
    ? resolve(process.env.GNAF_DATA_PATH, "..")
    : "./data";

  const results = await download({ outputDir, skipIfExists, version });

  const downloaded = results.filter((r) => !r.skipped);
  const skipped = results.filter((r) => r.skipped);

  console.error(`[download] Done: ${downloaded.length} downloaded, ${skipped.length} skipped`);

  if (downloaded.length > 0) {
    const totalBytes = downloaded.reduce((sum, r) => sum + r.bytesDownloaded, 0);
    console.error(`[download] Total downloaded: ${formatBytes(totalBytes)}`);
  }
}

// Run if invoked directly
const thisFile = fileURLToPath(import.meta.url);
const entryFile = process.argv[1] ? resolve(process.argv[1]) : "";
if (thisFile === entryFile || thisFile === entryFile.replace(/\.ts$/, ".js")) {
  main().catch((err) => {
    console.error("[download] Fatal:", err);
    process.exit(1);
  });
}
