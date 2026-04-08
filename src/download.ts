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
 *   await download({ version: '2026.05', outputDir: './data' });
 */

import {
  createWriteStream,
  existsSync,
  mkdirSync,
  readdirSync,
  renameSync,
  rmSync,
  statSync,
  unlinkSync,
} from "node:fs";
import { dirname, resolve } from "node:path";
import { pipeline } from "node:stream/promises";
import { Readable } from "node:stream";
import { execFile } from "node:child_process";
import { fileURLToPath } from "node:url";

// --- Data source configuration ---

export interface DataSource {
  name: string;
  url: string;
  extractedDir: string;
  /** Paths relative to extractedDir that must exist for the extraction to be considered complete. */
  sentinelPaths: string[];
}

/**
 * Default data sources for the Feb 2026 G-NAF release.
 * URLs verified via HEAD request — see memory/project_data_sources.md.
 *
 * sentinelPaths are well-known files/dirs within each extracted dataset.
 * Their presence confirms a complete extraction vs. a partial/interrupted one.
 *
 * For newer releases, override via DOWNLOAD_URL_GNAF / DOWNLOAD_URL_ADMIN_BDYS
 * env vars — each Geoscape release publishes new dataset UUIDs on data.gov.au,
 * so URLs are not templatable.
 */
export const DEFAULT_DATA_SOURCES: DataSource[] = [
  {
    name: "G-NAF GDA2020",
    url: "https://data.gov.au/data/dataset/19432f89-dc3a-4ef3-b943-5326ef1dbecc/resource/5be5278c-fe66-459e-845a-bea553f46b4b/download/g-naf_feb26_allstates_gda2020_psv_1022.zip",
    extractedDir: "G-NAF",
    sentinelPaths: ["G-NAF FEBRUARY 2026/Standard", "G-NAF FEBRUARY 2026/Authority Code"],
  },
  {
    name: "Administrative Boundaries GDA2020",
    url: "https://data.gov.au/data/dataset/bdcf5b09-89bc-47ec-9281-6b8e9ee147aa/resource/36cc98bd-df9b-4454-9a05-c2756ee1249e/download/feb26_adminbounds_gda_2020_shp.zip",
    extractedDir: "FEB26_AdminBounds_GDA_2020_SHP",
    sentinelPaths: ["LocalGovernmentAreas_*", "StateBoundaries_*"],
  },
];

export const DEFAULT_FALLBACK_VERSION = "2026.02";
export const GNAF_PACKAGE_ID = "19432f89-dc3a-4ef3-b943-5326ef1dbecc";
export const ADMIN_BDYS_PACKAGE_ID = "bdcf5b09-89bc-47ec-9281-6b8e9ee147aa";

interface CkanResource {
  format?: string;
  name?: string;
  state?: string;
  url?: string;
}

interface CkanPackageResponse {
  success?: boolean;
  result?: {
    resources?: CkanResource[];
  };
}

function readEnvOverride(name: string): string | undefined {
  const value = process.env[name]?.trim();
  return value ? value : undefined;
}

function monthToken(month: number): string {
  const tokens = [
    "JAN",
    "FEB",
    "MAR",
    "APR",
    "MAY",
    "JUN",
    "JUL",
    "AUG",
    "SEP",
    "OCT",
    "NOV",
    "DEC",
  ];
  const token = tokens[month - 1];
  if (!token) {
    throw new Error(`Invalid G-NAF month: ${month}`);
  }
  return token;
}

export function versionTokens(version: string): {
  year: number;
  month: number;
  shortYear: string;
  monthAbbrev: string;
  gnafNameToken: string;
  compactTokenLower: string;
  compactTokenUpper: string;
  adminExtractedDir: string;
} {
  const match = version.match(/^(\d{4})\.(\d{2})$/);
  if (!match) {
    throw new Error(`Invalid G-NAF version: "${version}" (expected YYYY.MM)`);
  }

  const year = Number(match[1]);
  const month = Number(match[2]);
  const monthAbbrev = monthToken(month);
  const shortYear = String(year).slice(-2);
  const compactTokenUpper = `${monthAbbrev}${shortYear}`;
  const compactTokenLower = compactTokenUpper.toLowerCase();

  return {
    year,
    month,
    shortYear,
    monthAbbrev,
    gnafNameToken: `${monthAbbrev} ${year}`,
    compactTokenLower,
    compactTokenUpper,
    adminExtractedDir: `${compactTokenUpper}_AdminBounds_GDA_2020_SHP`,
  };
}

