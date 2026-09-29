#!/usr/bin/env node

import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";

// Exercise the pinned upstream transformation against our tiny raw census
// fixture. Do not maintain a second copy of its table/column mapping.
export function extractCensusPrep(sqlText, schemaVersion) {
  if (!/^\d{6}$/.test(schemaVersion)) throw new Error("Expected a six-digit schema version");
  const end = sqlText.indexOf("\n-- # ");
  if (end === -1) throw new Error("Missing upstream census SQL section boundary");
  const sql = sqlText.slice(0, end);
  if (
    !sql.includes("CREATE TABLE admin_bdys.abs_2026_mb AS") ||
    !sql.includes("FROM raw_admin_bdys.aus_mb_2026;")
  ) {
    throw new Error("Unexpected upstream ABS 2026 mesh-block SQL");
  }
  return (
    sql
      .replaceAll("raw_admin_bdys.", `raw_admin_bdys_${schemaVersion}.`)
      .replaceAll("admin_bdys.", `admin_bdys_${schemaVersion}.`) + "\n"
  );
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const sql = readFileSync(
    new URL(
      "../gnaf-loader/postgres-scripts/02-02e-prep-census-2026-bdys-tables.sql",
      import.meta.url,
    ),
    "utf8",
  );
  process.stdout.write(extractCensusPrep(sql, process.argv[2] ?? "202602"));
}
