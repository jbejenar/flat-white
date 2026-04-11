/**
 * Unit tests for parquet.ts — NDJSON → Parquet conversion.
 */

import { describe, it, expect, beforeAll, afterAll } from "vitest";
import { writeFileSync, unlinkSync, existsSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { randomBytes } from "node:crypto";
import { ParquetReader } from "@dsnp/parquetjs";
import { convertToParquet } from "../../src/parquet.js";

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

describe("convertToParquet", () => {
  const files: string[] = [];

  afterAll(() => {
    for (const f of files) {
      if (existsSync(f)) unlinkSync(f);
    }
  });

  it("converts NDJSON to valid Parquet with correct row count", async () => {
    const ndjsonPath = tmpPath(".ndjson");
    const parquetPath = tmpPath(".parquet");
    files.push(ndjsonPath, parquetPath);

    const lines = [
      makeDoc({ _id: "GAVIC000000001" }),
      makeDoc({ _id: "GAVIC000000002", state: "NSW", localityName: "SYDNEY", postcode: "2000" }),
      makeDoc({ _id: "GAVIC000000003", state: "QLD", localityName: "BRISBANE", postcode: "4000" }),
    ];
    writeFileSync(ndjsonPath, lines.join("\n") + "\n");

    const result = await convertToParquet({ inputPath: ndjsonPath, outputPath: parquetPath });
    expect(result.count).toBe(3);

    // Verify Parquet is readable
    const reader = await ParquetReader.openFile(parquetPath);
    const cursor = reader.getCursor();
    const rows: Record<string, unknown>[] = [];
    let row: Record<string, unknown> | null;
    while ((row = (await cursor.next()) as Record<string, unknown> | null)) {
      rows.push(row);
    }
    await reader.close();

    expect(rows).toHaveLength(3);
    expect(rows[0]._id).toBe("GAVIC000000001");
    expect(rows[1].state).toBe("NSW");
    expect(rows[2].localityName).toBe("BRISBANE");
  });

  it("preserves scalar field values", async () => {
    const ndjsonPath = tmpPath(".ndjson");
    const parquetPath = tmpPath(".parquet");
    files.push(ndjsonPath, parquetPath);

    writeFileSync(
      ndjsonPath,
      makeDoc({
        _id: "GAVIC000000099",
        numberFirst: "42",
        numberLast: "44",
        flatType: "UNIT",
        flatNumber: "5",
        confidence: 1,
        aliasPrincipal: "ALIAS",
        primarySecondary: "SECONDARY",
      }) + "\n",
    );

    await convertToParquet({ inputPath: ndjsonPath, outputPath: parquetPath });

    const reader = await ParquetReader.openFile(parquetPath);
    const cursor = reader.getCursor();
    const row = (await cursor.next()) as Record<string, unknown>;
    await reader.close();

    expect(row.numberFirst).toBe("42");
    expect(row.numberLast).toBe("44");
    expect(row.flatType).toBe("UNIT");
    expect(row.flatNumber).toBe("5");
    expect(row.confidence).toBe(1);
    expect(row.aliasPrincipal).toBe("ALIAS");
    expect(row.primarySecondary).toBe("SECONDARY");
  });

  it("serializes complex fields as JSON strings", async () => {
    const ndjsonPath = tmpPath(".ndjson");
    const parquetPath = tmpPath(".parquet");
    files.push(ndjsonPath, parquetPath);

    const geocode = {
      latitude: -33.8,
      longitude: 151.2,
      type: "PROPERTY CENTROID",
      reliability: 3,
    };
    const locality = { pid: "NSW0001", class: "LOCALITY", neighbours: ["A", "B"], aliases: ["X"] };
    const location = { lat: geocode.latitude, lon: geocode.longitude };
    writeFileSync(ndjsonPath, makeDoc({ geocode, location, locality }) + "\n");

    await convertToParquet({ inputPath: ndjsonPath, outputPath: parquetPath });

    const reader = await ParquetReader.openFile(parquetPath);
    const cursor = reader.getCursor();
    const row = (await cursor.next()) as Record<string, unknown>;
    await reader.close();

    // Complex fields should be JSON strings that parse back to the original
    expect(JSON.parse(row.geocode as string)).toEqual(geocode);
    expect(JSON.parse(row.location as string)).toEqual(location);
    expect(JSON.parse(row.locality as string)).toEqual(locality);
  });

  it("handles null values in nullable fields", async () => {
    const ndjsonPath = tmpPath(".ndjson");
    const parquetPath = tmpPath(".parquet");
    files.push(ndjsonPath, parquetPath);

    writeFileSync(
      ndjsonPath,
      makeDoc({
        addressSiteName: null,
        buildingName: null,
        flatType: null,
        geocode: null,
        location: null,
        primarySecondary: null,
      }) + "\n",
    );

    await convertToParquet({ inputPath: ndjsonPath, outputPath: parquetPath });

    const reader = await ParquetReader.openFile(parquetPath);
    const cursor = reader.getCursor();
    const row = (await cursor.next()) as Record<string, unknown>;
    await reader.close();

    expect(row.addressSiteName).toBeNull();
    expect(row.buildingName).toBeNull();
    expect(row.flatType).toBeNull();
    expect(row.geocode).toBeNull();
    expect(row.location).toBeNull();
    expect(row.primarySecondary).toBeNull();
  });

  it("produces empty Parquet file from empty input", async () => {
    const ndjsonPath = tmpPath(".ndjson");
    const parquetPath = tmpPath(".parquet");
    files.push(ndjsonPath, parquetPath);

    writeFileSync(ndjsonPath, "");

    const result = await convertToParquet({ inputPath: ndjsonPath, outputPath: parquetPath });
    expect(result.count).toBe(0);

    // Empty Parquet should still be readable
    const reader = await ParquetReader.openFile(parquetPath);
    const cursor = reader.getCursor();
    const row = await cursor.next();
    await reader.close();

    expect(row).toBeNull();
  });

  it("converts fixture NDJSON with correct row count", async () => {
    const fixturePath = "fixtures/expected-output.ndjson";
    if (!existsSync(fixturePath)) return; // Skip if fixture not available

    const parquetPath = tmpPath(".parquet");
    files.push(parquetPath);

    const result = await convertToParquet({ inputPath: fixturePath, outputPath: parquetPath });
    expect(result.count).toBe(451);

    const reader = await ParquetReader.openFile(parquetPath);
    const cursor = reader.getCursor();
    let count = 0;
    while (await cursor.next()) count++;
    await reader.close();

    expect(count).toBe(451);
  });
});
