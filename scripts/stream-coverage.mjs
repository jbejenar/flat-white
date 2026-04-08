#!/usr/bin/env node
// Stream a per-state ndjson file and report boundary coverage percentages.
// Usage: node scripts/stream-coverage.mjs <state> <path>
import { createReadStream } from "node:fs";
import { createInterface } from "node:readline";

const [, , state, path] = process.argv;
if (!state || !path) {
  console.error("usage: node scripts/stream-coverage.mjs <state> <path>");
  process.exit(1);
}

let total = 0;
const c = { lga: 0, ward: 0, stateElectorate: 0, commonwealthElectorate: 0, meshBlock: 0, sa1: 0, sa2: 0 };

const rl = createInterface({ input: createReadStream(path), crlfDelay: Infinity });
for await (const line of rl) {
  if (!line.trim()) continue;
  total++;
  const d = JSON.parse(line);
  const b = d.boundaries || {};
  for (const k of Object.keys(c)) if (b[k]) c[k]++;
}

console.log(`${state} total: ${total}`);
for (const [k, v] of Object.entries(c)) {
  const pct = (v / total) * 100;
  console.log(`  ${k}: ${v} (${pct.toFixed(2)}%)`);
}
