/**
 * flat-white — Verification report generator (P4.02).
 *
 * Runs data quality checks on per-state NDJSON output files and produces
 * a structured markdown report suitable for uploading as a release asset.
 *
 * Usage: node dist/verification-report.js <asset-dir> [--output report.md]
 *
 * The asset directory should contain per-state .ndjson.gz files
 * (e.g. flat-white-2026.02-vic.ndjson.gz) and a metadata.json.
 */

import { createReadStream } from "node:fs";
import { writeFile, readFile, access } from "node:fs/promises";
import { createInterface } from "node:readline";
import { createGunzip } from "node:zlib";
import { resolve, join } from "node:path";
import { fileURLToPath } from "node:url";
import { PassThrough } from "node:stream";
import { AddressDocumentSchema } from "./schema.js";
import type { BuildMetadata } from "./metadata.js";
import { ENUM_FIELD_PATHS } from "./verify.js";
import type { EnumSets, EnumUnknownCounts } from "./verify.js";

const DEFAULT_STATES = ["ACT", "NSW", "NT", "OT", "QLD", "SA", "TAS", "VIC", "WA"] as const;
const VALID_STATES = new Set(DEFAULT_STATES);

/** Per-field minimum boundary coverage thresholds (percent, 0-100). */
export type BoundaryCoverageThresholds = Partial<
  Record<
    "lga" | "ward" | "stateElectorate" | "commonwealthElectorate" | "meshBlock" | "sa1" | "sa2",
    number
  >
>;

export interface CoverageBelowThreshold {
  field: string;
  actual: number;
  threshold: number;
}

export interface StateVerification {
  state: string;
  rowCount: number;
  schemaValid: boolean;
  schemaErrors: number;
  boundaryCoverage: Record<string, number>;
  coverageBelowThreshold: CoverageBelowThreshold[];
  qualityErrors: number;
  qualityWarnings: number;
  duplicatePids: number;
  enumUnknownCounts: EnumUnknownCounts;
  passed: boolean;
}

export interface VerificationReport {
  version: string;
  timestamp: string;
  states: StateVerification[];
  totalCount: number;
  overallPassed: boolean;
}

/**
 * Verify a single gzipped NDJSON file by decompressing and streaming through verify().
 *
 * Since verify() expects a file path, we decompress to a temp pipeline.
 * Instead, we directly stream and apply the same checks.
 */
