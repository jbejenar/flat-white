#!/usr/bin/env bash
set -euo pipefail

# flat-white Docker entrypoint
#
# Orchestrates the full pipeline:
#   start Postgres → download → gnaf-loader → flatten → verify → output → stop Postgres
#
# Exit codes (P2.04):
#   0   Success
#   1   Download failed
#   2   gnaf-loader failed
#   3   Flatten failed
#   4   Verification failed
#   5   Output write failed (split/compress/metadata)
#   10  Infrastructure failure (e.g. Postgres did not start)

PGDATA="${PGDATA:-/var/lib/postgresql/data}"
PGUSER="${POSTGRES_USER:-postgres}"
PGPASSWORD="${POSTGRES_PASSWORD:-postgres}"
PGDB="${POSTGRES_DB:-gnaf}"

# ── Logging helpers ──────────────────────────────────────────────────────────
# Structured JSON logs to stderr (human-readable via message field, machine-parseable via jq)

log_json() {
  local stage="$1" event="$2" message="$3"
  shift 3
  local extra=""
  while [[ $# -gt 0 ]]; do
    extra="${extra},\"$1\":$2"
    shift 2
  done
  echo "{\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"stage\":\"${stage}\",\"event\":\"${event}\",\"message\":\"${message}\"${extra}}" >&2
}

log() { echo "[entrypoint] $*"; }

stage_start() {
  STAGE_NAME="$1"
  STAGE_START=$(date +%s)
  log_json "$STAGE_NAME" "stage_start" "Stage: $STAGE_NAME started"
  log "▶ Stage: $STAGE_NAME"
}

stage_end() {
  local elapsed=$(( $(date +%s) - STAGE_START ))
  log_json "$STAGE_NAME" "stage_end" "Stage: $STAGE_NAME completed (${elapsed}s)" "elapsed_s" "$elapsed"
  log "✓ Stage: $STAGE_NAME completed (${elapsed}s)"
}

# ── Help ─────────────────────────────────────────────────────────────────────

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  cat <<'EOF'
flat-white — Australian address data, flattened and served.

Usage:
  docker run flat-white --help
  docker run flat-white --fixture-only --output /output/
  docker run -v $(pwd)/output:/output flat-white --states VIC --compress --output /output/

Flags:
  --help              Show this help
  --fixture-only      Run fixture build only (no download, no gnaf-loader)
  --states STATES     States to process (e.g. VIC, "VIC NSW")
  --output DIR        Output directory (default: /output)
  --compress          Gzip output files
  --split-states      Split output into per-state files
  --skip-download     Skip data download (assumes data in /data)
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
EOF
  exit 0
fi

# ── Parse arguments ──────────────────────────────────────────────────────────

MODE=""
OUTPUT_DIR="/output"
STATES=""
COMPRESS=false
SPLIT_STATES=false
SKIP_DOWNLOAD=false
GNAF_PATH=""
ADMIN_PATH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --fixture-only)  MODE="fixture"; shift ;;
    --states)        shift; STATES="$1"; shift ;;
    --output)        shift; OUTPUT_DIR="$1"; shift ;;
    --compress)      COMPRESS=true; shift ;;
    --split-states)  SPLIT_STATES=true; shift ;;
    --skip-download) SKIP_DOWNLOAD=true; shift ;;
    --gnaf-path)     shift; GNAF_PATH="$1"; shift ;;
    --admin-path)    shift; ADMIN_PATH="$1"; shift ;;
    *)
      log "Unknown argument: $1"
      log "Run with --help for usage."
      exit 1
      ;;
  esac
done

# ── Validate argument combinations ──────────────────────────────────────────

if [[ "$SKIP_DOWNLOAD" == "true" && ( -z "$GNAF_PATH" || -z "$ADMIN_PATH" ) ]]; then
  log "ERROR: --skip-download requires --gnaf-path and --admin-path to locate pre-downloaded data."
  exit 1
fi

if [[ "$MODE" == "fixture" && "$SKIP_DOWNLOAD" == "true" ]]; then
  log "ERROR: --fixture-only and --skip-download are mutually exclusive."
  exit 1
fi

