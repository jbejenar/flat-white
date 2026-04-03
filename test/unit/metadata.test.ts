/**
 * Unit tests for metadata.ts — build metadata generation.
 */

import { describe, it, expect, beforeAll, afterAll } from "vitest";
import {
  writeFileSync,
  mkdirSync,
  unlinkSync,
  existsSync,
  readdirSync,
  rmdirSync,
  readFileSync,
} from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { countByState, generateMetadata, writeMetadata } from "../../src/metadata.js";

const __dirname = dirname(fileURLToPath(import.meta.url));
const TMP_DIR = resolve(__dirname, "../../.tmp-test-metadata");

function tmpFile(name: string): string {
  return resolve(TMP_DIR, name);
}

function writeNdjson(path: string, docs: Array<{ state: string; [key: string]: unknown }>): void {
  writeFileSync(path, docs.map((d) => JSON.stringify(d)).join("\n") + "\n");
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

describe("countByState", () => {
  it("counts documents per state", async () => {
    const docs = [
      { _id: "A1", state: "VIC" },
      { _id: "A2", state: "VIC" },
      { _id: "A3", state: "NSW" },
      { _id: "A4", state: "QLD" },
    ];
    const path = tmpFile("count-states.ndjson");
    writeNdjson(path, docs);

    const result = await countByState(path);
    expect(result.totalCount).toBe(4);
    expect(result.states).toEqual({ VIC: 2, NSW: 1, QLD: 1 });
  });

  it("handles single state", async () => {
    const docs = [
      { _id: "A1", state: "VIC" },
      { _id: "A2", state: "VIC" },
    ];
    const path = tmpFile("single-state.ndjson");
    writeNdjson(path, docs);

    const result = await countByState(path);
    expect(result.totalCount).toBe(2);
    expect(result.states).toEqual({ VIC: 2 });
  });

  it("handles empty file", async () => {
    const path = tmpFile("empty.ndjson");
    writeFileSync(path, "");

    const result = await countByState(path);
    expect(result.totalCount).toBe(0);
    expect(result.states).toEqual({});
  });
});

describe("generateMetadata", () => {
  it("generates complete metadata object", async () => {
    const docs = [
      { _id: "A1", state: "VIC" },
      { _id: "A2", state: "NSW" },
    ];
    const path = tmpFile("gen-meta.ndjson");
    writeNdjson(path, docs);

    const meta = await generateMetadata({
      ndjsonPath: path,
      version: "2026.02",
      schemaVersion: "0.1.0",
      gnafLoaderVersion: "202602-5",
      outputFiles: ["output/fixture.ndjson"],
    });

    expect(meta.version).toBe("2026.02");
    expect(meta.schemaVersion).toBe("0.1.0");
    expect(meta.gnafLoaderVersion).toBe("202602-5");
    expect(meta.totalCount).toBe(2);
    expect(meta.states).toEqual({ VIC: 1, NSW: 1 });
    expect(meta.outputFiles).toEqual(["output/fixture.ndjson"]);
    expect(meta.buildTimestamp).toMatch(/^\d{4}-\d{2}-\d{2}T/);
  });
});

describe("writeMetadata", () => {
  it("writes metadata to JSON file", async () => {
    const docs = [
      { _id: "A1", state: "VIC" },
      { _id: "A2", state: "VIC" },
      { _id: "A3", state: "NSW" },
    ];
    const ndjsonPath = tmpFile("write-meta.ndjson");
    writeNdjson(ndjsonPath, docs);

    const outputPath = tmpFile("metadata.json");
    const meta = await writeMetadata({
      ndjsonPath,
      outputPath,
      version: "2026.02",
      schemaVersion: "0.1.0",
      gnafLoaderVersion: "202602-5",
    });

    expect(meta.totalCount).toBe(3);

    // Verify file was written and is valid JSON
    const written = JSON.parse(readFileSync(outputPath, "utf-8")) as Record<string, unknown>;
    expect(written.version).toBe("2026.02");
    expect(written.totalCount).toBe(3);
    expect(written.states).toEqual({ VIC: 2, NSW: 1 });
  });
});

describe("fixture expected-output.ndjson metadata", () => {
  const fixturePath = resolve(__dirname, "../../fixtures/expected-output.ndjson");

  it("counts 451 VIC documents", async () => {
    const result = await countByState(fixturePath);
    expect(result.totalCount).toBe(451);
    expect(result.states.VIC).toBe(451);
  });
});
