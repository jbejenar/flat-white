/**
 * flat-white — gnaf-loader wrapper.
 *
 * Spawns gnaf-loader (Python) as a child process to load G-NAF and
 * Administrative Boundaries into local Postgres. Streams output in
 * real time, validates prerequisites, and exits non-zero on failure.
 *
 * Usage:
 *   node dist/load.js --states VIC
 *   node dist/load.js --states VIC NSW --max-processes 8
 *
 * Or as a module:
 *   import { load } from './load.js';
 *   await load({ states: ['VIC'], dataDir: './data' });
 */

import { existsSync, readdirSync } from "node:fs";
import { resolve, relative, join, dirname } from "node:path";
import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const PROJECT_ROOT = resolve(__dirname, "..");

// --- Configuration ---

export interface LoadOptions {
  /** States to load (e.g. ['VIC']). Omit for all states. */
  states?: string[];
  /** Data directory containing extracted G-NAF and Admin Boundaries. Default: ./data */
  dataDir?: string;
  /** Postgres connection */
  pgHost?: string;
  pgPort?: number;
  pgDb?: string;
  pgUser?: string;
  pgPassword?: string;
  /** Geoscape version string, e.g. '202602' */
  geoscapeVersion?: string;
  /** Coordinate reference system. Default: 7844 (GDA2020) */
  srid?: number;
  /** Max parallel processes for gnaf-loader. Default: 4 */
  maxProcesses?: number;
  /** Skip gnaf-loader boundary tagging and rely on flat-white's SQL fallback. */
  noBoundaryTag?: boolean;
  /**
   * The path the Postgres SERVER sees for the data directory.
   * When Postgres runs in Docker with ./data mounted as /data,
   * this should be '/data'. Default: '/data' (assumes docker-compose mount).
   */
  serverDataDir?: string;
}

const VALID_STATES = ["ACT", "NSW", "NT", "OT", "QLD", "SA", "TAS", "VIC", "WA"];

/**
 * Derive the 6-digit geoscape version from GNAF_VERSION env var.
 * e.g. GNAF_VERSION="2026.05" → "202605"
 * Returns null if GNAF_VERSION is not set.
 */
/**
 * Validate that a geoscape version string is exactly 6 digits (YYYYMM).
 * Throws if the format is invalid.
 */
function validateGeoscapeVersion(v: string): string {
  if (!/^\d{6}$/.test(v)) {
    throw new Error(`--geoscape-version must be a 6-digit YYYYMM string (got "${v}")`);
  }
  return v;
}

export function deriveGeoscapeVersion(): string | null {
  const gnafVersion = process.env.GNAF_VERSION;
  if (!gnafVersion) return null;
  const stripped = gnafVersion.replace(/\./g, "");
  if (!/^\d{6}$/.test(stripped)) return null;
  return stripped;
}

/**
 * Resolve the G-NAF PSV tables path from the data directory.
 * gnaf-loader uses os.walk() and needs the parent directory that contains
 * BOTH "Standard/" (state PSV files) and "Authority Code/" (authority tables).
 * Structure: data/G-NAF/G-NAF FEBRUARY 2026/{Standard/,Authority Code/}
 */
export function resolveGnafTablesPath(dataDir: string): string {
  const base = resolve(dataDir, "G-NAF");
  if (!existsSync(base)) throw new Error(`G-NAF directory not found: ${base}`);

  // Find the versioned subdirectory (e.g. "G-NAF FEBRUARY 2026")
  const entries = readdirSync(base).filter((e) => e.startsWith("G-NAF "));
  if (entries.length === 0) throw new Error(`No G-NAF version directory found in ${base}`);

  const versionPath = resolve(base, entries[0]);
  const standardPath = resolve(versionPath, "Standard");
  if (!existsSync(standardPath))
    throw new Error(`G-NAF Standard directory not found: ${standardPath}`);

  // Return the parent (version dir) — gnaf-loader walks subdirectories to find both
  // Standard/ PSV files and Authority Code/ files
  return versionPath;
}

/**
 * Resolve the Admin Boundaries shapefile path from the data directory.
 */
export function resolveAdminBdysPath(dataDir: string): string {
  const entries = readdirSync(dataDir).filter(
    (e) => e.includes("AdminBounds") && !e.endsWith(".zip"),
  );
  if (entries.length === 0) throw new Error(`Admin Boundaries directory not found in ${dataDir}`);

  return resolve(dataDir, entries[0]);
}

/**
 * Build the gnaf-loader CLI arguments.
 */
