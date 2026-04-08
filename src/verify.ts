/**
 * flat-white — Output verification: row count + data quality checks.
 *
 * Compares NDJSON output line count against expected source count,
 * and runs data quality assertions (coordinate bounds, PID uniqueness,
 * boundary coverage, state/postcode cross-validation, enum-ish field validation).
 */

import { createReadStream } from "node:fs";
import { createInterface } from "node:readline";
import { fileURLToPath } from "node:url";
import { resolve } from "node:path";
import type { Sql } from "postgres";

// Australian bounding box including external territories
// Mainland: -44 to -10 lat, 112 to 154 lng
// Christmas Island: -10.57, 105.53
// Cocos (Keeling) Islands: -12.21, 96.82
// Norfolk Island: -29.08, 167.96
// Lord Howe Island: -31.56, 159.08
const AU_LAT_MIN = -44.0;
const AU_LAT_MAX = -9.0;
const AU_LNG_MIN = 96.0; // Cocos Islands
const AU_LNG_MAX = 168.0; // Norfolk Island

// State → postcode range mapping (approximate).
// Border localities may have cross-state postcodes — these are logged as
// warnings, not hard errors (see qualityWarnings in verify()).
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

const VALID_STATES = new Set(["NSW", "VIC", "QLD", "WA", "SA", "TAS", "ACT", "NT", "OT"]);

/**
 * Valid value sets for enum-ish fields, keyed by output field name.
 * Built by queryEnumSets() from authority tables, or constructed manually for tests.
 */
export type EnumSets = Record<string, Set<string>>;

/** Per-field count of documents with unknown enum values. */
export type EnumUnknownCounts = Record<string, number>;

/**
 * Names of enum-ish fields checked during validation.
 * Maps output field path → authority table context for error messages.
 */
export const ENUM_FIELD_PATHS: {
  field: string;
  path: (doc: Record<string, unknown>) => string | null;
}[] = [
  { field: "streetType", path: (d) => d.streetType as string | null },
  { field: "flatType", path: (d) => d.flatType as string | null },
  { field: "levelType", path: (d) => d.levelType as string | null },
  { field: "streetSuffix", path: (d) => d.streetSuffix as string | null },
  {
    field: "localityClass",
    path: (d) => {
      const loc = d.locality as { class?: string } | null;
      return loc?.class ?? null;
    },
  },
  { field: "state", path: (d) => d.state as string | null },
];

/**
 * Query authority tables from Postgres and build valid-value sets.
 *
 * NOTE on street_type_aut: This is the ONLY authority table where columns
 * are reversed — `code` contains the LONG FORM (e.g. "STREET") and `name`
 * contains the abbreviation (e.g. "ST"). The output uses the long form,
 * so we query `code` for streetType.
 */
export async function queryEnumSets(sql: Sql): Promise<EnumSets> {
  const raw = process.env.GNAF_VERSION?.replace(/\./g, "") ?? "202602";
  if (!/^\d{6}$/.test(raw)) {
    throw new Error(
      `Invalid GNAF_VERSION: must be YYYY.MM format, got "${process.env.GNAF_VERSION}"`,
    );
  }
  const schemaPrefix = `raw_gnaf_${raw}`;

  async function collectColumn(query: string, col: string): Promise<Set<string>> {
    const values = new Set<string>();
    for await (const batch of sql.unsafe(query).cursor(500)) {
      for (const row of batch) {
        values.add(row[col] as string);
      }
    }
    return values;
  }

  const [streetTypes, flatTypes, levelTypes, streetSuffixes, localityClasses] = await Promise.all([
    collectColumn(`SELECT code FROM ${schemaPrefix}.street_type_aut`, "code"),
    collectColumn(`SELECT name FROM ${schemaPrefix}.flat_type_aut`, "name"),
    collectColumn(`SELECT name FROM ${schemaPrefix}.level_type_aut`, "name"),
    collectColumn(`SELECT name FROM ${schemaPrefix}.street_suffix_aut`, "name"),
    collectColumn(`SELECT name FROM ${schemaPrefix}.locality_class_aut`, "name"),
  ]);

  return {
    streetType: streetTypes,
    flatType: flatTypes,
    levelType: levelTypes,
    streetSuffix: streetSuffixes,
    localityClass: localityClasses,
    state: VALID_STATES,
  };
}

