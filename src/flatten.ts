/**
 * flat-white — Streaming Postgres → NDJSON flattener.
 *
 * Reads address rows from Postgres via the master flatten SQL,
 * composes AddressDocument objects, Zod-validates each one,
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
import { AddressDocumentSchema } from "./schema.js";
import type { AddressDocument } from "./schema.js";

const __dirname = dirname(fileURLToPath(import.meta.url));
const SQL_PATH = resolve(__dirname, "..", "sql", "address_full.sql");
const PREP_SQL_PATH = resolve(__dirname, "..", "sql", "address_full_prep.sql");
const MAIN_SQL_PATH = resolve(__dirname, "..", "sql", "address_full_main.sql");

export interface FlattenOptions {
  /** Postgres connection URL */
  connectionString: string;
  /** Output file path (writes NDJSON) */
  outputPath: string;
  /** G-NAF data version (e.g. "2026.02") */
  version: string;
  /**
   * Pre-materialize aggregation CTEs as temp tables before streaming.
   * Required for production-scale runs (>10k rows). The CTE-based query
   * in address_full.sql is fine for fixtures but too slow when cursored
   * over millions of rows.
   */
  materialize?: boolean;
}

function mapPrimarySecondary(value: unknown): "PRIMARY" | "SECONDARY" | null {
  if (value === "P" || value === "PRIMARY") return "PRIMARY";
  if (value === "S" || value === "SECONDARY") return "SECONDARY";
  return null;
}

/**
 * Compose an AddressDocument from a flat SQL row.
 * Maps column names to the document schema fields.
 */
export function composeDocument(row: Record<string, unknown>, version: string): AddressDocument {
  const bestGeocode = row.best_geocode as Record<string, unknown> | null;
  const allGeocodes = row.all_geocodes as Array<Record<string, unknown>> | null;

  // Build addressLabelSearch by expanding abbreviations
  const searchLabel = composeSearchLabel(row);

  const doc: AddressDocument = {
    _id: row._id as string,
    _version: version,
    addressLabel: row.address_label as string,
    addressLabelSearch: searchLabel,
    addressSiteName: (row.address_site_name as string) ?? null,
    buildingName: (row.building_name as string) ?? null,
    flatType: (row.flat_type_name as string) ?? null,
    flatNumber: (row.flat_number_composed as string) ?? null,
    levelType: (row.level_type_name as string) ?? null,
    levelNumber: (row.level_number_composed as string) ?? null,
    numberFirst: (row.number_first as string) ?? null,
    numberLast: (row.number_last as string) ?? null,
    lotNumber: (row.lot_number as string) ?? null,
    streetName: row.street_name as string,
    streetType: (row.street_type_name as string) ?? null,
    streetSuffix: (row.street_suffix_code as string) ?? null,
    localityName: row.locality_name as string,
    state: row.state as string,
    postcode: (row.postcode as string) ?? null,
    legalParcelId: (row.legal_parcel_id as string) ?? null,
    confidence: Number(row.confidence),
    // P0 scope: query only joins address_principals, so all rows are PRINCIPAL.
    // Alias addresses would require a separate join on address_aliases.
    aliasPrincipal: "PRINCIPAL",
    primarySecondary: mapPrimarySecondary(row.primary_secondary),
    geocode: bestGeocode
      ? {
          latitude: Number(bestGeocode.latitude),
          longitude: Number(bestGeocode.longitude),
          type: bestGeocode.type as string,
          reliability: Number(bestGeocode.reliability),
        }
      : null,
    allGeocodes: allGeocodes
      ? allGeocodes.map((g) => ({
          lat: Number(g.lat),
          lng: Number(g.lng),
          type: g.type as string,
          reliability: Number(g.reliability),
        }))
      : [],
    locality: {
      pid: row.locality_pid as string,
      class: (row.locality_class_name as string) ?? "UNKNOWN",
      neighbours: row.locality_neighbours as string[],
      aliases: row.locality_aliases as string[],
    },
    street: {
      pid: row.street_locality_pid as string,
      class: (row.street_class_name as string) ?? "UNKNOWN",
      aliases: row.street_aliases as string[],
    },
    boundaries: composeBoundaries(row),
    aliases: row.address_aliases as Array<{ pid: string; label: string; type: string }>,
    secondaries: row.address_secondaries as Array<{ pid: string; label: string }>,
  };

  return doc;
}