export function hasManualDataSourceOverrides(): boolean {
  return Boolean(
    readEnvOverride("DOWNLOAD_URL_GNAF") ||
    readEnvOverride("DOWNLOAD_URL_ADMIN_BDYS") ||
    readEnvOverride("ADMIN_BDYS_EXTRACTED_DIR"),
  );
}

function assertCompleteManualOverrides(): void {
  if (!hasManualDataSourceOverrides()) {
    return;
  }

  const missing: string[] = [];
  if (!readEnvOverride("DOWNLOAD_URL_GNAF")) missing.push("DOWNLOAD_URL_GNAF");
  if (!readEnvOverride("DOWNLOAD_URL_ADMIN_BDYS")) missing.push("DOWNLOAD_URL_ADMIN_BDYS");
  if (!readEnvOverride("ADMIN_BDYS_EXTRACTED_DIR")) missing.push("ADMIN_BDYS_EXTRACTED_DIR");
  if (missing.length === 0) return;

  throw new Error(
    `Manual release data overrides must be provided together. Missing: ${missing.join(", ")}.\n` +
      "Set all three values or omit them entirely and let flat-white auto-discover the target quarterly release.",
  );
}

function isZipResource(resource: CkanResource): boolean {
  return (
    (resource.state ?? "active") === "active" && (resource.format ?? "").toUpperCase() === "ZIP"
  );
}

function findMatchingResource(
  resources: CkanResource[],
  predicates: Array<(resource: CkanResource) => boolean>,
): CkanResource | undefined {
  return resources.find((resource) => predicates.every((predicate) => predicate(resource)));
}

function resourceText(resource: CkanResource): string {
  return `${resource.name ?? ""} ${resource.url ?? ""}`.toLowerCase();
}

async function fetchCkanPackage(
  packageId: string,
  fetchImpl: typeof fetch = fetch,
): Promise<CkanResource[]> {
  const url = `https://data.gov.au/data/api/3/action/package_show?id=${packageId}`;
  const response = await fetchImpl(url, { redirect: "follow" });
  if (!response.ok) {
    throw new Error(`data.gov.au CKAN lookup failed for ${packageId}: HTTP ${response.status}`);
  }

  const payload = (await response.json()) as CkanPackageResponse;
  const resources = payload.result?.resources;
  if (!payload.success || !resources) {
    throw new Error(`data.gov.au CKAN lookup for ${packageId} returned an unexpected payload`);
  }

  return resources;
}

export async function discoverDataSources(
  version: string,
  fetchImpl: typeof fetch = fetch,
): Promise<DataSource[]> {
  const tokens = versionTokens(version);
  const [gnafResources, adminResources] = await Promise.all([
    fetchCkanPackage(GNAF_PACKAGE_ID, fetchImpl),
    fetchCkanPackage(ADMIN_BDYS_PACKAGE_ID, fetchImpl),
  ]);

  const gnaf = findMatchingResource(gnafResources, [
    isZipResource,
    (resource) => {
      const text = resourceText(resource);
      return (
        text.includes("gda2020") &&
        (text.includes(tokens.gnafNameToken.toLowerCase()) ||
          text.includes(tokens.compactTokenLower))
      );
    },
    (resource) => !resourceText(resource).includes("gda94"),
  ]);

  if (!gnaf?.url) {
    throw new Error(
      `Could not find the ${version} G-NAF GDA2020 ZIP on data.gov.au. ` +
        "Use manual download overrides if Geoscape has changed the resource naming.",
    );
  }

  const admin = findMatchingResource(adminResources, [
    isZipResource,
    (resource) => {
      const text = resourceText(resource);
      return (
        text.includes("gda2020") &&
        (text.includes("shapefile") || text.includes("_shp") || text.includes(" shp")) &&
        text.includes(tokens.compactTokenLower)
      );
    },
    (resource) => !resourceText(resource).includes("gda94"),
  ]);

  if (!admin?.url) {
    throw new Error(
      `Could not find the ${version} Administrative Boundaries GDA2020 shapefile ZIP on data.gov.au. ` +
        "Use manual download overrides if Geoscape has changed the resource naming.",
    );
  }

  return [
    {
      name: "G-NAF GDA2020",
      url: gnaf.url,
      extractedDir: "G-NAF",
      sentinelPaths: ["G-NAF */Standard", "G-NAF */Authority Code"],
    },
    {
      name: "Administrative Boundaries GDA2020",
      url: admin.url,
      extractedDir: tokens.adminExtractedDir,
      sentinelPaths: ["LocalGovernmentAreas_*", "StateBoundaries_*"],
    },
  ];
}

