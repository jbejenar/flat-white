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
  --dump-db PATH      Dump database after gnaf-loader (for caching)
  --restore-db PATH   Restore database from dump (skip download + gnaf-loader)

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
DUMP_DB=""
RESTORE_DB=""

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
    --dump-db)       shift; DUMP_DB="$1"; shift ;;
    --restore-db)    shift; RESTORE_DB="$1"; shift ;;
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

if [[ "$MODE" == "fixture" && -n "$DUMP_DB" ]]; then
  log "ERROR: --fixture-only and --dump-db are mutually exclusive."
  exit 1
fi

if [[ "$MODE" == "fixture" && -n "$RESTORE_DB" ]]; then
  log "ERROR: --fixture-only and --restore-db are mutually exclusive."
  exit 1
fi

if [[ -n "$DUMP_DB" && -n "$RESTORE_DB" ]]; then
  log "ERROR: --dump-db and --restore-db are mutually exclusive."
  exit 1
fi

if [[ -n "$RESTORE_DB" && "$SKIP_DOWNLOAD" == "true" ]]; then
  log "ERROR: --restore-db and --skip-download are mutually exclusive."
  exit 1
fi

# ── Require GNAF_VERSION for non-fixture builds ──────────────────────────────
# The version must be supplied explicitly to prevent shipping stale data.
# Fixture mode uses frozen 202602 data from seed-postgres.sql, so it defaults.

if [[ "$MODE" != "fixture" && -z "${GNAF_VERSION:-}" ]]; then
  log "ERROR: GNAF_VERSION environment variable is required for production builds."
  log "Set GNAF_VERSION=YYYY.MM (e.g. GNAF_VERSION=2026.05)"
  exit 1
fi

# Fixture mode: default to the frozen fixture version
if [[ "$MODE" == "fixture" ]]; then
  export GNAF_VERSION="${GNAF_VERSION:-2026.02}"
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

PG_LOG_DIR="/var/run/postgresql"
mkdir -p "$PG_LOG_DIR" && chown postgres:postgres "$PG_LOG_DIR"
PG_LOG="$PG_LOG_DIR/postgresql.log"
touch "$PG_LOG" && chown postgres:postgres "$PG_LOG"

if ! su postgres -c "pg_ctl -D $PGDATA -l $PG_LOG start -w -t 30" 2>>"$PG_LOG"; then
  # First run: initialize the database
  log "Initializing Postgres..."
  su postgres -c "initdb -D $PGDATA --auth=trust"
  echo "host all all 0.0.0.0/0 trust" >> "$PGDATA/pg_hba.conf"

  # Memory tuning for 7GB free runners (P4.07)
  # Default shared_buffers (128MB) works but leaves no margin for NSW (~4.6M rows).
  # These settings target ~500-700MB PostgreSQL footprint, leaving headroom for
  # gnaf-loader (Python), Node.js flatten (~65MB), and OS (~500MB).
  #
  # dynamic_shared_memory_type = sysv (E1.20 / "permanent build fix" PR):
  # Postgres parallel hash joins allocate dynamic shared memory chunks in
  # /dev/shm by default. Docker default /dev/shm is 64MB which is exhausted by
  # a single 64MB parallel hash table — flatten then fails with
  # "could not resize shared memory segment ... No space left on device".
  # Switching to SysV shared memory removes the /dev/shm dependency entirely;
  # SysV is bounded by SHMMAX/SHMALL kernel settings which Docker leaves at
  # the host defaults (very high). This is the structural fix — no magic
  # number tunable, no `--shm-size` insurance flag needed.
  cat >> "$PGDATA/postgresql.conf" <<PGCONF
listen_addresses = 'localhost'
shared_buffers = 256MB
work_mem = 64MB
maintenance_work_mem = 256MB
effective_cache_size = 2GB
max_connections = 20
dynamic_shared_memory_type = sysv
PGCONF

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
  # Fixture-only: mirror the supported local fixture pipeline so container smoke
  # exercises boundary preparation and verification, not just core G-NAF rows.
  stage_start "seed"
  su postgres -c "psql -d $PGDB -q -f /app/fixtures/seed-postgres.sql" || {
    log "ERROR: Fixture seeding failed"
    exit 2
  }

  su postgres -c "psql -d $PGDB -q -f /app/fixtures/seed-admin-bdys.sql" || {
    log "ERROR: Admin boundary fixture seeding failed"
    exit 2
  }

  SCHEMA_VERSION_FLAT="${GNAF_VERSION//.}"
  sed "s/__SCHEMA_VERSION__/${SCHEMA_VERSION_FLAT}/g" /app/fixtures/prep-admin-bdys.sql | \
    su postgres -c "psql -d $PGDB -q" || {
      log "ERROR: Admin boundary prep SQL failed"
      exit 2
    }

  node /app/scripts/extract-boundary-prelude.mjs /app/sql/address_full_prep.sql | \
    sed "s/__SCHEMA_VERSION__/${SCHEMA_VERSION_FLAT}/g" | \
    su postgres -c "psql -d $PGDB -q" || {
      log "ERROR: Fixture spatial join prep failed"
      exit 2
    }
  stage_end
