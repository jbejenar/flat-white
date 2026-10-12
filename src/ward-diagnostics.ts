import { z } from "zod";
import type { AddressDocument } from "./schema.js";
import { type WardLock } from "./ward-sources.js";
import type { WardLookup, WardPoint } from "./ward-spatial.js";

export const wardReasons = [
  "matched",
  "unsupported",
  "undivided",
  "insufficient_precision",
  "unmatched",
  "ambiguous",
] as const;
type Reason = (typeof wardReasons)[number];
const reasonSchema = z.enum(wardReasons);
const count = z.number().int().nonnegative();
const countSchema = z.object(
  Object.fromEntries(wardReasons.map((r) => [r, count])) as Record<Reason, typeof count>,
);
const counts = () => Object.fromEntries(wardReasons.map((r) => [r, 0])) as Record<Reason, number>;
const sum = (value: Record<Reason, number>) => Object.values(value).reduce((a, b) => a + b, 0);
const councilSchema = z.object({
  lgaCode: z.string().nullable(),
  lgaName: z.string().nullable(),
  sourceId: z.string().nullable(),
  reasons: countSchema,
  eligible: count,
  matched: count,
  coveragePercent: z.number().min(0).max(100).nullable(),
});
export const WardDiagnosticsSchema = z
  .object({
    formatVersion: z.literal(1),
    version: z.string(),
    sourceIdentity: z.string().regex(/^[a-f0-9]{64}$/),
    referenceDate: z.string(),
    passed: z.boolean(),
    errors: z.array(z.string()),
    nswAddresses: count,
    reasons: countSchema,
    councils: z.array(councilSchema).max(1024),
    samples: z.object(
      Object.fromEntries(wardReasons.map((r) => [r, z.array(z.string()).max(20)])) as Record<
        Reason,
        z.ZodArray<z.ZodString>
      >,
    ),
  })
  .superRefine((report, ctx) => {
    const fail = (message: string) => ctx.addIssue({ code: "custom", message });
    if (
      report.passed !== (report.errors.length === 0) ||
      sum(report.reasons) !== report.nswAddresses
    )
      fail("Ward diagnostic totals or status disagree");
    if (new Set(report.councils.map((c) => c.lgaCode)).size !== report.councils.length)
      fail("Duplicate ward council diagnosis");
    for (const reason of wardReasons)
      if (report.reasons[reason] !== report.councils.reduce((n, c) => n + c.reasons[reason], 0))
        fail("Council and state ward totals disagree");
    for (const council of report.councils) {
      const eligible =
        council.reasons.matched + council.reasons.unmatched + council.reasons.ambiguous;
      if (
        council.eligible !== eligible ||
        council.matched !== council.reasons.matched ||
        council.coveragePercent !== (eligible ? (100 * council.matched) / eligible : null)
      )
        fail("Ward eligibility or coverage is inconsistent");
    }
  });
export type WardReport = z.infer<typeof WardDiagnosticsSchema>;

export function hasQualifyingSite(doc: AddressDocument, lock: WardLock): boolean {
  const point = doc.geocode;
  return (
    !!point &&
    [1, 2].includes(point.reliability) &&
    lock.registry.preciseSiteTypes.some(
      (type) => point.type === type.code || point.type === type.name,
    )
  );
}

/** Reconcile the compressed export with producer diagnostics, without trusting row flags. */
export class WardOutputVerifier {
  private counts = new Map<string, { total: number; eligible: number; matched: number }>();
  private spatialReasons = new Map<string, Record<"matched" | "unmatched" | "ambiguous", number>>();
  private pending: (WardPoint & { lgaCode: string; wardName: string | null })[] = [];
  private invalid = false;
  constructor(
    private lock: WardLock,
    private report: WardReport,
    private version: string,
    private lookup: WardLookup,
  ) {}
  async observe(doc: AddressDocument): Promise<void> {
    if (doc.state !== "NSW") return;
    const code = doc.boundaries.lga?.code;
    const council = this.lock.registry.councils.find((c) => c.lgaCode === code);
    const qualified = council?.status === "enabled" && hasQualifyingSite(doc, this.lock);
    const ward = doc.boundaries.ward;
    if (ward && (!qualified || !council?.source?.wards.some((w) => w.name === ward.name)))
      this.invalid = true;
    if (council && doc.boundaries.lga?.name !== council.lgaName) this.invalid = true;
    const key = code ?? "unassigned";
    if (!this.counts.has(key) && this.counts.size >= 1024) {
      this.invalid = true;
      return;
    }
    const entry = this.counts.get(key) ?? { total: 0, eligible: 0, matched: 0 };
    entry.total++;
    if (qualified) entry.eligible++;
    if (ward) entry.matched++;
    this.counts.set(key, entry);
    if (qualified && doc.geocode) {
      this.pending.push({
        sourceId: council.id,
        lgaCode: council.lgaCode,
        longitude: doc.geocode.longitude,
        latitude: doc.geocode.latitude,
        wardName: ward?.name ?? null,
      });
      if (this.pending.length === 1000) await this.flush();
    }
  }
  private async flush(): Promise<void> {
    if (!this.pending.length) return;
    const intersections = await this.lookup(this.pending);
    if (intersections.length !== this.pending.length) throw new Error("Incomplete ward lookup");
    for (let i = 0; i < this.pending.length; i++) {
      const point = this.pending[i];
      const result = intersections[i];
      const reason =
        result.matches === 1 ? "matched" : result.matches === 0 ? "unmatched" : "ambiguous";
      if (point.wardName !== (result.matches === 1 ? result.name : null)) this.invalid = true;
      const reasons = this.spatialReasons.get(point.lgaCode) ?? {
        matched: 0,
        unmatched: 0,
        ambiguous: 0,
      };
      reasons[reason]++;
      this.spatialReasons.set(point.lgaCode, reasons);
    }
    this.pending = [];
  }
  async passed(): Promise<boolean> {
    await this.flush();
    const report = this.report;
    if (
      this.invalid ||
      !report.passed ||
      report.version !== this.version ||
      report.sourceIdentity !== this.lock.identity ||
      report.referenceDate !== this.lock.registry.referenceDate ||
      this.counts.size !== report.councils.length
    )
      return false;
    let total = 0;
    for (const [code, counts] of this.counts) {
      total += counts.total;
      const actual = report.councils.find((c) => (c.lgaCode ?? "unassigned") === code);
      const council = this.lock.registry.councils.find((c) => c.lgaCode === code);
      if (
        !actual ||
        sum(actual.reasons) !== counts.total ||
        actual.eligible !== counts.eligible ||
        actual.matched !== counts.matched ||
        actual.sourceId !== (council?.id ?? null) ||
        actual.lgaName !== (council?.lgaName ?? actual.lgaName)
      )
        return false;
      if (!council && actual.reasons.unsupported !== counts.total) return false;
      if (council?.status === "undivided" && actual.reasons.undivided !== counts.total)
        return false;
      if (
        council?.status === "enabled" &&
        (actual.reasons.insufficient_precision !== counts.total - counts.eligible ||
          actual.reasons.unsupported ||
          actual.reasons.undivided)
      )
        return false;
      const spatial = this.spatialReasons.get(code);
      for (const reason of ["matched", "unmatched", "ambiguous"] as const)
        if (actual.reasons[reason] !== (spatial?.[reason] ?? 0)) return false;
    }
    if (total)
      for (const council of this.lock.registry.councils.filter((c) => c.status === "enabled")) {
        const entry = this.counts.get(council.lgaCode);
        if (!entry?.eligible || entry.matched * 100 < entry.eligible * 99) return false;
      }
    return total === report.nswAddresses;
  }
}

