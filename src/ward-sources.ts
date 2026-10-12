/** Qualified council snapshots are imported after the base database cache. */
import { createHash } from "node:crypto";
import { readFile, writeFile, mkdir, rm, rename } from "node:fs/promises";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import type postgres from "postgres";
import { z } from "zod";
import { SourceLockSchema, validateBoundaryDate, quarterEnd } from "./source-lock.js";

const preciseSiteCodes = new Set([
  "BAP",
  "BC",
  "BCM",
  "CDF",
  "DF",
  "EA",
  "EAS",
  "ECP",
  "EM",
  "FC",
  "FCS",
  "FDA",
  "GCP",
  "GM",
  "ICP",
  "LB",
  "PAP",
  "PAPS",
  "PC",
  "PCM",
  "SCP",
  "TCP",
  "UC",
  "UCM",
  "WCP",
  "WM",
]);

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const identifier = z.string().regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/);
const sha256 = z.string().regex(/^[a-f0-9]{64}$/);
const date = z.string().regex(/^\d{4}-\d{2}-\d{2}$/);
const sourceSchema = z.strictObject({
  url: z.url().refine((url) => url.startsWith("https://")),
  file: z.string().regex(/^wards-[a-z0-9-]+\.json$/),
  sha256,
  bytes: z
    .number()
    .int()
    .positive()
    .max(8 * 1024 * 1024),
  epsg: z.union([z.literal(4326), z.literal(7844), z.literal(7856)]),
  featureCount: z.number().int().positive().max(10_000),
  wardProperty: z.string().min(1),
  wards: z.array(z.strictObject({ id: identifier, name: z.string().trim().min(1) })).min(1),
  licence: z.literal("CC-BY-4.0"),
  licenceUrl: z.url(),
  licenceEvidenceUrl: z.url(),
  licenceEvidenceSha256: sha256,
  attribution: z.string().min(1),
  qualificationNote: z.string().min(1),
});
export const WardRegistrySchema = z
  .strictObject({
    formatVersion: z.literal(1),
    fixtureOnly: z.boolean(),
    referenceDate: date,
    qualificationDate: date,
    preciseSiteTypes: z
      .array(z.strictObject({ code: z.string().regex(/^[A-Z]+$/), name: z.string().min(1) }))
      .min(1),
    councils: z
      .array(
        z.strictObject({
          id: identifier,
          lgaCode: z.string().regex(/^lga[a-f0-9]+$/),
          lgaName: z.string().min(1),
          status: z.enum(["enabled", "undivided"]),
          effectiveFrom: date,
          authorityUrl: z.url(),
          adoptionUrl: z.url(),
          currencyUrl: z.url(),
          source: sourceSchema.nullable(),
        }),
      )
      .min(1),
  })
  .superRefine((registry, ctx) => {
    const fail = (message: string) => ctx.addIssue({ code: "custom", message });
    const unique = (values: string[]) => new Set(values).size === values.length;
    try {
      for (const value of [
        registry.referenceDate,
        registry.qualificationDate,
        ...registry.councils.map((c) => c.effectiveFrom),
      ])
        validateBoundaryDate(value);
    } catch {
      fail("Invalid ward qualification date");
    }
    if (!registry.councils.some((c) => c.status === "enabled"))
      fail("At least one council must have a qualified source");
    if (
      !unique(registry.councils.map((c) => c.id)) ||
      !unique(registry.councils.map((c) => c.lgaCode)) ||
      !unique(registry.councils.flatMap((c) => (c.source ? [c.source.file] : [])))
    )
      fail("Council identity, crosswalk and filenames must be unique");
    if (
      !unique(registry.preciseSiteTypes.map((t) => t.code)) ||
      !unique(registry.preciseSiteTypes.map((t) => t.name)) ||
      registry.preciseSiteTypes.some((t) => !preciseSiteCodes.has(t.code))
    )
      fail("Approximate or unknown geocode types cannot qualify for wards");
    for (const council of registry.councils) {
      if ((council.status === "enabled") !== (council.source !== null))
        fail("Council status and source disagree");
      if (council.effectiveFrom > registry.referenceDate)
        fail("Ward boundaries are not yet effective");
      if (
        council.source &&
        (!unique(council.source.wards.map((w) => w.id)) ||
          !unique(council.source.wards.map((w) => w.name)))
      )
        fail("Logical ward IDs and names must be unambiguous");
    }
  });
