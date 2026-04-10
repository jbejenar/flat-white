import { describe, it, expect } from "vitest";
import { AddressDocumentSchema } from "../../src/schema.js";

/** Minimal valid document — all required fields, nullable fields set to null, arrays empty. */
function validDocument() {
  return {
    _id: "GAVIC425181432",
    _version: "2026.02",
    addressLabel: "1 MCNAB AV, FOOTSCRAY VIC 3011",
    addressLabelSearch: "1 MCNAB AVENUE FOOTSCRAY VIC 3011",
    addressSiteName: null,
    buildingName: null,
    flatType: null,
    flatNumber: null,
    levelType: null,
    levelNumber: null,
    numberFirst: "1",
    numberLast: null,
    lotNumber: null,
    streetName: "MCNAB",
    streetType: "AVENUE",
    streetSuffix: null,
    localityName: "FOOTSCRAY",
    state: "VIC",
    postcode: "3011",
    legalParcelId: "1\\PS733924",
    confidence: 2,
    aliasPrincipal: "PRINCIPAL" as const,
    primarySecondary: "PRIMARY" as const,
    geocode: {
      latitude: -37.79815294,
      longitude: 144.89719303,
      type: "FRONTAGE CENTRE SETBACK",
      reliability: 2,
    },
    location: {
      lat: -37.79815294,
      lon: 144.89719303,
    },
    allGeocodes: [
      { lat: -37.79815294, lng: 144.89719303, type: "FRONTAGE CENTRE SETBACK", reliability: 2 },
    ],
    locality: {
      pid: "loc67a11408d754",
      class: "GAZETTED LOCALITY",
      neighbours: ["ASCOT VALE", "FLEMINGTON"],
      aliases: [],
    },
    street: {
      pid: "VIC2104831",
      class: "CONFIRMED",
      aliases: [],
    },
    boundaries: {
      lga: { name: "MARIBYRNONG", code: "LGA24650" },
      ward: { name: "RIVER WARD" },
      stateElectorate: { name: "FOOTSCRAY" },
      commonwealthElectorate: { name: "GELLIBRAND" },
      meshBlock: { code: "20663890000", category: "COMMERCIAL" },
      sa1: "20604102614",
      sa2: { code: "20604", name: "FOOTSCRAY" },
      sa3: { code: "206", name: "MARIBYRNONG" },
      sa4: { code: "2", name: "MELBOURNE - WEST" },
      gccsa: { code: "2GMEL", name: "GREATER MELBOURNE" },
    },
    aliases: [],
    secondaries: [],
  };
}

describe("AddressDocumentSchema", () => {
  it("validates a complete document", () => {
    const result = AddressDocumentSchema.safeParse(validDocument());
    expect(result.success).toBe(true);
  });

  it("validates a document with aliases and secondaries", () => {
    const doc = validDocument();
    doc.aliases = [
      {
        pid: "MA13517230",
        label: "SHOP 1 GROUND 1 MCNAB AV, FOOTSCRAY VIC 3011",
        type: "SYNONYM",
      },
    ];
    doc.secondaries = [
      {
        pid: "GAVIC425495838",
        label: "SHOP 1 1 MCNAB AV, FOOTSCRAY VIC 3011",
      },
    ];
    const result = AddressDocumentSchema.safeParse(doc);
    expect(result.success).toBe(true);
  });

  it("validates a document with all nullable fields set to null", () => {
    const doc = validDocument();
    doc.addressSiteName = null;
    doc.buildingName = null;
    doc.flatType = null;
    doc.flatNumber = null;
    doc.levelType = null;
    doc.levelNumber = null;
    doc.numberFirst = null;
    doc.numberLast = null;
    doc.lotNumber = null;
    doc.streetType = null;
    doc.streetSuffix = null;
    doc.postcode = null;
    doc.legalParcelId = null;
    doc.primarySecondary = null;
    doc.location = null;
    doc.boundaries = {
      lga: null,
      ward: null,
      stateElectorate: null,
      commonwealthElectorate: null,
      meshBlock: null,
      sa1: null,
      sa2: null,
      sa3: null,
      sa4: null,
      gccsa: null,
    };
    const result = AddressDocumentSchema.safeParse(doc);
    expect(result.success).toBe(true);
  });

  it("rejects a document missing _id", () => {
    const doc = validDocument();
    const { _id, ...missing } = doc;
    const result = AddressDocumentSchema.safeParse(missing);
    expect(result.success).toBe(false);
  });

  it("rejects a document with wrong type for confidence", () => {
    const doc = validDocument();
    (doc as Record<string, unknown>).confidence = "high";
    const result = AddressDocumentSchema.safeParse(doc);
    expect(result.success).toBe(false);
  });

  it("rejects confidence outside 0-2 range", () => {
    const doc = validDocument();
    doc.confidence = 5;
    const result = AddressDocumentSchema.safeParse(doc);
    expect(result.success).toBe(false);
  });

  it("rejects invalid aliasPrincipal value", () => {
    const doc = validDocument();
    (doc as Record<string, unknown>).aliasPrincipal = "UNKNOWN";
    const result = AddressDocumentSchema.safeParse(doc);
    expect(result.success).toBe(false);
  });

  it("rejects geocode with reliability outside 1-6", () => {
    const doc = validDocument();
    doc.geocode.reliability = 0;
    const result = AddressDocumentSchema.safeParse(doc);
    expect(result.success).toBe(false);
  });

  it("rejects allGeocodes item missing required fields", () => {
    const doc = validDocument();
    (doc as Record<string, unknown>).allGeocodes = [{ lat: -37.0 }];
    const result = AddressDocumentSchema.safeParse(doc);
    expect(result.success).toBe(false);
  });

  it("validates ALIAS as aliasPrincipal", () => {
    const doc = validDocument();
    (doc as Record<string, unknown>).aliasPrincipal = "ALIAS";
    const result = AddressDocumentSchema.safeParse(doc);
    expect(result.success).toBe(true);
  });

  it("validates SECONDARY as primarySecondary", () => {
    const doc = validDocument();
    (doc as Record<string, unknown>).primarySecondary = "SECONDARY";
    const result = AddressDocumentSchema.safeParse(doc);
    expect(result.success).toBe(true);
  });
});
