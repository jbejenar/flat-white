/**
 * Unit tests for geoparquet.ts — NDJSON → Geoparquet conversion.
 */

import { describe, it, expect, afterAll } from "vitest";
import { writeFileSync, unlinkSync, existsSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { randomBytes } from "node:crypto";
import { ParquetReader } from "@dsnp/parquetjs";
import { convertToGeoparquet, encodeWKBPoint } from "../../src/geoparquet.js";

function tmpPath(ext: string): string {
  return join(tmpdir(), `flat-white-test-${randomBytes(4).toString("hex")}${ext}`);
}

/** Minimal valid AddressDocument as NDJSON line. */
function makeDoc(overrides: Record<string, unknown> = {}): string {
  const doc = {
    _id: "GAVIC000000001",
    _version: "2026.02",
    addressLabel: "1 TEST STREET, MELBOURNE VIC 3000",
    addressLabelSearch: "1 TEST STREET MELBOURNE VIC 3000",
    addressSiteName: null,
    buildingName: null,
    flatType: null,
    flatNumber: null,
    levelType: null,
    levelNumber: null,
    numberFirst: "1",
    numberLast: null,
    lotNumber: null,
    streetName: "TEST",
    streetType: "STREET",
    streetSuffix: null,
    localityName: "MELBOURNE",
    state: "VIC",
    postcode: "3000",
    legalParcelId: null,
    confidence: 2,
    aliasPrincipal: "PRINCIPAL",
    primarySecondary: "PRIMARY",
    geocode: {
      latitude: -37.8136,
      longitude: 144.9631,
      type: "FRONTAGE CENTRE SETBACK",
      reliability: 2,
    },
    location: {
      lat: -37.8136,
      lon: 144.9631,
    },
    allGeocodes: [
      { lat: -37.8136, lng: 144.9631, type: "FRONTAGE CENTRE SETBACK", reliability: 2 },
    ],
    locality: { pid: "VIC1234", class: "LOCALITY", neighbours: ["SOUTHBANK"], aliases: [] },
    street: { pid: "VIC5678", class: "CONFIRMED", aliases: [] },
    boundaries: {
      lga: { name: "MELBOURNE", code: "LGA123" },
      ward: null,
      stateElectorate: null,
      commonwealthElectorate: null,
      meshBlock: null,
      sa1: null,
      sa2: null,
      sa3: null,
      sa4: null,
      gccsa: null,
    },
    aliases: [],
    secondaries: [],
    ...overrides,
  };
  return JSON.stringify(doc);
}

describe("encodeWKBPoint", () => {
  it("produces 21-byte little-endian WKB", () => {
    const buf = encodeWKBPoint(144.9631, -37.8136);
    expect(buf.length).toBe(21);
    expect(buf.readUInt8(0)).toBe(1); // little-endian
    expect(buf.readUInt32LE(1)).toBe(1); // Point type
    expect(buf.readDoubleLE(5)).toBeCloseTo(144.9631, 4);
    expect(buf.readDoubleLE(13)).toBeCloseTo(-37.8136, 4);
  });
});

describe("convertToGeoparquet", () => {
  const files: string[] = [];

  afterAll(() => {
    for (const f of files) {
      if (existsSync(f)) unlinkSync(f);
    }
  });

  it("converts NDJSON to Geoparquet with correct row count", async () => {
    const ndjsonPath = tmpPath(".ndjson");
    const geoparquetPath = tmpPath(".geoparquet");
    files.push(ndjsonPath, geoparquetPath);

    const lines = [
      makeDoc({ _id: "GAVIC000000001" }),
      makeDoc({ _id: "GAVIC000000002", state: "NSW", localityName: "SYDNEY", postcode: "2000" }),
      makeDoc({ _id: "GAVIC000000003", state: "QLD", localityName: "BRISBANE", postcode: "4000" }),
    ];
    writeFileSync(ndjsonPath, lines.join("\n") + "\n");

    const result = await convertToGeoparquet({ inputPath: ndjsonPath, outputPath: geoparquetPath });
    expect(result.count).toBe(3);

    const reader = await ParquetReader.openFile(geoparquetPath);
    const cursor = reader.getCursor();
    const rows: Record<string, unknown>[] = [];
    let row: Record<string, unknown> | null;
    while ((row = (await cursor.next()) as Record<string, unknown> | null)) {
      rows.push(row);
    }
    await reader.close();

    expect(rows).toHaveLength(3);
  });

  it("includes WKB POINT geometry column", async () => {
    const ndjsonPath = tmpPath(".ndjson");
    const geoparquetPath = tmpPath(".geoparquet");
    files.push(ndjsonPath, geoparquetPath);

    writeFileSync(
      ndjsonPath,
      makeDoc({
        geocode: {
          latitude: -33.8688,
          longitude: 151.2093,
          type: "PROPERTY CENTROID",
          reliability: 2,
        },
      }) + "\n",
    );

    await convertToGeoparquet({ inputPath: ndjsonPath, outputPath: geoparquetPath });

    const reader = await ParquetReader.openFile(geoparquetPath);
    const cursor = reader.getCursor();
    const row = (await cursor.next()) as Record<string, unknown>;
    await reader.close();

    // Geometry should be a Buffer with WKB Point
    const geom = row.geometry as Buffer;
    expect(Buffer.isBuffer(geom)).toBe(true);
    expect(geom.length).toBe(21);
    expect(geom.readUInt8(0)).toBe(1); // LE
    expect(geom.readUInt32LE(1)).toBe(1); // Point
    expect(geom.readDoubleLE(5)).toBeCloseTo(151.2093, 4); // longitude
    expect(geom.readDoubleLE(13)).toBeCloseTo(-33.8688, 4); // latitude
  });

  it("sets Geoparquet v1.1.0 metadata", async () => {
    const ndjsonPath = tmpPath(".ndjson");
    const geoparquetPath = tmpPath(".geoparquet");
    files.push(ndjsonPath, geoparquetPath);

    writeFileSync(ndjsonPath, makeDoc() + "\n");

    await convertToGeoparquet({ inputPath: ndjsonPath, outputPath: geoparquetPath });

    const reader = await ParquetReader.openFile(geoparquetPath);
    const metadata = reader.getMetadata();
    await reader.close();

    expect(metadata.geo).toBeDefined();
    const geo = JSON.parse(metadata.geo as string);

    expect(geo.version).toBe("1.1.0");
    expect(geo.primary_column).toBe("geometry");
    expect(geo.columns.geometry.encoding).toBe("WKB");
    expect(geo.columns.geometry.geometry_types).toEqual(["Point"]);
    expect(geo.columns.geometry.crs.id).toEqual({ authority: "EPSG", code: 4326 });
  });

  it("computes correct bounding box", async () => {
    const ndjsonPath = tmpPath(".ndjson");
    const geoparquetPath = tmpPath(".geoparquet");
    files.push(ndjsonPath, geoparquetPath);

    const lines = [
      makeDoc({
        _id: "A1",
        geocode: { latitude: -33.0, longitude: 151.0, type: "PROPERTY CENTROID", reliability: 2 },
      }),
      makeDoc({
        _id: "A2",
        geocode: { latitude: -38.0, longitude: 144.0, type: "PROPERTY CENTROID", reliability: 2 },
      }),
    ];
    writeFileSync(ndjsonPath, lines.join("\n") + "\n");

    await convertToGeoparquet({ inputPath: ndjsonPath, outputPath: geoparquetPath });

    const reader = await ParquetReader.openFile(geoparquetPath);
    const geo = JSON.parse(reader.getMetadata().geo as string);
    await reader.close();

    // bbox is [minLon, minLat, maxLon, maxLat]
    expect(geo.columns.geometry.bbox).toEqual([144.0, -38.0, 151.0, -33.0]);
  });

  it("handles null geocode as null geometry", async () => {
    const ndjsonPath = tmpPath(".ndjson");
    const geoparquetPath = tmpPath(".geoparquet");
    files.push(ndjsonPath, geoparquetPath);

    writeFileSync(ndjsonPath, makeDoc({ geocode: null }) + "\n");

    await convertToGeoparquet({ inputPath: ndjsonPath, outputPath: geoparquetPath });

    const reader = await ParquetReader.openFile(geoparquetPath);
    const cursor = reader.getCursor();
    const row = (await cursor.next()) as Record<string, unknown>;
    await reader.close();

    expect(row.geometry).toBeNull();
  });

  it("preserves all scalar and complex fields alongside geometry", async () => {
    const ndjsonPath = tmpPath(".ndjson");
    const geoparquetPath = tmpPath(".geoparquet");
    files.push(ndjsonPath, geoparquetPath);

    writeFileSync(ndjsonPath, makeDoc({ _id: "GAVIC_SCALAR_TEST", numberFirst: "42" }) + "\n");

    await convertToGeoparquet({ inputPath: ndjsonPath, outputPath: geoparquetPath });

    const reader = await ParquetReader.openFile(geoparquetPath);
    const cursor = reader.getCursor();
    const row = (await cursor.next()) as Record<string, unknown>;
    await reader.close();

    expect(row._id).toBe("GAVIC_SCALAR_TEST");
    expect(row.numberFirst).toBe("42");
    expect(row.state).toBe("VIC");
    // Complex field should still be JSON string
    expect(JSON.parse(row.locality as string)).toHaveProperty("pid", "VIC1234");
    expect(JSON.parse(row.location as string)).toEqual({ lat: -37.8136, lon: 144.9631 });
    // Geometry should also be present
    expect(Buffer.isBuffer(row.geometry)).toBe(true);
  });

  it("converts fixture NDJSON with correct row count", async () => {
    const fixturePath = "fixtures/expected-output.ndjson";
    if (!existsSync(fixturePath)) return;

    const geoparquetPath = tmpPath(".geoparquet");
    files.push(geoparquetPath);

    const result = await convertToGeoparquet({
      inputPath: fixturePath,
      outputPath: geoparquetPath,
    });
    expect(result.count).toBe(451);

    const reader = await ParquetReader.openFile(geoparquetPath);
    const cursor = reader.getCursor();
    let count = 0;
    while (await cursor.next()) count++;

    // Verify geo metadata exists
    const geo = JSON.parse(reader.getMetadata().geo as string);
    expect(geo.version).toBe("1.1.0");
    expect(geo.columns.geometry.bbox).toHaveLength(4);

    await reader.close();

    expect(count).toBe(451);
  });
});
