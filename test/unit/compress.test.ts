/**
 * Unit tests for compress.ts — streaming gzip compression.
 */

import { describe, it, expect, beforeAll, afterAll } from "vitest";
import {
  writeFileSync,
  readFileSync,
  mkdirSync,
  unlinkSync,
  existsSync,
  readdirSync,
  rmdirSync,
} from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { gunzipSync } from "node:zlib";
import { compress } from "../../src/compress.js";

const __dirname = dirname(fileURLToPath(import.meta.url));
const TMP_DIR = resolve(__dirname, "../../.tmp-test-compress");

function tmpFile(name: string): string {
  return resolve(TMP_DIR, name);
}

beforeAll(() => {
  mkdirSync(TMP_DIR, { recursive: true });
});

afterAll(() => {
  if (existsSync(TMP_DIR)) {
    for (const f of readdirSync(TMP_DIR)) {
      unlinkSync(resolve(TMP_DIR, f));
    }
    rmdirSync(TMP_DIR);
  }
});

describe("compress", () => {
  it("produces a valid gzip archive", async () => {
    const content = '{"_id":"A1","state":"VIC"}\n{"_id":"A2","state":"NSW"}\n';
    const inputPath = tmpFile("valid.ndjson");
    const outputPath = tmpFile("valid.ndjson.gz");
    writeFileSync(inputPath, content);

    await compress({ inputPath, outputPath });

    // Decompress and verify content matches
    const compressed = readFileSync(outputPath);
    const decompressed = gunzipSync(compressed).toString("utf-8");
    expect(decompressed).toBe(content);
  });

  it("returns correct size metrics", async () => {
    // Create a reasonably sized input for meaningful compression ratio
    const lines: string[] = [];
    for (let i = 0; i < 100; i++) {
      lines.push(
        JSON.stringify({
          _id: `GAVIC${i.toString().padStart(6, "0")}`,
          state: "VIC",
          addressLabel: `${i} TEST STREET, TESTVILLE VIC 3000`,
          postcode: "3000",
          localityName: "TESTVILLE",
        }),
      );
    }
    const content = lines.join("\n") + "\n";
    const inputPath = tmpFile("sized.ndjson");
    const outputPath = tmpFile("sized.ndjson.gz");
    writeFileSync(inputPath, content);

    const result = await compress({ inputPath, outputPath });

    expect(result.inputSize).toBe(Buffer.byteLength(content));
    expect(result.outputSize).toBeGreaterThan(0);
    expect(result.outputSize).toBeLessThan(result.inputSize);
    expect(result.ratio).toBeGreaterThan(0);
    expect(result.ratio).toBeLessThan(1);
  });

  it("achieves reasonable compression on NDJSON data", async () => {
    // Realistic-ish address docs with repetitive structure
    const lines: string[] = [];
    for (let i = 0; i < 200; i++) {
      lines.push(
        JSON.stringify({
          _id: `GAVIC${i.toString().padStart(6, "0")}`,
          state: "VIC",
          addressLabel: `${i} BOURKE STREET, MELBOURNE VIC 3000`,
          postcode: "3000",
          localityName: "MELBOURNE",
          streetName: "BOURKE",
          streetType: "STREET",
          boundaries: { lga: { name: "MELBOURNE", code: "LGA1" } },
        }),
      );
    }
    const content = lines.join("\n") + "\n";
    const inputPath = tmpFile("compress-ratio.ndjson");
    const outputPath = tmpFile("compress-ratio.ndjson.gz");
    writeFileSync(inputPath, content);

    const result = await compress({ inputPath, outputPath });

    // NDJSON compresses well due to repetitive keys
    expect(result.ratio).toBeLessThan(0.3);
  });

  it("respects compression level parameter", async () => {
    const content = '{"_id":"A1","state":"VIC"}\n'.repeat(50);
    const inputPath = tmpFile("level.ndjson");
    writeFileSync(inputPath, content);

    const outputFast = tmpFile("level-fast.ndjson.gz");
    const outputBest = tmpFile("level-best.ndjson.gz");

    const resultFast = await compress({ inputPath, outputPath: outputFast, level: 1 });
    const resultBest = await compress({ inputPath, outputPath: outputBest, level: 9 });

    // Best compression should produce smaller or equal output
    expect(resultBest.outputSize).toBeLessThanOrEqual(resultFast.outputSize);

    // Both should be valid gzip
    const decompFast = gunzipSync(readFileSync(outputFast)).toString("utf-8");
    const decompBest = gunzipSync(readFileSync(outputBest)).toString("utf-8");
    expect(decompFast).toBe(content);
    expect(decompBest).toBe(content);
  });

  it("compresses fixture expected-output.ndjson", async () => {
    const fixturePath = resolve(__dirname, "../../fixtures/expected-output.ndjson");
    const outputPath = tmpFile("fixture.ndjson.gz");

    const result = await compress({ inputPath: fixturePath, outputPath });

    expect(result.inputSize).toBeGreaterThan(0);
    expect(result.outputSize).toBeGreaterThan(0);
    expect(result.ratio).toBeLessThan(0.5); // NDJSON compresses well

    // Verify it's a valid gzip archive
    const decompressed = gunzipSync(readFileSync(outputPath)).toString("utf-8");
    const inputContent = readFileSync(fixturePath, "utf-8");
    expect(decompressed).toBe(inputContent);
  });
});