if [[ "$MODE" == "fixture" && "$SPLIT_STATES" == "true" ]]; then
  log "ERROR: --fixture-only and --split-states are mutually exclusive."
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

# ── Postgres cleanup trap ────────────────────────────────────────────────────

cleanup() {
  log "Stopping Postgres..."
  su postgres -c "pg_ctl -D $PGDATA stop -m fast" 2>/dev/null || true
}
trap cleanup EXIT

# ── Stage 1: Start Postgres ─────────────────────────────────────────────────

stage_start "postgres"

PG_LOG="/tmp/postgresql.log"
touch "$PG_LOG" && chown postgres:postgres "$PG_LOG"

if ! su postgres -c "pg_ctl -D $PGDATA -l $PG_LOG start -w -t 30" 2>>"$PG_LOG"; then
  # First run: initialize the database
  log "Initializing Postgres..."
  su postgres -c "initdb -D $PGDATA --auth=trust"
  echo "host all all 0.0.0.0/0 trust" >> "$PGDATA/pg_hba.conf"
  echo "listen_addresses = 'localhost'" >> "$PGDATA/postgresql.conf"
  su postgres -c "pg_ctl -D $PGDATA -l $PG_LOG start -w -t 30"
  su postgres -c "createdb $PGDB" || true
  su postgres -c "psql -d $PGDB -c 'CREATE EXTENSION IF NOT EXISTS postgis'"
fi

# Wait for Postgres to be ready
for i in $(seq 1 30); do
  if su postgres -c "pg_isready" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

if ! su postgres -c "pg_isready" >/dev/null 2>&1; then
  log "ERROR: Postgres did not become ready within 30s"
  cat "$PG_LOG" 2>/dev/null || true
  exit 10
fi

stage_end

# ── Stage 2 & 3: Data acquisition ───────────────────────────────────────────

if [[ "$MODE" == "fixture" ]]; then
  # Fixture-only: seed from committed fixture SQL
  stage_start "seed"
  su postgres -c "psql -d $PGDB -q -f /app/fixtures/seed-postgres.sql" || {
    log "ERROR: Fixture seeding failed"
    exit 2
  }
  stage_end
else
  # Full pipeline: download + gnaf-loader

  # Stage 2: Download
  if [[ "$SKIP_DOWNLOAD" == "false" ]]; then
    stage_start "download"

    export GNAF_DATA_PATH="${GNAF_PATH:-}"
    export ADMIN_BDYS_PATH="${ADMIN_PATH:-}"

    if ! node /app/dist/download.js; then
      log "ERROR: Download failed"
      exit 1
    fi
    stage_end
  else
    log "Skipping download (--skip-download)"
  fi

  # Stage 3: gnaf-loader
  stage_start "load"

  LOAD_ARGS=""
  if [[ -n "$STATES" ]]; then
    LOAD_ARGS="--states $STATES"
  fi

  if ! node /app/dist/load.js $LOAD_ARGS; then
    log "ERROR: gnaf-loader failed"
    exit 2
  fi
  stage_end
fi

# ── Stage 4: Flatten ────────────────────────────────────────────────────────

stage_start "flatten"

# Construct output filename
if [[ "$MODE" == "fixture" ]]; then
  FLATTEN_OUTPUT="$OUTPUT_DIR/fixture.ndjson"
  MATERIALIZE_FLAG=""
