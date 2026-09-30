/** Acquire source bytes once; all state jobs verify and consume the same lock. */
import { createReadStream } from "node:fs";
import { mkdir, readFile, writeFile, rename, rm, stat, readdir } from "node:fs/promises";
import { createHash } from "node:crypto";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { z } from "zod";
import postgres from "postgres";
import {
  downloadFile,
  extractZip,
  isExtractionComplete,
  resolveDownloadDataSources,
  discoverDataSources,
} from "./download.js";

const run = promisify(execFile);
const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const quarter = z
  .string()
  .regex(/^\d{4}\.(02|05|08|11)$/)
  .refine((value) => value >= "2026.08", "ASGS 2026 requires August 2026 or newer");
const sha = z.string().regex(/^[a-f0-9]{64}$/);
const directory = z.string().regex(/^[A-Za-z0-9][A-Za-z0-9 _-]*$/);
const relativePath = z
  .string()
  .min(1)
  .refine(
    (value) =>
      !value.startsWith("/") &&
      !value.includes("\\") &&
      !value.includes(":") &&
      !value.split("/").includes(".."),
    "Unsafe archive path",
  );
const inventorySchema = z
  .array(
    z.object({
      path: relativePath,
      bytes: z.number().int().nonnegative(),
      crc32: z.number().int().nonnegative(),
    }),
  )
  .min(1)
  .max(100_000);
const sourceSchema = z.object({
  kind: z.enum(["gnaf", "admin"]),
  name: z.string(),
  url: z.url(),
  resourceId: z.string().nullable(),
  edition: z.string(),
  archive: z.enum(["gnaf.zip", "admin.zip"]),
  bytes: z.number().int().positive(),
  sha256: sha,
  extractedDir: directory,
  sentinelPaths: z.array(z.union([relativePath, z.array(relativePath).min(1)])).min(1),
  inventory: inventorySchema,
});
export const SourceLockSchema = z
  .object({
    formatVersion: z.literal(1),
    gnafVersion: quarter,
    adminVersion: z.union([quarter, z.literal("manual")]),
    boundaryReferenceDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
    acquiredAt: z.iso.datetime(),
    acquiredWith: z.object({
      loaderCommit: z.string().regex(/^[a-f0-9]{40}$/),
      preparationFingerprint: sha,
      node: z.string(),
    }),
    sources: z.array(sourceSchema).length(2),
  })
  .superRefine((lock, ctx) => {
    if (
      lock.sources[0].kind !== "gnaf" ||
      lock.sources[1].kind !== "admin" ||
      lock.sources[0].archive !== "gnaf.zip" ||
      lock.sources[1].archive !== "admin.zip" ||
      lock.sources[0].edition !== lock.gnafVersion ||
      lock.sources[1].edition !== lock.adminVersion ||
      lock.sources[0].extractedDir === lock.sources[1].extractedDir
    ) {
      ctx.addIssue({
        code: "custom",
        message: "Source lock editions, ordering or extraction destinations disagree",
      });
    }
    try {
      validateBoundaryDate(lock.boundaryReferenceDate);
      if (
        lock.adminVersion !== "manual" &&
        lock.boundaryReferenceDate !== quarterEnd(lock.adminVersion)
      )
        throw new Error("Wrong package reference date");
    } catch {
      ctx.addIssue({ code: "custom", message: "Invalid administrative package reference date" });
    }
  });
export type SourceLock = z.infer<typeof SourceLockSchema>;

function canonical(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(canonical);
  if (value !== null && typeof value === "object")
    return Object.fromEntries(
      Object.entries(value)
        .sort(([a], [b]) => (a < b ? -1 : a > b ? 1 : 0))
        .map(([key, item]) => [key, canonical(item)]),
    );
  return value;
}

export function sourceIdentity(lock: SourceLock): string {
  const { formatVersion, gnafVersion, adminVersion, boundaryReferenceDate, sources } = lock;
  return createHash("sha256")
    .update(
      JSON.stringify(
        canonical({ formatVersion, gnafVersion, adminVersion, boundaryReferenceDate, sources }),
      ),
    )
    .digest("hex");
}

async function loaderFingerprint(): Promise<string> {
  const hash = createHash("sha256");
  async function walk(directory: string, prefix: string) {
    const entries = await readdir(directory, { withFileTypes: true });
    for (const entry of entries.sort((a, b) => (a.name < b.name ? -1 : 1))) {
      if (entry.name.startsWith(".") || ["__pycache__", "tests"].includes(entry.name)) continue;
      const path = join(directory, entry.name);
      const relative = prefix + entry.name;
      if (entry.isDirectory()) await walk(path, relative + "/");
      else if (/\.(py|sql)$/.test(entry.name))
        hash.update(relative + "\0" + (await sha256File(path)) + "\0");
    }
  }
  await walk(join(root, "gnaf-loader"), "");
  return hash.digest("hex");
}