export type WardRegistry = z.infer<typeof WardRegistrySchema>;
export type WardCouncil = WardRegistry["councils"][number];
export const WardLockSchema = z
  .strictObject({
    formatVersion: z.literal(1),
    acquiredAt: z.iso.datetime(),
    identity: sha256,
    registry: WardRegistrySchema,
  })
  .superRefine((lock, ctx) => {
    if (lock.identity !== registryIdentity(lock.registry))
      ctx.addIssue({ code: "custom", message: "Ward registry checksum mismatch" });
  });
export type WardLock = z.infer<typeof WardLockSchema>;
export function registryIdentity(registry: WardRegistry): string {
  return createHash("sha256").update(JSON.stringify(registry)).digest("hex");
}
export async function readWardRegistry(fixtureOnly = false): Promise<WardRegistry> {
  return WardRegistrySchema.parse(
    JSON.parse(
      await readFile(
        join(root, fixtureOnly ? "fixtures/ward-sources/registry.json" : "config/nsw-wards.json"),
        "utf8",
      ),
    ),
  );
}

const position = z.tuple([z.number().finite(), z.number().finite()]);
const ring = z.array(position).min(4);
const polygon = z.array(ring).min(1);
const geometry = z.discriminatedUnion("type", [
  z.object({ type: z.literal("Polygon"), coordinates: polygon }),
  z.object({ type: z.literal("MultiPolygon"), coordinates: z.array(polygon).min(1) }),
]);
const collection = z.object({
  type: z.literal("FeatureCollection"),
  features: z
    .array(
      z.object({
        type: z.literal("Feature"),
        properties: z.record(z.string(), z.unknown()),
        geometry,
      }),
    )
    .min(1),
});
export function parseWardFeatures(data: Buffer, council: WardCouncil) {
  const source = council.source;
  if (
    !source ||
    data.length !== source.bytes ||
    createHash("sha256").update(data).digest("hex") !== source.sha256
  )
    throw new Error(`Ward source bytes changed: ${council.id}`);
  const parsed = collection.parse(JSON.parse(data.toString("utf8")));
  if (parsed.features.length !== source.featureCount)
    throw new Error(`Wrong ward feature count: ${council.id}`);
  const seen = new Set<string>();
  const features = parsed.features.map((feature) => {
    const ward = source.wards.find((w) => w.name === feature.properties[source.wardProperty]);
    if (!ward) throw new Error(`Unknown ward name: ${council.id}`);
    seen.add(ward.id);
    return { id: `${council.id}:${ward.id}`, name: ward.name, geometry: feature.geometry };
  });
  if (seen.size !== source.wards.length) throw new Error(`Missing logical wards: ${council.id}`);
  return features;
}

async function fetchBounded(source: NonNullable<WardCouncil["source"]>): Promise<Buffer> {
  for (let attempt = 0; attempt < 3; attempt++) {
    try {
      const response = await fetch(source.url, { signal: AbortSignal.timeout(30_000) });
      if (!response.ok || !response.body) throw new Error(`Ward download HTTP ${response.status}`);
      const chunks: Uint8Array[] = [];
      let size = 0;
      for await (const chunk of response.body) {
        size += chunk.length;
        if (size > source.bytes) throw new Error("Ward source exceeds approved byte length");
        chunks.push(chunk);
      }
      return Buffer.concat(chunks);
    } catch (error) {
      if (attempt === 2) throw error;
    }
  }
  throw new Error("Ward download failed");
}

/** New quarters require a reviewed registry update, even if the URL still works. */
export async function acquireWardSources(
  directory: string,
  referenceDate: string,
): Promise<WardLock> {
  await mkdir(directory, { recursive: true });
  await rm(join(directory, "ward-source-lock.json"), { force: true });
  const registry = await readWardRegistry();
  if (registry.referenceDate !== referenceDate || registry.fixtureOnly)
    throw new Error("Ward sources are not qualified for this boundary reference date");
  for (const council of registry.councils) {
    if (!council.source) continue;
    const data = await fetchBounded(council.source);
    parseWardFeatures(data, council);
    const path = join(directory, council.source.file);
    await writeFile(`${path}.partial`, data);
    await rename(`${path}.partial`, path);
  }
  const lock = WardLockSchema.parse({
    formatVersion: 1,
    acquiredAt: new Date().toISOString(),
    identity: registryIdentity(registry),
    registry,
  });
  await writeFile(join(directory, "ward-source-lock.json"), JSON.stringify(lock, null, 2) + "\n");
  return lock;
}

export async function loadWardLock(
  path: string,
  referenceDate: string,
  fixtureOnly = false,
): Promise<WardLock> {
  const lock = WardLockSchema.parse(JSON.parse(await readFile(path, "utf8")));
  const registry = await readWardRegistry(fixtureOnly);
  if (
    lock.registry.fixtureOnly !== fixtureOnly ||
    lock.registry.referenceDate !== referenceDate ||
    lock.identity !== registryIdentity(registry)
  )
    throw new Error("Ward source lock does not match the reviewed registry and boundary date");
  return lock;
}

