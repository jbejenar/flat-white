import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { gzipSync } from "node:zlib";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import { AddressDocumentSchema, type AddressDocument } from "../../src/schema.js";
import { verifyGzippedState } from "../../src/verification-report.js";
import { PER_STATE_BOUNDARY_THRESHOLDS, verify } from "../../src/verify.js";

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

  it.each(["meshBlock", "sa1", "sa2", "sa3", "sa4", "gccsa"] as const)(
    "rejects near-total %s loss in both production verification paths",
    async (field) => {
      const docs = Array.from({ length: 100 }, (_, i) => document(i));
      for (const doc of docs.slice(1)) doc.boundaries[field] = null;
      const report = await verifyGzippedState(archive(docs), "VIC");
      expect(report.passed).toBe(false);
      expect(report.coverageBelowThreshold).toContainEqual({ field, actual: 1, threshold: 99 });
      const path = join(root, "vic.ndjson");
      writeFileSync(path, docs.map((doc) => JSON.stringify(doc)).join("\n") + "\n");
      const production = await verify({
        outputPath: path,
        expectedCount: 100,
        boundaryCoveragePerState: PER_STATE_BOUNDARY_THRESHOLDS,
      });
      expect(production.passed).toBe(false);
      expect(
        production.boundaryCoverageErrors.some((error) => error.field === `VIC.${field}`),
      ).toBe(true);
    },
  );

  it("allows isolated legitimate census nulls at exactly 99 percent coverage", async () => {
    const docs = Array.from({ length: 100 }, (_, i) => document(i));
    for (const field of ["meshBlock", "sa1", "sa2", "sa3", "sa4", "gccsa"] as const) {
      docs[0].boundaries[field] = null;
    }
    expect((await verifyGzippedState(archive(docs), "VIC")).passed).toBe(true);
  });

  it("does not let a healthy large state hide census loss in a small state", async () => {
    const docs = Array.from({ length: 1000 }, (_, i) => document(i));
    const missing = { ...document(1000), state: "NSW", postcode: "2000" };
    for (const field of ["meshBlock", "sa1", "sa2", "sa3", "sa4", "gccsa"] as const)
      missing.boundaries[field] = null;
    docs.push(missing);
    const path = join(root, "combined.ndjson");
    writeFileSync(path, docs.map((doc) => JSON.stringify(doc)).join("\n") + "\n");
    const result = await verify({
      outputPath: path,
      expectedCount: docs.length,
      boundaryCoveragePerState: PER_STATE_BOUNDARY_THRESHOLDS,
    });
    expect(result.passed).toBe(false);
    expect(result.boundaryCoverageErrors).toHaveLength(6);
    expect(result.boundaryCoverageErrors.every((error) => error.field.startsWith("NSW."))).toBe(
      true,
    );
  });

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
