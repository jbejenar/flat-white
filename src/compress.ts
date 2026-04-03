/**
 * flat-white — Streaming gzip compression.
 *
 * Compresses NDJSON files using streaming gzip to avoid
 * memory spikes on large datasets.
 */

import { createReadStream, createWriteStream, statSync } from "node:fs";
import { createGzip } from "node:zlib";
import { pipeline } from "node:stream/promises";

export interface CompressOptions {
  /** Path to the input file (.ndjson) */
  inputPath: string;
  /** Path to the output file (.ndjson.gz) */
  outputPath: string;
  /** Gzip compression level (1-9, default 6) */
  level?: number;
}

export interface CompressResult {
  /** Input file size in bytes */
  inputSize: number;
  /** Output file size in bytes */
  outputSize: number;
  /** Compression ratio (outputSize / inputSize) */
  ratio: number;
}

/**
 * Compress a file using streaming gzip.
 *
 * Uses Node.js stream pipeline for backpressure-safe streaming.
 * Memory usage stays constant regardless of input size.
 */
export async function compress(options: CompressOptions): Promise<CompressResult> {
  const { inputPath, outputPath, level = 6 } = options;

  const input = createReadStream(inputPath);
  const gzip = createGzip({ level });
  const output = createWriteStream(outputPath);

  await pipeline(input, gzip, output);

  const inputSize = statSync(inputPath).size;
  const outputSize = statSync(outputPath).size;

  return {
    inputSize,
    outputSize,
    ratio: inputSize > 0 ? outputSize / inputSize : 0,
  };
}