/** TEMP tables cannot enter a cached pg_dump; every flatten session verifies and imports. */
export async function importWardSources(
  sql: postgres.ReservedSql,
  lock: WardLock,
  directory: string,
): Promise<void> {
  await sql.unsafe(await readFile(join(root, "sql/ward_sources_prep.sql"), "utf8")); // no cursor needed: DDL
  for (const { code } of lock.registry.preciseSiteTypes)
    for await (const batch of sql
      .unsafe("INSERT INTO tmp_ward_types VALUES ($1) RETURNING code", [code])
      .cursor(1))
      void batch;
  for (const council of lock.registry.councils) {
    for await (const batch of sql
      .unsafe("INSERT INTO tmp_ward_sources VALUES ($1,$2,$3,$4) RETURNING source_id", [
        council.lgaCode,
        council.lgaName,
        council.id,
        council.status,
      ])
      .cursor(1))
      void batch;
    if (!council.source) continue;
    const features = parseWardFeatures(
      await readFile(join(directory, council.source.file)),
      council,
    );
    for (const feature of features) {
      for await (const batch of sql
        .unsafe(
          `INSERT INTO tmp_ward_polygons VALUES ($1,$2,$3,
        ST_Multi(ST_Transform(ST_SetSRID(ST_GeomFromGeoJSON($4),$5),7844))) RETURNING ward_id`,
          [
            council.id,
            feature.id,
            feature.name,
            JSON.stringify(feature.geometry),
            council.source.epsg,
          ],
        )
        .cursor(1))
        void batch;
    }
  }
  for await (const batch of sql
    .unsafe(
      `SELECT ward_id FROM tmp_ward_polygons WHERE NOT ST_IsValid(geom)
    OR ST_IsEmpty(geom) OR NOT ST_CoveredBy(geom,ST_MakeEnvelope(96,-44,168,-9,7844))`,
    )
    .cursor(1))
    if (batch.length)
      throw new Error(`Invalid or out-of-bounds ward geometry: ${String(batch[0].ward_id)}`);
  const indexSql =
    "CREATE INDEX ON tmp_ward_polygons USING gist (geom); CREATE INDEX ON tmp_ward_polygons (source_id); ANALYZE tmp_ward_sources; ANALYZE tmp_ward_polygons; ANALYZE tmp_ward_types;";
  await sql.unsafe(indexSql); // no cursor needed: DDL
}

export async function wardContext(version: string): Promise<{ lock: WardLock; directory: string }> {
  const fixtureOnly = version === "2026.02";
  const path = fixtureOnly
    ? join(root, "fixtures/ward-sources/ward-source-lock.json")
    : (process.env.WARD_SOURCE_LOCK_PATH ??
      join(
        dirname(process.env.SOURCE_LOCK_PATH ?? "/sources/source-lock.json"),
        "ward-source-lock.json",
      ));
  const referenceDate = fixtureOnly
    ? "2026-02-28"
    : SourceLockSchema.parse(
        JSON.parse(
          await readFile(process.env.SOURCE_LOCK_PATH ?? "/sources/source-lock.json", "utf8"),
        ),
      ).boundaryReferenceDate;
  return { lock: await loadWardLock(path, referenceDate, fixtureOnly), directory: dirname(path) };
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  if (process.argv.includes("--check-date")) {
    const pinned = process.env.PINNED_SOURCE_LOCK
      ? SourceLockSchema.parse(JSON.parse(await readFile(process.env.PINNED_SOURCE_LOCK, "utf8")))
      : undefined;
    const date =
      pinned?.boundaryReferenceDate ??
      (process.env.BOUNDARY_REFERENCE_DATE ||
        quarterEnd(process.env.ADMIN_BDYS_VERSION || process.env.GNAF_VERSION || ""));
    const registry = await readWardRegistry();
    if (registry.fixtureOnly || registry.referenceDate !== date)
      throw new Error(
        `No qualified ward sources for ${date}; review config/nsw-wards.json before acquiring archives`,
      );
  } else {
    const directory = resolve(process.env.SOURCE_ARCHIVE_DIR ?? "sources");
    const sourceLock = SourceLockSchema.parse(
      JSON.parse(await readFile(join(directory, "source-lock.json"), "utf8")),
    );
    await acquireWardSources(directory, sourceLock.boundaryReferenceDate);
  }
}
