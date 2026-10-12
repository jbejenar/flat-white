/** Independent, bounded spatial checks against the locked council source bytes. */
import postgres from "postgres";
import { z } from "zod";
import { importWardSources, type WardLock } from "./ward-sources.js";

export interface WardPoint {
  sourceId: string;
  longitude: number;
  latitude: number;
}
export interface WardIntersection {
  matches: number;
  name: string | null;
}
export type WardLookup = (points: WardPoint[]) => Promise<WardIntersection[]>;
const intersectionSchema = z.object({
  ordinal: z.number().int().nonnegative(),
  matches: z.number().int().nonnegative(),
  name: z.string().nullable(),
});

export async function createWardLookup(
  lock: WardLock,
  directory: string,
  databaseUrl: string | undefined,
): Promise<{ lookup: WardLookup; close: () => Promise<void> }> {
  if (!databaseUrl)
    throw new Error("WARD_VERIFICATION_DATABASE_URL must identify a temporary PostGIS database");
  const connection = postgres(databaseUrl, { max: 1, max_lifetime: null, onnotice: () => {} });
  let sql: postgres.ReservedSql | undefined;
  try {
    sql = await connection.reserve();
    // A new session imports the original, checksum-verified polygons. No producer
    // tables, materialized assignments or per-address row flags are reused.
    await importWardSources(sql, lock, directory);
  } catch (error) {
    sql?.release();
    await connection.end({ timeout: 5 });
    throw error;
  }
  const session = sql;
  return {
    async lookup(points) {
      if (points.length > 1000) throw new Error("Ward verification batch exceeds 1000 points");
      const result: WardIntersection[] = [];
      for await (const batch of session
        .unsafe(
          `SELECT point.ordinal, count(DISTINCT ward.ward_id)::int AS matches,
                  min(ward.name) AS name
           FROM jsonb_to_recordset($1::text::jsonb)
             AS point(ordinal int, "sourceId" text, longitude double precision, latitude double precision)
           LEFT JOIN tmp_ward_polygons AS ward
             ON ward.source_id = point."sourceId"
             AND ST_Covers(ward.geom, ST_SetSRID(ST_MakePoint(point.longitude, point.latitude), 7844))
           GROUP BY point.ordinal ORDER BY point.ordinal`,
          [JSON.stringify(points.map((point, ordinal) => ({ ...point, ordinal })))],
        )
        .cursor(1000)) {
        for (const row of batch) {
          const checked = intersectionSchema.parse(row);
          if (checked.ordinal !== result.length) throw new Error("Ward lookup lost point order");
          result.push({ matches: checked.matches, name: checked.name });
        }
      }
      if (result.length !== points.length) throw new Error("Ward lookup lost address points");
      return result;
    },
    async close() {
      session.release();
      await connection.end({ timeout: 5 });
    },
  };
}
