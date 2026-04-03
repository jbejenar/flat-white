/**
 * flat-white — Output verification: row count + data quality checks.
 *
 * Compares NDJSON output line count against expected source count,
 * and runs data quality assertions (coordinate bounds, PID uniqueness,
 * boundary coverage, state/postcode cross-validation).
 */

import { createReadStream } from "node:fs";
import { createInterface } from "node:readline";

// Australian mainland + territories bounding box
const AU_LAT_MIN = -44.0;
const AU_LAT_MAX = -9.0;
const AU_LNG_MIN = 112.0;
const AU_LNG_MAX = 154.0;

// State → postcode range mapping (approximate)
const STATE_POSTCODE_RANGES: Record<string, [number, number][]> = {
  NSW: [
    [1000, 2599],
    [2619, 2899],
    [2921, 2999],
  ],
  VIC: [
    [3000, 3999],
    [8000, 8999],
  ],
  QLD: [
    [4000, 4999],
    [9000, 9999],
  ],
  SA: [[5000, 5999]],
  WA: [[6000, 6999]],
  TAS: [[7000, 7999]],
  NT: [[800, 999]],
  ACT: [
    [200, 299],
    [2600, 2618],
    [2900, 2920],
  ],
};

export interface VerifyOptions {
  /** Path to the NDJSON output file */
  outputPath: string;
  /** Expected row count from source (e.g. address_principals COUNT) */
  expectedCount: number;
  /** Tolerance as a fraction (0.001 = 0.1%). Default 0.001 */
  tolerance?: number;
}

export interface QualityIssue {
  pid: string;
  check: string;
  message: string;
}

export interface VerifyResult {
  outputCount: number;
  expectedCount: number;
  difference: number;
  differencePercent: number;
  passed: boolean;
  qualityIssues: QualityIssue[];
  boundaryCoverage: BoundaryCoverage;
  duplicatePids: string[];
}

export interface BoundaryCoverage {
  total: number;
  lga: number;
  ward: number;
  stateElectorate: number;
  commonwealthElectorate: number;
  meshBlock: number;
  sa1: number;
  sa2: number;
}

/**
 * Check if coordinates fall within Australian bounding box.
 */
export function isWithinAustralia(lat: number, lng: number): boolean {
  return lat >= AU_LAT_MIN && lat <= AU_LAT_MAX && lng >= AU_LNG_MIN && lng <= AU_LNG_MAX;
}

/**
 * Check if a postcode is valid for a given state.
 * Returns true if valid or if postcode/state is missing.
 */
export function isValidStatePostcode(state: string, postcode: string | null): boolean {
  if (!postcode) return true;
  const ranges = STATE_POSTCODE_RANGES[state];
  if (!ranges) return true; // Unknown state — don't flag
  const pc = parseInt(postcode, 10);
  if (isNaN(pc)) return true; // Non-numeric postcode — don't flag here
  return ranges.some(([min, max]) => pc >= min && pc <= max);
}

/**
 * Run row count verification and data quality checks against an NDJSON file.
 */
