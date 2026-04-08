/**
 * Unit tests for verification-report.ts — report formatting (P4.02).
 *
 * Note: verifyGzippedState() requires actual gzipped files — tested in integration.
 * These tests cover the report formatting logic.
 */

import { describe, it, expect } from "vitest";
import {
  formatVerificationReport,
  parseBoundaryThresholdsArg,
  parseStatesArg,
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