export async function verifyGzippedState(
  gzPath: string,
  state: string,
  enumSets?: EnumSets,
  thresholds?: BoundaryCoverageThresholds,
): Promise<StateVerification> {
  let rowCount = 0;
  let schemaErrors = 0;
  const boundaryCounts: Record<string, number> = {
    lga: 0,
    ward: 0,
    stateElectorate: 0,
    commonwealthElectorate: 0,
    meshBlock: 0,
    sa1: 0,
    sa2: 0,
  };
  let qualityErrors = 0;
  let qualityWarnings = 0;
  // NOTE: For NSW (~4.5M addresses), this Set can consume ~250-360MB.
  // The Set is scoped per-state (released between calls), and the workflow
  // step uses --max-old-space-size=512 to provide headroom.
  const pids = new Set<string>();
  let duplicatePids = 0;
  const enumUnknownCounts: EnumUnknownCounts = {};

  const gunzip = createGunzip();
  const passthrough = new PassThrough();
  const fileStream = createReadStream(gzPath);

  // Pipe through gunzip without awaiting — we read from readline
  fileStream.pipe(gunzip).pipe(passthrough);

  const rl = createInterface({
    input: passthrough,
    crlfDelay: Infinity,
  });

  for await (const line of rl) {
    if (!line.trim()) continue;
    rowCount++;

    let doc: Record<string, unknown>;
    try {
      doc = JSON.parse(line) as Record<string, unknown>;
    } catch {
      schemaErrors++;
      continue;
    }

    // Schema validation (sample: validate first 100 + every 1000th for performance)
    if (rowCount <= 100 || rowCount % 1000 === 0) {
      const result = AddressDocumentSchema.safeParse(doc);
      if (!result.success) {
        schemaErrors++;
      }
    }

    // PID uniqueness
    const pid = doc._id as string;
    if (pid) {
      if (pids.has(pid)) {
        duplicatePids++;
      }
      pids.add(pid);
    }

    // Boundary coverage
    const boundaries = doc.boundaries as Record<string, unknown> | null;
    if (boundaries) {
      if (boundaries.lga) boundaryCounts.lga++;
      if (boundaries.ward) boundaryCounts.ward++;
      if (boundaries.stateElectorate) boundaryCounts.stateElectorate++;
      if (boundaries.commonwealthElectorate) boundaryCounts.commonwealthElectorate++;
      if (boundaries.meshBlock) boundaryCounts.meshBlock++;
      if (boundaries.sa1) boundaryCounts.sa1++;
      if (boundaries.sa2) boundaryCounts.sa2++;
    }

    // Coordinate quality check
    const geocode = doc.geocode as { latitude: number; longitude: number } | null;
    if (geocode) {
      const { latitude, longitude } = geocode;
      if (latitude < -44 || latitude > -9 || longitude < 96 || longitude > 168) {
        qualityErrors++;
      }
    }

    // State/postcode cross-validation
    const docState = doc.state as string;
    const postcode = doc.postcode as string | null;
    if (postcode && docState !== state && docState) {
      qualityWarnings++;
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
        }
      }
    }
  }

  const boundaryCoverage: Record<string, number> = {};
  if (rowCount > 0) {
    for (const [key, count] of Object.entries(boundaryCounts)) {
      boundaryCoverage[key] = Math.round((count / rowCount) * 1000) / 10;
    }
  }

  const enumErrorCount = Object.values(enumUnknownCounts).reduce((s, n) => s + n, 0);

  // Threshold evaluation runs regardless of rowCount. An empty state file
  // (rowCount === 0) is effectively 0% coverage for every field — treating it
  // as "no thresholds to check" would let a regression that produces an empty
  // NSW silently ship, because there are also no schema/quality/enum/dupe
  // errors to flag on zero rows. Coerce missing values to 0 so empty states
  // explicitly fail every configured threshold.
  const coverageBelowThreshold: CoverageBelowThreshold[] = [];
  if (thresholds) {
    for (const [field, threshold] of Object.entries(thresholds) as [
      keyof BoundaryCoverageThresholds,
      number,
    ][]) {
      if (threshold === undefined) continue;
      const actual = rowCount > 0 ? (boundaryCoverage[field] ?? 0) : 0;
      if (actual < threshold) {
        coverageBelowThreshold.push({ field, actual, threshold });
      }
    }
  }

  return {
    state,
    rowCount,
    schemaValid: schemaErrors === 0,
    schemaErrors,
    boundaryCoverage,
    coverageBelowThreshold,
    qualityErrors,
    qualityWarnings,
    duplicatePids,
    enumUnknownCounts,
    // Independent safety: a zero-row state file is always a failure, even if
    // no thresholds are configured. Every schema/quality/enum check is
    // vacuously "passing" on an empty file, so without this gate the function
    // would return passed=true for an empty artifact.
    passed:
      rowCount > 0 &&
      schemaErrors === 0 &&
      qualityErrors === 0 &&
      duplicatePids === 0 &&
      enumErrorCount === 0 &&
      coverageBelowThreshold.length === 0,
  };
}

/**
 * Generate a markdown verification report from per-state results.
 */