export async function databaseSourceProvenance(options: {
  lockPath: string;
  connectionString: string;
  states: string[];
  create?: boolean;
}): Promise<void> {
  const lock = await readSourceLock(options.lockPath);
  const context = {
    sourceIdentity: sourceIdentity(lock),
    boundaryReferenceDate: lock.boundaryReferenceDate,
    loaderFingerprint: await loaderFingerprint(),
    states: [...new Set(options.states)].sort(),
  };
  const sql = postgres(options.connectionString, { max: 1 });
  const table = `gnaf_${lock.gnafVersion.replace(".", "")}.flat_white_source_attestation`;
  try {
    if (options.create) {
      // DDL and a single bounded metadata row; address queries remain cursored.
      await sql.begin(async (transaction) => {
        await transaction`CREATE TABLE IF NOT EXISTS ${transaction(table)} (singleton boolean PRIMARY KEY CHECK (singleton), context jsonb NOT NULL)`;
        await transaction`INSERT INTO ${transaction(table)} VALUES (true, ${transaction.json(context)}) ON CONFLICT (singleton) DO UPDATE SET context = EXCLUDED.context`;
      });
    } else {
      let found = false;
      for await (const rows of sql`SELECT context FROM ${sql(table)} WHERE singleton`.cursor(1)) {
        for (const row of rows) {
          found = true;
          if (JSON.stringify(canonical(row.context)) !== JSON.stringify(canonical(context)))
            throw new Error(
              "Loaded database does not match the locked sources, selected states or loader preparation",
            );
        }
      }
      if (!found)
        throw new Error("Database has no source attestation; rebuild from the locked archives");
    }
  } finally {
    await sql.end();
  }
}

export function validateBoundaryDate(value: string): string {
  if (
    !/^\d{4}-\d{2}-\d{2}$/.test(value) ||
    new Date(value + "T00:00:00Z").toISOString().slice(0, 10) !== value
  )
    throw new Error("Invalid boundary reference date");
  return value;
}

export function quarterEnd(version: string): string {
  if (!/^\d{4}\.(02|05|08|11)$/.test(version)) throw new Error("Expected a source quarter");
  const [year, month] = version.split(".").map(Number);
  return new Date(Date.UTC(year, month, 0)).toISOString().slice(0, 10);
}

export async function sha256File(path: string): Promise<string> {
  const hash = createHash("sha256");
  for await (const chunk of createReadStream(path)) hash.update(chunk);
  return hash.digest("hex");
}

export async function readSourceLock(path: string): Promise<SourceLock> {
  return SourceLockSchema.parse(JSON.parse(await readFile(path, "utf8")));
}

async function inventory(path: string) {
  const { stdout } = await run("python3", [join(root, "scripts/zip_inventory.py"), path], {
    maxBuffer: 16 * 1024 * 1024,
  });
  return inventorySchema.parse(JSON.parse(stdout));
}

