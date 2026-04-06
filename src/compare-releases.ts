/**
 * flat-white — Build-over-build comparison (P4.03).
 *
 * Compares current build metadata against a prior release's metadata.json
 * to detect anomalies (>1% change in any state's count or total).
 *
 * Usage: node dist/compare-releases.js <current-metadata.json> <prior-metadata.json> [--threshold 1.0]
 *
 * Exit codes:
 *   0 — no anomalies (or no prior release)
 *   2 — anomalies detected (warning only — human decides)
 */

import { readFile, writeFile } from "node:fs/promises";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";
import type { BuildMetadata } from "./metadata.js";

export interface StateDelta {
  state: string;
  current: number;
  prior: number;
  delta: number;
  deltaPercent: number;
  isAnomaly: boolean;
}

export interface ComparisonResult {
  currentVersion: string;
  priorVersion: string;
  threshold: number;
  totalCurrent: number;
  totalPrior: number;
  totalDelta: number;
  totalDeltaPercent: number;
  totalAnomaly: boolean;
  states: StateDelta[];
  newStates: string[];
  retiredStates: string[];
  hasAnomalies: boolean;
}

/**
 * Compare two metadata objects and produce a structured comparison.
 */
export function compareMetadata(
  current: BuildMetadata,
  prior: BuildMetadata,
  threshold = 1.0,
): ComparisonResult {
  const currentStates = new Set(Object.keys(current.states));
  const priorStates = new Set(Object.keys(prior.states));

  const newStates = [...currentStates].filter((s) => !priorStates.has(s));
  const retiredStates = [...priorStates].filter((s) => !currentStates.has(s));

  const allStates = new Set([...currentStates, ...priorStates]);
  const states: StateDelta[] = [];

  for (const state of [...allStates].sort()) {
    const currentCount = current.states[state] ?? 0;
    const priorCount = prior.states[state] ?? 0;
    const delta = currentCount - priorCount;
    const deltaPercent =
      priorCount > 0 ? (Math.abs(delta) / priorCount) * 100 : currentCount > 0 ? 100 : 0;
    const isAnomaly = deltaPercent > threshold;

    states.push({
      state,
      current: currentCount,
      prior: priorCount,
      delta,
      deltaPercent,
      isAnomaly,
    });
  }

  const totalDelta = current.totalCount - prior.totalCount;
  const totalDeltaPercent =
    prior.totalCount > 0
      ? (Math.abs(totalDelta) / prior.totalCount) * 100
      : current.totalCount > 0
        ? 100
        : 0;
  const totalAnomaly = totalDeltaPercent > threshold;

  const hasAnomalies =
    totalAnomaly ||
    states.some((s) => s.isAnomaly) ||
    newStates.length > 0 ||
    retiredStates.length > 0;

  return {
    currentVersion: current.version,
    priorVersion: prior.version,
    threshold,
    totalCurrent: current.totalCount,
    totalPrior: prior.totalCount,
    totalDelta,
    totalDeltaPercent,
    totalAnomaly,
    states,
    newStates,
    retiredStates,
    hasAnomalies,
  };
}

/**
 * Format a comparison result as a human-readable markdown report.
 */
