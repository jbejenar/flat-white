/**
 * Unit tests for verify.ts — row count verification and data quality checks.
 */

import { describe, it, expect, beforeAll, afterAll } from "vitest";
import { writeFileSync, mkdirSync, unlinkSync, existsSync, readdirSync, rmdirSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import {
  verify,
  formatReport,
  isWithinAustralia,
  isValidStatePostcode,
  DEFAULT_BOUNDARY_THRESHOLDS,
  type EnumSets,
  type BoundaryCoverageThresholds,
} from "../../src/verify.js";

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

  it("passes enum checks with fixture-derived authority values", async () => {
    // These are the actual values present in the fixture's authority tables
    const fixtureEnumSets: EnumSets = {
      streetType: new Set([
        "AVENUE",
        "BOULEVARD",
        "CHASE",
        "CIRCUIT",
        "CLOSE",
        "COURT",
        "CRESCENT",
        "DRIVE",
        "ESPLANADE",
        "GROVE",
        "HIGHWAY",
        "LANE",
        "PARADE",
        "PLACE",
        "RISE",
        "ROAD",
        "SQUARE",
        "STREET",
        "TERRACE",
        "WALK",
        "WAY",
      ]),
      flatType: new Set([
        "APARTMENT",
        "CARPARK",
        "CARSPACE",
        "FACTORY",
        "FLAT",
        "SHOP",
        "SITE",
        "SUITE",
        "UNIT",
      ]),
      levelType: new Set(["FLOOR", "LEVEL"]),
      streetSuffix: new Set(["EAST", "NORTH", "WEST"]),
      localityClass: new Set(["GAZETTED LOCALITY"]),
      state: new Set(["NSW", "VIC", "QLD", "WA", "SA", "TAS", "ACT", "NT", "OT"]),
    };
    const result = await verify({
      outputPath: fixturePath,
      expectedCount: 451,
      enumSets: fixtureEnumSets,
    });
    expect(result.passed).toBe(true);
    expect(Object.keys(result.enumUnknownCounts)).toHaveLength(0);
  });

  it("reports high boundary coverage", async () => {
    const result = await verify({ outputPath: fixturePath, expectedCount: 451 });
    const cov = result.boundaryCoverage;
    expect(cov.lga / cov.total).toBeGreaterThan(0.99);
    expect(cov.stateElectorate / cov.total).toBeGreaterThan(0.98);
  });
});