/**
 * Resolve data sources, applying env var URL overrides if set.
 *
 * Env vars:
 * - DOWNLOAD_URL_GNAF — overrides the G-NAF download URL
 * - DOWNLOAD_URL_ADMIN_BDYS — overrides the Admin Boundaries download URL
 * - ADMIN_BDYS_EXTRACTED_DIR — overrides extractedDir for Admin Boundaries
 *   (each Geoscape release uses a different directory name, e.g. "MAY26_AdminBounds_GDA_2020_SHP")
 *
 * sentinelPaths for G-NAF are relaxed to a wildcard when URLs are overridden
 * (the versioned directory name inside the zip changes per release).
 */
export function resolveDataSources(_version?: string): DataSource[] {
  assertCompleteManualOverrides();

  const gnafUrl = readEnvOverride("DOWNLOAD_URL_GNAF");
  const adminUrl = readEnvOverride("DOWNLOAD_URL_ADMIN_BDYS");
  const adminExtractedDir = readEnvOverride("ADMIN_BDYS_EXTRACTED_DIR");

  const sources = DEFAULT_DATA_SOURCES.map((s) => ({ ...s, sentinelPaths: [...s.sentinelPaths] }));

  if (gnafUrl) {
    const gnaf = sources.find((s) => s.name.includes("G-NAF"));
    if (gnaf) {
      gnaf.url = gnafUrl;
      // The versioned subdirectory name changes per release (e.g. "G-NAF MAY 2026"),
      // so relax sentinels to match any "G-NAF *" directory with Standard/Authority Code.
      gnaf.sentinelPaths = ["G-NAF */Standard", "G-NAF */Authority Code"];
    }
  }

  if (adminUrl) {
    const admin = sources.find((s) => s.name.includes("Administrative"));
    if (admin) {
      admin.url = adminUrl;
      if (adminExtractedDir) {
        admin.extractedDir = adminExtractedDir;
      }
    }
  }

  return sources;
}

export async function resolveDownloadDataSources(
  version: string,
  fetchImpl: typeof fetch = fetch,
): Promise<DataSource[]> {
  if (hasManualDataSourceOverrides()) {
    return resolveDataSources(version);
  }

  if (version === DEFAULT_FALLBACK_VERSION) {
    return resolveDataSources(version);
  }

  console.error(`[download] Auto-discovering data.gov.au sources for ${version}...`);
  return discoverDataSources(version, fetchImpl);
}

// --- Types ---

