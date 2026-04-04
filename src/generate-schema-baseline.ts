/**
 * Generate schema-baseline.json from the current Zod schemas.
 *
 * Usage: node dist/generate-schema-baseline.js
 */

import { writeFileSync } from "node:fs";
import { resolve } from "node:path";
import { toJSONSchema } from "zod";
import { AddressDocumentSchema, LocalityDocumentSchema } from "./schema.js";
import type { SchemaSnapshot } from "./schema-compat.js";

const snapshot: SchemaSnapshot = {
  generatedAt: new Date().toISOString(),
  schemas: {
    AddressDocument: toJSONSchema(AddressDocumentSchema) as Record<string, unknown>,
    LocalityDocument: toJSONSchema(LocalityDocumentSchema) as Record<string, unknown>,
  },
};

const outPath = resolve(import.meta.dirname ?? ".", "../fixtures/schema-baseline.json");
writeFileSync(outPath, JSON.stringify(snapshot, null, 2) + "\n");
console.log(`Schema baseline written to ${outPath}`);
