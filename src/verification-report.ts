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

const STATES = ["ACT", "NSW", "NT", "OT", "QLD", "SA", "TAS", "VIC", "WA"] as const;

export interface StateVerification {
  state: string;
  rowCount: number;
  schemaValid: boolean;
  schemaErrors: number;
  boundaryCoverage: Record<string, number>;
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
async function verifyGzippedState(
  gzPath: string,
  state: string,
  enumSets?: EnumSets,
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

  return {
    state,
    rowCount,
    schemaValid: schemaErrors === 0,
    schemaErrors,
    boundaryCoverage,
    qualityErrors,
    qualityWarnings,
    duplicatePids,
    enumUnknownCounts,
    passed:
      schemaErrors === 0 && qualityErrors === 0 && duplicatePids === 0 && enumErrorCount === 0,
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
function findStateFiles(assetDir: string, version: string): { state: string; path: string }[] {
  const found: { state: string; path: string }[] = [];
  for (const state of STATES) {
    const lower = state.toLowerCase();
    const filename = `flat-white-${version}-${lower}.ndjson.gz`;
    found.push({ state, path: join(assetDir, filename) });
  }
  return found;
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

  // Read metadata.json for version
  const metadataPath = join(assetDir, "metadata.json");
  let version = "unknown";
  try {
    const meta = JSON.parse(await readFile(metadataPath, "utf-8")) as BuildMetadata;
    version = meta.version;
  } catch {
    console.warn("Warning: Could not read metadata.json — version will be 'unknown'");
  }

  const stateFiles = findStateFiles(assetDir, version);

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
      const result = await verifyGzippedState(path, state);
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
