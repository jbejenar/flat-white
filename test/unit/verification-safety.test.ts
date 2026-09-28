import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { gzipSync } from "node:zlib";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import { AddressDocumentSchema, type AddressDocument } from "../../src/schema.js";
import { verifyGzippedState } from "../../src/verification-report.js";

const example = AddressDocumentSchema.parse(
  JSON.parse(readFileSync("fixtures/expected-output-sample.json", "utf8")),
);

describe("release verification safety", () => {
  let root: string;

  beforeEach(() => {
    root = mkdtempSync(join(tmpdir(), "flat-white-verification-"));
  });
  afterEach(() => rmSync(root, { recursive: true, force: true }));

  function document(id: number): AddressDocument {
    return { ...structuredClone(example), _id: `GAVIC${id}` };
  }

  function archive(docs: unknown[]): string {
    const path = join(root, "vic.ndjson.gz");
    writeFileSync(path, gzipSync(docs.map((doc) => JSON.stringify(doc)).join("\n") + "\n"));
    return path;
  }

  it("rejects an invalid document outside the old schema sample", async () => {
    const docs: unknown[] = Array.from({ length: 101 }, (_, i) => document(i));
    docs[100] = { ...document(100), boundaries: { ...example.boundaries, sa3: 42 } };
    const result = await verifyGzippedState(archive(docs), "VIC");
    expect(result.schemaErrors).toBe(1);
    expect(result.passed).toBe(false);
  });

  it("counts a JSON null as an invalid record and continues checking later rows", async () => {
    const result = await verifyGzippedState(archive([null, document(1)]), "VIC");
    expect(result.rowCount).toBe(2);
    expect(result.schemaErrors).toBe(1);
    expect(result.passed).toBe(false);
  });

  it("rejects a document in the wrong state file even without a postcode", async () => {
    const result = await verifyGzippedState(
      archive([{ ...document(1), state: "NSW", postcode: null }]),
      "VIC",
    );
    expect(result.qualityErrors).toBe(1);
    expect(result.passed).toBe(false);
  });

  it("checks alternative geocodes as well as the primary geocode", async () => {
    const doc = document(1);
    doc.allGeocodes = [{ lat: 45, lng: 151, type: "PC", reliability: 2 }];
    const result = await verifyGzippedState(archive([doc]), "VIC");
    expect(result.qualityErrors).toBe(1);
    expect(result.passed).toBe(false);
  });

  it("reports every census hierarchy level and applies thresholds before rounding", async () => {
    const docs = Array.from({ length: 99 }, (_, i) => document(i));
    docs[0].boundaries.sa3 = null;
    const result = await verifyGzippedState(archive(docs), "VIC", undefined, {
      sa3: 99,
      sa4: 99,
      gccsa: 99,
    });
    expect(result.boundaryCoverage).toMatchObject({ sa3: 99, sa4: 100, gccsa: 100 });
    expect(result.coverageBelowThreshold).toHaveLength(1);
    expect(result.coverageBelowThreshold[0].actual).toBeCloseTo(98.989898);
    expect(result.passed).toBe(false);
  });

  it.each(["missing", "not-gzip", "truncated"])(
    "rejects %s input without an uncaught stream error",
    async (kind) => {
      const path = join(root, "broken.ndjson.gz");
      if (kind === "not-gzip") writeFileSync(path, "not a gzip archive");
      if (kind === "truncated")
        writeFileSync(path, gzipSync(JSON.stringify(document(1))).subarray(0, -8));
      await expect(verifyGzippedState(path, "VIC")).rejects.toThrow();
    },
  );
});