export function formatVerificationReport(report: VerificationReport): string {
  const lines: string[] = [];

  lines.push("# Verification Report");
  lines.push("");
  lines.push(`**Version:** ${report.version}`);
  lines.push(`**Generated:** ${report.timestamp}`);
  lines.push(`**Total addresses:** ${report.totalCount.toLocaleString()}`);
  lines.push(`**Overall:** ${report.overallPassed ? "PASS ✓" : "FAIL ✗"}`);
  lines.push("");

  // Per-state summary table
  lines.push("## Per-State Summary");
  lines.push("");
  lines.push("| State | Count | Schema | Quality | Duplicates | Result |");
  lines.push("|-------|------:|:------:|:-------:|:----------:|:------:|");

  for (const s of report.states) {
    const schema = s.schemaValid ? "PASS" : `FAIL (${s.schemaErrors})`;
    const quality = s.qualityErrors === 0 ? "PASS" : `FAIL (${s.qualityErrors})`;
    const dupes = s.duplicatePids === 0 ? "PASS" : `FAIL (${s.duplicatePids})`;
    const result = s.passed ? "PASS" : "FAIL";
    lines.push(
      `| ${s.state} | ${s.rowCount.toLocaleString()} | ${schema} | ${quality} | ${dupes} | ${result} |`,
    );
  }

  lines.push("");

  // Boundary coverage table
  lines.push("## Boundary Coverage (%)");
  lines.push("");
  lines.push("| State | LGA | Ward | State Elect. | Cwlth Elect. | Mesh Block | SA1 | SA2 |");
  lines.push("|-------|----:|-----:|-------------:|-------------:|-----------:|----:|----:|");

  for (const s of report.states) {
    const c = s.boundaryCoverage;
    lines.push(
      `| ${s.state} | ${c.lga ?? "-"} | ${c.ward ?? "-"} | ${c.stateElectorate ?? "-"} | ${c.commonwealthElectorate ?? "-"} | ${c.meshBlock ?? "-"} | ${c.sa1 ?? "-"} | ${c.sa2 ?? "-"} |`,
    );
  }

  lines.push("");

  // Coverage thresholds
  const totalCoverageFailures = report.states.reduce(
    (sum, s) => sum + s.coverageBelowThreshold.length,
    0,
  );
  if (totalCoverageFailures > 0) {
    lines.push("## Boundary Coverage Threshold: FAIL");
    lines.push("");
    lines.push("| State | Field | Actual % | Threshold % |");
    lines.push("|-------|-------|---------:|------------:|");
    for (const s of report.states) {
      for (const c of s.coverageBelowThreshold) {
        lines.push(`| ${s.state} | ${c.field} | ${c.actual} | ${c.threshold} |`);
      }
    }
    lines.push("");
  }

  // Enum field validation
  const totalEnumErrors = report.states.reduce(
    (sum, s) => sum + Object.values(s.enumUnknownCounts).reduce((a, b) => a + b, 0),
    0,
  );
  if (totalEnumErrors > 0) {
    lines.push("## Enum Field Validation: FAIL");
    lines.push("");
    lines.push("| State | Field | Unknown Count |");
    lines.push("|-------|-------|-------------:|");
    for (const s of report.states) {
      for (const [field, count] of Object.entries(s.enumUnknownCounts)) {
        if (count > 0) {
          lines.push(`| ${s.state} | ${field} | ${count} |`);
        }
      }
    }
    lines.push("");
  }

  // Quality warnings
  const totalWarnings = report.states.reduce((sum, s) => sum + s.qualityWarnings, 0);
  if (totalWarnings > 0) {
    lines.push(`## Quality Warnings: ${totalWarnings}`);
    lines.push("");
    for (const s of report.states) {
      if (s.qualityWarnings > 0) {
        lines.push(`- **${s.state}:** ${s.qualityWarnings} warnings`);
      }
    }
    lines.push("");
  }

  lines.push("---");
  lines.push("*Generated by flat-white verification pipeline*");

  return lines.join("\n");
}

/**
 * Find per-state gzipped NDJSON files in a directory.
 */
function findStateFiles(
  assetDir: string,
  version: string,
  states: readonly string[],
): { state: string; path: string }[] {
  const found: { state: string; path: string }[] = [];
  for (const state of states) {
    const lower = state.toLowerCase();
    const filename = `flat-white-${version}-${lower}.ndjson.gz`;
    found.push({ state, path: join(assetDir, filename) });
  }
  return found;
}

const VALID_THRESHOLD_FIELDS = new Set<keyof BoundaryCoverageThresholds>([
  "lga",
  "ward",
  "stateElectorate",
  "commonwealthElectorate",
  "meshBlock",
  "sa1",
  "sa2",
]);

/**
 * Parse a boundary coverage threshold spec like "lga=99,ward=95,sa1=99".
 * Returns undefined when the spec is missing/empty (no thresholds applied).
 * Throws on unknown fields or non-numeric values so a typo fails loud.
 */
export function parseBoundaryThresholdsArg(
  raw: string | undefined,
): BoundaryCoverageThresholds | undefined {
  if (!raw) return undefined;

  const out: BoundaryCoverageThresholds = {};
  for (const piece of raw.split(",")) {
    const trimmed = piece.trim();
    if (!trimmed) continue;
    const parts = trimmed.split("=");
    if (parts.length !== 2) {
      throw new Error(`Invalid boundary threshold spec: '${trimmed}' (expected 'field=value')`);
    }
    const rawField = parts[0].trim();
    const rawValue = parts[1].trim();
    const field = rawField as keyof BoundaryCoverageThresholds;
    if (!rawField || !VALID_THRESHOLD_FIELDS.has(field)) {
      throw new Error(`Unknown boundary threshold field: '${rawField}'`);
    }
    if (!rawValue) {
      throw new Error(`Missing threshold value for ${field}`);
    }
    const value = Number(rawValue);
    if (!Number.isFinite(value) || value < 0 || value > 100) {
      throw new Error(`Invalid threshold value for ${field}: '${rawValue}' (expected 0-100)`);
    }
    out[field] = value;
  }
  return Object.keys(out).length > 0 ? out : undefined;
}

