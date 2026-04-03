/**
 * flat-white — Per-state NDJSON splitter.
 *
 * Streams an NDJSON file and splits it into one file per state.
 * Each output file contains only addresses for that state.
 */

import { createReadStream, createWriteStream, type WriteStream } from "node:fs";
import { createInterface } from "node:readline";
import { resolve } from "node:path";

export interface SplitOptions {
  /** Path to the input NDJSON file */
  inputPath: string;
  /** Output directory for per-state files */
  outputDir: string;
  /** G-NAF version string (e.g. "2026.02") */
  version: string;
}

export interface SplitResult {
  /** Per-state document counts */
  states: Record<string, number>;
  /** Total documents processed */
  totalCount: number;
  /** Paths to output files */
  outputFiles: string[];
}

/**
 * Build the output filename for a state.
 */
function stateFilename(version: string, state: string): string {
  return `flat-white-${version}-${state.toLowerCase()}.ndjson`;
}

/**
 * Split an NDJSON file into per-state files.
 *
 * Streams the input line by line, lazily opening write streams
 * for each state encountered.
 */
export async function split(options: SplitOptions): Promise<SplitResult> {
  const { inputPath, outputDir, version } = options;

  const writers = new Map<string, WriteStream>();
  const counts: Record<string, number> = {};
  let totalCount = 0;

  const rl = createInterface({
    input: createReadStream(inputPath),
    crlfDelay: Infinity,
  });

  for await (const line of rl) {
    if (!line.trim()) continue;
    totalCount++;

    const doc = JSON.parse(line) as { state: string };
    const state = doc.state;
    counts[state] = (counts[state] ?? 0) + 1;

    if (!writers.has(state)) {
      const filename = stateFilename(version, state);
      const outputPath = resolve(outputDir, filename);
      writers.set(state, createWriteStream(outputPath));
    }

    // Writer is guaranteed to exist — we just set it above if missing
    const writer = writers.get(state) as WriteStream;
    const ok = writer.write(line + "\n");
    if (!ok) {
      // Backpressure: wait for drain before continuing
      await new Promise<void>((resolve) => writer.once("drain", resolve));
    }
  }

  // Close all write streams
  const closePromises: Promise<void>[] = [];
  for (const writer of writers.values()) {
    closePromises.push(
      new Promise<void>((resolve, reject) => {
        writer.end(() => resolve());
        writer.on("error", reject);
      }),
    );
  }
  await Promise.all(closePromises);

  const outputFiles = Array.from(writers.keys())
    .sort()
    .map((state) => resolve(outputDir, stateFilename(version, state)));

  return {
    states: counts,
    totalCount,
    outputFiles,
  };
}
