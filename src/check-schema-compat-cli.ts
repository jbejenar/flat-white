/**
 * CLI entry point for schema compatibility checking.
 *
 * Compares current Zod schemas against fixtures/schema-baseline.json.
 * Exits 0 if no changes or non-breaking only; exits 1 if breaking.
 *
 * Usage: node dist/check-schema-compat-cli.js
 */

import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { toJSONSchema } from "zod";
import { AddressDocumentSchema, LocalityDocumentSchema } from "./schema.js";
import { compareSnapshots, type SchemaSnapshot } from "./schema-compat.js";

const baselinePath = resolve(import.meta.dirname ?? ".", "../fixtures/schema-baseline.json");

let baseline: SchemaSnapshot;
try {
  baseline = JSON.parse(readFileSync(baselinePath, "utf-8")) as SchemaSnapshot;
} catch {
  console.error(
    `ERROR: Cannot read schema baseline at ${baselinePath}\n` +
      "Run: npm run build && node dist/generate-schema-baseline.js",
  );
  process.exit(1);
}

const current: SchemaSnapshot = {
  generatedAt: new Date().toISOString(),
  schemas: {
    AddressDocument: toJSONSchema(AddressDocumentSchema) as Record<string, unknown>,
    LocalityDocument: toJSONSchema(LocalityDocumentSchema) as Record<string, unknown>,
  },
};

const result = compareSnapshots(baseline, current);

if (result.breaking.length === 0 && result.nonBreaking.length === 0) {
  console.log("Schema compatibility check: no changes detected.");
  process.exit(0);
}

if (result.nonBreaking.length > 0) {
  console.log("Non-breaking schema changes:");
  for (const change of result.nonBreaking) {
    console.log(`  + ${change.path}: ${change.description}`);
  }
}

if (result.breaking.length > 0) {
  console.error("\nBREAKING schema changes detected:");
  for (const change of result.breaking) {
    console.error(`  ✗ ${change.path}: ${change.description}`);
  }
  console.error(
    "\nTo proceed with breaking changes:\n" +
      "  1. Bump the major version in package.json\n" +
      "  2. Update docs/DOCUMENT-SCHEMA.md\n" +
      "  3. Update fixtures/expected-output.ndjson\n" +
      "  4. Regenerate baseline: npm run build && node dist/generate-schema-baseline.js\n",
  );
  process.exit(1);
}

console.log("\nSchema compatibility check passed (non-breaking changes only).");
process.exit(0);
