/**
 * Unit tests for compare-releases.ts — build-over-build comparison (P4.03).
 */

import { describe, it, expect } from "vitest";
import {
  compareMetadata,
  formatComparisonReport,
  type ComparisonResult,
} from "../../src/compare-releases.js";
import type { BuildMetadata } from "../../src/metadata.js";

function makeMeta(overrides: Partial<BuildMetadata> = {}): BuildMetadata {
  return {
    version: "2026.02",
    schemaVersion: "0.1.0",
    buildTimestamp: "2026-02-15T02:00:00Z",
    gnafLoaderVersion: "abc1234",
    states: { VIC: 3800000, NSW: 4500000, QLD: 2800000 },
    totalCount: 11100000,
    outputFiles: [],
    ...overrides,
  };
}

describe("compareMetadata", () => {
  it("detects no anomalies when counts are identical", () => {
    const current = makeMeta({ version: "2026.05" });
    const prior = makeMeta({ version: "2026.02" });
    const result = compareMetadata(current, prior);

    expect(result.hasAnomalies).toBe(false);
    expect(result.totalDelta).toBe(0);
    expect(result.totalDeltaPercent).toBe(0);
    expect(result.states.every((s) => !s.isAnomaly)).toBe(true);
  });

  it("detects anomaly when total changes >1%", () => {
    const current = makeMeta({
      version: "2026.05",
      states: { VIC: 3800000, NSW: 4500000, QLD: 2800000 },
      totalCount: 11100000,
    });
    const prior = makeMeta({
      version: "2026.02",
      states: { VIC: 3800000, NSW: 4500000, QLD: 2500000 },
      totalCount: 10800000,
    });

    const result = compareMetadata(current, prior);
    expect(result.hasAnomalies).toBe(true);

    const qldDelta = result.states.find((s) => s.state === "QLD");
    expect(qldDelta?.isAnomaly).toBe(true);
    expect(qldDelta?.delta).toBe(300000);
  });

  it("respects custom threshold", () => {
    const current = makeMeta({
      version: "2026.05",
      states: { VIC: 3819000, NSW: 4500000, QLD: 2800000 },
      totalCount: 11119000,
    });
    const prior = makeMeta({ version: "2026.02" });

    // VIC delta = 19000/3800000 = 0.5% — not anomalous at 1% threshold
    const result1 = compareMetadata(current, prior, 1.0);
    const vicDelta1 = result1.states.find((s) => s.state === "VIC");
    expect(vicDelta1?.isAnomaly).toBe(false);

    // 0.5% change in VIC — anomalous at 0.1% threshold
    const result2 = compareMetadata(current, prior, 0.1);
    const vicDelta2 = result2.states.find((s) => s.state === "VIC");
    expect(vicDelta2?.isAnomaly).toBe(true);
  });

  it("detects new states", () => {
    const current = makeMeta({
      version: "2026.05",
      states: { VIC: 3800000, NSW: 4500000, QLD: 2800000, SA: 1200000 },
      totalCount: 12300000,
    });
    const prior = makeMeta({ version: "2026.02" });

    const result = compareMetadata(current, prior);
    expect(result.newStates).toContain("SA");
    expect(result.hasAnomalies).toBe(true);
  });

  it("detects retired states", () => {
    const current = makeMeta({
      version: "2026.05",
      states: { VIC: 3800000, NSW: 4500000 },
      totalCount: 8300000,
    });
    const prior = makeMeta({ version: "2026.02" });

    const result = compareMetadata(current, prior);
    expect(result.retiredStates).toContain("QLD");
    expect(result.hasAnomalies).toBe(true);
  });

  it("handles zero prior counts gracefully", () => {
    const current = makeMeta({
      version: "2026.05",
      states: { VIC: 100 },
      totalCount: 100,
    });
    const prior = makeMeta({
      version: "2026.02",
      states: { VIC: 0 },
      totalCount: 0,
    });

    const result = compareMetadata(current, prior);
    const vicDelta = result.states.find((s) => s.state === "VIC");
    expect(vicDelta?.deltaPercent).toBe(100);
    expect(vicDelta?.isAnomaly).toBe(true);
  });

  it("reports no anomalies for small changes within threshold", () => {
    const current = makeMeta({
      version: "2026.05",
      states: { VIC: 3800100, NSW: 4499950, QLD: 2800050 },
      totalCount: 11100100,
    });
    const prior = makeMeta({ version: "2026.02" });

    const result = compareMetadata(current, prior);
    expect(result.hasAnomalies).toBe(false);
    expect(result.states.every((s) => !s.isAnomaly)).toBe(true);
  });
});

describe("formatComparisonReport", () => {
  it("produces valid markdown with no anomalies", () => {
    const current = makeMeta({ version: "2026.05" });
    const prior = makeMeta({ version: "2026.02" });
    const result = compareMetadata(current, prior);
    const report = formatComparisonReport(result);

    expect(report).toContain("# Build-Over-Build Comparison");
    expect(report).toContain("2026.05");
    expect(report).toContain("2026.02");
    expect(report).toContain("No Anomalies");
    expect(report).not.toContain("Anomalies Detected");
  });

  it("produces valid markdown with anomalies", () => {
    const current = makeMeta({
      version: "2026.05",
      states: { VIC: 3800000, NSW: 4500000, QLD: 2500000 },
      totalCount: 10800000,
    });
    const prior = makeMeta({ version: "2026.02" });
    const result = compareMetadata(current, prior);
    const report = formatComparisonReport(result);

    expect(report).toContain("Anomalies Detected");
    expect(report).toContain("QLD");
  });
});
