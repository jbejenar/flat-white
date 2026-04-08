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
  /**
   * Boundary coverage thresholds. When provided, verify fails if any field
   * drops below its threshold.
   *
   * - When `boundaryCoveragePerState` is also provided, this is used as the
   *   FALLBACK for any address whose `state` field is not in the per-state
   *   map. Single-state production callers can leave this undefined.
   * - When `boundaryCoveragePerState` is NOT provided, this is applied
   *   globally against the aggregate coverage (legacy behaviour, used by
   *   the fixture path and any all-states caller).
   */
  boundaryCoverageThresholds?: BoundaryCoverageThresholds;
  /**
   * Per-state boundary coverage thresholds. When provided, verify buckets
   * addresses by their `state` field and applies each state's thresholds
   * to its bucket. This is the correct way to validate multi-state output
   * because per-state polygon coverage varies (NT 60% ward → VIC 99% ward;
   * ACT no LGA polygon → NSW full LGA coverage). The CLI populates this
   * from `PER_STATE_BOUNDARY_THRESHOLDS` keyed by the `STATES` env var.
   *
   * For unknown state buckets (e.g. an address with state="XYZ" or a
   * state not in this map), falls back to `boundaryCoverageThresholds`
   * if provided, else skips the check for that bucket.
   */
  boundaryCoveragePerState?: Record<string, BoundaryCoverageThresholds>;
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
  /** Aggregate coverage across the entire output (all states combined). */
  boundaryCoverage: BoundaryCoverage;
  /**
   * Per-state coverage breakdown — populated unconditionally during the
   * streaming pass. Used by the per-state threshold check (when
   * `boundaryCoveragePerState` is provided) and by the formatted report.
   * Empty for unstated rows.
   */
  boundaryCoverageByState: Map<string, BoundaryCoverage>;
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
 * Validate a STATES env value (whitespace-separated state codes) and
 * return the matching per-state thresholds for the SINGLE-STATE case.
 *
 * This function exists as an input validation helper and a convenience
 * for callers that want a single threshold map for one state. It is
 * NOT the source of truth for multi-state correctness — that's
 * `boundaryCoveragePerState` plus per-record state bucketing in
 * `verify()`. See the doc on the `boundaryCoveragePerState` field of
 * `VerifyOptions` for why.
 *
 * Behaviour:
 *
 * - empty/undefined/whitespace-only → `DEFAULT_BOUNDARY_THRESHOLDS`
 *   (back-compat: the fixture path and any all-states caller still
 *   gets strict-all-five via this entry point).
 *
 * - exactly one known state → `PER_STATE_BOUNDARY_THRESHOLDS[state]`.
 *
 * - multiple known states → `DEFAULT_BOUNDARY_THRESHOLDS`. The flat
 *   threshold map can't faithfully represent multi-state output;
 *   callers needing correctness MUST pass `boundaryCoveragePerState`
 *   to `verify()` instead. The CLI does this automatically.
 *
 * - any unknown token → throws (CLI catches and exits 4).
 *
 * Tokens are normalized: trimmed, split on shell whitespace, deduped
 * (so `"VIC VIC"` is identical to `"VIC"`), validated against the
 * known set.
 */
export function thresholdsForStates(
  states: string | undefined,
): Required<BoundaryCoverageThresholds> {
  const tokens = parseStatesEnv(states);
  if (tokens.length === 0) return DEFAULT_BOUNDARY_THRESHOLDS;
  if (tokens.length === 1) {
    const t = PER_STATE_BOUNDARY_THRESHOLDS[tokens[0]];
    if (t) return t;
  }
  // Multi-state: flat threshold map can't represent the union correctly.
  // Callers that need multi-state correctness use boundaryCoveragePerState
  // + per-record bucketing in verify(). This entry point falls back to
  // the strict default so it remains usable as a programmatic helper.
  return DEFAULT_BOUNDARY_THRESHOLDS;
}

/**
 * Parse and validate a STATES env value into a deduped, ordered token
 * list. Throws on unknown tokens. Used by `thresholdsForStates` and the
 * CLI to validate input before building the per-state threshold map.
 */
