/**
 * flat-white — Build metadata generator.
 *
 * Reads NDJSON output, counts documents per state,
 * and produces a machine-readable metadata JSON file.
 */

import { createReadStream } from "node:fs";
import { writeFile } from "node:fs/promises";
import { createInterface } from "node:readline";

export interface BuildMetadata {
  version: string;
  schemaVersion: string;
  buildTimestamp: string;
  gnafLoaderVersion: string;
  states: Record<string, number>;
  totalCount: number;
  outputFiles: string[];
}

export interface MetadataOptions {
  /** Path to the NDJSON output file */
  ndjsonPath: string;
  /** G-NAF data version (e.g. "2026.02") */
  version: string;
  /** flat-white schema version (from package.json) */
  schemaVersion: string;
  /** gnaf-loader version string */
  gnafLoaderVersion: string;
  /** List of output file paths to include in metadata */
  outputFiles?: string[];
}

/**
 * Count documents per state by streaming an NDJSON file.
 */
export async function countByState(
  ndjsonPath: string,
): Promise<{ states: Record<string, number>; totalCount: number }> {
  const states: Record<string, number> = {};
  let totalCount = 0;

  const rl = createInterface({
    input: createReadStream(ndjsonPath),
    crlfDelay: Infinity,
  });

  for await (const line of rl) {
    if (!line.trim()) continue;
    totalCount++;

    let doc: { state: string };
    try {
      doc = JSON.parse(line) as { state: string };
    } catch (e) {
      throw new Error(`Malformed JSON at line ${totalCount}: ${line.slice(0, 100)}`, { cause: e });
    }
    const state = doc.state;
    states[state] = (states[state] ?? 0) + 1;
  }

  return { states, totalCount };
}

/**
 * Generate build metadata from an NDJSON output file.
 */
export async function generateMetadata(options: MetadataOptions): Promise<BuildMetadata> {
  const { ndjsonPath, version, schemaVersion, gnafLoaderVersion, outputFiles = [] } = options;

  const { states, totalCount } = await countByState(ndjsonPath);

  return {
    version,
    schemaVersion,
    buildTimestamp: new Date().toISOString(),
    gnafLoaderVersion,
    states,
    totalCount,
    outputFiles,
  };
}

/**
 * Generate metadata and write it to a JSON file.
 */
export async function writeMetadata(
  options: MetadataOptions & { outputPath: string },
): Promise<BuildMetadata> {
  const { outputPath, ...metadataOptions } = options;
  const metadata = await generateMetadata(metadataOptions);
  await writeFile(outputPath, JSON.stringify(metadata, null, 2) + "\n");
  return metadata;
}