export function parseStatesArg(raw: string | undefined): string[] {
  if (!raw) {
    return [...DEFAULT_STATES];
  }

  const states = raw
    .split(",")
    .map((state) => state.trim().toUpperCase())
    .filter(Boolean);

  if (states.length === 0) {
    throw new Error("Expected at least one state in --states");
  }

  for (const state of states) {
    if (!VALID_STATES.has(state as (typeof DEFAULT_STATES)[number])) {
      throw new Error(`Invalid state in --states: ${state}`);
    }
  }

  return states;
}

// --- CLI entry point ---

async function main(): Promise<void> {
  const assetDir = process.argv[2];
  if (!assetDir) {
    console.error("Usage: node dist/verification-report.js <asset-dir> [--output report.md]");
    process.exit(1);
  }

  const outputIdx = process.argv.indexOf("--output");
  const outputPath = outputIdx !== -1 ? process.argv[outputIdx + 1] : "verification-report.md";
  const statesIdx = process.argv.indexOf("--states");
  const statesArg =
    statesIdx !== -1 && statesIdx + 1 < process.argv.length
      ? process.argv[statesIdx + 1]
      : undefined;
  const states = parseStatesArg(statesArg);

  const thresholdsIdx = process.argv.indexOf("--boundary-thresholds");
  const thresholdsArg =
    thresholdsIdx !== -1 && thresholdsIdx + 1 < process.argv.length
      ? process.argv[thresholdsIdx + 1]
      : undefined;
  const thresholds = parseBoundaryThresholdsArg(thresholdsArg);

  // Read metadata.json for version
  const metadataPath = join(assetDir, "metadata.json");
  let version = "unknown";
  try {
    const meta = JSON.parse(await readFile(metadataPath, "utf-8")) as BuildMetadata;
    version = meta.version;
  } catch {
    console.warn("Warning: Could not read metadata.json — version will be 'unknown'");
  }

  const stateFiles = findStateFiles(assetDir, version, states);

  console.log(`Verifying ${stateFiles.length} states for version ${version}...`);

  const stateResults: StateVerification[] = [];
  let totalCount = 0;
  let overallPassed = true;

  for (const { state, path } of stateFiles) {
    process.stdout.write(`  ${state}... `);

    // Check file existence before attempting verification
    try {
      await access(path);
    } catch {
      console.log(`SKIPPED — file not found: ${path}`);
      stateResults.push({
        state,
        rowCount: 0,
        schemaValid: false,
        schemaErrors: 0,
        boundaryCoverage: {},
        coverageBelowThreshold: [],
        qualityErrors: 0,
        qualityWarnings: 0,
        duplicatePids: 0,
        enumUnknownCounts: {},
        passed: false,
      });
      overallPassed = false;
      continue;
    }

    try {
      const result = await verifyGzippedState(path, state, undefined, thresholds);
      stateResults.push(result);
      totalCount += result.rowCount;
      if (!result.passed) overallPassed = false;
      console.log(`${result.rowCount.toLocaleString()} docs, ${result.passed ? "PASS" : "FAIL"}`);
    } catch (err) {
      console.log(`ERROR: ${err instanceof Error ? err.message : String(err)}`);
      stateResults.push({
        state,
        rowCount: 0,
        schemaValid: false,
        schemaErrors: 1,
        boundaryCoverage: {},
        coverageBelowThreshold: [],
        qualityErrors: 1,
        qualityWarnings: 0,
        duplicatePids: 0,
        enumUnknownCounts: {},
        passed: false,
      });
      overallPassed = false;
    }
  }

  const report: VerificationReport = {
    version,
    timestamp: new Date().toISOString(),
    states: stateResults,
    totalCount,
    overallPassed,
  };

  const markdown = formatVerificationReport(report);
  await writeFile(outputPath, markdown, "utf-8");
  console.log(`\nReport written to ${outputPath}`);
  console.log(`Overall: ${overallPassed ? "PASS" : "FAIL"}`);

  // Also write JSON for machine consumption
  const jsonPath = outputPath.replace(/\.md$/, ".json");
  await writeFile(jsonPath, JSON.stringify(report, null, 2), "utf-8");
  console.log(`JSON written to ${jsonPath}`);

  if (!overallPassed) {
    process.exit(4);
  }
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main().catch((err) => {
    console.error(err);
    process.exit(4);
  });
}
