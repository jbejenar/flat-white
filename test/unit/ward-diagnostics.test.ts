import { readFileSync } from "node:fs";
import { describe, expect, it } from "vitest";
import { WardLockSchema } from "../../src/ward-sources.js";
import {
  WardDiagnostics,
  WardOutputVerifier,
  WardDiagnosticsSchema,
} from "../../src/ward-diagnostics.js";
import { AddressDocumentSchema, type AddressDocument } from "../../src/schema.js";

const lock = WardLockSchema.parse(
  JSON.parse(readFileSync("fixtures/ward-sources/ward-source-lock.json", "utf8")),
);
const base = AddressDocumentSchema.parse(
  JSON.parse(readFileSync("fixtures/expected-output.ndjson", "utf8").split("\n")[0]),
);
const lga = { code: "lga2a2057496fb7", name: "Camden Council" };
const matched: AddressDocument = {
  ...base,
  state: "NSW",
  boundaries: { ...base.boundaries, lga, ward: { name: "North Ward" } },
};
const row = { ward_reason: "matched", ward_source_id: "camden-2024" };
describe("ward coverage and independent artifact validation", () => {
  it("requires 99% of eligible points and reports zero eligibility as undefined", () => {
    const none = new WardDiagnostics("2026.02", lock);
    none.observe(
      { ...row, ward_reason: "insufficient_precision" },
      { ...matched, geocode: null, boundaries: { ...matched.boundaries, ward: null } },
    );
    expect(none.report()).toMatchObject({
      passed: false,
      councils: [{ eligible: 0, coveragePercent: null }],
    });
    const diagnostics = new WardDiagnostics("2026.02", lock);
    for (let i = 0; i < 99; i++) diagnostics.observe(row, { ...matched, _id: String(i) });
    diagnostics.observe(
      { ...row, ward_reason: "ambiguous" },
      { ...matched, boundaries: { ...matched.boundaries, ward: null } },
    );
    const report = diagnostics.report();
    expect(report).toMatchObject({
      passed: true,
      councils: [{ eligible: 100, matched: 99, coveragePercent: 99 }],
    });
    expect(report.samples.matched).toHaveLength(20);
    diagnostics.observe(
      { ...row, ward_reason: "unmatched" },
      { ...matched, boundaries: { ...matched.boundaries, ward: null } },
    );
    expect(diagnostics.report().passed).toBe(false);
  });
  it("keeps unsupported and confirmed undivided councils separate", () => {
    const diagnostics = new WardDiagnostics("2026.02", lock);
    diagnostics.observe(row, matched);
    const sydney = lock.registry.councils[1];
    diagnostics.observe(
      { ward_reason: "undivided", ward_source_id: sydney.id },
      {
        ...matched,
        boundaries: {
          ...matched.boundaries,
          ward: null,
          lga: { code: sydney.lgaCode, name: sydney.lgaName },
        },
      },
    );
    diagnostics.observe(
      { ward_reason: "unsupported", ward_source_id: null },
      { ...matched, boundaries: { ...matched.boundaries, ward: null, lga: null } },
    );
    expect(diagnostics.report().reasons).toMatchObject({
      matched: 1,
      unsupported: 1,
      undivided: 1,
    });
  });
  it("rejects fallback, approximate, unknown and imprecise primary points for assignments", () => {
    for (const point of [
      null,
      { ...matched.geocode!, type: "GAP GEOCODE" },
      { ...matched.geocode!, type: "UNKNOWN" },
      { ...matched.geocode!, reliability: 3 },
    ])
      expect(() =>
        new WardDiagnostics("2026.02", lock).observe(row, { ...matched, geocode: point }),
      ).toThrow(/precision/);
    expect(() =>
      new WardDiagnostics("2026.02", lock).observe(row, {
        ...matched,
        boundaries: { ...matched.boundaries, lga: { ...lga, name: "Different council" } },
      }),
    ).toThrow(/crosswalk/);
  });
  it("reconciles report identity, eligible denominators, counts and output scope", () => {
    const diagnostics = new WardDiagnostics("2026.02", lock);
    diagnostics.observe(row, matched);
    const report = diagnostics.report();
    const verify = (doc: AddressDocument, changed = report) => {
      const checker = new WardOutputVerifier(lock, changed, "2026.02");
      checker.observe(doc);
      return checker.passed();
    };
    expect(verify(matched)).toBe(true);
    expect(verify({ ...matched, boundaries: { ...matched.boundaries, ward: null } })).toBe(false);
    expect(verify({ ...matched, geocode: null })).toBe(false);
    expect(
      verify({ ...matched, boundaries: { ...matched.boundaries, ward: { name: "Invented" } } }),
    ).toBe(false);
    expect(verify(matched, { ...report, sourceIdentity: "0".repeat(64) })).toBe(false);
    expect(
      WardDiagnosticsSchema.safeParse({ ...report, reasons: { ...report.reasons, matched: 2 } })
        .success,
    ).toBe(false);
    expect(
      WardDiagnosticsSchema.safeParse({
        ...report,
        councils: [{ ...report.councils[0], eligible: 0, coveragePercent: 100 }],
      }).success,
    ).toBe(false);
  });
});
