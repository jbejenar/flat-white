/**
 * flat-white — Streaming Postgres → NDJSON locality flattener.
 *
 * Reads locality rows from Postgres via the locality flatten SQL,
 * composes LocalityDocument objects, Zod-validates each one,
 * and writes line-delimited JSON to the output stream.
 *
 * Memory-safe: cursor-based streaming keeps RSS under 500MB
 * regardless of dataset size.
 */

import { createWriteStream, readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { pipeline } from "node:stream/promises";
import { Readable, Transform } from "node:stream";
import postgres from "postgres";
import { LocalityDocumentSchema } from "./schema.js";
import type { LocalityDocument } from "./schema.js";

const __dirname = dirname(fileURLToPath(import.meta.url));
const SQL_PATH = resolve(__dirname, "..", "sql", "locality_full.sql");

export interface FlattenLocalitiesOptions {
  /** Postgres connection URL */
  connectionString: string;
  /** Output file path (writes NDJSON) */
  outputPath: string;
  /** G-NAF data version (e.g. "2026.02") */
  version: string;
}

/**
 * Compose a LocalityDocument from a flat SQL row.
 */
export function composeLocalityDocument(
  row: Record<string, unknown>,
  version: string,
): LocalityDocument {
  return {
    _id: row.locality_pid as string,
    _version: version,
    localityName: row.locality_name as string,
    state: row.state as string,
    postcode: (row.postcode as string) ?? null,
    class: (row.locality_class_name as string) ?? "UNKNOWN",
    neighbours: row.locality_neighbours as string[],
    aliases: row.locality_aliases as string[],
    latitude: row.latitude != null ? Number(row.latitude) : null,
    longitude: row.longitude != null ? Number(row.longitude) : null,
  };
}

/**
 * Run the locality flatten pipeline: read from Postgres, compose documents, write NDJSON.
 */
export async function flattenLocalities(
  options: FlattenLocalitiesOptions,
): Promise<{ count: number; errors: number }> {
  const { connectionString, outputPath, version } = options;

  const sql = postgres(connectionString, {
    max: 1,
    transform: {
      undefined: null,
    },
  });

  const flattenSql = readFileSync(SQL_PATH, "utf-8");
  let count = 0;
  let errors = 0;

  try {
    const cursor = sql.unsafe(flattenSql).cursor(500);

    const source = Readable.from(
      (async function* () {
        for await (const batch of cursor) {
          for (const row of batch) {
            yield row;
          }
        }
      })(),
    );

    const compose = new Transform({
      objectMode: true,
      transform(row: Record<string, unknown>, _encoding, callback) {
        try {
          const doc = composeLocalityDocument(row, version);
          const result = LocalityDocumentSchema.safeParse(doc);
          if (result.success) {
            count++;
            callback(null, JSON.stringify(result.data) + "\n");
          } else {
            errors++;
            const pid = row.locality_pid as string;
            console.error(
              `[flatten-localities] Validation failed for ${pid}: ${result.error.message}`,
            );
            callback();
          }
        } catch (err) {
          errors++;
          const pid = (row.locality_pid as string) ?? "unknown";
          console.error(`[flatten-localities] Error composing ${pid}:`, err);
          callback();
        }
      },
    });

    const output = createWriteStream(outputPath);

    await pipeline(source, compose, output);
  } finally {
    await sql.end();
  }

  return { count, errors };
}
