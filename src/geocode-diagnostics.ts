import { z } from "zod";
import type { AddressDocument } from "./schema.js";

const count = z.number().int().nonnegative();
const reasons = [
  "invalidSite",
  "invalidDefault",
  "conflictingDefaults",
  "duplicateDefaults",
  "noSiteOrDefault",
  "noSiteInvalidDefault",
] as const;
type Reason = (typeof reasons)[number];
const counts = () => Object.fromEntries(reasons.map((key) => [key, 0])) as Record<Reason, number>;
const samples = () =>
  Object.fromEntries(reasons.map((key) => [key, [] as string[]])) as Record<Reason, string[]>;

/** Counts describe affected exported addresses, not unique rows in a shared site table. */
export const GeocodeDiagnosticsSchema = z
  .object({
    formatVersion: z.literal(1),
    version: z.string(),
    passed: z.boolean(),
    totalAddresses: count,
    site: count,
    fallback: z.object({ street: count, locality: count, unknown: count }),
    affectedAddresses: z.object(
      Object.fromEntries(reasons.map((key) => [key, count])) as Record<Reason, typeof count>,
    ),
    samples: z.object(
      Object.fromEntries(reasons.map((key) => [key, z.array(z.string()).max(20)])) as Record<
        Reason,
        z.ZodArray<z.ZodString>
      >,
    ),
  })
  .superRefine((report, ctx) => {
    if (report.passed !== (report.affectedAddresses.conflictingDefaults === 0))
      ctx.addIssue({ code: "custom", message: "Conflicting defaults must block publication" });
    const categorized = report.site + Object.values(report.fallback).reduce((a, b) => a + b, 0);
    if (
      categorized > report.totalAddresses ||
      Object.values(report.affectedAddresses).some((n) => n > report.totalAddresses)
    )
      ctx.addIssue({ code: "custom", message: "Geocode counts exceed the address population" });
  });

export class GeocodeDiagnostics {
  private totalAddresses = 0;
  private site = 0;
  private fallback = { street: 0, locality: 0, unknown: 0 };
  private affectedAddresses = counts();
  private samples = samples();

  constructor(private version: string) {}

  observe(row: Record<string, unknown>, doc: AddressDocument): void {
    const invalidSite = count.parse(Number(row.invalid_site_count));
    const invalidDefault = count.parse(Number(row.invalid_default_count));
    const activeDefaults = count.parse(Number(row.active_default_count));
    const distinctDefaults = count.parse(Number(row.distinct_default_count));
    if (distinctDefaults > activeDefaults || invalidDefault > activeDefaults)
      throw new Error("Invalid default geocode source counts");
    this.totalAddresses++;
    if (doc.geocode) this.site++;
    if (doc.fallbackGeocode) this.fallback[doc.fallbackGeocode.precision]++;
    const record = (reason: Reason) => {
      this.affectedAddresses[reason]++;
      if (this.samples[reason].length < 20) this.samples[reason].push(doc._id);
    };
    if (invalidSite > 0) record("invalidSite");
    if (invalidDefault > 0) record("invalidDefault");
    if (distinctDefaults > 1) record("conflictingDefaults");
    else if (activeDefaults > 1) record("duplicateDefaults");
    if (!doc.geocode && activeDefaults === 0) record("noSiteOrDefault");
    if (!doc.geocode && invalidDefault > 0) record("noSiteInvalidDefault");
  }

  report(): z.infer<typeof GeocodeDiagnosticsSchema> {
    return GeocodeDiagnosticsSchema.parse({
      formatVersion: 1,
      version: this.version,
      passed: this.affectedAddresses.conflictingDefaults === 0,
      totalAddresses: this.totalAddresses,
      site: this.site,
      fallback: this.fallback,
      affectedAddresses: this.affectedAddresses,
      samples: this.samples,
    });
  }
}