export interface DownloadOptions {
  /** Output directory for extracted data (default: ./data) */
  outputDir?: string;
  /** Skip download if extracted data already exists */
  skipIfExists?: boolean;
  /** G-NAF data version label (e.g. "2026.05"). Falls back to GNAF_VERSION env var. Required. */
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

// --- Extraction validation ---

/**
 * Check whether an extracted directory contains all expected sentinel paths.
 * Returns true only if every sentinel file/directory exists, indicating a
 * complete extraction. Returns false for empty, partial, or missing directories.
 */
export function isExtractionComplete(extractedPath: string, sentinelPaths: string[]): boolean {
  if (!existsSync(extractedPath)) return false;
  try {
    if (!statSync(extractedPath).isDirectory()) return false;
  } catch {
    return false;
  }
  if (sentinelPaths.length === 0) return false;
  // Read directory once for glob matching (avoids repeated readdirSync per sentinel)
  const hasGlob = sentinelPaths.some((s) => s.includes("*"));
  const entries = hasGlob ? readdirSync(extractedPath) : [];
  return sentinelPaths.every((sentinel) => {
    if (sentinel.includes("/") && sentinel.includes("*")) {
      // Path-segment wildcard: "G-NAF */Standard" — first segment has a wildcard, rest is literal
      const [globSegment, ...rest] = sentinel.split("/");
      const prefix = globSegment.replaceAll("*", "");
      const matchingDirs = entries.filter((entry) => entry.startsWith(prefix));
      const subPath = rest.join("/");
      return matchingDirs.some((dir) => existsSync(resolve(extractedPath, dir, subPath)));
    }
    if (sentinel.endsWith("*")) {
      // Trailing wildcard: "LocalGovernmentAreas_*" matches any entry starting with the prefix
      const prefix = sentinel.slice(0, -1);
      return entries.some((entry) => entry.startsWith(prefix));
    }
    return existsSync(resolve(extractedPath, sentinel));
  });
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
  const version = options.version ?? process.env.GNAF_VERSION;
  if (!version) {
    throw new Error(
      "G-NAF version is required. Set the GNAF_VERSION environment variable (e.g. GNAF_VERSION=2026.05) " +
        "or pass { version } in DownloadOptions.",
    );
  }

  console.error(`[download] G-NAF version: ${version}`);
  console.error(`[download] Output directory: ${outputDir}`);

  mkdirSync(outputDir, { recursive: true });

  const results: DownloadResult[] = [];
  const dataSources = await resolveDownloadDataSources(version);

  for (const source of dataSources) {
    const extractedPath = resolve(outputDir, source.extractedDir);

    // Skip only if all sentinel paths are present — a partial/interrupted extraction
    // will fail this check and trigger a re-download.
    if (skipIfExists && isExtractionComplete(extractedPath, source.sentinelPaths)) {
      console.error(`[download] ${source.name}: skipped (${extractedPath} validated)`);
      results.push({
        source: source.name,
        skipped: true,
        bytesDownloaded: 0,
        extractedTo: extractedPath,
      });
      continue;
    }

    if (skipIfExists && existsSync(extractedPath)) {
      console.error(
        `[download] ${source.name}: directory exists but failed sentinel validation — re-downloading`,
      );
    }

    const zipFilename = source.url.split("/").pop() ?? `${source.extractedDir}.zip`;
    const zipPath = resolve(outputDir, zipFilename);

    // Download
    const bytesDownloaded = await downloadFile(source.url, zipPath, source.name);

    // Extract to a temporary directory, then atomically rename into place.
    // This prevents partial extractions from being mistaken for complete ones.
    const tmpExtractDir = resolve(outputDir, `${source.extractedDir}.extracting`);

    // Clean up any leftover temp dir from a previous failed attempt
    if (existsSync(tmpExtractDir)) {
      rmSync(tmpExtractDir, { recursive: true, force: true });
    }

    console.error(`[download] ${source.name}: extracting to temporary directory...`);
    await extractZip(zipPath, tmpExtractDir);

    // The zip may extract with the directory name inside tmpExtractDir,
    // e.g. tmpExtractDir/G-NAF/... — detect and handle both cases.
    const innerPath = resolve(tmpExtractDir, source.extractedDir);
    const sourceDir = existsSync(innerPath) ? innerPath : tmpExtractDir;

    // Validate sentinel paths before promoting
    if (!isExtractionComplete(sourceDir, source.sentinelPaths)) {
      // Clean up failed extraction
      rmSync(tmpExtractDir, { recursive: true, force: true });
      try {
        unlinkSync(zipPath);
      } catch {
        // ignore
      }
      throw new Error(
        `Extraction of ${source.name} failed sentinel validation — expected paths not found: ${source.sentinelPaths.join(", ")}`,
      );
    }

    // Remove any existing incomplete directory at the final location
    if (existsSync(extractedPath)) {
      rmSync(extractedPath, { recursive: true, force: true });
    }

    // Atomic rename into final location
    renameSync(sourceDir, extractedPath);

    // Clean up temp dir shell (if inner dir was moved out of it)
    if (existsSync(tmpExtractDir)) {
      rmSync(tmpExtractDir, { recursive: true, force: true });
    }

    console.error(`[download] ${source.name}: extraction complete — validated ${extractedPath}`);

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

// --- Path resolution ---

/**
 * Resolve the download output directory from environment variables.
 *
 * Priority:
 * 1. DATA_DIR — explicit download root (e.g. "./data")
 * 2. Derived from GNAF_DATA_PATH and/or ADMIN_BDYS_PATH — takes the parent dir,
 *    but validates that both env vars are consistent (same parent, correct child names).
 * 3. Default: "./data"
 *
 * Throws if GNAF_DATA_PATH and ADMIN_BDYS_PATH point to different parent directories,
 * or if their final directory names don't match the expected extractedDir values.
 */
export function resolveOutputDir(version?: string): string {
  // Explicit download root takes priority
  if (process.env.DATA_DIR) {
    return resolve(process.env.DATA_DIR);
  }

  const gnafPath = process.env.GNAF_DATA_PATH;
  const adminPath = process.env.ADMIN_BDYS_PATH;

  if (!gnafPath && !adminPath) {
    return resolve("./data");
  }

  const sources = resolveDataSources(version);
  const effectiveVersion = version ?? process.env.GNAF_VERSION;
  const fallbackAdminExtractedDir = DEFAULT_DATA_SOURCES.find((s) =>
    s.name.includes("Administrative"),
  )?.extractedDir;
  const adminExtractedDir =
    readEnvOverride("ADMIN_BDYS_EXTRACTED_DIR") ??
    (effectiveVersion && effectiveVersion !== DEFAULT_FALLBACK_VERSION
      ? versionTokens(effectiveVersion).adminExtractedDir
      : fallbackAdminExtractedDir);
  const gnafSource = sources.find((s) => s.name.includes("G-NAF"));
  const adminSource = adminExtractedDir
    ? {
        ...(sources.find((s) => s.name.includes("Administrative")) ?? {
          name: "Administrative Boundaries GDA2020",
          url: "",
          sentinelPaths: [],
        }),
        extractedDir: adminExtractedDir,
      }
    : sources.find((s) => s.name.includes("Administrative"));

  if (!gnafSource || !adminSource) {
    throw new Error("DATA_SOURCES is missing expected G-NAF or Administrative Boundaries entry");
  }

  /** Get the final path segment (basename) from a resolved path. */
  function baseName(p: string): string {
    const segments = resolve(p).split("/");
    return segments[segments.length - 1] ?? "";
  }

  /** Validate that a path's basename matches the expected extractedDir. */
  function validateDirName(envVar: string, envValue: string, expected: string): void {
    const actual = baseName(envValue);
    if (actual !== expected) {
      const parent = dirname(resolve(envValue));
      throw new Error(
        `${envVar} final directory "${actual}" does not match expected "${expected}".\n` +
          `The downloader extracts to: <DATA_DIR>/${expected}\n` +
          `Either set ${envVar}=${parent}/${expected} or set DATA_DIR explicitly.`,
      );
    }
  }

  if (gnafPath && adminPath) {
    const gnafParent = dirname(resolve(gnafPath));
    const adminParent = dirname(resolve(adminPath));

    if (gnafParent !== adminParent) {
      throw new Error(
        `GNAF_DATA_PATH and ADMIN_BDYS_PATH must share the same parent directory.\n` +
          `  GNAF_DATA_PATH parent:       ${gnafParent}\n` +
          `  ADMIN_BDYS_PATH parent:      ${adminParent}\n` +
          `Set DATA_DIR explicitly if you need different roots.`,
      );
    }

    validateDirName("GNAF_DATA_PATH", gnafPath, gnafSource.extractedDir);
    validateDirName("ADMIN_BDYS_PATH", adminPath, adminSource.extractedDir);

    return gnafParent;
  }

  // Only one path set — derive parent from it
  if (gnafPath) {
    validateDirName("GNAF_DATA_PATH", gnafPath, gnafSource.extractedDir);
    return dirname(resolve(gnafPath));
  }

  // adminPath is guaranteed non-null here (we returned early if both were falsy)
  const adminPathValue = adminPath as string;
  validateDirName("ADMIN_BDYS_PATH", adminPathValue, adminSource.extractedDir);
  return dirname(resolve(adminPathValue));
}

// --- CLI entry point ---

async function main() {
  const args = process.argv.slice(2);
  const skipIfExists = args.includes("--skip-download");
  const version = process.env.GNAF_VERSION;
  if (!version) {
    console.error("[download] ERROR: GNAF_VERSION environment variable is required.");
    console.error("[download] Set GNAF_VERSION=YYYY.MM (e.g. GNAF_VERSION=2026.05)");
    process.exit(1);
  }
  const outputDir = resolveOutputDir(version);

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
