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
  const { outputPath, expectedCount, tolerance = 0.001, enumSets } = options;

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

  // Partition quality issues: coordinate-bounds and enum-value are hard errors, rest are warnings
  const qualityErrors = qualityIssues.filter(
    (i) => i.check === "coordinate-bounds" || i.check === "enum-value",
  );
  const qualityWarnings = qualityIssues.filter(
    (i) => i.check !== "coordinate-bounds" && i.check !== "enum-value",
  );

  const passed =
    !emptyOutput && !rowCountFailed && duplicatePids.length === 0 && qualityErrors.length === 0;

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
      "Usage: node verify.js <ndjson-file> [--expected-count N] [--db-url URL] [--skip-enum-check]",
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
  const dbUrlIdx = process.argv.indexOf("--db-url");
  const dbUrl = dbUrlIdx !== -1 ? process.argv[dbUrlIdx + 1] : undefined;

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