else
  STATE_LOWER=$(echo "${STATES:-all}" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
  FLATTEN_OUTPUT="$OUTPUT_DIR/flat-white-${STATE_LOWER}.ndjson"
  MATERIALIZE_FLAG="--materialize"
fi

GNAF_VERSION="${GNAF_VERSION:-2026.02}" \
  DATABASE_URL="postgres://$PGUSER:$PGPASSWORD@localhost:5432/$PGDB" \
  node /app/dist/flatten.js "$FLATTEN_OUTPUT" $MATERIALIZE_FLAG || {
  log "ERROR: Flatten failed"
  exit 3
}

LINE_COUNT=$(wc -l < "$FLATTEN_OUTPUT" | tr -d ' ')
log "Flatten output: $LINE_COUNT documents → $FLATTEN_OUTPUT"
stage_end

# ── Stage 5: Verify ─────────────────────────────────────────────────────────

stage_start "verify"

# Streaming verification: Zod schema validation + data quality checks
if [[ ! -s "$FLATTEN_OUTPUT" ]]; then
  log "ERROR: Output file is empty"
  exit 4
fi

DATABASE_URL="postgres://$PGUSER:$PGPASSWORD@localhost:5432/$PGDB" \
  node /app/dist/verify.js "$FLATTEN_OUTPUT" --expected-count "$LINE_COUNT" || {
  log "ERROR: Verification failed"
  exit 4
}

# Regression check for fixture mode
if [[ "$MODE" == "fixture" && -f /app/fixtures/expected-output.ndjson ]]; then
  EXPECTED_COUNT=$(wc -l < /app/fixtures/expected-output.ndjson | tr -d ' ')
  if [[ "$LINE_COUNT" -ne "$EXPECTED_COUNT" ]]; then
    log "ERROR: Expected $EXPECTED_COUNT lines, got $LINE_COUNT"
    exit 4
  fi
  if ! diff -q "$FLATTEN_OUTPUT" /app/fixtures/expected-output.ndjson >/dev/null 2>&1; then
    log "ERROR: Output differs from expected-output.ndjson"
    exit 4
  fi
  log "Regression check: PASS (byte-for-byte match)"
fi

stage_end

# ── Stage 6: Split (optional) ───────────────────────────────────────────────

if [[ "$SPLIT_STATES" == "true" && "$MODE" != "fixture" ]]; then
  stage_start "split"
  SPLIT_INPUT="$FLATTEN_OUTPUT" \
  SPLIT_OUTPUT_DIR="$OUTPUT_DIR" \
  SPLIT_VERSION="${GNAF_VERSION:-2026.02}" \
  node --input-type=module -e "
    import { split } from '/app/dist/split.js';
    const r = await split({
      inputPath: process.env.SPLIT_INPUT,
      outputDir: process.env.SPLIT_OUTPUT_DIR,
      version: process.env.SPLIT_VERSION
    });
    console.log('[split] ' + r.totalCount + ' docs → ' + r.outputFiles.length + ' files');
  " || {
    log "ERROR: Split failed"
    exit 5
  }
  stage_end
fi

# ── Stage 7: Compress (optional) ────────────────────────────────────────────

if [[ "$COMPRESS" == "true" ]]; then
  stage_start "compress"

  # Compress the main output file (or per-state files if split)
  if [[ "$SPLIT_STATES" == "true" && "$MODE" != "fixture" ]]; then
    # Compress each per-state file
    for f in "$OUTPUT_DIR"/flat-white-*.ndjson; do
      [[ -f "$f" ]] || continue
      COMPRESS_INPUT="$f" \
      COMPRESS_OUTPUT="${f}.gz" \
      node --input-type=module -e "
        import { compress } from '/app/dist/compress.js';
        const r = await compress({ inputPath: process.env.COMPRESS_INPUT, outputPath: process.env.COMPRESS_OUTPUT });
        console.log('[compress] ' + process.env.COMPRESS_INPUT + ' → ratio ' + (r.ratio * 100).toFixed(1) + '%');
      " || {
        log "ERROR: Compress failed for $f"
        exit 5
      }
    done
  else
    COMPRESS_INPUT="$FLATTEN_OUTPUT" \
    COMPRESS_OUTPUT="${FLATTEN_OUTPUT}.gz" \
    node --input-type=module -e "
      import { compress } from '/app/dist/compress.js';
      const r = await compress({ inputPath: process.env.COMPRESS_INPUT, outputPath: process.env.COMPRESS_OUTPUT });
      console.log('[compress] ratio ' + (r.ratio * 100).toFixed(1) + '%');
    " || {
      log "ERROR: Compress failed"
      exit 5
    }
  fi
  stage_end
fi

# ── Summary ──────────────────────────────────────────────────────────────────

log "Pipeline complete."
log "Output: $OUTPUT_DIR"
ls -lh "$OUTPUT_DIR"/ 2>/dev/null || true
