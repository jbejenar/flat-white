#!/usr/bin/env bash
# build-local.sh — Full local build: [load →] flatten → verify
#
# Usage:
#   ./scripts/build-local.sh                       # Full build (load + flatten + verify)
#   ./scripts/build-local.sh --skip-load           # Skip gnaf-loader (data already loaded)
#   ./scripts/build-local.sh --states VIC          # VIC only (default)
#   ./scripts/build-local.sh --states "VIC NSW"    # Multiple states (quote!)
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

# --- Defaults ---
STATES="VIC"
SKIP_LOAD=false
OUTPUT_DIR="./output"
VERSION="${GNAF_VERSION:-}"

# --- Parse args ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-load) SKIP_LOAD=true; shift ;;
    --states) shift; STATES="$1"; shift ;;
    --output-dir) shift; OUTPUT_DIR="$1"; shift ;;
    --version) shift; VERSION="$1"; shift ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

if [[ -z "$VERSION" ]]; then
  echo "ERROR: Version is required. Set GNAF_VERSION env var or pass --version YYYY.MM"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"
export POSTGRES_PORT="${POSTGRES_PORT:-$(printf '%s' "$PROJECT_DIR" | cksum | awk '{print 20000 + ($1 % 20000)}')}"

ensure_db_container() {
  local ps_json
  ps_json="$(docker compose ps --format json 2>/dev/null || true)"

  if [[ "$ps_json" != *"\"PublishedPort\":${POSTGRES_PORT}"* ]]; then
    echo "[build] Starting Postgres on host port ${POSTGRES_PORT}..."
    docker compose up -d db --wait --force-recreate
    return
  fi

  if ! docker compose exec -T db pg_isready -U postgres -q 2>/dev/null; then
    echo "[build] Restarting Postgres..."
    docker compose up -d db --wait
  fi
}

resolve_db_url() {
  if [[ -n "${DATABASE_URL:-}" ]]; then
    printf '%s\n' "$DATABASE_URL"
    return
  fi

  printf 'postgres://postgres:postgres@localhost:%s/gnaf\n' "$POSTGRES_PORT"
}

echo "========================================"
echo " flat-white local build"
echo "========================================"
echo "  States:    $STATES"
echo "  Output:    $OUTPUT_DIR"
echo "  Version:   $VERSION"
echo "  Skip load: $SKIP_LOAD"
echo "========================================"

BUILD_START=$(date +%s)

# --- Step 0: Prerequisites ---
echo ""
echo "[build] Step 0: Checking prerequisites..."

if ! docker compose ps db --format '{{.Status}}' 2>/dev/null | grep -q "Up"; then
  echo "[build] Starting Postgres..."
  docker compose up -d db
  echo "[build] Waiting for Postgres to be ready..."
  sleep 5
fi

ensure_db_container
DB_URL="$(resolve_db_url)"

npm run build --silent 2>/dev/null

echo "[build] Prerequisites OK"

# --- Step 1: Load (optional) ---
if [ "$SKIP_LOAD" = false ]; then
  echo ""
  echo "[build] Step 1: Running gnaf-loader for states: $STATES"
  LOAD_START=$(date +%s)
  GNAF_VERSION="$VERSION" node dist/load.js --states $STATES --server-data-dir /data
  LOAD_END=$(date +%s)
  echo "[build] Load completed in $((LOAD_END - LOAD_START)) seconds"
else
  echo ""
  echo "[build] Step 1: Skipped (--skip-load)"
fi

# --- Step 2: Flatten ---
echo ""
echo "[build] Step 2: Flattening addresses to NDJSON..."
FLATTEN_START=$(date +%s)

# Construct output filename from states
STATE_LOWER=$(echo "$STATES" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
OUTPUT_FILE="$OUTPUT_DIR/flat-white-${STATE_LOWER}.ndjson"

DATABASE_URL="$DB_URL" GNAF_VERSION="$VERSION" node dist/flatten.js "$OUTPUT_FILE" --materialize

FLATTEN_END=$(date +%s)
FLATTEN_DURATION=$((FLATTEN_END - FLATTEN_START))
echo "[build] Flatten completed in ${FLATTEN_DURATION} seconds"

# --- Step 3: Verify ---
echo ""
echo "[build] Step 3: Output verification..."

LINE_COUNT=$(wc -l < "$OUTPUT_FILE" | tr -d ' ')
FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
echo "[build] Output: $OUTPUT_FILE"
echo "[build] Lines:  $LINE_COUNT"
echo "[build] Size:   $FILE_SIZE"

# Quick schema validation on first 100 lines
echo "[build] Validating schema on sample..."
head -100 "$OUTPUT_FILE" | node -e "
const { AddressDocumentSchema } = require('./dist/schema.js');
const readline = require('readline');
const rl = readline.createInterface({ input: process.stdin });
let valid = 0, invalid = 0;
rl.on('line', (line) => {
  const result = AddressDocumentSchema.safeParse(JSON.parse(line));
  if (result.success) valid++; else { invalid++; console.error(result.error.message); }
});
rl.on('close', () => {
  console.log('[build] Sample validation: ' + valid + ' valid, ' + invalid + ' invalid');
  if (invalid > 0) process.exit(1);
});
"

# --- Step 4: Summary ---
BUILD_END=$(date +%s)
TOTAL_DURATION=$((BUILD_END - BUILD_START))

echo ""
echo "========================================"
echo " Build complete"
echo "========================================"
echo "  Output:   $OUTPUT_FILE"
echo "  Lines:    $LINE_COUNT"
echo "  Size:     $FILE_SIZE"
echo "  Duration: ${TOTAL_DURATION}s ($((TOTAL_DURATION / 60))m $((TOTAL_DURATION % 60))s)"
echo "========================================"
