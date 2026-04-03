/**
 * Unit tests for flatten.ts document composition logic.
 *
 * Tests the composeDocument and composeSearchLabel functions
 * using mock SQL rows (no Postgres connection needed).
 */

import { describe, it, expect } from "vitest";
import { AddressDocumentSchema } from "../../src/schema.js";
import { composeDocument, composeSearchLabel, composeBoundaries } from "../../src/flatten.js";

// --- Mock data ---

const baseRow: Record<string, unknown> = {
  _id: "GAVIC425181432",
  address_label: "1 MCNAB AV, FOOTSCRAY VIC 3011",
  address_site_name: null,
  building_name: null,
  flat_number_composed: null,
  flat_type_name: null,
  level_number_composed: null,
  level_type_name: null,
  number_first: "1",
  number_last: null,
  lot_number: null,
  street_name: "MCNAB",
  street_type_name: "AVENUE",
  street_suffix_code: null,
  street_suffix_name: null,
  locality_name: "FOOTSCRAY",
  state: "VIC",
  postcode: "3011",
  legal_parcel_id: "1\\PS733924",
  confidence: 2,
  primary_secondary: null,
  best_geocode: {
    latitude: -37.79815294,
    longitude: 144.89719303,
    type: "FRONTAGE CENTRE SETBACK",
    reliability: 2,
  },
  all_geocodes: [
    { lat: -37.79815294, lng: 144.89719303, type: "FCS", reliability: 2 },
    { lat: -37.798211, lng: 144.897254, type: "PC", reliability: 2 },
  ],
  locality_pid: "loc67a11408d754",
  locality_class_name: "GAZETTED LOCALITY",
  locality_neighbours: ["ASCOT VALE", "FLEMINGTON", "SEDDON"],
  locality_aliases: [],
  street_locality_pid: "VIC2104831",
  street_class_name: "CONFIRMED",
  street_aliases: [],
  lga_pid: "LGA24650",
  lga_name: "MARIBYRNONG",
  ward_name: "RIVER WARD",
  state_electorate_name: "FOOTSCRAY",
  commonwealth_electorate_name: "GELLIBRAND",
  mb_2021_code: 20663890000,
  mesh_block_category: "COMMERCIAL",
  sa1_21code: "20604102614",
  sa2_21code: "20604",
  sa2_21name: "FOOTSCRAY",
  sa3_21code: "206",
  sa3_21name: "MARIBYRNONG",
  sa4_21code: "2",
  sa4_21name: "MELBOURNE - WEST",
  gcc_21code: "2GMEL",
  gcc_21name: "GREATER MELBOURNE",
  address_aliases: [],
  address_secondaries: [],
};

// --- Tests ---

describe("composeSearchLabel", () => {
  it("composes a simple address label with expanded street type", () => {
    const label = composeSearchLabel(baseRow);
    expect(label).toBe("1 MCNAB AVENUE FOOTSCRAY VIC 3011");
  });

  it("includes flat type and number when present", () => {
    const row = { ...baseRow, flat_type_name: "UNIT", flat_number_composed: "3A" };
    const label = composeSearchLabel(row);
    expect(label).toBe("UNIT 3A 1 MCNAB AVENUE FOOTSCRAY VIC 3011");
  });

  it("includes level type and number when present", () => {
    const row = { ...baseRow, level_type_name: "LEVEL", level_number_composed: "2" };
    const label = composeSearchLabel(row);
    expect(label).toBe("LEVEL 2 1 MCNAB AVENUE FOOTSCRAY VIC 3011");
  });

  it("includes flat + level when both present", () => {
    const row = {
      ...baseRow,
      flat_type_name: "UNIT",
      flat_number_composed: "5",
      level_type_name: "LEVEL",
      level_number_composed: "1",
    };
    const label = composeSearchLabel(row);
    expect(label).toBe("UNIT 5 LEVEL 1 1 MCNAB AVENUE FOOTSCRAY VIC 3011");
  });

  it("handles number ranges", () => {
    const row = { ...baseRow, number_first: "1", number_last: "5" };
    const label = composeSearchLabel(row);
    expect(label).toBe("1-5 MCNAB AVENUE FOOTSCRAY VIC 3011");
  });

  it("handles lot numbers without street number", () => {
    const row = { ...baseRow, lot_number: "3", number_first: null };
    const label = composeSearchLabel(row);
    expect(label).toBe("LOT 3 MCNAB AVENUE FOOTSCRAY VIC 3011");
  });

  it("handles street suffix (expanded in search label)", () => {
    const row = { ...baseRow, street_suffix_code: "NORTH", street_suffix_name: "NORTH" };
    const label = composeSearchLabel(row);
    expect(label).toBe("1 MCNAB AVENUE NORTH FOOTSCRAY VIC 3011");
  });

  it("handles null postcode", () => {
    const row = { ...baseRow, postcode: null };
    const label = composeSearchLabel(row);
    expect(label).toBe("1 MCNAB AVENUE FOOTSCRAY VIC");
  });
});

