/**
 * Unit tests for split.ts — per-state NDJSON splitter.
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
import { split } from "../../src/split.js";

const __dirname = dirname(fileURLToPath(import.meta.url));
const TMP_DIR = resolve(__dirname, "../../.tmp-test-split");
const TMP_OUT = resolve(TMP_DIR, "output");

function tmpFile(name: string): string {
  return resolve(TMP_DIR, name);
}

function writeNdjson(path: string, docs: Array<Record<string, unknown>>): void {
  writeFileSync(path, docs.map((d) => JSON.stringify(d)).join("\n") + "\n");
}

function readLines(path: string): string[] {
  return readFileSync(path, "utf-8").trimEnd().split("\n");
}

beforeAll(() => {
  mkdirSync(TMP_DIR, { recursive: true });
  mkdirSync(TMP_OUT, { recursive: true });
});

afterAll(() => {
  if (existsSync(TMP_DIR)) {
    const cleanup = (dir: string) => {
      for (const f of readdirSync(dir)) {
        const p = resolve(dir, f);
        try {
          unlinkSync(p);
        } catch {
          // directory
          cleanup(p);
          rmdirSync(p);
        }
      }
    };
    cleanup(TMP_DIR);
    rmdirSync(TMP_DIR);
  }
});

describe("split", () => {
  it("splits multi-state NDJSON into per-state files", async () => {
    const docs = [
      { _id: "A1", state: "VIC" },
      { _id: "A2", state: "NSW" },
      { _id: "A3", state: "VIC" },
      { _id: "A4", state: "QLD" },
      { _id: "A5", state: "NSW" },
    ];
    const inputPath = tmpFile("multi-state.ndjson");
    const outDir = resolve(TMP_OUT, "multi");
    mkdirSync(outDir, { recursive: true });
    writeNdjson(inputPath, docs);

    const result = await split({ inputPath, outputDir: outDir, version: "2026.02" });

    expect(result.totalCount).toBe(5);
    expect(result.states).toEqual({ VIC: 2, NSW: 2, QLD: 1 });
    expect(result.outputFiles.length).toBe(3);

    // Verify VIC file
    const vicPath = resolve(outDir, "flat-white-2026.02-vic.ndjson");
    expect(existsSync(vicPath)).toBe(true);
    const vicLines = readLines(vicPath);
    expect(vicLines.length).toBe(2);
    for (const line of vicLines) {
      const doc = JSON.parse(line) as { state: string };
      expect(doc.state).toBe("VIC");
    }

    // Verify NSW file
    const nswPath = resolve(outDir, "flat-white-2026.02-nsw.ndjson");
    expect(existsSync(nswPath)).toBe(true);
    const nswLines = readLines(nswPath);
    expect(nswLines.length).toBe(2);

    // Verify QLD file
    const qldPath = resolve(outDir, "flat-white-2026.02-qld.ndjson");
    expect(existsSync(qldPath)).toBe(true);
    const qldLines = readLines(qldPath);
    expect(qldLines.length).toBe(1);
  });

  it("handles single-state input", async () => {
    const docs = [
      { _id: "A1", state: "VIC" },
      { _id: "A2", state: "VIC" },
    ];
    const inputPath = tmpFile("single-state.ndjson");
    const outDir = resolve(TMP_OUT, "single");
    mkdirSync(outDir, { recursive: true });
    writeNdjson(inputPath, docs);

    const result = await split({ inputPath, outputDir: outDir, version: "2026.02" });

    expect(result.totalCount).toBe(2);
    expect(result.states).toEqual({ VIC: 2 });
    expect(result.outputFiles.length).toBe(1);
  });

  it("sum of per-state counts equals total", async () => {
    const docs = [
      { _id: "A1", state: "VIC" },
      { _id: "A2", state: "NSW" },
      { _id: "A3", state: "QLD" },
      { _id: "A4", state: "SA" },
      { _id: "A5", state: "WA" },
      { _id: "A6", state: "TAS" },
      { _id: "A7", state: "NT" },
      { _id: "A8", state: "ACT" },
      { _id: "A9", state: "OT" },
    ];
    const inputPath = tmpFile("all-states.ndjson");
    const outDir = resolve(TMP_OUT, "all");
    mkdirSync(outDir, { recursive: true });
    writeNdjson(inputPath, docs);

    const result = await split({ inputPath, outputDir: outDir, version: "2026.02" });

    const sum = Object.values(result.states).reduce((a, b) => a + b, 0);
    expect(sum).toBe(result.totalCount);
    expect(result.totalCount).toBe(9);
    expect(Object.keys(result.states).length).toBe(9);
  });

  it("preserves document content exactly", async () => {
    const doc = { _id: "FULL1", state: "VIC", addressLabel: "1 TEST ST", postcode: "3000" };
    const inputPath = tmpFile("preserve.ndjson");
    const outDir = resolve(TMP_OUT, "preserve");
    mkdirSync(outDir, { recursive: true });
    writeNdjson(inputPath, [doc]);

    await split({ inputPath, outputDir: outDir, version: "2026.02" });

    const vicPath = resolve(outDir, "flat-white-2026.02-vic.ndjson");
    const outputDoc = JSON.parse(readLines(vicPath)[0]);
    expect(outputDoc).toEqual(doc);
  });
});
