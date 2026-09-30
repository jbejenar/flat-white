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
import { pipeline } from "node:stream/promises";
import { AddressDocumentSchema } from "./schema.js";
import type { AddressDocument } from "./schema.js";
import { PidLedger } from "./pid-ledger.js";
import { z } from "zod";
import { VERSION } from "./index.js";
import { ASGS_YEAR } from "./schema.js";
import { checkAugustOtFederal } from "./release-quality.js";
import { readSourceLock, sourceIdentity } from "./source-lock.js";
import { PER_STATE_BOUNDARY_THRESHOLDS, ENUM_FIELD_PATHS } from "./verify.js";
import type { EnumSets, EnumUnknownCounts } from "./verify.js";

const DEFAULT_STATES = ["ACT", "NSW", "NT", "OT", "QLD", "SA", "TAS", "VIC", "WA"] as const;
const VALID_STATES: ReadonlySet<string> = new Set(DEFAULT_STATES);
/** Per-field minimum boundary coverage thresholds (percent, 0-100). */
export type BoundaryCoverageThresholds = Partial<
  Record<keyof AddressDocument["boundaries"], number>
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
  qualityDiagnostics?: string[];
}

export interface VerificationReport {
  version: string;
  timestamp: string;
  states: StateVerification[];
  totalCount: number;
  overallPassed: boolean;
  nationalDuplicatePids?: number;
}

const releaseMetadataSchema = z.object({
  version: z.string().regex(/^\d{4}\.(?:02|05|08|11)(?:\.[1-9]\d*)?$/),
  gnafVersion: z
    .string()
    .regex(/^\d{4}\.(?:02|05|08|11)$/)
    .optional(),
  adminBoundariesVersion: z.string().optional(),
  schemaVersion: z.literal(VERSION),
  asgsYear: z.literal(ASGS_YEAR),
  sourceLock: z.literal("source-lock.json").optional(),
  boundaryReferenceDate: z.string().optional(),
  states: z.record(z.string(), z.number().int().positive()),
  totalCount: z.number().int().positive(),
});

export function parseReleaseMetadata(value: unknown) {
  const metadata = releaseMetadataSchema.parse(value);
  if (
    Object.keys(metadata.states).some((state) => !VALID_STATES.has(state)) ||
    Object.values(metadata.states).reduce((sum, count) => sum + count, 0) !== metadata.totalCount
  ) {
    throw new Error("Release metadata has invalid states or inconsistent totals");
  }
  if (metadata.gnafVersion && metadata.gnafVersion !== metadata.version.slice(0, 7)) {
    throw new Error("Release version and G-NAF source quarter disagree");
  }
  return metadata;
}

/** State artifacts must all derive from the one acquired source set. */
export async function verifyBuildProvenance(
  assetDir: string,
  metadata: ReturnType<typeof parseReleaseMetadata>,
): Promise<void> {
  if (
    !metadata.sourceLock ||
    Object.keys(metadata.states).sort().join() !== [...DEFAULT_STATES].sort().join()
  )
    throw new Error("Production releases require a source lock and all nine states");
  const lock = await readSourceLock(join(assetDir, metadata.sourceLock));
  if (
    lock.gnafVersion !== metadata.gnafVersion ||
    lock.adminVersion !== metadata.adminBoundariesVersion ||
    lock.boundaryReferenceDate !== metadata.boundaryReferenceDate
  )
    throw new Error("Release metadata disagrees with source lock");
  const checksum = z.string().regex(/^[a-f0-9]{64}$/);
  let runtimeFingerprint: string | undefined;
  for (const state of DEFAULT_STATES) {
    const report = z
      .object({
        context: z.object({
          formatVersion: z.literal(1),
          sourceIdentity: z.literal(sourceIdentity(lock)),
          gnafVersion: z.literal(lock.gnafVersion),
          boundaryReferenceDate: z.literal(lock.boundaryReferenceDate),
          states: z.tuple([z.literal(state)]),
          runtimeFingerprint: checksum,
          scope: z.literal("base-gnaf-geoscape"),
        }),
        dumpSha256: checksum,
      })
      .parse(JSON.parse(await readFile(join(assetDir, `build-provenance-${state}.json`), "utf8")));
    if (runtimeFingerprint && runtimeFingerprint !== report.context.runtimeFingerprint)
      throw new Error("State artifacts were prepared by different code or runtimes");
    runtimeFingerprint = report.context.runtimeFingerprint;
  }
}

/** Validate evidence produced by the database reconciliation, before trusting its digest. */
export function reconciliationDigest(value: unknown, sourceVersion: string, count: number): string {
  const summary = z.object({
    count: z.literal(count),
    duplicateCount: z.literal(0),
    sha256: z.string().regex(/^[a-f0-9]{64}$/),
  });
  const comparison = z.object({ missing: z.literal(0), unexpected: z.literal(0) });
  const report = z
    .object({
      version: z.literal(sourceVersion),
      passed: z.literal(true),
      raw: summary,
      loaded: summary,
      output: summary,
      sourceToLoaded: comparison,
      loadedToOutput: comparison,
    })
    .parse(value);
  if (report.raw.sha256 !== report.loaded.sha256 || report.loaded.sha256 !== report.output.sha256) {
    throw new Error("Reconciliation evidence contains inconsistent PID digests");
  }
  return report.output.sha256;
}

