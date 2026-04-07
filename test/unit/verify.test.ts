/**
 * Unit tests for verify.ts — row count verification and data quality checks.
 */

import { describe, it, expect, beforeAll, afterAll } from "vitest";
import { writeFileSync, mkdirSync, unlinkSync, existsSync, readdirSync, rmdirSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { verify, formatReport, isWithinAustralia, isValidStatePostcode } from "../../src/verify.js";

const __dirname = dirname(fileURLToPath(import.meta.url));
const TMP_DIR = resolve(__dirname, "../../.tmp-test");

function tmpFile(name: string): string {
  return resolve(TMP_DIR, name);
}

function writeNdjson(path: string, docs: Record<string, unknown>[]): void {
  writeFileSync(path, docs.map((d) => JSON.stringify(d)).join("\n") + "\n");
}

function makeDoc(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    _id: `GAVIC${Math.random().toString(36).slice(2, 10)}`,
    addressLabel: "1 TEST ST, TESTVILLE VIC 3000",
    state: "VIC",
    postcode: "3000",
    geocode: { latitude: -37.8, longitude: 144.9, type: "FRONTAGE CENTRE SETBACK", reliability: 2 },
    allGeocodes: [{ lat: -37.8, lng: 144.9, type: "FRONTAGE CENTRE SETBACK", reliability: 2 }],
    boundaries: {
      lga: { name: "Melbourne", code: "LGA1" },
      ward: { name: "Test Ward" },
      stateElectorate: { name: "Melbourne" },
      commonwealthElectorate: { name: "Melbourne" },
      meshBlock: { code: "123", category: "Residential" },
      sa1: "12345",
      sa2: { code: "123", name: "Test" },
    },
    ...overrides,
  };
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

describe("isWithinAustralia", () => {
  it("returns true for Melbourne coordinates", () => {
    expect(isWithinAustralia(-37.8136, 144.9631)).toBe(true);
  });

  it("returns true for Perth coordinates", () => {
    expect(isWithinAustralia(-31.9505, 115.8605)).toBe(true);
  });

  it("returns false for London coordinates", () => {
    expect(isWithinAustralia(51.5074, -0.1278)).toBe(false);
  });

  it("returns false for 0,0 (Atlantic Ocean)", () => {
    expect(isWithinAustralia(0, 0)).toBe(false);
  });

  it("returns true for Tasmania (-42 lat)", () => {
    expect(isWithinAustralia(-42.8821, 147.3272)).toBe(true);
  });

  it("returns true for Darwin (-12 lat)", () => {
    expect(isWithinAustralia(-12.4634, 130.8456)).toBe(true);
  });
});

describe("isValidStatePostcode", () => {
  it("accepts VIC 3000", () => {
    expect(isValidStatePostcode("VIC", "3000")).toBe(true);
  });

  it("accepts NSW 2000", () => {
    expect(isValidStatePostcode("NSW", "2000")).toBe(true);
  });

  it("rejects VIC with NSW postcode 2000", () => {
    expect(isValidStatePostcode("VIC", "2000")).toBe(false);
  });

  it("accepts null postcode", () => {
    expect(isValidStatePostcode("VIC", null)).toBe(true);
  });

  it("accepts ACT 2600", () => {
    expect(isValidStatePostcode("ACT", "2600")).toBe(true);
  });

  it("accepts NT 0800", () => {
    expect(isValidStatePostcode("NT", "0800")).toBe(true);
  });
});

describe("verify", () => {
  it("passes when counts match exactly", async () => {
    const docs = [makeDoc({ _id: "A1" }), makeDoc({ _id: "A2" }), makeDoc({ _id: "A3" })];
    const path = tmpFile("exact-match.ndjson");
    writeNdjson(path, docs);

    const result = await verify({ outputPath: path, expectedCount: 3 });
    expect(result.passed).toBe(true);
    expect(result.outputCount).toBe(3);
    expect(result.difference).toBe(0);
    expect(result.duplicatePids.length).toBe(0);
  });

  it("fails when counts differ beyond tolerance", async () => {
    const docs = [makeDoc({ _id: "A1" }), makeDoc({ _id: "A2" })];
    const path = tmpFile("count-mismatch.ndjson");
    writeNdjson(path, docs);

    const result = await verify({ outputPath: path, expectedCount: 100 });
    expect(result.passed).toBe(false);
    expect(result.difference).toBe(98);
  });

  it("detects duplicate PIDs", async () => {
    const docs = [makeDoc({ _id: "DUP1" }), makeDoc({ _id: "DUP1" }), makeDoc({ _id: "A3" })];
    const path = tmpFile("dup-pids.ndjson");
    writeNdjson(path, docs);

    const result = await verify({ outputPath: path, expectedCount: 3 });
    expect(result.passed).toBe(false);
    expect(result.duplicatePids).toContain("DUP1");
  });

  it("flags coordinates outside Australia", async () => {
    const docs = [
      makeDoc({
        _id: "BAD_GEO",
        geocode: { latitude: 0, longitude: 0, type: "FRONTAGE CENTRE SETBACK", reliability: 2 },
        allGeocodes: [{ lat: 0, lng: 0, type: "FRONTAGE CENTRE SETBACK", reliability: 2 }],
      }),
    ];
    const path = tmpFile("bad-geo.ndjson");
    writeNdjson(path, docs);

    const result = await verify({ outputPath: path, expectedCount: 1 });
    expect(result.passed).toBe(false);
    expect(result.qualityErrors.length).toBeGreaterThan(0);
    expect(result.qualityErrors[0].pid).toBe("BAD_GEO");
    expect(result.qualityErrors[0].check).toBe("coordinate-bounds");
  });

  it("flags state/postcode mismatches", async () => {
    const docs = [makeDoc({ _id: "BAD_PC", state: "VIC", postcode: "2000" })];
    const path = tmpFile("bad-postcode.ndjson");
    writeNdjson(path, docs);

    const result = await verify({ outputPath: path, expectedCount: 1 });
    expect(result.passed).toBe(true); // state-postcode is a warning, not an error
    expect(result.qualityWarnings.length).toBe(1);
    expect(result.qualityWarnings[0].check).toBe("state-postcode");
  });

  it("reports boundary coverage", async () => {
    const fullBoundary = makeDoc({ _id: "FULL" });
    const noBoundary = makeDoc({
      _id: "NONE",
      boundaries: {
        lga: null,
        ward: null,
        stateElectorate: null,
        commonwealthElectorate: null,
        meshBlock: null,
        sa1: null,
        sa2: null,
      },
    });
    const path = tmpFile("coverage.ndjson");
    writeNdjson(path, [fullBoundary, noBoundary]);

    const result = await verify({ outputPath: path, expectedCount: 2 });
    expect(result.boundaryCoverage.total).toBe(2);
    expect(result.boundaryCoverage.lga).toBe(1);
    expect(result.boundaryCoverage.ward).toBe(1);
  });

  it("handles null geocode gracefully", async () => {
    const docs = [makeDoc({ _id: "NULL_GEO", geocode: null, allGeocodes: [] })];
    const path = tmpFile("null-geo.ndjson");
    writeNdjson(path, docs);

    const result = await verify({ outputPath: path, expectedCount: 1 });
    expect(result.qualityIssues.filter((i) => i.check === "coordinate-bounds").length).toBe(0);
  });
});

describe("verify against fixture expected-output.ndjson", () => {
  const fixturePath = resolve(__dirname, "../../fixtures/expected-output.ndjson");

  it("passes all quality checks", async () => {
    const result = await verify({ outputPath: fixturePath, expectedCount: 451 });
    expect(result.passed).toBe(true);
    expect(result.outputCount).toBe(451);
    expect(result.difference).toBe(0);
    expect(result.duplicatePids.length).toBe(0);
    expect(result.qualityErrors.length).toBe(0);
    expect(result.qualityWarnings.length).toBe(0);
  });

  it("reports high boundary coverage", async () => {
    const result = await verify({ outputPath: fixturePath, expectedCount: 451 });
    const cov = result.boundaryCoverage;
    expect(cov.lga / cov.total).toBeGreaterThan(0.99);
    expect(cov.stateElectorate / cov.total).toBeGreaterThan(0.98);
  });
});

describe("formatReport", () => {
  it("produces readable output", async () => {
    const docs = [makeDoc({ _id: "A1" }), makeDoc({ _id: "A2" })];
    const path = tmpFile("report.ndjson");
    writeNdjson(path, docs);

    const result = await verify({ outputPath: path, expectedCount: 2 });
    const report = formatReport(result);
    expect(report).toContain("PASS");
    expect(report).toContain("Source count:");
    expect(report).toContain("Boundary coverage");
  });
});
