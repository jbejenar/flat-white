/** Reconcile raw eligible principals -> loaded principals -> exported PIDs. */
import postgres from "postgres";
import { writeFile } from "node:fs/promises";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { deriveSchemaVersion } from "./flatten.js";
import { PidLedger, pidLines, comparePidLedgers } from "./pid-ledger.js";

export async function reconcile(options: {
  connectionString: string;
  version: string;
  outputPath: string;
}) {
  const version = deriveSchemaVersion(options.version);
  const sql = postgres(options.connectionString, { max: 1, max_lifetime: null });
  const ledgers: PidLedger[] = [];
  try {
    for (let i = 0; i < 3; i++) ledgers.push(await PidLedger.create());
    const [raw, loaded, output] = ledgers;
    const queries = [
      `SELECT address_detail_pid AS pid FROM raw_gnaf_${version}.address_detail
       WHERE confidence >= 0 AND alias_principal = 'P' AND date_retired IS NULL`,
      `SELECT gnaf_pid AS pid FROM gnaf_${version}.address_principals`,
    ];
    for (const [index, query] of queries.entries()) {
      for await (const batch of sql.unsafe(query).cursor(1000)) {
        for (const row of batch) await ledgers[index].add(row.pid as string);
      }
    }
    for await (const line of pidLines(options.outputPath)) {
      if (!line.trim()) continue;
      const doc: unknown = JSON.parse(line);
      if (
        typeof doc !== "object" ||
        doc === null ||
        !("_id" in doc) ||
        typeof doc._id !== "string"
      ) {
        throw new Error("Output document has no string PID");
      }
      await output.add(doc._id);
    }
    const summaries = [];
    for (const ledger of ledgers) summaries.push(await ledger.finish());
    const sourceToLoaded = await comparePidLedgers(raw, loaded);
    const loadedToOutput = await comparePidLedgers(loaded, output);
    const passed =
      summaries[0].count > 0 &&
      summaries.every((s) => s.duplicateCount === 0) &&
      [sourceToLoaded, loadedToOutput].every((r) => r.missing === 0 && r.unexpected === 0);
    return {
      version: options.version,
      passed,
      raw: summaries[0],
      loaded: summaries[1],
      output: summaries[2],
      sourceToLoaded,
      loadedToOutput,
    };
  } finally {
    await Promise.all(ledgers.map((ledger) => ledger.close()));
    await sql.end();
  }
}

async function main(): Promise<void> {
  const outputPath = process.argv[2];
  const connectionString = process.env.DATABASE_URL;
  if (!outputPath || !connectionString)
    throw new Error("reconcile requires an NDJSON path and DATABASE_URL");
  const report = await reconcile({
    connectionString,
    outputPath,
    version: process.env.GNAF_VERSION ?? "2026.02",
  });
  await writeFile(outputPath + ".reconciliation.json", JSON.stringify(report, null, 2) + "\n");
  console.log(
    `PID reconciliation: ${report.passed ? "PASS" : "FAIL"} (${report.raw.count} raw, ${report.loaded.count} loaded, ${report.output.count} output)`,
  );
  if (!report.passed) throw new Error(JSON.stringify(report));
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main().catch((error: unknown) => {
    console.error(error);
    process.exitCode = 1;
  });
}