elif [[ -n "$RESTORE_DB" ]]; then
  # Cache hit: restore database from dump, skip download + gnaf-loader
  stage_start "restore"
  if [[ ! -f "$RESTORE_DB" ]]; then
    log "ERROR: --restore-db file not found: $RESTORE_DB"
    exit 2
  fi
  log "Restoring database from cache: $RESTORE_DB"
  PGPASSWORD="$PGPASSWORD" pg_restore \
    -h localhost \
    -U "$PGUSER" \
    -d "$PGDB" \
    --no-owner \
    --no-privileges \
    --jobs=2 \
    "$RESTORE_DB" || {
    log "ERROR: Database restore failed"
    exit 2
  }
  DUMP_SIZE=$(du -h "$RESTORE_DB" | cut -f1)
  log "Database restored from $DUMP_SIZE dump"
  # validate-db-cache.sh prints "[cache-validate] FAIL: <reason>" to stderr
  # on the failing check; that line is the operator-actionable detail.
  # STATES is passed via inline env so the validator can apply state-aware
  # polygon table requirements (mirroring gnaf-loader's per-state filtering
  # in settings.py:208-217). $STATES is a local bash variable in this
  # entrypoint and is NOT exported, so the inline prefix is required.
  if ! STATES="$STATES" /app/scripts/validate-db-cache.sh; then
    log "ERROR: Restored database failed validation (see [cache-validate] FAIL line above for reason)"
    exit 2
  fi

  # E1.26: Refresh planner statistics after pg_restore.
  #
  # Problem: pg_restore does NOT restore per-table statistics (pg_dump never
  # captures them — they live in pg_statistic which is excluded from dumps).
  # Without stats, the Postgres planner uses defaults that work for some
  # data shapes but pick pathological plans for others.
  #
  # Empirical evidence (forensic scan of quarterly run 24163471133):
  # WA cursor stream rate dropped from ~17,500 rows/sec (fresh build) to
  # 442 rows/sec (cache restore) on identical data — 40-75x slower.
  # Steady throughout, no stalls. Pattern matches "wrong query plan" not
  # "intermittent contention." Fresh ANALYZE on the restored DB should
  # restore performance to fresh-build levels.
  #
  # ANALYZE (no table list) refreshes stats for ALL tables in the current
  # database. Typically takes 30s-2min on a fully-loaded gnaf-loader DB.
  # Acceptable cost given the failure mode it prevents (~50min waste per
  # WA quarterly run).
  log "Running ANALYZE after cache restore (E1.26 — pg_restore doesn't preserve planner statistics)"
  ANALYZE_START=$(date +%s)
  PGPASSWORD="$PGPASSWORD" psql -h localhost -U "$PGUSER" -d "$PGDB" -c "ANALYZE;" -q
  ANALYZE_ELAPSED=$(( $(date +%s) - ANALYZE_START ))
  log "✓ ANALYZE completed in ${ANALYZE_ELAPSED}s"

  stage_end
