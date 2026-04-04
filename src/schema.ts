/**
 * flat-white — Address document Zod schema and TypeScript types.
 *
 * This schema IS the contract. It must match docs/DOCUMENT-SCHEMA.md exactly.
 * When changing the schema, update both files together (see AGENTS.md rule 3).
 */

import { z } from "zod";

// --- Nested schemas ---

export const GeocodeSchema = z.object({
  latitude: z.number(),
  longitude: z.number(),
  type: z.string(),
  reliability: z.number().int().min(1).max(6),
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

export const BoundariesSchema = z.object({
  lga: NameCodeSchema.nullable(),
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
});

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
  allGeocodes: z.array(AllGeocodesItemSchema),
  locality: LocalitySchema,
  street: StreetSchema,
  boundaries: BoundariesSchema,
  aliases: z.array(AliasSchema),
  secondaries: z.array(SecondarySchema),
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

export type Geocode = z.infer<typeof GeocodeSchema>;
export type AllGeocodesItem = z.infer<typeof AllGeocodesItemSchema>;
export type Locality = z.infer<typeof LocalitySchema>;
export type Street = z.infer<typeof StreetSchema>;
export type Boundaries = z.infer<typeof BoundariesSchema>;
export type Alias = z.infer<typeof AliasSchema>;
export type Secondary = z.infer<typeof SecondarySchema>;
export type AddressDocument = z.infer<typeof AddressDocumentSchema>;
export type LocalityDocument = z.infer<typeof LocalityDocumentSchema>;
