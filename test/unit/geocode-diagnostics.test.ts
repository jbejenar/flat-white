import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";
import { GeocodeDiagnostics, GeocodeDiagnosticsSchema } from "../../src/geocode-diagnostics.js";
import { AddressDocumentSchema } from "../../src/schema.js";

const doc = AddressDocumentSchema.parse(
  JSON.parse(readFileSync("fixtures/expected-output.ndjson", "utf8").split("\n")[0]),
);
const row = {
  invalid_site_count: 0,
  invalid_default_count: 0,
  active_default_count: 1,
  distinct_default_count: 1,
};

describe("geocode source diagnostics", () => {
  it("blocks conflicting defaults even with a valid site point and bounds samples", () => {
    const diagnostics = new GeocodeDiagnostics("2026.02");
    for (let i = 0; i < 100; i++)
      diagnostics.observe(
        { ...row, active_default_count: 2, distinct_default_count: 2 },
        { ...doc, _id: String(i) },
      );
    const report = diagnostics.report();
    expect(report).toMatchObject({
      totalAddresses: 100,
      site: 100,
      passed: false,
      affectedAddresses: { conflictingDefaults: 100 },
    });
    expect(report.samples.conflictingDefaults).toHaveLength(20);
    expect(GeocodeDiagnosticsSchema.safeParse({ ...report, passed: true }).success).toBe(false);
  });
  it("does not confuse duplicates with conflicts or accept missing source diagnostics", () => {
    const diagnostics = new GeocodeDiagnostics("2026.02");
    diagnostics.observe({ ...row, active_default_count: 2 }, doc);
    expect(diagnostics.report()).toMatchObject({
      passed: true,
      affectedAddresses: { duplicateDefaults: 1, conflictingDefaults: 0 },
    });
    expect(() => diagnostics.observe({}, doc)).toThrow();
    expect(() => diagnostics.observe({ ...row, distinct_default_count: 2 }, doc)).toThrow();
  });
});