/**
 * Compose the search-optimised address label.
 * Expands abbreviations: street type (AV → AVENUE), flat type, level type.
 */
export function composeSearchLabel(row: Record<string, unknown>): string {
  const parts: string[] = [];

  // Flat type + number (use composed number from raw address_detail fields)
  const flatType = row.flat_type_name as string | null;
  const flatNumber = row.flat_number_composed as string | null;
  if (flatType && flatNumber) {
    parts.push(`${flatType} ${flatNumber}`);
  } else if (flatNumber) {
    parts.push(flatNumber);
  }

  // Level type + number (use composed number from raw address_detail fields)
  const levelType = row.level_type_name as string | null;
  const levelNumber = row.level_number_composed as string | null;
  if (levelType && levelNumber) {
    parts.push(`${levelType} ${levelNumber}`);
  } else if (levelNumber) {
    parts.push(`LEVEL ${levelNumber}`);
  }

  // Street number
  const numberFirst = row.number_first as string | null;
  const numberLast = row.number_last as string | null;
  if (numberFirst && numberLast) {
    parts.push(`${numberFirst}-${numberLast}`);
  } else if (numberFirst) {
    parts.push(numberFirst);
  }

  // Lot number (if no street number)
  const lotNumber = row.lot_number as string | null;
  if (lotNumber && !numberFirst) {
    parts.push(`LOT ${lotNumber}`);
  }

  // Street name + expanded type + suffix
  const streetName = row.street_name as string;
  const streetType = row.street_type_name as string | null;
  const streetSuffix = row.street_suffix_code as string | null;
  const streetParts = [streetName, streetType, streetSuffix].filter(Boolean).join(" ");
  parts.push(streetParts);

  // Locality, state, postcode
  const locality = row.locality_name as string;
  const state = row.state as string;
  const postcode = row.postcode as string | null;

  const locationParts = [locality, state, postcode].filter(Boolean).join(" ");
  parts.push(locationParts);

  return parts.join(" ");
}

/**
 * Compose the boundaries nested object from SQL row columns.
 */
export function composeBoundaries(row: Record<string, unknown>) {
  const lgaName = row.lga_name as string | null;
  const lgaPid = row.lga_pid as string | null;
  const wardName = row.ward_name as string | null;
  const stateElectorateName = row.state_electorate_name as string | null;
  const ceElectorateName = row.commonwealth_electorate_name as string | null;
  const mb2021Code = row.mb_2021_code as string | number | null;
  const mbCategory = row.mesh_block_category as string | null;
  const sa1 = row.sa1_21code as string | null;
  const sa2Code = row.sa2_21code as string | null;
  const sa2Name = row.sa2_21name as string | null;
  const sa3Code = row.sa3_21code as string | null;
  const sa3Name = row.sa3_21name as string | null;
  const sa4Code = row.sa4_21code as string | null;
  const sa4Name = row.sa4_21name as string | null;
  const gccsaCode = row.gcc_21code as string | null;
  const gccsaName = row.gcc_21name as string | null;

  return {
    lga: lgaName && lgaPid ? { name: lgaName, code: lgaPid } : null,
    ward: wardName ? { name: wardName } : null,
    stateElectorate: stateElectorateName ? { name: stateElectorateName } : null,
    commonwealthElectorate: ceElectorateName ? { name: ceElectorateName } : null,
    meshBlock:
      mb2021Code != null && mbCategory ? { code: String(mb2021Code), category: mbCategory } : null,
    sa1: sa1 ?? null,
    sa2: sa2Code && sa2Name ? { code: sa2Code, name: sa2Name } : null,
    sa3: sa3Code && sa3Name ? { code: sa3Code, name: sa3Name } : null,
    sa4: sa4Code && sa4Name ? { code: sa4Code, name: sa4Name } : null,
    gccsa: gccsaCode && gccsaName ? { code: gccsaCode, name: gccsaName } : null,
  };
}

