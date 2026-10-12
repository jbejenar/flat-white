/**
 * flat-white — Address document Zod schema and TypeScript types.
 *
 * This schema IS the contract. It must match docs/DOCUMENT-SCHEMA.md exactly.
 * When changing the schema, update both files together (see AGENTS.md rule 3).
 */

import { z } from "zod";

/** Schema 1.x census boundaries use ASGS Edition 4 (2026), never a 2021 fallback. */
export const ASGS_YEAR = 2026;

// --- Nested schemas ---

export const GeocodeSchema = z.object({
  latitude: z.number(),
  longitude: z.number(),
  type: z.string(),
  reliability: z.number().int().min(1).max(6),
});

/** Coarse/default coordinates are deliberately separate from the site geometry. */
export const FallbackGeocodeSchema = z.object({
  latitude: z.number().min(-44).max(-9),
  longitude: z.number().min(96).max(168),
  typeCode: z.string().min(1),
  type: z.string().min(1),
  source: z.literal("GNAF_DEFAULT"),
  precision: z.enum(["street", "locality", "unknown"]),
});

export const LocationSchema = z.object({
  lat: z.number(),
  lon: z.number(),
});

export const AllGeocodesItemSchema = z.object({
  lat: z.number(),
  lng: z.number(),
  type: z.string(),
  reliability: z.number().int().min(1).max(6),
});

export const LocalitySchema = z.object({
  pid: z.string(),
  class: z.string(),
  neighbours: z.array(z.string()),
  aliases: z.array(z.string()),
});

export const StreetSchema = z.object({
  pid: z.string(),
  class: z.string(),
  aliases: z.array(z.string()),
});

const NameCodeSchema = z.object({
  name: z.string(),
  code: z.string(),
});

const NameOnlySchema = z.object({
  name: z.string(),
});

export const BoundariesSchema = z
  .object({
    lga: NameCodeSchema.nullable(),
    // NSW requires a reviewed council source and a precise primary site point.
    // See docs/NSW-WARD-SOURCES.md; default coordinates never assign wards.
    ward: NameOnlySchema.nullable(),
    stateElectorate: NameOnlySchema.nullable(),
    commonwealthElectorate: NameOnlySchema.nullable(),
    meshBlock: z
      .object({
        code: z.string(),
        category: z.string(),
      })
      .nullable(),
    sa1: z.string().nullable(),
    sa2: NameCodeSchema.nullable(),
    sa3: NameCodeSchema.nullable(),
    sa4: NameCodeSchema.nullable(),
    gccsa: NameCodeSchema.nullable(),
  })
  .describe("Census boundaries (meshBlock, SA1-SA4, GCCSA) use ASGS 2026 in schema 1.x.");

export const AliasSchema = z.object({
  pid: z.string(),
  label: z.string(),
  type: z.string(),
});

export const SecondarySchema = z.object({
  pid: z.string(),
  label: z.string(),
});

// --- Top-level document schema ---

export const AddressDocumentSchema = z.object({
  _id: z.string(),
  _version: z.string(),
  addressLabel: z.string(),
  addressLabelSearch: z.string(),
  addressSiteName: z.string().nullable(),
  buildingName: z.string().nullable(),
  flatType: z.string().nullable(),
  flatNumber: z.string().nullable(),
  levelType: z.string().nullable(),
  levelNumber: z.string().nullable(),
  numberFirst: z.string().nullable(),
  numberLast: z.string().nullable(),
  lotNumber: z.string().nullable(),
  streetName: z.string(),
  streetType: z.string().nullable(),
  streetSuffix: z.string().nullable(),
  localityName: z.string(),
  state: z.string(),
  postcode: z.string().nullable(),
  legalParcelId: z.string().nullable(),
  confidence: z.number().int().min(0).max(2),
  aliasPrincipal: z.enum(["PRINCIPAL", "ALIAS"]),
  primarySecondary: z.enum(["PRIMARY", "SECONDARY"]).nullable(),
  geocode: GeocodeSchema.nullable(),
  // Optional for readers of schema 1.0.0; every 1.1.0 writer emits object or null.
  fallbackGeocode: FallbackGeocodeSchema.nullable().optional(),
  location: LocationSchema.nullable(),
  allGeocodes: z.array(AllGeocodesItemSchema),
  locality: LocalitySchema,
  street: StreetSchema,
  boundaries: BoundariesSchema,
  aliases: z.array(AliasSchema),
  secondaries: z.array(SecondarySchema),
});

/** Stricter producer contract; keep the reader compatible with historical documents. */
export const AddressDocumentWriterSchema = AddressDocumentSchema.extend({
  fallbackGeocode: FallbackGeocodeSchema.nullable(),
}).superRefine((doc, ctx) => {
  const issue = (path: string[], message: string) =>
    ctx.addIssue({ code: "custom", path, message });
  if (doc.geocode) {
    if (
      !doc.allGeocodes.some(
        (point) =>
          point.lat === doc.geocode?.latitude &&
          point.lng === doc.geocode.longitude &&
          point.type === doc.geocode.type &&
          point.reliability === doc.geocode.reliability,
      )
    )
      issue(["geocode"], "Selected site point must occur in allGeocodes");
    if (doc.fallbackGeocode !== null)
      issue(["fallbackGeocode"], "A site point excludes a fallback");
    if (doc.location?.lat !== doc.geocode.latitude || doc.location?.lon !== doc.geocode.longitude)
      issue(["location"], "Location must copy the selected site point");
  } else if (doc.location !== null || doc.allGeocodes.length !== 0) {
    issue(["geocode"], "Missing site point requires null location and no site geocodes");
  }
  for (const point of [
    ...(doc.geocode ? [{ lat: doc.geocode.latitude, lng: doc.geocode.longitude }] : []),
    ...doc.allGeocodes,
  ]) {
    if (point.lat < -44 || point.lat > -9 || point.lng < 96 || point.lng > 168)
      issue(["geocode"], "Site point lies outside the supported Australian bounds");
  }
  if (doc.fallbackGeocode) {
    const code = doc.fallbackGeocode.typeCode;
    const precision = code === "STL" ? "street" : code === "LOC" ? "locality" : "unknown";
    if (doc.fallbackGeocode.precision !== precision)
      issue(["fallbackGeocode", "precision"], "Precision must follow the source type code");
  }
});

// --- Locality-only document schema ---

export const LocalityDocumentSchema = z.object({
  _id: z.string(),
  _version: z.string(),
  localityName: z.string(),
  state: z.string(),
  postcode: z.string().nullable(),
  class: z.string(),
  neighbours: z.array(z.string()),
  aliases: z.array(z.string()),
  latitude: z.number().nullable(),
  longitude: z.number().nullable(),
});

// --- Inferred TypeScript types ---

export type FallbackGeocode = z.infer<typeof FallbackGeocodeSchema>;
export type Geocode = z.infer<typeof GeocodeSchema>;
export type Location = z.infer<typeof LocationSchema>;
export type AllGeocodesItem = z.infer<typeof AllGeocodesItemSchema>;
export type Locality = z.infer<typeof LocalitySchema>;
export type Street = z.infer<typeof StreetSchema>;
export type Boundaries = z.infer<typeof BoundariesSchema>;
export type Alias = z.infer<typeof AliasSchema>;
export type Secondary = z.infer<typeof SecondarySchema>;
export type AddressDocument = z.infer<typeof AddressDocumentSchema>;
export type LocalityDocument = z.infer<typeof LocalityDocumentSchema>;
