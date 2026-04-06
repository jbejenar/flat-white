/**
 * flat-white — NDJSON → Parquet converter.
 *
 * Reads an NDJSON file of AddressDocuments and writes a Parquet file
 * with the same data. Scalar fields become native Parquet columns;
 * complex nested fields (objects, arrays) are serialized as JSON strings
 * for maximum reader compatibility.
 */

import { createReadStream } from "node:fs";
import { createInterface } from "node:readline";
import { ParquetSchema, ParquetWriter } from "@dsnp/parquetjs";

export interface ParquetConvertOptions {
  /** Path to input NDJSON file */
  inputPath: string;
  /** Path for output .parquet file */
  outputPath: string;
}

/**
 * Parquet schema for AddressDocument.
 *
 * Scalar fields → native types.
 * Complex fields (geocode, allGeocodes, locality, street, boundaries,
 * aliases, secondaries) → UTF8 JSON strings.
 */
export const ADDRESS_PARQUET_SCHEMA = new ParquetSchema({
  _id: { type: "UTF8" },
  _version: { type: "UTF8" },
  addressLabel: { type: "UTF8" },
  addressLabelSearch: { type: "UTF8" },
  addressSiteName: { type: "UTF8", optional: true },
  buildingName: { type: "UTF8", optional: true },
  flatType: { type: "UTF8", optional: true },
  flatNumber: { type: "UTF8", optional: true },
  levelType: { type: "UTF8", optional: true },
  levelNumber: { type: "UTF8", optional: true },
  numberFirst: { type: "UTF8", optional: true },
  numberLast: { type: "UTF8", optional: true },
  lotNumber: { type: "UTF8", optional: true },
  streetName: { type: "UTF8" },
  streetType: { type: "UTF8", optional: true },
  streetSuffix: { type: "UTF8", optional: true },
  localityName: { type: "UTF8" },
  state: { type: "UTF8" },
  postcode: { type: "UTF8", optional: true },
  legalParcelId: { type: "UTF8", optional: true },
  confidence: { type: "INT32" },
  aliasPrincipal: { type: "UTF8" },
  primarySecondary: { type: "UTF8", optional: true },
  // Complex fields serialized as JSON strings
  geocode: { type: "UTF8", optional: true },
  allGeocodes: { type: "UTF8" },
  locality: { type: "UTF8" },
  street: { type: "UTF8" },
  boundaries: { type: "UTF8" },
  aliases: { type: "UTF8" },
  secondaries: { type: "UTF8" },
});

/**
 * Map an AddressDocument (parsed from NDJSON) to a flat Parquet row.
 * Null values are omitted so parquetjs treats them as null.
 */
export function toParquetRow(doc: Record<string, unknown>): Record<string, unknown> {
  const row: Record<string, unknown> = {
    _id: doc._id,
    _version: doc._version,
    addressLabel: doc.addressLabel,
    addressLabelSearch: doc.addressLabelSearch,
    streetName: doc.streetName,
    localityName: doc.localityName,
    state: doc.state,
    confidence: doc.confidence,
    aliasPrincipal: doc.aliasPrincipal,
    // Complex fields → JSON strings
    allGeocodes: JSON.stringify(doc.allGeocodes),
    locality: JSON.stringify(doc.locality),
    street: JSON.stringify(doc.street),
    boundaries: JSON.stringify(doc.boundaries),
    aliases: JSON.stringify(doc.aliases),
    secondaries: JSON.stringify(doc.secondaries),
  };

  // Nullable scalar fields — only include if non-null
  const nullableScalars = [
    "addressSiteName",
    "buildingName",
    "flatType",
    "flatNumber",
    "levelType",
    "levelNumber",
    "numberFirst",
    "numberLast",
    "lotNumber",
    "streetType",
    "streetSuffix",
    "postcode",
    "legalParcelId",
    "primarySecondary",
  ] as const;

  for (const field of nullableScalars) {
    if (doc[field] != null) {
      row[field] = doc[field];
    }
  }

  // Nullable complex field: geocode
  if (doc.geocode != null) {
    row.geocode = JSON.stringify(doc.geocode);
  }

  return row;
}

/**
 * Convert an NDJSON file to Parquet format.
 *
 * Streams the input line-by-line and writes rows to the Parquet file
 * using @dsnp/parquetjs. Memory usage is bounded by the Parquet
 * writer's internal row group buffering.
 */
export async function convertToParquet(options: ParquetConvertOptions): Promise<{ count: number }> {
  const { inputPath, outputPath } = options;

  const writer = await ParquetWriter.openFile(ADDRESS_PARQUET_SCHEMA, outputPath);
  let count = 0;

  const rl = createInterface({
    input: createReadStream(inputPath),
    crlfDelay: Infinity,
  });

  for await (const line of rl) {
    if (!line.trim()) continue;
    const doc = JSON.parse(line) as Record<string, unknown>;
    const row = toParquetRow(doc);
    await writer.appendRow(row);
    count++;
  }

  await writer.close();

  return { count };
}