export function buildArgs(opts: LoadOptions): string[] {
  const dataDir = resolve(opts.dataDir ?? resolve(PROJECT_ROOT, "data"));
  const gnafTablesPath = resolveGnafTablesPath(dataDir);
  const adminBdysPath = resolveAdminBdysPath(dataDir);

  const args: string[] = [
    resolve(PROJECT_ROOT, "gnaf-loader", "load-gnaf.py"),
    "--pghost",
    opts.pgHost ?? "localhost",
    "--pgport",
    String(opts.pgPort ?? 5432),
    "--pgdb",
    opts.pgDb ?? "gnaf",
    "--pguser",
    opts.pgUser ?? "postgres",
    "--geoscape-version",
    validateGeoscapeVersion(
      opts.geoscapeVersion ??
        deriveGeoscapeVersion() ??
        (() => {
          throw new Error(
            "Geoscape version is required. Set GNAF_VERSION env var (e.g. GNAF_VERSION=2026.05) " +
              "or pass --geoscape-version YYYYMM.",
          );
        })(),
    ),
    "--srid",
    String(opts.srid ?? 7844),
    "--max-processes",
    String(opts.maxProcesses ?? 4),
    "--gnaf-tables-path",
    gnafTablesPath,
    "--admin-bdys-path",
    adminBdysPath,
  ];

  // Only remap paths when Postgres runs in a separate container (docker-compose).
  // When Postgres is local (self-contained Docker image), paths are the same.
  if (opts.serverDataDir) {
    const relativeGnafPath = relative(dataDir, gnafTablesPath);
    args.push("--local-server-dir", join(opts.serverDataDir, relativeGnafPath));
  }

  if (opts.states && opts.states.length > 0) {
    args.push("--states", ...opts.states);
  }

  if (opts.noBoundaryTag) {
    args.push("--no-boundary-tag");
  }

  return args;
}

/**
 * Validate prerequisites before running gnaf-loader.
 */
async function validatePrerequisites(opts: LoadOptions): Promise<void> {
  const dataDir = resolve(opts.dataDir ?? resolve(PROJECT_ROOT, "data"));

  // Check gnaf-loader exists
  const loaderPath = resolve(PROJECT_ROOT, "gnaf-loader", "load-gnaf.py");
  if (!existsSync(loaderPath)) {
    throw new Error(`gnaf-loader not found at ${loaderPath}. Run: git submodule update --init`);
  }

  // Check data directory exists
  if (!existsSync(dataDir)) {
    throw new Error(`Data directory not found: ${dataDir}. Run: node dist/download.js`);
  }

  // Validate state codes
  if (opts.states) {
    for (const state of opts.states) {
      if (!VALID_STATES.includes(state)) {
        throw new Error(`Invalid state code: ${state}. Valid: ${VALID_STATES.join(", ")}`);
      }
    }
  }

  // Resolve paths (throws if not found)
  resolveGnafTablesPath(dataDir);
  resolveAdminBdysPath(dataDir);
}

/**
 * Run gnaf-loader to load G-NAF and Admin Boundaries into Postgres.
 */
export async function load(opts: LoadOptions = {}): Promise<void> {
  await validatePrerequisites(opts);

  const args = buildArgs(opts);
  const statesLabel = opts.states?.join(", ") ?? "ALL";

  console.log(`[load] Starting gnaf-loader for states: ${statesLabel}`);
  console.log(`[load] Python: python3 ${args.join(" ")}`);

  const startTime = Date.now();

  return new Promise<void>((resolve, reject) => {
    const child = spawn("python3", args, {
      cwd: PROJECT_ROOT,
      stdio: ["ignore", "pipe", "pipe"],
      env: { ...process.env, PGPASSWORD: opts.pgPassword ?? "postgres" },
    });

    child.stdout.on("data", (data: Buffer) => {
      process.stdout.write(data);
    });

    child.stderr.on("data", (data: Buffer) => {
      process.stderr.write(data);
    });

    child.on("error", (err) => {
      reject(new Error(`Failed to start gnaf-loader: ${err.message}`));
    });

    child.on("close", (code) => {
      const elapsed = ((Date.now() - startTime) / 1000 / 60).toFixed(1);
      if (code === 0) {
        console.log(`[load] gnaf-loader completed successfully in ${elapsed} minutes`);
        resolve();
      } else {
        reject(new Error(`gnaf-loader exited with code ${code} after ${elapsed} minutes`));
      }
    });
  });
}

// --- CLI entrypoint ---

async function main(): Promise<void> {
  const args = process.argv.slice(2);
  const opts: LoadOptions = {};

  for (let i = 0; i < args.length; i++) {
    switch (args[i]) {
      case "--states": {
        opts.states = [];
        while (i + 1 < args.length && !args[i + 1].startsWith("--")) {
          opts.states.push(args[++i]);
        }
        break;
      }
      case "--data-dir":
        opts.dataDir = args[++i];
        break;
      case "--max-processes":
        opts.maxProcesses = Number(args[++i]);
        break;
      case "--pghost":
        opts.pgHost = args[++i];
        break;
      case "--pgport":
        opts.pgPort = Number(args[++i]);
        break;
      case "--pgdb":
        opts.pgDb = args[++i];
        break;
      case "--geoscape-version": {
        const v = args[++i];
        if (!/^\d{6}$/.test(v)) {
          throw new Error(`--geoscape-version must be a 6-digit YYYYMM string (got "${v}")`);
        }
        opts.geoscapeVersion = v;
        break;
      }
      case "--server-data-dir":
        opts.serverDataDir = args[++i];
        break;
      case "--no-boundary-tag":
        opts.noBoundaryTag = true;
        break;
      default:
        console.error(`Unknown argument: ${args[i]}`);
        process.exit(1);
    }
  }

  try {
    await load(opts);
  } catch (err) {
    console.error(`[load] ERROR: ${(err as Error).message}`);
    process.exit(1);
  }
}

// Only run CLI when this module is the entry point (not when imported as a library)
if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main();
}