export function formatComparisonReport(result: ComparisonResult): string {
  const lines: string[] = [];
  const sign = (n: number) => (n >= 0 ? `+${n}` : `${n}`);
  const pct = (n: number) => n.toFixed(2);

  lines.push("# Build-Over-Build Comparison");
  lines.push("");
  lines.push(`**Current:** ${result.currentVersion}`);
  lines.push(`**Prior:** ${result.priorVersion}`);
  lines.push(`**Anomaly threshold:** ${result.threshold}%`);
  lines.push("");

  // Overall summary
  lines.push("## Summary");
  lines.push("");
  lines.push(`| Metric | Current | Prior | Delta | Change |`);
  lines.push("|--------|--------:|------:|------:|-------:|");
  lines.push(
    `| **Total** | ${result.totalCurrent.toLocaleString()} | ${result.totalPrior.toLocaleString()} | ${sign(result.totalDelta)} | ${pct(result.totalDeltaPercent)}% ${result.totalAnomaly ? "⚠️" : ""} |`,
  );
  lines.push("");

  // Per-state table
  lines.push("## Per-State Comparison");
  lines.push("");
  lines.push("| State | Current | Prior | Delta | Change | Anomaly |");
  lines.push("|-------|--------:|------:|------:|-------:|:-------:|");

  for (const s of result.states) {
    const anomalyFlag = s.isAnomaly ? "⚠️ YES" : "-";
    lines.push(
      `| ${s.state} | ${s.current.toLocaleString()} | ${s.prior.toLocaleString()} | ${sign(s.delta)} | ${pct(s.deltaPercent)}% | ${anomalyFlag} |`,
    );
  }

  lines.push("");

  // New/retired states
  if (result.newStates.length > 0) {
    lines.push(`## New States: ${result.newStates.join(", ")}`);
    lines.push("");
  }
  if (result.retiredStates.length > 0) {
    lines.push(`## Retired States: ${result.retiredStates.join(", ")}`);
    lines.push("");
  }

  // Anomaly summary
  if (result.hasAnomalies) {
    lines.push("## ⚠️ Anomalies Detected");
    lines.push("");
    if (result.totalAnomaly) {
      lines.push(
        `- **Total count** changed by ${pct(result.totalDeltaPercent)}% (threshold: ${result.threshold}%)`,
      );
    }
    for (const s of result.states.filter((s) => s.isAnomaly)) {
      lines.push(
        `- **${s.state}** changed by ${pct(s.deltaPercent)}% (${sign(s.delta)} addresses)`,
      );
    }
    for (const s of result.newStates) {
      lines.push(`- **${s}** is a new state (not in prior release)`);
    }
    for (const s of result.retiredStates) {
      lines.push(`- **${s}** was retired (not in current release)`);
    }
    lines.push("");
    lines.push(
      "> **Action required:** Review anomalies before publishing this release. " +
        "The release has been kept as a draft.",
    );
  } else {
    lines.push("## No Anomalies");
    lines.push("");
    lines.push("All metrics within expected range. Release can be published.");
  }

  lines.push("");
  lines.push("---");
  lines.push("*Generated by flat-white build-over-build comparison*");

  return lines.join("\n");
}

// --- CLI entry point ---

async function main(): Promise<void> {
  const currentPath = process.argv[2];
  const priorPath = process.argv[3];

  if (!currentPath || !priorPath) {
    console.error(
      "Usage: node dist/compare-releases.js <current-metadata.json> <prior-metadata.json> [--threshold 1.0]",
    );
    process.exit(1);
  }

  const thresholdIdx = process.argv.indexOf("--threshold");
  const threshold = thresholdIdx !== -1 ? parseFloat(process.argv[thresholdIdx + 1]) : 1.0;

  const current = JSON.parse(await readFile(currentPath, "utf-8")) as BuildMetadata;
  const prior = JSON.parse(await readFile(priorPath, "utf-8")) as BuildMetadata;

  const result = compareMetadata(current, prior, threshold);
  const markdown = formatComparisonReport(result);

  console.log(markdown);

  // Write reports
  const outputBase = `comparison-${result.currentVersion}-vs-${result.priorVersion}`;
  await writeFile(`${outputBase}.md`, markdown, "utf-8");
  await writeFile(`${outputBase}.json`, JSON.stringify(result, null, 2), "utf-8");

  console.log(`\nReports written: ${outputBase}.md, ${outputBase}.json`);

  if (result.hasAnomalies) {
    console.log("\n⚠️  Anomalies detected — review before publishing.");
    process.exit(2);
  }
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main().catch((err) => {
    console.error(err);
    process.exit(1);
  });
}