export async function verify(options: VerifyOptions): Promise<VerifyResult> {
  const { outputPath, expectedCount, tolerance = 0.001 } = options;

  const pids = new Set<string>();
  const duplicatePids: string[] = [];
  const qualityIssues: QualityIssue[] = [];
  let outputCount = 0;

  const coverage: BoundaryCoverage = {
    total: 0,
    lga: 0,
    ward: 0,
    stateElectorate: 0,
    commonwealthElectorate: 0,
    meshBlock: 0,
    sa1: 0,
    sa2: 0,
  };

  const rl = createInterface({
    input: createReadStream(outputPath),
    crlfDelay: Infinity,
  });

  for await (const line of rl) {
    if (!line.trim()) continue;
    outputCount++;

    const doc = JSON.parse(line) as Record<string, unknown>;
    const pid = doc._id as string;

    // PID uniqueness
    if (pids.has(pid)) {
      duplicatePids.push(pid);
    }
    pids.add(pid);

    // Coordinate bounding box
    const geocode = doc.geocode as { latitude: number; longitude: number } | null;
    if (geocode) {
      if (!isWithinAustralia(geocode.latitude, geocode.longitude)) {
        qualityIssues.push({
          pid,
          check: "coordinate-bounds",
          message: `Coordinates (${geocode.latitude}, ${geocode.longitude}) outside Australia`,
        });
      }
    }

    const allGeocodes = doc.allGeocodes as Array<{ lat: number; lng: number }> | null;
    if (allGeocodes) {
      for (const g of allGeocodes) {
        if (!isWithinAustralia(g.lat, g.lng)) {
          qualityIssues.push({
            pid,
            check: "coordinate-bounds",
            message: `allGeocodes entry (${g.lat}, ${g.lng}) outside Australia`,
          });
        }
      }
    }

    // State/postcode cross-validation
    const state = doc.state as string;
    const postcode = doc.postcode as string | null;
    if (!isValidStatePostcode(state, postcode)) {
      qualityIssues.push({
        pid,
        check: "state-postcode",
        message: `Postcode ${postcode} unexpected for state ${state}`,
      });
    }

    // Boundary coverage
    const boundaries = doc.boundaries as Record<string, unknown> | null;
    coverage.total++;
    if (boundaries) {
      if (boundaries.lga) coverage.lga++;
      if (boundaries.ward) coverage.ward++;
      if (boundaries.stateElectorate) coverage.stateElectorate++;
      if (boundaries.commonwealthElectorate) coverage.commonwealthElectorate++;
      if (boundaries.meshBlock) coverage.meshBlock++;
      if (boundaries.sa1) coverage.sa1++;
      if (boundaries.sa2) coverage.sa2++;
    }
  }

  const difference = Math.abs(outputCount - expectedCount);
  const differencePercent = expectedCount > 0 ? (difference / expectedCount) * 100 : 0;
  const passed = differencePercent <= tolerance * 100 && duplicatePids.length === 0;

  return {
    outputCount,
    expectedCount,
    difference,
    differencePercent,
    passed,
    qualityIssues,
    boundaryCoverage: coverage,
    duplicatePids,
  };
}

/**
 * Format a human-readable verification report.
 */
export function formatReport(result: VerifyResult): string {
  const lines: string[] = [];
  lines.push("=== Verification Report ===");
  lines.push(`Source count:  ${result.expectedCount}`);
  lines.push(`Output count:  ${result.outputCount}`);
  lines.push(`Difference:    ${result.difference} (${result.differencePercent.toFixed(3)}%)`);
  lines.push(
    `Row count:     ${result.difference === 0 ? "PASS" : result.differencePercent <= 0.1 ? "PASS (within tolerance)" : "FAIL"}`,
  );

  if (result.duplicatePids.length > 0) {
    lines.push(`Duplicate PIDs: FAIL (${result.duplicatePids.length} duplicates)`);
    for (const pid of result.duplicatePids.slice(0, 5)) {
      lines.push(`  - ${pid}`);
    }
  } else {
    lines.push("Duplicate PIDs: PASS (all unique)");
  }

  const cov = result.boundaryCoverage;
  if (cov.total > 0) {
    const pct = (n: number) => ((n / cov.total) * 100).toFixed(1);
    lines.push(`Boundary coverage (${cov.total} addresses):`);
    lines.push(`  LGA:                   ${pct(cov.lga)}%`);
    lines.push(`  Ward:                  ${pct(cov.ward)}%`);
    lines.push(`  State electorate:      ${pct(cov.stateElectorate)}%`);
    lines.push(`  Commonwealth elect.:   ${pct(cov.commonwealthElectorate)}%`);
    lines.push(`  Mesh block:            ${pct(cov.meshBlock)}%`);
    lines.push(`  SA1:                   ${pct(cov.sa1)}%`);
    lines.push(`  SA2:                   ${pct(cov.sa2)}%`);
  }

  if (result.qualityIssues.length > 0) {
    lines.push(`Quality issues: ${result.qualityIssues.length}`);
    for (const issue of result.qualityIssues.slice(0, 10)) {
      lines.push(`  [${issue.check}] ${issue.pid}: ${issue.message}`);
    }
    if (result.qualityIssues.length > 10) {
      lines.push(`  ... and ${result.qualityIssues.length - 10} more`);
    }
  } else {
    lines.push("Quality issues: PASS (none found)");
  }

  lines.push(`Overall: ${result.passed ? "PASS" : "FAIL"}`);
  return lines.join("\n");
}