else
  # Full pipeline: download + gnaf-loader

  # Export GNAF_DATA_PATH and ADMIN_BDYS_PATH for both download.js (Stage 2)
  # AND load.js (Stage 3). The vars are exported here unconditionally so the
  # --skip-download path also honors the --gnaf-path / --admin-path flags.
  # Without this, --skip-download silently falls back to dist/load.js's
  # default ./data lookup (E1.25 fix).
  export GNAF_DATA_PATH="${GNAF_PATH:-}"
  export ADMIN_BDYS_PATH="${ADMIN_PATH:-}"

  # Stage 2: Download
  if [[ "$SKIP_DOWNLOAD" == "false" ]]; then
    stage_start "download"

    # GNAF_VERSION is already validated/set above

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

  # Derive 6-digit geoscape version from GNAF_VERSION (e.g. "2026.05" → "202605")
  GEOSCAPE_VERSION=$(echo "$GNAF_VERSION" | tr -d '.')
  if [[ ! "$GEOSCAPE_VERSION" =~ ^[0-9]{6}$ ]]; then
    log "ERROR: GNAF_VERSION '${GNAF_VERSION}' must be in YYYY.MM format (e.g. 2026.05)"
    exit 1
  fi

  LOAD_ARGS="--geoscape-version $GEOSCAPE_VERSION"
  if [[ -n "$STATES" ]]; then
    LOAD_ARGS="$LOAD_ARGS --states $STATES"
  fi

  LOAD_LOG="/tmp/load.log"
  rm -f "$LOAD_LOG"

  set +e
  GNAF_VERSION="$GNAF_VERSION" node /app/dist/load.js $LOAD_ARGS 2>&1 | tee "$LOAD_LOG"
  LOAD_EXIT=${PIPESTATUS[0]}
  set -e

  # Layered defence: if gnaf-loader fails AND the failure happened during/after
  # boundary tagging (Part 5 of 6), retry with --no-boundary-tag so flat-white's
  # spatial-join fallback in address_full_prep.sql can populate boundaries via
  # ST_Intersects against the admin_bdys polygon tables.
  #
  # Detection logic is in scripts/detect-load-failure.sh — broad-by-design
  # (catches ANY error in Part 5, not just specific column names) so it
  # auto-recovers from any future upstream gnaf-loader regression in Part 5.
  # When upstream ships a fix (E1.20), the first attempt succeeds and the
  # retry never fires.
  #
  # Tested by test/integration/load-detection/test.sh (8 sample fixtures
  # covering all known failure modes plus negative cases).
  if /app/scripts/detect-load-failure.sh "$LOAD_LOG" "$LOAD_EXIT"; then
    log "WARNING: gnaf-loader boundary tagging failed (Part 5)"
    log "         retrying with --no-boundary-tag — flat-white spatial-join fallback will populate boundaries"
    rm -f "$LOAD_LOG"
    set +e
    GNAF_VERSION="$GNAF_VERSION" node /app/dist/load.js $LOAD_ARGS --no-boundary-tag 2>&1 | tee "$LOAD_LOG"
    LOAD_EXIT=${PIPESTATUS[0]}
    set -e
  fi

  if [[ $LOAD_EXIT -ne 0 ]]; then
    log "ERROR: gnaf-loader failed"
    exit 2
  fi
  stage_end

  # Stage 3a: Validate post-load DB state. Catches silent regressions
  # (missing required boundary polygon tables, empty raw tables) BEFORE we
  # propagate them via cache dump or burn time on flatten.
  # STATES is passed inline so the validator applies state-aware polygon
  # table requirements (see scripts/validate-db-cache.sh comment block).
  stage_start "validate"
  if ! STATES="$STATES" /app/scripts/validate-db-cache.sh; then
    log "ERROR: Post-load database failed validation (see [cache-validate] FAIL line above for reason)"
    exit 2
  fi
  stage_end

  # Stage 3b: Dump database for caching (if requested)
  if [[ -n "$DUMP_DB" ]]; then
    stage_start "dump"
    DUMP_DIR=$(dirname "$DUMP_DB")
    mkdir -p "$DUMP_DIR"
    PGPASSWORD="$PGPASSWORD" pg_dump \
      -h localhost \
      -U "$PGUSER" \
      -d "$PGDB" \
      -Fc \
      --compress=6 \
      -f "$DUMP_DB" || {
      log "ERROR: Database dump failed"
      exit 2
    }
    DUMP_SIZE=$(du -h "$DUMP_DB" | cut -f1)
    log "Database dumped: $DUMP_DB ($DUMP_SIZE)"
    stage_end
  fi
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

GNAF_VERSION="$GNAF_VERSION" \
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
STATES="$STATES" \
  node /app/dist/verify.js "$FLATTEN_OUTPUT" --expected-count "$LINE_COUNT" \
    --db-url "postgres://$PGUSER:$PGPASSWORD@localhost:5432/$PGDB" \
    --check-boundary-coverage || {
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
  SPLIT_VERSION="$GNAF_VERSION" \
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
  # Remove the original unsplit file to avoid double-counting during concatenation
  rm -f "$FLATTEN_OUTPUT"
  stage_end
fi

# ── Stage 7: Compress (optional) ────────────────────────────────────────────

if [[ "$COMPRESS" == "true" ]]; then
  stage_start "compress"

  # Compress the main output file (or per-state files if split)
  if [[ "$SPLIT_STATES" == "true" && "$MODE" != "fixture" ]]; then
    # Compress each per-state split file (original was removed above)
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