/**
 * Stream a gzipped state artifact, validating every record before publication.
 * Decompression and input errors reject the promise and close the whole stream.
 * Uses the same per-state coverage policy as the build verifier.
 */
export async function verifyGzippedState(
  gzPath: string,
  state: string,
  enumSets?: EnumSets,
  thresholds?: BoundaryCoverageThresholds,
  expected?: {
    sourceVersion: string;
    count: number;
    pidSha256?: string;
    onPid?: (pid: string) => Promise<void>;
    adminBoundariesVersion?: string;
  },
): Promise<StateVerification> {
  const stateThresholds = PER_STATE_BOUNDARY_THRESHOLDS[state];
  if (!VALID_STATES.has(state)) throw new Error(`Invalid verification state: ${state}`);
  let rowCount = 0;
  let schemaErrors = 0;
  const boundaryCounts: Record<keyof AddressDocument["boundaries"], number> = {
    lga: 0,
    ward: 0,
    stateElectorate: 0,
    commonwealthElectorate: 0,
    meshBlock: 0,
    sa1: 0,
    sa2: 0,
    sa3: 0,
    sa4: 0,
    gccsa: 0,
  };
  let qualityErrors = 0;
  const qualityDiagnostics: string[] = [];
  const checkOtSnapshot =
    state === "OT" &&
    expected?.sourceVersion === "2026.08" &&
    expected.adminBoundariesVersion === "2026.08";
  const missingFederalPids: string[] = [];
  const federalCounts: Record<string, number> = {};
  const qualityWarnings = 0;
  const ledger = await PidLedger.create();
  let duplicatePids = 0;
  try {
    const enumUnknownCounts: EnumUnknownCounts = {};

    const gunzip = createGunzip();
    const fileStream = createReadStream(gzPath);
    const rl = createInterface({
      input: gunzip,
      crlfDelay: Infinity,
    });
    // Register the reader before starting I/O and handle the pipeline rejection
    // immediately. Neither a missing file nor a truncated gzip can leak an
    // unhandled error or leave the reader waiting forever.
    const lines = rl[Symbol.asyncIterator]();
    let streamError: unknown;
    const completion = pipeline(fileStream, gunzip).catch((error: unknown) => {
      streamError = error;
      rl.close();
    });

    try {
      for await (const line of lines) {
        if (!line.trim()) continue;
        rowCount++;

        let value: unknown;
        try {
          value = JSON.parse(line);
        } catch {
          schemaErrors++;
          continue;
        }

        const parsed = AddressDocumentSchema.safeParse(value);
        if (!parsed.success) {
          schemaErrors++;
          continue;
        }
        const doc = parsed.data;

        if (checkOtSnapshot) {
          const name = doc.boundaries.commonwealthElectorate?.name.toUpperCase();
          if (name) {
            // Keep diagnostics bounded even when a corrupted artifact supplies
            // a different electorate string for every row.
            const key = ["BEAN", "FENNER", "LINGIARI"].includes(name) ? name : "OTHER";
            federalCounts[key] = (federalCounts[key] ?? 0) + 1;
          } else if (missingFederalPids.length < 3) missingFederalPids.push(doc._id);
        }

        if (expected && doc._version !== expected.sourceVersion) qualityErrors++;

        await ledger.add(doc._id);
        await expected?.onPid?.(doc._id);

        // Boundary coverage
        for (const field of Object.keys(boundaryCounts) as (keyof typeof boundaryCounts)[]) {
          if (doc.boundaries[field]) boundaryCounts[field]++;
        }

        // Coordinate quality check
        const geocode = doc.geocode;
        if (geocode) {
          const { latitude, longitude } = geocode;
          if (latitude < -44 || latitude > -9 || longitude < 96 || longitude > 168) {
            qualityErrors++;
          }
        }
        for (const { lat, lng } of doc.allGeocodes) {
          if (lat < -44 || lat > -9 || lng < 96 || lng > 168) qualityErrors++;
        }

        // A per-state artifact must contain only that state, including records
        // whose postcode is null (valid for some addresses).
        if (doc.state !== state) qualityErrors++;

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
    } finally {
      rl.close();
      gunzip.destroy();
      await completion;
    }
    if (streamError) throw streamError;
    const identities = await ledger.finish();
    duplicatePids = identities.duplicateCount;
    if (expected && rowCount !== expected.count) qualityErrors++;
    if (expected?.pidSha256 && identities.sha256 !== expected.pidSha256) qualityErrors++;
    if (checkOtSnapshot && !checkAugustOtFederal(rowCount, missingFederalPids, federalCounts)) {
      qualityErrors++;
      qualityDiagnostics.push(
        "August 2026 OT federal assignments differ from the audited 3,803 matches and two named source exceptions",
      );
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
    const effectiveThresholds = {
      ...Object.fromEntries(
        Object.entries(stateThresholds).map(([field, fraction]) => [field, fraction * 100]),
      ),
      ...thresholds,
    };
    for (const [field, threshold] of Object.entries(effectiveThresholds) as [
      keyof BoundaryCoverageThresholds,
      number,
    ][]) {
      if (threshold === undefined) continue;
      const actual = rowCount > 0 ? (boundaryCounts[field] / rowCount) * 100 : 0;
      if (actual < threshold) {
        coverageBelowThreshold.push({ field, actual, threshold });
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
      qualityDiagnostics,
      qualityWarnings,
      duplicatePids,
      enumUnknownCounts,
      // Independent safety: a zero-row state file is always a failure, even if
      // thresholds are explicitly overridden to zero. Every schema/quality/enum check is
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
  } finally {
    await ledger.close();
  }
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

  if (report.nationalDuplicatePids !== undefined) {
    lines.push(
      `National PID uniqueness: ${report.nationalDuplicatePids === 0 ? "PASS" : `FAIL (${report.nationalDuplicatePids} repeated PIDs)`}`,
    );
    lines.push("");
  }

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
  lines.push(
    "| State | LGA | Ward | State Elect. | Cwlth Elect. | Mesh Block | SA1 | SA2 | SA3 | SA4 | GCCSA |",
  );
  lines.push(
    "|-------|----:|-----:|-------------:|-------------:|-----------:|----:|----:|----:|----:|------:|",
  );

  for (const s of report.states) {
    const c = s.boundaryCoverage;
    lines.push(
      `| ${s.state} | ${c.lga ?? "-"} | ${c.ward ?? "-"} | ${c.stateElectorate ?? "-"} | ${c.commonwealthElectorate ?? "-"} | ${c.meshBlock ?? "-"} | ${c.sa1 ?? "-"} | ${c.sa2 ?? "-"} | ${c.sa3 ?? "-"} | ${c.sa4 ?? "-"} | ${c.gccsa ?? "-"} |`,
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
  "sa3",
  "sa4",
  "gccsa",
]);

/**
 * Parse a boundary coverage threshold spec like "lga=99,ward=95,sa1=99".
 * Returns undefined when the spec is missing/empty (keep census defaults).
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

  // Publication must never proceed with guessed versions or unchecked counts.
  const metadataPath = join(assetDir, "metadata.json");
  const metadata = parseReleaseMetadata(JSON.parse(await readFile(metadataPath, "utf-8")));
  const version = metadata.version;
  const sourceVersion = metadata.gnafVersion ?? version.slice(0, 7);
  const fixtureOnly = process.argv.includes("--fixture-only");
  if (fixtureOnly && sourceVersion !== "2026.02")
    throw new Error("Fixture verification requires the frozen 2026.02 snapshot");
  if (!fixtureOnly) await verifyBuildProvenance(assetDir, metadata);

  const stateFiles = findStateFiles(assetDir, version, states);

  console.log(`Verifying ${stateFiles.length} states for version ${version}...`);

  const stateResults: StateVerification[] = [];
  let totalCount = 0;
  let overallPassed = true;

  const nationalLedger = await PidLedger.create();
  try {
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
        const count = metadata.states[state];
        if (!count) throw new Error(`No expected count in metadata for ${state}`);
        const pidSha256 = fixtureOnly
          ? undefined
          : reconciliationDigest(
              JSON.parse(await readFile(join(assetDir, `reconciliation-${state}.json`), "utf8")),
              sourceVersion,
              count,
            );
        const result = await verifyGzippedState(path, state, undefined, thresholds, {
          sourceVersion,
          count,
          pidSha256,
          adminBoundariesVersion: metadata.adminBoundariesVersion,
          onPid: (pid) => nationalLedger.add(pid),
        });
        stateResults.push(result);
        totalCount += result.rowCount;
        if (!result.passed) overallPassed = false;
        console.log(`${result.rowCount.toLocaleString()} docs, ${result.passed ? "PASS" : "FAIL"}`);
        for (const message of result.qualityDiagnostics ?? [])
          console.error(`  ${state}: ${message}`);
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

    const nationalDuplicatePids = (await nationalLedger.finish()).duplicateCount;
    if (nationalDuplicatePids > 0) overallPassed = false;

    const report: VerificationReport = {
      version,
      timestamp: new Date().toISOString(),
      nationalDuplicatePids,
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
      process.exitCode = 4;
    }
  } finally {
    await nationalLedger.close();
  }
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main().catch((err) => {
    console.error(err);
    process.exit(4);
  });
}
