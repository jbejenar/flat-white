#!/usr/bin/env node

import { execFileSync } from "node:child_process";
import { createReadStream } from "node:fs";
import { appendFile, mkdir, readFile, rm, writeFile } from "node:fs/promises";
import { basename, join, resolve } from "node:path";
import { createInterface } from "node:readline";
import { createGunzip } from "node:zlib";
import { compress } from "../dist/compress.js";
import { buildAddressManifestV2, validateAddressManifestV2 } from "../dist/manifest.js";
import { writeMetadata } from "../dist/metadata.js";
import { split } from "../dist/split.js";

const DEFAULT_VERSION = "2026.02";

function parseArgs(argv) {
  const args = {
    input: "output/fixture.ndjson",
    assetDir: "output/quarterly-fixture-assets",
    version: DEFAULT_VERSION,
  };

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === "--input") {
      args.input = argv[++i];
    } else if (arg === "--asset-dir") {
      args.assetDir = argv[++i];
    } else if (arg === "--version") {
      args.version = argv[++i];
    } else {
      throw new Error(`Unknown argument: ${arg}`);
    }
  }

  return args;
}

async function concatenateGzipFiles(inputPaths, outputPath) {
  await writeFile(outputPath, "");
  for (const inputPath of inputPaths) {
    await appendFile(outputPath, await readFile(inputPath));
  }
}

async function countGzipLines(path) {
  let count = 0;
  const rl = createInterface({
    input: createReadStream(path).pipe(createGunzip()),
    crlfDelay: Infinity,
  });

  for await (const line of rl) {
    if (line.trim()) {
      count += 1;
    }
  }

  return count;
}

function resolveGnafLoaderVersion() {
  try {
    return execFileSync("git", ["-C", "gnaf-loader", "rev-parse", "--short", "HEAD"], {
      encoding: "utf-8",
    }).trim();
  } catch {
    return "unknown";
  }
}

async function manifestFileForPath({ gzipPath, key, records }) {
  return {
    key,
    records,
    bytes: (await readFile(gzipPath)).byteLength,
    sha256: execFileSync("sha256sum", [gzipPath], { encoding: "utf-8" }).split(/\s+/)[0],
  };
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const inputPath = resolve(args.input);
  const assetDir = resolve(args.assetDir);
  const versionDash = args.version.replaceAll(".", "-");
  const packageJson = JSON.parse(
    await readFile(new URL("../package.json", import.meta.url), "utf-8"),
  );

  await rm(assetDir, { recursive: true, force: true });
  await mkdir(assetDir, { recursive: true });

  const splitResult = await split({
    inputPath,
    outputDir: assetDir,
    version: args.version,
  });

  const compressedFiles = [];
  for (const outputFile of splitResult.outputFiles) {
    const gzipPath = `${outputFile}.gz`;
    await compress({ inputPath: outputFile, outputPath: gzipPath });
    await rm(outputFile);
    compressedFiles.push(gzipPath);
  }

  compressedFiles.sort();
  const allFile = join(assetDir, `flat-white-${args.version}-all.ndjson.gz`);
  await concatenateGzipFiles(compressedFiles, allFile);

  const manifestFiles = await Promise.all(compressedFiles.map(async (gzipPath) => {
    const state = basename(gzipPath).match(/-([a-z]+)\.ndjson\.gz$/)?.[1];
    if (state == null) {
      throw new Error(`Could not derive state key from ${gzipPath}`);
    }

    const stateUpper = state.toUpperCase();
    const records = splitResult.states[stateUpper];
    if (records == null) {
      throw new Error(`Missing split record count for ${stateUpper}`);
    }

    return manifestFileForPath({
      gzipPath,
      key: `data/address/${versionDash}/${state}.ndjson.gz`,
      records,
    });
  }));

  manifestFiles.push(
    await manifestFileForPath({
      gzipPath: allFile,
      key: `data/address/${versionDash}/all.ndjson.gz`,
      records: splitResult.totalCount,
    }),
  );

  const metadata = await writeMetadata({
    ndjsonPath: inputPath,
    version: args.version,
    schemaVersion: packageJson.version,
    gnafLoaderVersion: resolveGnafLoaderVersion(),
    outputFiles: [...compressedFiles.map((path) => basename(path)), basename(allFile)],
    outputPath: join(assetDir, "metadata.json"),
  });

  const totalFromAll = await countGzipLines(allFile);
  if (totalFromAll !== metadata.totalCount) {
    throw new Error(
      `All-states gzip count mismatch: got ${totalFromAll}, expected ${metadata.totalCount}`,
    );
  }

  const states = Object.keys(splitResult.states).sort();

  const manifest = buildAddressManifestV2({
    version: versionDash,
    createdAt: new Date().toISOString(),
    pipeline: {
      repo: "fixture/quarterly-shape-smoke",
      commit: "fixture",
      run_id: "fixture",
    },
    source: {
      name: "G-NAF",
      release: "Fixture",
      url: "https://data.gov.au/dataset/geocoded-national-address-file-g-naf",
    },
    files: manifestFiles,
    sourceKeys: [`data/address/${versionDash}/all.ndjson.gz`],
  });
  validateAddressManifestV2(manifest, [`data/address/${versionDash}/all.ndjson.gz`]);
  await writeFile(join(assetDir, "manifest.json"), JSON.stringify(manifest, null, 2) + "\n");

  // Boundary coverage thresholds for the FIXTURE shape smoke. The committed
  // fixture sits at 100% on every boundary type except ward (99.6%, two
  // edge-case addresses fall outside any ward polygon by design — see
  // fixtures/edge-cases.md). Thresholds are set tight enough that any
  // regression that drops a boundary type entirely will fail the smoke,
  // while still passing the legitimate fixture state.
  //
  // This is the gate that catches an `address_full_prep.sql` change that
  // silently breaks LGA tagging — the v2026.04 incident class — at PR time.
  const FIXTURE_BOUNDARY_THRESHOLDS =
    "lga=99,ward=99,stateElectorate=99,commonwealthElectorate=99,meshBlock=99,sa1=99,sa2=99";

  execFileSync(
    "node",
    [
      "dist/verification-report.js",
      assetDir,
      "--output",
      join(assetDir, "verification-report.md"),
      "--states",
      states.join(","),
      "--boundary-thresholds",
      FIXTURE_BOUNDARY_THRESHOLDS,
    ],
    { stdio: "inherit" },
  );
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
});
