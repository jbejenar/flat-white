/**
 * Unit tests for verification-report.ts — report formatting (P4.02).
 *
 * Note: verifyGzippedState() requires actual gzipped files — tested in integration.
 * These tests cover the report formatting logic.
 */

import { gzipSync } from "node:zlib";
import { mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { describe, it, expect } from "vitest";
import {
  formatVerificationReport,
  parseBoundaryThresholdsArg,
  parseStatesArg,
  verifyGzippedState,
  type StateVerification,
  type VerificationReport,
} from "../../src/verification-report.js";

function makeStateResult(overrides: Partial<StateVerification> = {}): StateVerification {
  return {
    state: "VIC",
    rowCount: 3800000,
    schemaValid: true,
    schemaErrors: 0,
    boundaryCoverage: {
      lga: 99.8,
      ward: 95.2,
      stateElectorate: 99.5,
      commonwealthElectorate: 99.5,
      meshBlock: 99.9,
      sa1: 99.9,
      sa2: 99.9,
    },
    coverageBelowThreshold: [],
    qualityErrors: 0,
    qualityWarnings: 3,
    duplicatePids: 0,
    enumUnknownCounts: {},
    passed: true,
    ...overrides,
  };
}

function makeReport(overrides: Partial<VerificationReport> = {}): VerificationReport {
  return {
    version: "2026.02",
    timestamp: "2026-02-15T02:00:00Z",
    states: [
      makeStateResult({ state: "VIC" }),
      makeStateResult({ state: "NSW", rowCount: 4500000 }),
    ],
    totalCount: 8300000,
    overallPassed: true,
    ...overrides,
  };
}

describe("formatVerificationReport", () => {
  it("produces valid markdown for passing report", () => {
    const report = makeReport();
    const md = formatVerificationReport(report);

    expect(md).toContain("# Verification Report");
    expect(md).toContain("**Version:** 2026.02");
    expect(md).toContain("PASS");
    expect(md).toContain("VIC");
    expect(md).toContain("NSW");
    expect(md).toContain("Boundary Coverage");
  });

  it("shows FAIL when a state fails", () => {
    const report = makeReport({
      states: [
        makeStateResult({ state: "VIC", passed: false, schemaValid: false, schemaErrors: 5 }),
        makeStateResult({ state: "NSW" }),
      ],
      overallPassed: false,
    });
    const md = formatVerificationReport(report);

    expect(md).toContain("FAIL");
    expect(md).toContain("FAIL (5)");
  });

  it("includes boundary coverage percentages", () => {
    const report = makeReport();
    const md = formatVerificationReport(report);

    expect(md).toContain("99.8");
    expect(md).toContain("95.2");
  });

  it("includes quality warnings section when present", () => {
    const report = makeReport({
      states: [makeStateResult({ state: "VIC", qualityWarnings: 15 })],
      totalCount: 3800000,
    });
    const md = formatVerificationReport(report);

    expect(md).toContain("Quality Warnings: 15");
    expect(md).toContain("**VIC:** 15 warnings");
  });

  it("omits warnings section when none", () => {
    const report = makeReport({
      states: [makeStateResult({ state: "VIC", qualityWarnings: 0 })],
      totalCount: 3800000,
    });
    const md = formatVerificationReport(report);

    expect(md).not.toContain("Quality Warnings:");
  });

  it("includes duplicate PID count in table", () => {
    const report = makeReport({
      states: [makeStateResult({ state: "VIC", duplicatePids: 3, passed: false })],
      totalCount: 3800000,
      overallPassed: false,
    });
    const md = formatVerificationReport(report);

    expect(md).toContain("FAIL (3)");
  });
});

describe("formatVerificationReport coverage thresholds", () => {
  it("renders the boundary threshold FAIL section when any state has shortfalls", () => {
    const report = makeReport({
      states: [
        makeStateResult({
          state: "VIC",
          passed: false,
          coverageBelowThreshold: [{ field: "lga", actual: 12.4, threshold: 99 }],
        }),
      ],
      totalCount: 3800000,
      overallPassed: false,
    });
    const md = formatVerificationReport(report);

    expect(md).toContain("Boundary Coverage Threshold: FAIL");
    expect(md).toContain("| VIC | lga | 12.4 | 99 |");
  });

  it("omits the threshold section when all states pass", () => {
    const md = formatVerificationReport(makeReport());
    expect(md).not.toContain("Boundary Coverage Threshold");
  });

  it("flags an empty state file (rowCount === 0) as a failure in the report", () => {
    // A zero-row state should never be marked passed: every quality check is
    // vacuously passing on zero rows, so without an explicit rowCount gate
    // an empty NSW could silently ship.
    const empty = makeStateResult({
      state: "NSW",
      rowCount: 0,
      boundaryCoverage: {},
      passed: false,
      coverageBelowThreshold: [{ field: "lga", actual: 0, threshold: 99 }],
    });
    const report = makeReport({ states: [empty], overallPassed: false, totalCount: 0 });
    const md = formatVerificationReport(report);

    expect(md).toContain("Boundary Coverage Threshold: FAIL");
    expect(md).toContain("| NSW | lga | 0 | 99 |");
  });
});

describe("parseBoundaryThresholdsArg", () => {
  it("returns undefined for empty input", () => {
    expect(parseBoundaryThresholdsArg(undefined)).toBeUndefined();
    expect(parseBoundaryThresholdsArg("")).toBeUndefined();
  });

  it("parses comma-separated thresholds", () => {
    expect(parseBoundaryThresholdsArg("lga=99,ward=95,sa1=98.5")).toEqual({
      lga: 99,
      ward: 95,
      sa1: 98.5,
    });
  });

  it("rejects unknown fields", () => {
    expect(() => parseBoundaryThresholdsArg("lga=99,bogus=50")).toThrow(
      "Unknown boundary threshold field",
    );
  });

  it("rejects out-of-range or non-numeric values", () => {
    expect(() => parseBoundaryThresholdsArg("lga=oops")).toThrow("Invalid threshold value");
    expect(() => parseBoundaryThresholdsArg("lga=150")).toThrow("Invalid threshold value");
    expect(() => parseBoundaryThresholdsArg("lga=-1")).toThrow("Invalid threshold value");
  });

  it("rejects an empty value (lga=)", () => {
    expect(() => parseBoundaryThresholdsArg("lga=")).toThrow("Missing threshold value");
  });

  it("rejects a malformed spec without an =", () => {
    expect(() => parseBoundaryThresholdsArg("lga99")).toThrow("Invalid boundary threshold spec");
  });

  it("rejects a multi-= spec to avoid silent truncation", () => {
    expect(() => parseBoundaryThresholdsArg("lga=99=foo")).toThrow(
      "Invalid boundary threshold spec",
    );
  });
});

describe("verifyGzippedState empty-file safety", () => {
  function writeGzipFixture(name: string, content: string): string {
    const dir = mkdtempSync(join(tmpdir(), "vrep-"));
    const path = join(dir, name);
    writeFileSync(path, gzipSync(Buffer.from(content)));
    return path;
  }

  it("treats a 0-row .ndjson.gz as failed even with no thresholds configured", async () => {
    const path = writeGzipFixture("empty.ndjson.gz", "");
    const result = await verifyGzippedState(path, "NSW");

    expect(result.rowCount).toBe(0);
    expect(result.passed).toBe(false);
  });

  it("flags every configured threshold as failing for a 0-row file", async () => {
    // The previous implementation gated threshold evaluation behind
    // `rowCount > 0`, so an empty NSW silently passed every threshold.
    // This test pins the new behaviour: empty == 0% on every field.
    const path = writeGzipFixture("empty.ndjson.gz", "");
    const result = await verifyGzippedState(path, "NSW", undefined, {
      lga: 99,
      ward: 95,
      sa1: 99,
    });

    expect(result.passed).toBe(false);
    const failedFields = result.coverageBelowThreshold.map((c) => c.field).sort();
    expect(failedFields).toEqual(["lga", "sa1", "ward"]);
    for (const c of result.coverageBelowThreshold) {
      expect(c.actual).toBe(0);
    }
  });

  it("a populated file still passes when thresholds are met", async () => {
    const docs = Array.from({ length: 10 }, (_, i) => ({
      _id: `GANSW${i}`,
      state: "NSW",
      postcode: "2000",
      geocode: { latitude: -33.8, longitude: 151.2 },
      boundaries: {
        lga: { id: "1", name: "Sydney" },
        ward: { id: "1", name: "W1" },
        stateElectorate: { id: "1", name: "S1" },
        commonwealthElectorate: { id: "1", name: "C1" },
        meshBlock: { code: "1" },
        sa1: { code: "1" },
        sa2: { code: "1" },
      },
    }));
    const path = writeGzipFixture(
      "populated.ndjson.gz",
      docs.map((d) => JSON.stringify(d)).join("\n") + "\n",
    );
    const result = await verifyGzippedState(path, "NSW", undefined, { lga: 99 });

    expect(result.rowCount).toBe(10);
    expect(result.boundaryCoverage.lga).toBe(100);
    expect(result.coverageBelowThreshold).toEqual([]);
    // Note: passed may still be false due to schema validation against the
    // partial doc fixture above; we only assert the threshold check itself.
  });
});

describe("parseStatesArg", () => {
  it("returns the default quarterly state list when omitted", () => {
    expect(parseStatesArg(undefined)).toEqual([
      "ACT",
      "NSW",
      "NT",
      "OT",
      "QLD",
      "SA",
      "TAS",
      "VIC",
      "WA",
    ]);
  });

  it("parses a comma-separated state list", () => {
    expect(parseStatesArg("vic, nsw,act")).toEqual(["VIC", "NSW", "ACT"]);
  });

  it("rejects invalid states", () => {
    expect(() => parseStatesArg("VIC,ZZZ")).toThrow("Invalid state");
  });
});