export interface VerifyOptions {
  /** Path to the NDJSON output file */
  outputPath: string;
  /** Expected row count from source (e.g. address_principals COUNT) */
  expectedCount: number;
  /** Tolerance as a fraction (0.001 = 0.1%). Default 0.001 */
  tolerance?: number;
  /** Valid value sets for enum-ish fields. When provided, validates each document. */
  enumSets?: EnumSets;
  /** Boundary coverage thresholds. When provided, verify fails if any field drops below its threshold. */
  boundaryCoverageThresholds?: BoundaryCoverageThresholds;
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
  tolerancePercent: number;
  passed: boolean;
  qualityIssues: QualityIssue[];
  qualityErrors: QualityIssue[];
  qualityWarnings: QualityIssue[];
  boundaryCoverage: BoundaryCoverage;
  boundaryCoverageErrors: BoundaryCoverageError[];
  boundaryCoverageChecked: boolean;
  duplicatePids: string[];
  enumUnknownCounts: EnumUnknownCounts;
  enumChecked: boolean;
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
 * Per-field minimum boundary coverage thresholds (0–1 fraction).
 * When provided to verify(), any field dropping below its threshold causes failure.
 */
export interface BoundaryCoverageThresholds {
  lga?: number;
  ward?: number;
  stateElectorate?: number;
  commonwealthElectorate?: number;
}

/**
 * Default thresholds for empty / multi-state / unknown STATES.
 *
 * These reflect a "fully populated, all-state" build (e.g. the
 * docker-smoke fixture path which has all 5 boundary types at 99%+,
 * or a hypothetical all-9-state production caller). They're strict.
 *
 * For per-state production builds, `PER_STATE_BOUNDARY_THRESHOLDS`
 * provides empirically-tuned per-state values that override these
 * defaults — see the comment block on that constant.
 */
export const DEFAULT_BOUNDARY_THRESHOLDS: Required<BoundaryCoverageThresholds> = {
  lga: 0.99,
  ward: 0.95,
  stateElectorate: 0.99,
  commonwealthElectorate: 0.99,
};

/**
 * Per-state empirical boundary coverage thresholds. Each value is set
 * ~5-8 percentage points BELOW the actual measured coverage from a
 * 2026.02 local build of every state on a 64 GB MacBook Pro M5,
 * providing margin for normal quarterly variation while still catching
 * catastrophic regressions.
 *
 * Why per-state: ward coverage varies wildly by state (NT 60.4% → VIC
 * 99.94%) because not every council in every state has wards in the
 * Geoscape data set. A single global ward threshold would either fail
 * for low-ward states (NT, WA) or allow VIC to silently drop 30+
 * points unnoticed. Per-state thresholds tune to each state's
 * empirical reality.
 *
 * Why state-aware AT ALL: gnaf-loader's per-state shapefile filter
 * (load-gnaf.py:325-330) means a single-state build only loads
 * shapefiles whose filename matches the state prefix. The Geoscape
 * archive doesn't ship `act_lga.shp`, `ot_state_electoral.shp`, etc.
 * — those administrative units don't exist for those states. The
 * resulting per-state polygon set comes from
 * `gnaf-loader/settings.py:208-217` admin_bdy_list logic, mirrored in
 * `scripts/validate-db-cache.sh`. When a polygon doesn't exist, its
 * threshold here is 0 (the field will be 0% in the output, and 0 < 0
 * is false, so the check passes vacuously).
 *
 * Source: 2026.02 local build, all 9 states, run #PR-FOLLOWUP. Update
 * this map after each successful quarterly run if coverage shifts.
 *
 * | State | LGA measured | Ward measured | Notes                  |
 * |-------|--------------|---------------|------------------------|
 * | ACT   | n/a (no poly)| n/a (no poly) | only ce + se_lower     |
 * | NSW   | ~100%        | n/a (no poly) | no ward in Geoscape    |
 * | NT    | 100%         | 60.4%         | lowest ward coverage   |
 * | OT    | 38.2%        | n/a (no poly) | mostly unincorporated  |
 * | QLD   | ~100%        | n/a (no poly) | no ward in Geoscape    |
 * | SA    | 100%         | 77.2%         |                        |
 * | TAS   | ~100%        | n/a (no poly) | no ward in Geoscape    |
 * | VIC   | 100%         | 99.94%        | gold standard          |
 * | WA    | 100%         | 68.07%        |                        |
 *
 * Coverage of `0` means: no polygon table for this state (gnaf-loader
 * didn't load it), so the field is null in the output. We pass the
 * check vacuously by setting threshold to 0.
 */
export const PER_STATE_BOUNDARY_THRESHOLDS: Record<string, Required<BoundaryCoverageThresholds>> = {
  ACT: { lga: 0, ward: 0, stateElectorate: 0.99, commonwealthElectorate: 0.99 },
  NSW: { lga: 0.99, ward: 0, stateElectorate: 0.99, commonwealthElectorate: 0.99 },
  NT: { lga: 0.99, ward: 0.55, stateElectorate: 0.99, commonwealthElectorate: 0.99 },
  OT: { lga: 0.3, ward: 0, stateElectorate: 0, commonwealthElectorate: 0 },
  QLD: { lga: 0.99, ward: 0, stateElectorate: 0.99, commonwealthElectorate: 0.99 },
  SA: { lga: 0.99, ward: 0.7, stateElectorate: 0.99, commonwealthElectorate: 0.99 },
  TAS: { lga: 0.99, ward: 0, stateElectorate: 0.99, commonwealthElectorate: 0.99 },
  VIC: { lga: 0.99, ward: 0.95, stateElectorate: 0.99, commonwealthElectorate: 0.99 },
  WA: { lga: 0.99, ward: 0.6, stateElectorate: 0.99, commonwealthElectorate: 0.99 },
};

const KNOWN_STATES = new Set(["ACT", "NSW", "NT", "OT", "QLD", "SA", "TAS", "VIC", "WA"]);

/**
 * Pick the right boundary coverage thresholds for a given STATES env value.
 *
 * Behaviour by input shape:
 *
 * - empty/undefined/whitespace-only → `DEFAULT_BOUNDARY_THRESHOLDS`
 *   (strict-all-five — fixture path and any all-states caller)
 *
 * - single known state → `PER_STATE_BOUNDARY_THRESHOLDS[state]`
 *   (the production reality — every quarterly job runs one state at
 *   a time per the matrix in `quarterly-build.yml`)
 *
 * - multiple known states → element-wise MIN across each selected
 *   state's per-state thresholds
 *
 *   Why MIN: a multi-state output is the union of per-state addresses.
 *   For each boundary field, the field's coverage in the union depends
 *   on the per-state coverages weighted by row counts. Without doing
 *   per-record state bucketing (a larger refactor), the safest correct
 *   thing is to use the LOOSEST threshold across the selected states.
 *   This guarantees the check accepts every legitimate combination
 *   while still catching catastrophic regressions for any field where
 *   AT LEAST ONE selected state has a tight threshold.
 *
 *   Example: STATES="VIC NSW"
 *     - VIC: lga 0.99, ward 0.95, se 0.99, ce 0.99
 *     - NSW: lga 0.99, ward 0   , se 0.99, ce 0.99
 *     - MIN: lga 0.99, ward 0   , se 0.99, ce 0.99
 *     - Ward check is skipped (NSW has no ward polygon, so the union
 *       has only VIC's ward addresses; we don't enforce any minimum).
 *     - LGA / state / cwlth still gate at 0.99 — catastrophic regression
 *       in either state still trips the check.
 *
 *   Trade-off: this is more permissive than per-record bucketing for
 *   fields where states have different non-zero thresholds (e.g.
 *   "WA SA" → ward MIN(0.60, 0.70) = 0.60, slightly looser than what
 *   per-state bucketing would enforce). Per-record bucketing is the
 *   correct future enhancement; for now, MIN is a clean unblock for
 *   the multi-state CLI flag without invasive refactoring.
 *
 * - any unknown token → throws (CLI catches and exits 4)
 *
 * Tokens are normalized: trimmed, split on shell whitespace, deduped
 * (so `"VIC VIC"` is identical to `"VIC"`), validated against the
 * known set.
 */
export function thresholdsForStates(
  states: string | undefined,
): Required<BoundaryCoverageThresholds> {
  if (!states || !states.trim()) return DEFAULT_BOUNDARY_THRESHOLDS;

  // Normalize: split on whitespace, drop empties, dedupe (preserving order)
  const seen = new Set<string>();
  const tokens: string[] = [];
  for (const raw of states.trim().split(/\s+/)) {
    if (!raw) continue;
    if (!KNOWN_STATES.has(raw)) {
      throw new Error(
        `Unknown STATES token: '${raw}'. Must be one of: ${[...KNOWN_STATES].sort().join(", ")}`,
      );
    }
    if (!seen.has(raw)) {
      seen.add(raw);
      tokens.push(raw);
    }
  }

  if (tokens.length === 0) return DEFAULT_BOUNDARY_THRESHOLDS;

  if (tokens.length === 1) {
    const t = PER_STATE_BOUNDARY_THRESHOLDS[tokens[0]];
    if (t) return t;
    // unreachable because every KNOWN_STATES key has a per-state entry,
    // but fall back defensively
    return DEFAULT_BOUNDARY_THRESHOLDS;
  }

  // Multi-state: element-wise MIN across the selected states' per-state
  // thresholds. See the JSDoc above for the rationale.
  const result: Required<BoundaryCoverageThresholds> = {
    lga: Number.POSITIVE_INFINITY,
    ward: Number.POSITIVE_INFINITY,
    stateElectorate: Number.POSITIVE_INFINITY,
    commonwealthElectorate: Number.POSITIVE_INFINITY,
  };
  for (const token of tokens) {
    const t = PER_STATE_BOUNDARY_THRESHOLDS[token];
    if (!t) continue;
    result.lga = Math.min(result.lga, t.lga);
    result.ward = Math.min(result.ward, t.ward);
    result.stateElectorate = Math.min(result.stateElectorate, t.stateElectorate);
    result.commonwealthElectorate = Math.min(
      result.commonwealthElectorate,
      t.commonwealthElectorate,
    );
  }
  return result;
}

export interface BoundaryCoverageError {
  field: string;
  actual: number;
  threshold: number;
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
  const {
    outputPath,
    expectedCount,
    tolerance = 0.001,
    enumSets,
    boundaryCoverageThresholds,
  } = options;