export function parseStatesEnv(states: string | undefined): string[] {
  if (!states || !states.trim()) return [];
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
  return tokens;
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
/**
 * Sentinel bucket key for rows whose `state` field is null, empty,
 * whitespace-only, or otherwise non-string. Such rows are bucketed under
 * this key so they can't silently evade boundary coverage validation in
 * per-state mode. The threshold check treats this bucket as "unknown
 * state" and applies the strict fallback thresholds.
 *
 * Exported so tests and debugging tooling can inspect the bucket map.
 */
export const UNKNOWN_STATE_BUCKET = "__UNKNOWN_STATE__";

function emptyCoverage(): BoundaryCoverage {
  return {
    total: 0,
    lga: 0,
    ward: 0,
    stateElectorate: 0,
    commonwealthElectorate: 0,
    meshBlock: 0,
    sa1: 0,
    sa2: 0,
  };
}

function tallyBoundaries(cov: BoundaryCoverage, boundaries: Record<string, unknown> | null): void {
  cov.total++;
  if (boundaries) {
    if (boundaries.lga) cov.lga++;
    if (boundaries.ward) cov.ward++;
    if (boundaries.stateElectorate) cov.stateElectorate++;
    if (boundaries.commonwealthElectorate) cov.commonwealthElectorate++;
    if (boundaries.meshBlock) cov.meshBlock++;
    if (boundaries.sa1) cov.sa1++;
    if (boundaries.sa2) cov.sa2++;
  }
}

export async function verify(options: VerifyOptions): Promise<VerifyResult> {
  const {
    outputPath,
    expectedCount,
    tolerance = 0.001,
    enumSets,
    boundaryCoverageThresholds,
    boundaryCoveragePerState,
  } = options;

  const pids = new Set<string>();
  const duplicatePids: string[] = [];
  const qualityIssues: QualityIssue[] = [];
  const enumUnknownCounts: EnumUnknownCounts = {};
  let outputCount = 0;

  const coverage: BoundaryCoverage = emptyCoverage();
  // Per-state buckets — populated unconditionally so the report can show
  // a per-state breakdown even when no per-state thresholds are configured.
  const coverageByState = new Map<string, BoundaryCoverage>();

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

    // Boundary coverage — accumulate both global and per-state buckets in
    // a single pass. The per-state map is the load-bearing one for
    // multi-state verification (per-record bucketing prevents one state's
    // missing polygon from disabling validation for another state).
    //
    // Every row is bucketed unconditionally — including rows whose `state`
    // field is null, empty, or whitespace-only. Such rows go into the
    // `UNKNOWN_STATE_BUCKET` sentinel bucket, which gets validated against
    // the strict fallback thresholds in per-state mode (see threshold
    // check below). This prevents a silent verification hole where a
    // regression that drops the `state` field could evade boundary
    // coverage checks entirely. Same applies to rows whose `state` value
    // isn't in `boundaryCoveragePerState` — they fall back to strict
    // thresholds via the same map-lookup miss path.
    const boundaries = doc.boundaries as Record<string, unknown> | null;
    tallyBoundaries(coverage, boundaries);
    const stateKey = typeof state === "string" && state.trim() ? state : UNKNOWN_STATE_BUCKET;
    let stateBucket = coverageByState.get(stateKey);
    if (!stateBucket) {
      stateBucket = emptyCoverage();
      coverageByState.set(stateKey, stateBucket);
    }
    tallyBoundaries(stateBucket, boundaries);

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

  // Boundary coverage threshold check.
  //
  // Two modes:
  //
  //   1. Per-state mode (preferred for multi-state output): apply each
  //      state's per-state thresholds to that state's bucket. This is the
  //      correct way to validate a multi-state file because per-state
  //      polygon coverage varies dramatically (NT 60% ward → VIC 99%
  //      ward; ACT no LGA polygon → NSW full LGA coverage). Without
  //      per-record bucketing, a state with `0` threshold for a field
  //      would disable validation for every other state in the file.
  //      Triggered when `boundaryCoveragePerState` is provided.
  //
  //   2. Global mode (legacy / fixture path): apply one set of thresholds
  //      to the global aggregate. Used when only `boundaryCoverageThresholds`
  //      is provided. Preserved for back-compat with the fixture path
  //      and any caller that doesn't have per-state context.
  //
  // Errors from per-state checks are namespaced as `${state}.${field}`
  // (e.g. `NSW.lga`) so the report shows which state's check failed.
  const boundaryCoverageErrors: BoundaryCoverageError[] = [];
  const fields: (keyof BoundaryCoverageThresholds)[] = [
    "lga",
    "ward",
    "stateElectorate",
    "commonwealthElectorate",
  ];

  if (boundaryCoveragePerState) {
    // Per-state mode — bucket by state and apply each state's thresholds.
    //
    // For known state buckets (state in `boundaryCoveragePerState`): use
    // that state's per-state thresholds.
    //
    // For unknown buckets — the `UNKNOWN_STATE_BUCKET` sentinel (rows
    // with null/empty `state` field) AND any state value the caller
    // didn't include in the per-state map — fall back to
    // `boundaryCoverageThresholds` if provided, else hard-floor to
    // `DEFAULT_BOUNDARY_THRESHOLDS`. Either way the unknown bucket
    // gets validated against strict thresholds, NOT silently skipped.
    // This is the load-bearing safety: a regression that drops the
    // `state` field MUST NOT silently evade boundary coverage checks.
    const fallback: BoundaryCoverageThresholds =
      boundaryCoverageThresholds ?? DEFAULT_BOUNDARY_THRESHOLDS;
    for (const [state, stateBucket] of coverageByState) {
      if (stateBucket.total === 0) continue;
      const stateThresholds = boundaryCoveragePerState[state] ?? fallback;
      for (const field of fields) {
        const threshold = stateThresholds[field];
        if (threshold === undefined) continue;
        const actual = stateBucket[field] / stateBucket.total;
        if (actual < threshold) {
          boundaryCoverageErrors.push({
            field: `${state}.${field}`,
            actual,
            threshold,
          });
        }
      }
    }
  } else if (boundaryCoverageThresholds && coverage.total > 0) {
    // Global mode — single threshold set against the aggregate
    for (const field of fields) {
      const threshold = boundaryCoverageThresholds[field];
      if (threshold === undefined) continue;
      const actual = coverage[field] / coverage.total;
      if (actual < threshold) {
        boundaryCoverageErrors.push({ field, actual, threshold });
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
    boundaryCoverageByState: coverageByState,
    boundaryCoverageErrors,
    boundaryCoverageChecked: !!(boundaryCoverageThresholds || boundaryCoveragePerState),
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
  // format) selects per-state empirical thresholds. The CLI builds a
  // `boundaryCoveragePerState` map from STATES so the verify pipeline
  // can apply each state's thresholds to that state's bucket via
  // per-record state bucketing — the only correct approach for
  // multi-state output where polygon coverage varies dramatically
  // by state. See PER_STATE_BOUNDARY_THRESHOLDS doc for details.
  //
  // Empty STATES → fall back to global DEFAULT_BOUNDARY_THRESHOLDS
  // (strict-all-five) applied to the aggregate. Suitable for the
  // fixture path and any all-states caller with high coverage.
  // Unknown token → throws → exit 4 (fail closed).
  let boundaryCoverageThresholds: Required<BoundaryCoverageThresholds> | undefined;
  let boundaryCoveragePerState: Record<string, BoundaryCoverageThresholds> | undefined;
  if (checkBoundaryCoverage) {
    const statesEnv = process.env.STATES;
    let tokens: string[];
    try {
      tokens = parseStatesEnv(statesEnv);
    } catch (err) {
      console.error(`[verify] ERROR: ${err instanceof Error ? err.message : String(err)}`);
      console.error(
        `[verify] STATES must be a whitespace-separated list of state codes ` +
          `(e.g. STATES="VIC" or STATES="NSW VIC"). Got: '${statesEnv ?? "(unset)"}'`,
      );
      process.exit(4);
    }

    if (tokens.length > 0) {
      // Build the per-state map from validated tokens. Per-record bucketing
      // in verify() applies each entry to its state's bucket — this is the
      // ONLY correct way to verify multi-state output where polygon coverage
      // varies dramatically by state. A flat threshold map (e.g. taking
      // MIN of selected states) would either false-fail legitimate
      // combinations or silently allow regressions in one state by being
      // pulled loose by another's missing polygon. See the verify() doc.
      const perState: Record<string, BoundaryCoverageThresholds> = {};
      for (const token of tokens) {
        const t = PER_STATE_BOUNDARY_THRESHOLDS[token];
        if (t) perState[token] = t;
      }
      boundaryCoveragePerState = perState;
      // Fallback for unknown state buckets (shouldn't happen in practice
      // — the input file should only contain addresses for the requested
      // states). Use the strict default so anomalies fail loud.
      boundaryCoverageThresholds = DEFAULT_BOUNDARY_THRESHOLDS;
    } else {
      // No STATES → strict global defaults applied to the aggregate.
      boundaryCoverageThresholds = DEFAULT_BOUNDARY_THRESHOLDS;
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
    boundaryCoveragePerState,
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