describe("enum-ish field validation", () => {
  const validEnumSets: EnumSets = {
    streetType: new Set(["STREET", "AVENUE", "ROAD", "PLACE", "DRIVE"]),
    flatType: new Set(["FLAT", "UNIT", "APARTMENT"]),
    levelType: new Set(["LEVEL", "FLOOR"]),
    streetSuffix: new Set(["NORTH", "SOUTH", "EAST", "WEST"]),
    localityClass: new Set(["GAZETTED LOCALITY"]),
    state: new Set(["NSW", "VIC", "QLD", "WA", "SA", "TAS", "ACT", "NT", "OT"]),
  };

  it("passes when all enum-ish fields have valid values", async () => {
    const docs = [
      makeDoc({ _id: "ENUM_OK", streetType: "STREET", flatType: "FLAT", state: "VIC" }),
    ];
    const path = tmpFile("enum-valid.ndjson");
    writeNdjson(path, docs);

    const result = await verify({
      outputPath: path,
      expectedCount: 1,
      enumSets: validEnumSets,
    });
    expect(result.passed).toBe(true);
    expect(Object.keys(result.enumUnknownCounts)).toHaveLength(0);
  });

  it("fails when streetType has an abbreviation instead of long form", async () => {
    const docs = [makeDoc({ _id: "ENUM_BAD_ST", streetType: "PL" })];
    const path = tmpFile("enum-bad-streettype.ndjson");
    writeNdjson(path, docs);

    const result = await verify({
      outputPath: path,
      expectedCount: 1,
      enumSets: validEnumSets,
    });
    expect(result.passed).toBe(false);
    expect(result.enumUnknownCounts.streetType).toBe(1);
    expect(result.qualityErrors.some((e) => e.check === "enum-value")).toBe(true);
  });

  it("accepts null for nullable enum-ish fields", async () => {
    const docs = [
      makeDoc({
        _id: "ENUM_NULL",
        streetType: null,
        flatType: null,
        levelType: null,
        streetSuffix: null,
      }),
    ];
    const path = tmpFile("enum-null.ndjson");
    writeNdjson(path, docs);

    const result = await verify({
      outputPath: path,
      expectedCount: 1,
      enumSets: validEnumSets,
    });
    expect(result.passed).toBe(true);
    expect(Object.keys(result.enumUnknownCounts)).toHaveLength(0);
  });

  it("skips enum check when enumSets is not provided (backward compatible)", async () => {
    const docs = [makeDoc({ _id: "ENUM_SKIP", streetType: "BOGUS_VALUE" })];
    const path = tmpFile("enum-skip.ndjson");
    writeNdjson(path, docs);

    const result = await verify({ outputPath: path, expectedCount: 1 });
    expect(result.passed).toBe(true);
    expect(Object.keys(result.enumUnknownCounts)).toHaveLength(0);
  });

  it("validates localityClass nested inside locality object", async () => {
    const docs = [
      makeDoc({
        _id: "ENUM_LOC",
        locality: { pid: "LOC1", class: "INVALID CLASS", neighbours: [], aliases: [] },
      }),
    ];
    const path = tmpFile("enum-bad-locality.ndjson");
    writeNdjson(path, docs);

    const result = await verify({
      outputPath: path,
      expectedCount: 1,
      enumSets: validEnumSets,
    });
    expect(result.passed).toBe(false);
    expect(result.enumUnknownCounts.localityClass).toBe(1);
  });

  it("counts multiple unknown values per field across documents", async () => {
    const docs = [
      makeDoc({ _id: "E1", streetType: "BOGUS" }),
      makeDoc({ _id: "E2", streetType: "ALSO_BOGUS" }),
      makeDoc({ _id: "E3", streetType: "STREET" }),
    ];
    const path = tmpFile("enum-multi.ndjson");
    writeNdjson(path, docs);

    const result = await verify({
      outputPath: path,
      expectedCount: 3,
      enumSets: validEnumSets,
    });
    expect(result.passed).toBe(false);
    expect(result.enumUnknownCounts.streetType).toBe(2);
  });
});

