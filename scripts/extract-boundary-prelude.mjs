#!/usr/bin/env node

import { readFileSync } from "node:fs";
import { resolve } from "node:path";

const START_MARKER = "-- FIXTURE_BOUNDARY_PRELUDE_START";
const END_MARKER = "-- FIXTURE_BOUNDARY_PRELUDE_END";

export function extractBoundaryPrelude(sqlText) {
  const start = sqlText.indexOf(START_MARKER);
  if (start === -1) {
    throw new Error(`Missing start marker: ${START_MARKER}`);
  }

  const end = sqlText.indexOf(END_MARKER, start);
  if (end === -1) {
    throw new Error(`Missing end marker: ${END_MARKER}`);
  }

  const afterStart = sqlText.indexOf("\n", start);
  if (afterStart === -1) {
    throw new Error("Start marker must be followed by SQL content");
  }

  return sqlText.slice(afterStart + 1, end).trimEnd() + "\n";
}

function main() {
  const inputPath = process.argv[2] ?? resolve("sql", "address_full_prep.sql");
  const sqlText = readFileSync(inputPath, "utf8");
  process.stdout.write(extractBoundaryPrelude(sqlText));
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}