export class WardDiagnostics {
  private reasons = counts();
  private samples = Object.fromEntries(wardReasons.map((r) => [r, [] as string[]])) as Record<
    Reason,
    string[]
  >;
  private councils = new Map<string, z.infer<typeof councilSchema>>();
  constructor(
    private version: string,
    private lock: WardLock,
  ) {}

  observe(row: Record<string, unknown>, doc: AddressDocument): void {
    if (doc.state !== "NSW") {
      if (row.ward_reason !== "not_applicable")
        throw new Error("Council enrichment applied outside NSW");
      return;
    }
    const reason = reasonSchema.parse(row.ward_reason);
    const lga = doc.boundaries.lga;
    const approved = this.lock.registry.councils.find((c) => c.lgaCode === lga?.code);
    if (
      (row.ward_source_id ?? null) !== (approved?.id ?? null) ||
      (approved && approved.lgaName !== lga?.name)
    )
      throw new Error(`Ward crosswalk differs from reviewed LGA: ${doc._id}`);
    if (
      (reason === "matched") !== (doc.boundaries.ward !== null) ||
      (reason === "matched" &&
        (!hasQualifyingSite(doc, this.lock) ||
          !approved?.source?.wards.some((w) => w.name === doc.boundaries.ward?.name)))
    )
      throw new Error(`Ward assignment or precision is inconsistent: ${doc._id}`);
    if (
      (reason === "unsupported") !== !approved ||
      (reason === "undivided") !== (approved?.status === "undivided")
    )
      throw new Error(`Incorrect ward coverage reason: ${doc._id}`);
    const key = lga?.code ?? "unassigned";
    if (!this.councils.has(key) && this.councils.size >= 1024)
      throw new Error("Too many distinct NSW councils");
    let council = this.councils.get(key);
    if (!council) {
      council = {
        lgaCode: lga?.code ?? null,
        lgaName: lga?.name ?? null,
        sourceId: approved?.id ?? null,
        reasons: counts(),
        eligible: 0,
        matched: 0,
        coveragePercent: null,
      };
      this.councils.set(key, council);
    }
    council.reasons[reason]++;
    this.reasons[reason]++;
    if (this.samples[reason].length < 20) this.samples[reason].push(doc._id);
  }

  report(): WardReport {
    const errors: string[] = [];
    const nswAddresses = sum(this.reasons);
    for (const council of this.councils.values()) {
      council.eligible =
        council.reasons.matched + council.reasons.unmatched + council.reasons.ambiguous;
      council.matched = council.reasons.matched;
      council.coveragePercent = council.eligible
        ? (100 * council.matched) / council.eligible
        : null;
    }
    if (nswAddresses) {
      for (const source of this.lock.registry.councils.filter((c) => c.status === "enabled")) {
        const council = this.councils.get(source.lgaCode);
        if (!council?.eligible)
          errors.push(`${source.id}: no eligible addresses; coverage is undefined`);
        else if (council.matched * 100 < council.eligible * 99)
          errors.push(`${source.id}: ward coverage below 99% of eligible addresses`);
      }
    }
    return WardDiagnosticsSchema.parse({
      formatVersion: 1,
      version: this.version,
      sourceIdentity: this.lock.identity,
      referenceDate: this.lock.registry.referenceDate,
      passed: errors.length === 0,
      errors,
      nswAddresses,
      reasons: this.reasons,
      councils: [...this.councils.values()].sort((a, b) =>
        (a.lgaCode ?? "").localeCompare(b.lgaCode ?? ""),
      ),
      samples: this.samples,
    });
  }
}