/**
 * Run the flatten pipeline: read from Postgres, compose documents, write NDJSON.
 */
export async function flatten(options: FlattenOptions): Promise<{ count: number; errors: number }> {
  const { connectionString, outputPath, version, materialize } = options;

  const sql = postgres(connectionString, {
    max: 1,
    transform: {
      // Column names from SQL are already snake_case; keep them as-is
      undefined: null,
    },
  });

  let flattenSql: string;

  if (materialize) {
    // Production mode: pre-materialize aggregations as temp tables, then stream the simple join
    const prepSql = readFileSync(PREP_SQL_PATH, "utf-8");
    console.log("[flatten] Materializing aggregation tables...");
    await sql.unsafe(prepSql); // DDL: creates temp tables, no cursor needed
    console.log("[flatten] Aggregation tables ready. Starting cursor stream...");
    flattenSql = readFileSync(MAIN_SQL_PATH, "utf-8");
  } else {
    // Fixture mode: use the CTE-based query (fine for small datasets)
    flattenSql = readFileSync(SQL_PATH, "utf-8");
  }

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
          const doc = composeDocument(row, version);
          const result = AddressDocumentSchema.safeParse(doc);
          if (result.success) {
            count++;
            callback(null, JSON.stringify(result.data) + "\n");
          } else {
            errors++;
            const pid = row._id as string;
            console.error(`[flatten] Validation failed for ${pid}: ${result.error.message}`);
            callback();
          }
        } catch (err) {
          errors++;
          const pid = (row._id as string) ?? "unknown";
          console.error(`[flatten] Error composing ${pid}:`, err);
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

/**
 * CLI entry point for fixture-only builds.
 */
async function main() {
  const connectionString =
    process.env.DATABASE_URL ?? "postgres://postgres:postgres@localhost:5432/gnaf";
  const version = process.env.GNAF_VERSION ?? "2026.02";
  const localityOnly = process.argv.includes("--locality-only");

  if (localityOnly) {
    const outputPath =
      process.argv.find(
        (a) => !a.startsWith("-") && a !== process.argv[0] && a !== process.argv[1],
      ) ?? "output/localities.ndjson";
    const { flattenLocalities } = await import("./flatten-localities.js");

    console.log(`[flatten] Mode: locality-only`);
    console.log(`[flatten] Connecting to ${connectionString}`);
    console.log(`[flatten] Output: ${outputPath}`);
    console.log(`[flatten] Version: ${version}`);

    const { count, errors } = await flattenLocalities({ connectionString, outputPath, version });

    console.log(`[flatten] Done: ${count} locality documents written, ${errors} errors`);

    if (errors > 0) {
      process.exit(3);
    }
    return;
  }

  const materialize = process.argv.includes("--materialize");
  const outputPath =
    process.argv.find(
      (a) => !a.startsWith("-") && a !== process.argv[0] && a !== process.argv[1],
    ) ?? "output/fixture.ndjson";

  console.log(`[flatten] Connecting to ${connectionString}`);
  console.log(`[flatten] Output: ${outputPath}`);
  console.log(`[flatten] Version: ${version}`);

  const { count, errors } = await flatten({ connectionString, outputPath, version, materialize });

  console.log(`[flatten] Done: ${count} documents written, ${errors} errors`);

  if (errors > 0) {
    process.exit(3);
  }
}

// Run if invoked directly (node dist/flatten.js)
const thisFile = fileURLToPath(import.meta.url);
const entryFile = process.argv[1] ? resolve(process.argv[1]) : "";
if (thisFile === entryFile || thisFile === entryFile.replace(/\.ts$/, ".js")) {
  main().catch((err) => {
    console.error("[flatten] Fatal:", err);
    process.exit(3);
  });
}
