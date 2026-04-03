/**
 * Regression test: validates every document in expected-output.ndjson
 * against the Zod AddressDocumentSchema and verifies data quality.
 *
 * Covers:
 * - P0.12 DoD: "Every document validates against the schema"
 * - P1.15 DoD: "Regression test compares against expected-output.ndjson"
 * - P1.10 DoD: "Row count verification"
 * - P1.10A DoD: "PID uniqueness, coordinate bounds, boundary coverage"
 */

import { readFileSync, existsSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { describe, it, expect } from "vitest";
import { AddressDocumentSchema } from "../../src/schema.js";
import { verify, isWithinAustralia } from "../../src/verify.js";

const __dirname = dirname(fileURLToPath(import.meta.url));
const EXPECTED_OUTPUT = resolve(__dirname, "../../fixtures/expected-output.ndjson");

describe("expected-output.ndjson", () => {
  it("file exists", () => {
    expect(existsSync(EXPECTED_OUTPUT)).toBe(true);
  });

  it("every document validates against AddressDocumentSchema", () => {
    const content = readFileSync(EXPECTED_OUTPUT, "utf-8").trimEnd();
    const lines = content.split("\n");

    expect(lines.length).toBeGreaterThan(0);

    const failures: Array<{ line: number; pid: string; errors: string }> = [];

    for (let i = 0; i < lines.length; i++) {
      const doc = JSON.parse(lines[i]) as Record<string, unknown>;
      const result = AddressDocumentSchema.safeParse(doc);
      if (!result.success) {
        failures.push({
          line: i + 1,
          pid: (doc._id as string) ?? "unknown",
          errors: result.error.message,
        });
      }
    }

    if (failures.length > 0) {
      const summary = failures
        .slice(0, 5)
        .map((f) => `  Line ${f.line} (${f.pid}): ${f.errors}`)
        .join("\n");
      expect.fail(`${failures.length}/${lines.length} documents failed validation:\n${summary}`);
    }
  });

  it("line count matches expected address count (451)", () => {
    const content = readFileSync(EXPECTED_OUTPUT, "utf-8").trimEnd();
    const lines = content.split("\n");
    expect(lines.length).toBe(451);
  });

  it("no duplicate _id values", () => {
    const content = readFileSync(EXPECTED_OUTPUT, "utf-8").trimEnd();
    const lines = content.split("\n");
    const ids = lines.map((line) => (JSON.parse(line) as Record<string, unknown>)._id as string);
    const unique = new Set(ids);
    expect(unique.size).toBe(ids.length);
  });

  it("all geocodes within Australian bounding box", () => {
    const content = readFileSync(EXPECTED_OUTPUT, "utf-8").trimEnd();
    const lines = content.split("\n");
    const outOfBounds: Array<{ pid: string; lat: number; lng: number }> = [];

    for (const line of lines) {
      const doc = JSON.parse(line) as Record<string, unknown>;
      const pid = doc._id as string;
      const geocode = doc.geocode as { latitude: number; longitude: number } | null;
      if (geocode && !isWithinAustralia(geocode.latitude, geocode.longitude)) {
        outOfBounds.push({ pid, lat: geocode.latitude, lng: geocode.longitude });
      }
    }

    if (outOfBounds.length > 0) {
      const summary = outOfBounds
        .slice(0, 5)
        .map((o) => `  ${o.pid}: (${o.lat}, ${o.lng})`)
        .join("\n");
      expect.fail(
        `${outOfBounds.length} addresses have coordinates outside Australia:\n${summary}`,
      );
    }
  });

  it("passes full verification suite", async () => {
    const result = await verify({ outputPath: EXPECTED_OUTPUT, expectedCount: 451 });
    expect(result.passed).toBe(true);
    expect(result.qualityIssues.length).toBe(0);
    expect(result.duplicatePids.length).toBe(0);

    // Boundary coverage should be high for VIC fixture data
    const cov = result.boundaryCoverage;
    expect(cov.lga / cov.total).toBeGreaterThan(0.99);
  });
});