export async function acquireSources(options: {
  version: string;
  adminVersion: string;
  directory: string;
  pinnedLock?: string;
  boundaryDate?: string;
}): Promise<SourceLock> {
  quarter.parse(options.version);
  const pinned = options.pinnedLock ? await readSourceLock(options.pinnedLock) : undefined;
  if (
    pinned &&
    (pinned.gnafVersion !== options.version || pinned.adminVersion !== options.adminVersion)
  )
    throw new Error("Pinned source lock has different editions");
  const date =
    pinned?.boundaryReferenceDate ??
    (options.adminVersion === "manual"
      ? validateBoundaryDate(options.boundaryDate ?? "")
      : quarterEnd(quarter.parse(options.adminVersion)));
  if (options.boundaryDate && options.boundaryDate !== date)
    throw new Error("Boundary date disagrees with the pinned lock or package month-end");
  const sources =
    pinned?.sources ??
    (options.adminVersion === "manual"
      ? await resolveDownloadDataSources(options.version)
      : await discoverDataSources(options.version, fetch, options.adminVersion));
  await mkdir(options.directory, { recursive: true });
  // A failed reacquisition must not leave a lock describing a mixed archive set.
  await rm(join(options.directory, "source-lock.json"), { force: true });
  const locked: SourceLock["sources"] = [];
  for (const [index, source] of sources.entries()) {
    const kind = index === 0 ? "gnaf" : "admin";
    const archive = `${kind}.zip` as const;
    const path = join(options.directory, archive);
    const partial = path + ".partial";
    try {
      await downloadFile(source.url, partial, source.name);
      const checksum = await sha256File(partial);
      const bytes = (await stat(partial)).size;
      const members = await inventory(partial);
      const expected = pinned?.sources[index];
      if (
        expected &&
        (checksum !== expected.sha256 ||
          bytes !== expected.bytes ||
          JSON.stringify(members) !== JSON.stringify(expected.inventory))
      ) {
        throw new Error(`Source bytes changed for locked ${kind} archive`);
      }
      // Validate compressed payloads too, before distributing a partial archive.
      await run("unzip", ["-tqq", partial], { maxBuffer: 65536 });
      await rename(partial, path);
      locked.push({
        ...source,
        kind,
        archive,
        edition: index === 0 ? options.version : options.adminVersion,
        resourceId: source.url.match(/\/resource\/([^/]+)\//)?.[1] ?? null,
        sha256: checksum,
        bytes,
        inventory: members,
      });
    } finally {
      await rm(partial, { force: true });
    }
  }
  const lock =
    pinned ??
    SourceLockSchema.parse({
      formatVersion: 1,
      gnafVersion: options.version,
      adminVersion: options.adminVersion,
      boundaryReferenceDate: date,
      acquiredAt: new Date().toISOString(),
      sources: locked,
      acquiredWith: {
        loaderCommit: (
          await run("git", ["-C", join(root, "gnaf-loader"), "rev-parse", "HEAD"])
        ).stdout.trim(),
        preparationFingerprint: (
          await run("python3", [join(root, "scripts/cache_fingerprint.py")])
        ).stdout.trim(),
        node: process.version,
      },
    });
  await writeFile(
    join(options.directory, "source-lock.json"),
    JSON.stringify(lock, null, 2) + "\n",
  );
  return lock;
}

export async function extractLockedSources(
  lockPath: string,
  archiveDirectory: string,
  outputDirectory: string,
): Promise<void> {
  const lock = await readSourceLock(lockPath);
  // Verify both inputs before replacing either extracted dataset.
  for (const source of lock.sources) {
    const path = join(archiveDirectory, source.archive);
    if ((await stat(path)).size !== source.bytes || (await sha256File(path)) !== source.sha256)
      throw new Error(`Source checksum mismatch: ${source.kind}`);
    if (JSON.stringify(await inventory(path)) !== JSON.stringify(source.inventory))
      throw new Error(`Source inventory mismatch: ${source.kind}`);
  }
  await mkdir(outputDirectory, { recursive: true });
  // Never retain a valid stamp if either replacement fails part-way through.
  await rm(join(outputDirectory, ".flat-white-source-identity"), { force: true });
  for (const source of lock.sources) {
    const temporary = join(outputDirectory, source.extractedDir + ".extracting");
    await rm(temporary, { recursive: true, force: true });
    try {
      await extractZip(join(archiveDirectory, source.archive), temporary);
      const wrapped = join(temporary, source.extractedDir);
      const extracted = await stat(wrapped).then(
        () => wrapped,
        () => temporary,
      );
      if (!isExtractionComplete(extracted, source.sentinelPaths))
        throw new Error(`Incomplete locked extraction: ${source.kind}`);
      const destination = join(outputDirectory, source.extractedDir);
      await rm(destination, { recursive: true, force: true });
      await rename(extracted, destination);
    } finally {
      await rm(temporary, { recursive: true, force: true });
    }
  }
  await writeFile(
    join(outputDirectory, ".flat-white-source-identity"),
    sourceIdentity(lock) + "\n",
  );
}

async function main() {
  const command = process.argv[2];
  const archiveDirectory = resolve(process.env.SOURCE_ARCHIVE_DIR ?? "sources");
  if (command === "acquire") {
    const lock = await acquireSources({
      version: process.env.GNAF_VERSION ?? "",
      adminVersion: process.env.ADMIN_BDYS_VERSION ?? process.env.GNAF_VERSION ?? "",
      directory: archiveDirectory,
      pinnedLock: process.env.PINNED_SOURCE_LOCK,
      boundaryDate: process.env.BOUNDARY_REFERENCE_DATE,
    });
    console.log(`source_identity=${sourceIdentity(lock)}`);
  } else if (command === "verify-db") {
    await databaseSourceProvenance({
      lockPath: process.env.SOURCE_LOCK_PATH ?? join(archiveDirectory, "source-lock.json"),
      connectionString: process.env.DATABASE_URL ?? "",
      states: (process.env.STATES?.trim() || "ACT NSW NT OT QLD SA TAS VIC WA").split(/\s+/),
    });
  } else if (command === "extract") {
    await extractLockedSources(
      process.env.SOURCE_LOCK_PATH ?? join(archiveDirectory, "source-lock.json"),
      archiveDirectory,
      resolve(process.env.DATA_DIR ?? "data"),
    );
  } else if (command === "inspect") {
    const lock = await readSourceLock(
      process.env.SOURCE_LOCK_PATH ?? join(archiveDirectory, "source-lock.json"),
    );
    if (process.env.GNAF_VERSION && lock.gnafVersion !== process.env.GNAF_VERSION)
      throw new Error("Source lock and GNAF_VERSION disagree");
    if (
      process.env.ADMIN_BDYS_VERSION?.trim() &&
      lock.adminVersion !== process.env.ADMIN_BDYS_VERSION.trim()
    )
      throw new Error("Source lock and ADMIN_BDYS_VERSION disagree");
    console.log(lock.boundaryReferenceDate);
  } else throw new Error("Expected acquire, extract, inspect or verify-db");
}
if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main().catch((error: unknown) => {
    console.error(error);
    process.exitCode = 1;
  });
}