describe("composeDocument", () => {
  it("produces a valid AddressDocument from a complete row", () => {
    const doc = composeDocument(baseRow, "2026.02");
    const result = AddressDocumentSchema.safeParse(doc);
    expect(result.success).toBe(true);
  });

  it("sets _id and _version correctly", () => {
    const doc = composeDocument(baseRow, "2026.02");
    expect(doc._id).toBe("GAVIC425181432");
    expect(doc._version).toBe("2026.02");
  });

  it("maps geocode fields correctly", () => {
    const doc = composeDocument(baseRow, "2026.02");
    expect(doc.geocode.latitude).toBe(-37.79815294);
    expect(doc.geocode.longitude).toBe(144.89719303);
    expect(doc.geocode.type).toBe("FRONTAGE CENTRE SETBACK");
    expect(doc.geocode.reliability).toBe(2);
  });

  it("maps allGeocodes correctly", () => {
    const doc = composeDocument(baseRow, "2026.02");
    expect(doc.allGeocodes).toHaveLength(2);
    expect(doc.allGeocodes[0].type).toBe("FCS");
    expect(doc.allGeocodes[1].type).toBe("PC");
  });

  it("maps boundaries correctly", () => {
    const doc = composeDocument(baseRow, "2026.02");
    expect(doc.boundaries.lga).toEqual({ name: "MARIBYRNONG", code: "LGA24650" });
    expect(doc.boundaries.ward).toEqual({ name: "RIVER WARD" });
    expect(doc.boundaries.sa1).toBe("20604102614");
    expect(doc.boundaries.sa2).toEqual({ code: "20604", name: "FOOTSCRAY" });
    expect(doc.boundaries.gccsa).toEqual({ code: "2GMEL", name: "GREATER MELBOURNE" });
  });

  it("handles null boundaries gracefully", () => {
    const row = {
      ...baseRow,
      lga_pid: null,
      lga_name: null,
      ward_name: null,
      state_electorate_name: null,
      commonwealth_electorate_name: null,
      mb_2021_code: null,
      mesh_block_category: null,
      sa1_21code: null,
      sa2_21code: null,
      sa2_21name: null,
      sa3_21code: null,
      sa3_21name: null,
      sa4_21code: null,
      sa4_21name: null,
      gcc_21code: null,
      gcc_21name: null,
    };
    const doc = composeDocument(row, "2026.02");
    const result = AddressDocumentSchema.safeParse(doc);
    expect(result.success).toBe(true);
    expect(doc.boundaries.lga).toBeNull();
    expect(doc.boundaries.meshBlock).toBeNull();
    expect(doc.boundaries.sa1).toBeNull();
  });

  it("sets aliasPrincipal to PRINCIPAL for principal addresses", () => {
    const doc = composeDocument(baseRow, "2026.02");
    expect(doc.aliasPrincipal).toBe("PRINCIPAL");
  });

  it("handles addresses with aliases and secondaries", () => {
    const row = {
      ...baseRow,
      primary_secondary: "PRIMARY",
      address_aliases: [
        { pid: "MA001", label: "1 MCNAB AVENUE, FOOTSCRAY VIC 3011", type: "SYNONYM" },
      ],
      address_secondaries: [{ pid: "GAVIC002", label: "UNIT 1 1 MCNAB AV, FOOTSCRAY VIC 3011" }],
    };
    const doc = composeDocument(row, "2026.02");
    const result = AddressDocumentSchema.safeParse(doc);
    expect(result.success).toBe(true);
    expect(doc.aliases).toHaveLength(1);
    expect(doc.secondaries).toHaveLength(1);
    expect(doc.primarySecondary).toBe("PRIMARY");
  });

  it("maps single-letter primary_secondary codes to full words", () => {
    const rowP = { ...baseRow, primary_secondary: "P" };
    const docP = composeDocument(rowP, "2026.02");
    expect(docP.primarySecondary).toBe("PRIMARY");
    const resultP = AddressDocumentSchema.safeParse(docP);
    expect(resultP.success).toBe(true);

    const rowS = { ...baseRow, primary_secondary: "S" };
    const docS = composeDocument(rowS, "2026.02");
    expect(docS.primarySecondary).toBe("SECONDARY");
    const resultS = AddressDocumentSchema.safeParse(docS);
    expect(resultS.success).toBe(true);
  });

  it("returns null geocode when best_geocode is null", () => {
    const row = { ...baseRow, best_geocode: null, all_geocodes: null };
    const doc = composeDocument(row, "2026.02");
    expect(doc.geocode).toBeNull();
    expect(doc.allGeocodes).toEqual([]);
    const result = AddressDocumentSchema.safeParse(doc);
    expect(result.success).toBe(true);
  });
});

describe("composeBoundaries", () => {
  it("returns all boundary fields when data is present", () => {
    const boundaries = composeBoundaries(baseRow);
    expect(boundaries.lga).not.toBeNull();
    expect(boundaries.ward).not.toBeNull();
    expect(boundaries.stateElectorate).not.toBeNull();
    expect(boundaries.commonwealthElectorate).not.toBeNull();
    expect(boundaries.meshBlock).not.toBeNull();
    expect(boundaries.sa1).not.toBeNull();
    expect(boundaries.sa2).not.toBeNull();
    expect(boundaries.sa3).not.toBeNull();
    expect(boundaries.sa4).not.toBeNull();
    expect(boundaries.gccsa).not.toBeNull();
  });

  it("returns nulls when data is missing", () => {
    const row: Record<string, unknown> = {};
    const boundaries = composeBoundaries(row);
    expect(boundaries.lga).toBeNull();
    expect(boundaries.ward).toBeNull();
    expect(boundaries.stateElectorate).toBeNull();
    expect(boundaries.commonwealthElectorate).toBeNull();
    expect(boundaries.meshBlock).toBeNull();
    expect(boundaries.sa1).toBeNull();
    expect(boundaries.sa2).toBeNull();
    expect(boundaries.sa3).toBeNull();
    expect(boundaries.sa4).toBeNull();
    expect(boundaries.gccsa).toBeNull();
  });
});
