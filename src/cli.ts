/**
 * flat-white — CLI argument parser and validator.
 *
 * Parses command-line flags for the flat-white pipeline.
 * Used by the TypeScript build orchestrator and tested independently.
 * The Docker entrypoint (bash) has its own parser that mirrors these flags.
 */

/** Supported output formats. */
export type OutputFormat = "ndjson" | "parquet" | "geoparquet";

/** Parsed CLI options for the flat-white pipeline. */
export interface CliOptions {
  /** Show help and exit */
  help: boolean;
  /** Run fixture build only (no download, no gnaf-loader) */
  fixtureOnly: boolean;
  /** States to process (e.g. ["VIC", "NSW"]) */
  states: string[];
  /** Output directory (default: /output) */
  outputDir: string;
  /** Output format (default: ndjson) */
  format: OutputFormat;
  /** Gzip output files */
  compress: boolean;
  /** Split output into per-state files */
  splitStates: boolean;
  /** Skip data download (assumes data already available) */
  skipDownload: boolean;
  /** Path to extracted G-NAF data */
  gnafPath: string | null;
  /** Path to extracted Admin Boundaries data */
  adminPath: string | null;
}

const VALID_FORMATS: readonly OutputFormat[] = ["ndjson", "parquet", "geoparquet"];

const DEFAULT_OPTIONS: CliOptions = {
  help: false,
  fixtureOnly: false,
  states: [],
  outputDir: "/output",
  format: "ndjson",
  compress: false,
  splitStates: false,
  skipDownload: false,
  gnafPath: null,
  adminPath: null,
};

/**
 * Parse CLI arguments into a structured CliOptions object.
 * Throws on unknown flags.
 */
export function parseArgs(argv: string[]): CliOptions {
  const opts: CliOptions = { ...DEFAULT_OPTIONS, states: [] };

  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    switch (arg) {
      case "--help":
      case "-h":
        opts.help = true;
        break;
      case "--fixture-only":
        opts.fixtureOnly = true;
        break;
      case "--states": {
        i++;
        if (i >= argv.length || argv[i].startsWith("--")) {
          throw new CliError("--states requires at least one value");
        }
        // Collect state values until next flag or end
        while (i < argv.length && !argv[i].startsWith("--")) {
          opts.states.push(argv[i].toUpperCase());
          i++;
        }
        i--; // Back up so the outer loop's i++ lands on the next flag
        break;
      }
      case "--output": {
        i++;
        if (i >= argv.length || argv[i].startsWith("--")) {
          throw new CliError("--output requires a directory path");
        }
        opts.outputDir = argv[i];
        break;
      }
      case "--format": {
        i++;
        if (i >= argv.length || argv[i].startsWith("--")) {
          throw new CliError(`--format requires a value (${VALID_FORMATS.join(", ")})`);
        }
        const fmt = argv[i].toLowerCase();
        if (!VALID_FORMATS.includes(fmt as OutputFormat)) {
          throw new CliError(
            `Invalid format "${argv[i]}". Valid formats: ${VALID_FORMATS.join(", ")}`,
          );
        }
        opts.format = fmt as OutputFormat;
        break;
      }
      case "--compress":
        opts.compress = true;
        break;
      case "--split-states":
        opts.splitStates = true;
        break;
      case "--skip-download":
        opts.skipDownload = true;
        break;
      case "--gnaf-path": {
        i++;
        if (i >= argv.length || argv[i].startsWith("--")) {
          throw new CliError("--gnaf-path requires a file path");
        }
        opts.gnafPath = argv[i];
        break;
      }
      case "--admin-path": {
        i++;
        if (i >= argv.length || argv[i].startsWith("--")) {
          throw new CliError("--admin-path requires a file path");
        }
        opts.adminPath = argv[i];
        break;
      }
      default:
        throw new CliError(`Unknown argument: ${arg}\nRun with --help for usage.`);
    }
  }

  return opts;
}

/**
 * Validate parsed CLI options for invalid combinations.
 * Throws CliError with a helpful message on invalid input.
 */
export function validateArgs(opts: CliOptions): void {
  if (opts.help) return; // Skip validation when showing help

  if (opts.fixtureOnly && opts.skipDownload) {
    throw new CliError(
      "--fixture-only and --skip-download are mutually exclusive. " +
        "Fixture mode does not download data.",
    );
  }

  if (opts.skipDownload && (!opts.gnafPath || !opts.adminPath)) {
    throw new CliError(
      "--skip-download requires --gnaf-path and --admin-path to locate pre-downloaded data.",
    );
  }

  if (opts.fixtureOnly && opts.splitStates) {
    throw new CliError(
      "--fixture-only and --split-states are mutually exclusive. " +
        "Fixture output is a single file.",
    );
  }

  if (opts.fixtureOnly && opts.states.length > 0) {
    throw new CliError(
      "--fixture-only and --states are mutually exclusive. " +
        "Fixture mode uses committed test data, not state-specific data.",
    );
  }
}

/** Error class for CLI argument issues. */
export class CliError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "CliError";
  }
}

/** Help text for the flat-white CLI. */
export const HELP_TEXT = `flat-white — Australian address data, flattened and served.

Usage:
  docker run flat-white --help
  docker run flat-white --fixture-only --output /output/
  docker run -v $(pwd)/output:/output flat-white --states VIC --compress --output /output/

Flags:
  --help, -h          Show this help
  --fixture-only      Run fixture build only (no download, no gnaf-loader)
  --states STATES     States to process (e.g. VIC, VIC NSW)
  --output DIR        Output directory (default: /output)
  --format FORMAT     Output format: ndjson (default), parquet, or geoparquet
  --compress          Gzip output files
  --split-states      Split output into per-state files
  --skip-download     Skip data download (assumes data at --gnaf-path / --admin-path)
  --gnaf-path PATH    Path to extracted G-NAF data
  --admin-path PATH   Path to extracted Admin Boundaries data

Exit codes:
  0   Success
  1   Download failed
  2   gnaf-loader (data load) failed
  3   Flatten failed
  4   Verification failed
  5   Output write failed (split/compress)
  10  Infrastructure failure (e.g. Postgres did not start)

Pipeline stages:
  1. Start Postgres (internal)
  2. Download G-NAF + Admin Boundaries (or --skip-download / --fixture-only)
  3. Run gnaf-loader to load data into Postgres (or seed fixtures)
  4. Flatten: stream Postgres → NDJSON
  5. Verify output (row count, schema, data quality)
  6. Split per-state (if --split-states)
  7. Compress (if --compress)
  8. Stop Postgres
`;
