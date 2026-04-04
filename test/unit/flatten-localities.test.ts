/**
 * Unit tests for flatten-localities.ts document composition logic.
 *
 * Tests the composeLocalityDocument function using mock SQL rows
 * (no Postgres connection needed).
 */

import { describe, it, expect } from "vitest";
import { LocalityDocumentSchema } from "../../src/schema.js";
import { composeLocalityDocument } from "../../src/flatten-localities.js";

// --- Mock data ---

const baseLocalityRow: Record<string, unknown> = {
  locality_pid: "loc67a11408d754",
  locality_name: "FOOTSCRAY",
  state: "VIC",
  postcode: "3011",
  locality_class_name: "GAZETTED LOCALITY",
  locality_neighbours: ["ASCOT VALE", "FLEMINGTON", "SEDDON"],
  locality_aliases: ["FOOTSCRAY WEST"],
  latitude: -37.7998,
  longitude: 144.8991,
};

// --- Tests ---

describe("composeLocalityDocument", () => {
  it("produces a valid LocalityDocument from a complete row", () => {
    const doc = composeLocalityDocument(baseLocalityRow, "2026.02");
    const result = LocalityDocumentSchema.safeParse(doc);
    expect(result.success).toBe(true);
  });

  it("sets _id to locality_pid and _version correctly", () => {
    const doc = composeLocalityDocument(baseLocalityRow, "2026.02");
    expect(doc._id).toBe("loc67a11408d754");
    expect(doc._version).toBe("2026.02");
  });

  it("maps locality fields correctly", () => {
    const doc = composeLocalityDocument(baseLocalityRow, "2026.02");
    expect(doc.localityName).toBe("FOOTSCRAY");
    expect(doc.state).toBe("VIC");
    expect(doc.postcode).toBe("3011");
    expect(doc.class).toBe("GAZETTED LOCALITY");
  });

  it("maps neighbours and aliases correctly", () => {
    const doc = composeLocalityDocument(baseLocalityRow, "2026.02");
    expect(doc.neighbours).toEqual(["ASCOT VALE", "FLEMINGTON", "SEDDON"]);
    expect(doc.aliases).toEqual(["FOOTSCRAY WEST"]);
  });

  it("maps latitude and longitude correctly", () => {
    const doc = composeLocalityDocument(baseLocalityRow, "2026.02");
    expect(doc.latitude).toBe(-37.7998);
    expect(doc.longitude).toBe(144.8991);
  });

  it("handles locality with no neighbours or aliases", () => {
    const row = {
      ...baseLocalityRow,
      locality_neighbours: [],
      locality_aliases: [],
    };
    const doc = composeLocalityDocument(row, "2026.02");
    const result = LocalityDocumentSchema.safeParse(doc);
    expect(result.success).toBe(true);
    expect(doc.neighbours).toEqual([]);
    expect(doc.aliases).toEqual([]);
  });

  it("handles null postcode", () => {
    const row = { ...baseLocalityRow, postcode: null };
    const doc = composeLocalityDocument(row, "2026.02");
    const result = LocalityDocumentSchema.safeParse(doc);
    expect(result.success).toBe(true);
    expect(doc.postcode).toBeNull();
  });

  it("handles null latitude and longitude", () => {
    const row = { ...baseLocalityRow, latitude: null, longitude: null };
    const doc = composeLocalityDocument(row, "2026.02");
    const result = LocalityDocumentSchema.safeParse(doc);
    expect(result.success).toBe(true);
    expect(doc.latitude).toBeNull();
    expect(doc.longitude).toBeNull();
  });

  it("defaults class to UNKNOWN when locality_class_name is null", () => {
    const row = { ...baseLocalityRow, locality_class_name: null };
    const doc = composeLocalityDocument(row, "2026.02");
    expect(doc.class).toBe("UNKNOWN");
    const result = LocalityDocumentSchema.safeParse(doc);
    expect(result.success).toBe(true);
  });
});