  const pids = new Set<string>();
  const duplicatePids: string[] = [];
  const qualityIssues: QualityIssue[] = [];
  const enumUnknownCounts: EnumUnknownCounts = {};
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

    // Enum-ish field validation
    if (enumSets) {
      for (const { field, path } of ENUM_FIELD_PATHS) {
        const value = path(doc);
        if (value === null || value === undefined) continue;
        const validSet = enumSets[field];
        if (!validSet) continue;
        if (!validSet.has(value)) {
          enumUnknownCounts[field] = (enumUnknownCounts[field] ?? 0) + 1;
          qualityIssues.push({
            pid,
            check: "enum-value",
            message: `${field} "${value}" not in authority table`,
          });
        }
      }
    }
  }

  const difference = Math.abs(outputCount - expectedCount);
  const differencePercent = expectedCount > 0 ? (difference / expectedCount) * 100 : 0;
  const tolerancePercent = tolerance * 100;

  // Fail if output file is empty — regardless of expectedCount
  const emptyOutput = outputCount === 0;

  // Row-count check is only meaningful when expectedCount > 0
  const rowCountFailed = expectedCount > 0 && differencePercent > tolerancePercent;

  // Boundary coverage threshold check
  const boundaryCoverageErrors: BoundaryCoverageError[] = [];
  if (boundaryCoverageThresholds && coverage.total > 0) {
    const checks: { field: keyof BoundaryCoverageThresholds; count: number }[] = [
      { field: "lga", count: coverage.lga },
      { field: "ward", count: coverage.ward },
      { field: "stateElectorate", count: coverage.stateElectorate },
      { field: "commonwealthElectorate", count: coverage.commonwealthElectorate },
    ];
    for (const { field, count } of checks) {
      const threshold = boundaryCoverageThresholds[field];
      if (threshold !== undefined) {
        const actual = count / coverage.total;
        if (actual < threshold) {
          boundaryCoverageErrors.push({ field, actual, threshold });
        }
      }
    }
  }