describe("boundary coverage thresholds", () => {
  it("fails when LGA coverage drops below threshold", async () => {
    // 10 docs: only 5 have LGA → 50% coverage, threshold is 99%
    const docs = Array.from({ length: 10 }, (_, i) =>
      makeDoc({
        _id: `BT${i}`,
        boundaries:
          i < 5
            ? {
                lga: { name: "Melbourne", code: "LGA1" },
                ward: { name: "Test Ward" },
                stateElectorate: { name: "Melbourne" },
                commonwealthElectorate: { name: "Melbourne" },
                meshBlock: { code: "123", category: "Residential" },
                sa1: "12345",
                sa2: { code: "123", name: "Test" },
              }
            : {
                lga: null,
                ward: { name: "Test Ward" },
                stateElectorate: { name: "Melbourne" },
                commonwealthElectorate: { name: "Melbourne" },
                meshBlock: null,
                sa1: null,
                sa2: null,
              },
      }),
    );
    const path = tmpFile("boundary-low-lga.ndjson");
    writeNdjson(path, docs);

    const result = await verify({
      outputPath: path,
      expectedCount: 10,
      boundaryCoverageThresholds: DEFAULT_BOUNDARY_THRESHOLDS,
    });
    expect(result.passed).toBe(false);
    expect(result.boundaryCoverageChecked).toBe(true);
    expect(result.boundaryCoverageErrors.length).toBeGreaterThan(0);
    expect(result.boundaryCoverageErrors.some((e) => e.field === "lga")).toBe(true);
  });

  it("passes when all coverage exceeds thresholds", async () => {
    const docs = Array.from({ length: 10 }, (_, i) => makeDoc({ _id: `BTP${i}` }));
    const path = tmpFile("boundary-pass.ndjson");
    writeNdjson(path, docs);

    const result = await verify({
      outputPath: path,
      expectedCount: 10,
      boundaryCoverageThresholds: DEFAULT_BOUNDARY_THRESHOLDS,
    });
    expect(result.passed).toBe(true);
    expect(result.boundaryCoverageChecked).toBe(true);
    expect(result.boundaryCoverageErrors.length).toBe(0);
  });

  it("skips threshold check when not provided (backward compatible)", async () => {
    // All boundaries null — would fail with thresholds, passes without
    const docs = Array.from({ length: 5 }, (_, i) =>
      makeDoc({
        _id: `BTS${i}`,
        boundaries: {
          lga: null,
          ward: null,
          stateElectorate: null,
          commonwealthElectorate: null,
          meshBlock: null,
          sa1: null,
          sa2: null,
        },
      }),
    );
    const path = tmpFile("boundary-skip.ndjson");
    writeNdjson(path, docs);

    const result = await verify({ outputPath: path, expectedCount: 5 });
    expect(result.passed).toBe(true);
    expect(result.boundaryCoverageChecked).toBe(false);
    expect(result.boundaryCoverageErrors.length).toBe(0);
  });

  it("checks only specified threshold fields", async () => {
    // All ward null, but only check LGA threshold (which is at 100%)
    const docs = Array.from({ length: 5 }, (_, i) =>
      makeDoc({
        _id: `BTP2${i}`,
        boundaries: {
          lga: { name: "Melbourne", code: "LGA1" },
          ward: null,
          stateElectorate: { name: "Melbourne" },
          commonwealthElectorate: { name: "Melbourne" },
          meshBlock: { code: "123", category: "Residential" },
          sa1: "12345",
          sa2: { code: "123", name: "Test" },
        },
      }),
    );
    const path = tmpFile("boundary-partial.ndjson");
    writeNdjson(path, docs);

    const partial: BoundaryCoverageThresholds = { lga: 0.99 };
    const result = await verify({
      outputPath: path,
      expectedCount: 5,
      boundaryCoverageThresholds: partial,
    });
    expect(result.passed).toBe(true);
    expect(result.boundaryCoverageErrors.length).toBe(0);
  });

  it("reports correct actual vs threshold in errors", async () => {
    // 0 out of 4 have ward → 0% coverage
    const docs = Array.from({ length: 4 }, (_, i) =>
      makeDoc({
        _id: `BTE${i}`,
        boundaries: {
          lga: { name: "Melbourne", code: "LGA1" },
          ward: null,
          stateElectorate: { name: "Melbourne" },
          commonwealthElectorate: { name: "Melbourne" },
          meshBlock: null,
          sa1: null,
          sa2: null,
        },
      }),
    );
    const path = tmpFile("boundary-error-detail.ndjson");
    writeNdjson(path, docs);

    const result = await verify({
      outputPath: path,
      expectedCount: 4,
      boundaryCoverageThresholds: { ward: 0.95 },
    });
    expect(result.passed).toBe(false);
    expect(result.boundaryCoverageErrors).toHaveLength(1);
    expect(result.boundaryCoverageErrors[0].field).toBe("ward");
    expect(result.boundaryCoverageErrors[0].actual).toBe(0);
    expect(result.boundaryCoverageErrors[0].threshold).toBe(0.95);
  });
});

describe("verify against fixture with boundary thresholds", () => {
  const fixturePath = resolve(__dirname, "../../fixtures/expected-output.ndjson");

  it("passes boundary coverage thresholds against fixture data", async () => {
    const result = await verify({
      outputPath: fixturePath,
      expectedCount: 451,
      boundaryCoverageThresholds: DEFAULT_BOUNDARY_THRESHOLDS,
    });
    expect(result.passed).toBe(true);
    expect(result.boundaryCoverageChecked).toBe(true);
    expect(result.boundaryCoverageErrors.length).toBe(0);
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

  it("shows boundary threshold failures in report", async () => {
    const docs = Array.from({ length: 4 }, (_, i) =>
      makeDoc({
        _id: `FR${i}`,
        boundaries: {
          lga: null,
          ward: null,
          stateElectorate: null,
          commonwealthElectorate: null,
          meshBlock: null,
          sa1: null,
          sa2: null,
        },
      }),
    );
    const path = tmpFile("report-boundary-fail.ndjson");
    writeNdjson(path, docs);

    const result = await verify({
      outputPath: path,
      expectedCount: 4,
      boundaryCoverageThresholds: DEFAULT_BOUNDARY_THRESHOLDS,
    });
    const report = formatReport(result);
    expect(report).toContain("Boundary coverage: FAIL");
    expect(report).toContain("lga:");
    expect(report).toContain("threshold:");
  });
});
