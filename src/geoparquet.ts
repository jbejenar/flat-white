/**
 * flat-white — NDJSON → Geoparquet converter.
 *
 * Extends the standard Parquet output (src/parquet.ts) with a WKB-encoded
 * POINT geometry column and Geoparquet v1.1.0 file-level metadata.
 * Spatial tools (QGIS, GeoPandas, DuckDB Spatial) can read the output
 * with native geometry support.
 */

import { createReadStream } from "node:fs";
import { createInterface } from "node:readline";
import { ParquetSchema, ParquetWriter } from "@dsnp/parquetjs";
import { toParquetRow } from "./parquet.js";

export interface GeoparquetConvertOptions {
  /** Path to input NDJSON file */
  inputPath: string;
  /** Path for output .geoparquet file */
  outputPath: string;
}

/**
 * Encode a WGS 84 POINT as WKB (Well-Known Binary).
 *
 * Layout (21 bytes, little-endian):
 *   [0]    byte order: 0x01 (LE)
 *   [1-4]  geometry type: 1 (Point)
 *   [5-12] X (longitude) as float64
 *   [13-20] Y (latitude) as float64
 */
export function encodeWKBPoint(longitude: number, latitude: number): Buffer {
  const buf = Buffer.alloc(21);
  buf.writeUInt8(1, 0);
  buf.writeUInt32LE(1, 1);
  buf.writeDoubleLE(longitude, 5);
  buf.writeDoubleLE(latitude, 13);
  return buf;
}

/**
 * Parquet schema for Geoparquet output.
 *
 * Same columns as ADDRESS_PARQUET_SCHEMA plus a `geometry` BYTE_ARRAY
 * column for WKB-encoded POINT geometries.
 */
const GEOPARQUET_SCHEMA = new ParquetSchema({
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
  // Geometry column — WKB-encoded POINT
  geometry: { type: "BYTE_ARRAY", optional: true },
});

/**
 * Build the Geoparquet "geo" metadata object per the v1.1.0 spec.
 * https://geoparquet.org/releases/v1.1.0/
 */
function buildGeoMetadata(bbox: [number, number, number, number] | null): Record<string, unknown> {
  const columnMeta: Record<string, unknown> = {
    encoding: "WKB",
    geometry_types: ["Point"],
    crs: {
      $schema: "https://proj.org/schemas/v0.7/projjson.schema.json",
      type: "GeographicCRS",
      name: "WGS 84",
      datum: {
        type: "GeodeticReferenceFrame",
        name: "World Geodetic System 1984",
        ellipsoid: {
          name: "WGS 84",
          semi_major_axis: 6378137,
          inverse_flattening: 298.257223563,
        },
      },
      coordinate_system: {
        subtype: "ellipsoidal",
        axis: [
          {
            name: "Geodetic latitude",
            abbreviation: "Lat",
            direction: "north",
            unit: "degree",
          },
          {
            name: "Geodetic longitude",
            abbreviation: "Lon",
            direction: "east",
            unit: "degree",
          },
        ],
      },
      id: { authority: "EPSG", code: 4326 },
    },
  };

  if (bbox) {
    columnMeta.bbox = bbox;
  }

  return {
    version: "1.1.0",
    primary_column: "geometry",
    columns: {
      geometry: columnMeta,
    },
  };
}

/**
 * Convert an NDJSON file to Geoparquet format.
 *
 * Streams the input line-by-line, writes rows with a WKB POINT geometry
 * column, and sets Geoparquet v1.1.0 file-level metadata.
 */
export async function convertToGeoparquet(
  options: GeoparquetConvertOptions,
): Promise<{ count: number }> {
  const { inputPath, outputPath } = options;

  const writer = await ParquetWriter.openFile(GEOPARQUET_SCHEMA, outputPath);
  let count = 0;

  // Track bounding box
  let minLon = Infinity;
  let minLat = Infinity;
  let maxLon = -Infinity;
  let maxLat = -Infinity;
  let hasGeometry = false;

  const rl = createInterface({
    input: createReadStream(inputPath),
    crlfDelay: Infinity,
  });

  for await (const line of rl) {
    if (!line.trim()) continue;
    const doc = JSON.parse(line) as Record<string, unknown>;
    const row = toParquetRow(doc);

    // Add geometry column from geocode coordinates
    const geocode = doc.geocode as { latitude: number; longitude: number } | null;
    if (geocode != null && geocode.latitude != null && geocode.longitude != null) {
      row.geometry = encodeWKBPoint(geocode.longitude, geocode.latitude);

      // Update bbox
      if (geocode.longitude < minLon) minLon = geocode.longitude;
      if (geocode.longitude > maxLon) maxLon = geocode.longitude;
      if (geocode.latitude < minLat) minLat = geocode.latitude;
      if (geocode.latitude > maxLat) maxLat = geocode.latitude;
      hasGeometry = true;
    }
    // If geocode is null, geometry is omitted → parquetjs treats as null

    await writer.appendRow(row);
    count++;
  }

  // Set Geoparquet metadata before closing
  const bbox: [number, number, number, number] | null = hasGeometry
    ? [minLon, minLat, maxLon, maxLat]
    : null;
  writer.setMetadata("geo", JSON.stringify(buildGeoMetadata(bbox)));

  await writer.close();

  return { count };
}