  // Partition quality issues: coordinate-bounds and enum-value are hard errors, rest are warnings
  const qualityErrors = qualityIssues.filter(
    (i) => i.check === "coordinate-bounds" || i.check === "enum-value",
  );
  const qualityWarnings = qualityIssues.filter(
    (i) => i.check !== "coordinate-bounds" && i.check !== "enum-value",
  );

  const passed =
    !emptyOutput &&
    !rowCountFailed &&
    duplicatePids.length === 0 &&
    qualityErrors.length === 0 &&
    boundaryCoverageErrors.length === 0;

  return {
    outputCount,
    expectedCount,
    difference,
    differencePercent,
    tolerancePercent,
    passed,
    qualityIssues,
    qualityErrors,
    qualityWarnings,
    boundaryCoverage: coverage,
    boundaryCoverageErrors,
    boundaryCoverageChecked: !!boundaryCoverageThresholds,
    duplicatePids,
    enumUnknownCounts,
    enumChecked: !!enumSets,
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
  if (result.outputCount === 0) {
    lines.push("Row count:     FAIL (output file is empty)");
  } else if (result.expectedCount === 0) {
    lines.push("Row count:     SKIP (no expected count provided)");
  } else {
    lines.push(`Difference:    ${result.difference} (${result.differencePercent.toFixed(3)}%)`);
    lines.push(
      `Row count:     ${result.difference === 0 ? "PASS" : result.differencePercent <= result.tolerancePercent ? "PASS (within tolerance)" : "FAIL"}`,
    );
  }

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

  // Boundary coverage threshold check
  if (result.boundaryCoverageChecked) {
    if (result.boundaryCoverageErrors.length > 0) {
      lines.push("Boundary coverage: FAIL");
      for (const err of result.boundaryCoverageErrors) {
        lines.push(
          `  ${err.field}: ${(err.actual * 100).toFixed(1)}% (threshold: ${(err.threshold * 100).toFixed(1)}%)`,
        );
      }
    } else {
      lines.push("Boundary coverage: PASS");
    }
  }

  // Enum-ish field validation
  if (result.enumChecked) {
    const enumFields = Object.entries(result.enumUnknownCounts).filter(([, n]) => n > 0);
    if (enumFields.length > 0) {
      lines.push("Enum field check: FAIL");
      for (const [field, count] of enumFields) {
        lines.push(`  ${field}: ${count} unknown values`);
      }
    } else {
      lines.push("Enum field check: PASS");
    }
  }

  if (result.qualityErrors.length > 0) {
    lines.push(`Quality errors: FAIL (${result.qualityErrors.length})`);
    for (const issue of result.qualityErrors.slice(0, 10)) {
      lines.push(`  [${issue.check}] ${issue.pid}: ${issue.message}`);
    }
    if (result.qualityErrors.length > 10) {
      lines.push(`  ... and ${result.qualityErrors.length - 10} more`);
    }
  } else {
    lines.push("Quality errors: PASS (none found)");
  }

  if (result.qualityWarnings.length > 0) {
    lines.push(`Quality warnings: ${result.qualityWarnings.length}`);
    for (const issue of result.qualityWarnings.slice(0, 5)) {
      lines.push(`  [${issue.check}] ${issue.pid}: ${issue.message}`);
    }
    if (result.qualityWarnings.length > 5) {
      lines.push(`  ... and ${result.qualityWarnings.length - 5} more`);
    }
  }

  lines.push(`Overall: ${result.passed ? "PASS" : "FAIL"}`);
  return lines.join("\n");
}

// --- CLI entry point ---

async function main(): Promise<void> {
  const filePath = process.argv[2];
  if (!filePath) {
    console.error(
      "Usage: node verify.js <ndjson-file> [--expected-count N] [--db-url URL] [--skip-enum-check] [--check-boundary-coverage]",
    );
    process.exit(1);
  }

  const expectedIdx = process.argv.indexOf("--expected-count");
  const expectedCount = expectedIdx !== -1 ? parseInt(process.argv[expectedIdx + 1], 10) : 0;

  if (expectedIdx === -1) {
    console.warn(
      "Warning: --expected-count not provided. Row-count verification will be skipped (only empty-file and quality checks apply).",
    );
  }

  const skipEnumCheck = process.argv.includes("--skip-enum-check");
  const checkBoundaryCoverage = process.argv.includes("--check-boundary-coverage");
  const dbUrlIdx = process.argv.indexOf("--db-url");
  const dbUrl = dbUrlIdx !== -1 ? process.argv[dbUrlIdx + 1] : undefined;

  // STATES env var (whitespace-separated, matching gnaf-loader's --states
  // format) selects per-state empirical thresholds. Empty/multi-state →
  // strict-all-five default. Unknown token → throws → exit 4.
  let boundaryCoverageThresholds: Required<BoundaryCoverageThresholds> | undefined;
  if (checkBoundaryCoverage) {
    try {
      boundaryCoverageThresholds = thresholdsForStates(process.env.STATES);
    } catch (err) {
      console.error(`[verify] ERROR: ${err instanceof Error ? err.message : String(err)}`);
      console.error(
        `[verify] STATES must be a whitespace-separated list of state codes ` +
          `(e.g. STATES="VIC" or STATES="NSW VIC"). Got: '${process.env.STATES ?? "(unset)"}'`,
      );
      process.exit(4);
    }
  }

  let enumSets: EnumSets | undefined;
  if (!skipEnumCheck && dbUrl) {
    const postgres = (await import("postgres")).default;
    const sql = postgres(dbUrl);
    try {
      enumSets = await queryEnumSets(sql);
    } finally {
      await sql.end();
    }
  }

  const result = await verify({
    outputPath: filePath,
    expectedCount,
    enumSets,
    boundaryCoverageThresholds,
  });

  console.log(formatReport(result));

  if (!result.passed) {
    process.exit(4);
  }
}

// Only run CLI when this module is the entry point
if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main().catch((err) => {
    console.error(err);
    process.exit(4);
  });
}
