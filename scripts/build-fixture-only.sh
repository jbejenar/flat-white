#!/usr/bin/env bash
set -euo pipefail

# build-fixture-only.sh — Dev loop: seed Postgres with fixtures, flatten, output NDJSON
# Target: <30 seconds, no download, no gnaf-loader
#
# Usage: ./scripts/build-fixture-only.sh
#
# Prerequisites:
#   docker compose up db  (Postgres 16 + PostGIS 3.5 running)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="$PROJECT_DIR/output"
OUTPUT_FILE="$OUTPUT_DIR/fixture.ndjson"
OUTPUT_FILE_MAT="$OUTPUT_DIR/fixture-materialize.ndjson"
FIXTURE_SQL="$PROJECT_DIR/fixtures/seed-postgres.sql"
DB_URL="${DATABASE_URL:-postgres://postgres:postgres@localhost:5432/gnaf}"

echo "[fixture-build] Starting fixture-only build..."
START_TIME=$(date +%s)

# 1. Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# 2. Check Postgres is reachable
echo "[fixture-build] Checking Postgres..."
if ! docker compose exec -T db pg_isready -U postgres -q 2>/dev/null; then
  echo "[fixture-build] Postgres not ready. Starting..."
  docker compose up db -d --wait
fi

# 3. Seed fixture data
echo "[fixture-build] Seeding fixture data (451 addresses)..."
docker compose exec -T db psql -U postgres -d gnaf -q -f /fixtures/seed-postgres.sql

# 4. Build TypeScript
echo "[fixture-build] Building TypeScript..."
npm run build --silent

# Fixture data is frozen at the Feb 2026 G-NAF release — default to 2026.02.
# Production builds (docker-entrypoint.sh) require GNAF_VERSION explicitly.
GNAF_VERSION="${GNAF_VERSION:-2026.02}"
export GNAF_VERSION

# 5a. Run flatten — legacy path (CTE-based, sql/address_full.sql)
echo "[fixture-build] Running flatten (legacy CTE path)..."
DATABASE_URL="$DB_URL" node "$PROJECT_DIR/dist/flatten.js" "$OUTPUT_FILE"

# 5b. Run flatten — materialize path (sql/address_full_prep.sql + address_full_main.sql)
# This is what production uses. Must produce byte-identical output to the legacy path
# against the fixture — guards against drift between the two SQL files (e.g. PR #29
# regressed streetType in this path while the legacy fixture path stayed correct).
echo "[fixture-build] Running flatten (materialize path)..."
DATABASE_URL="$DB_URL" node "$PROJECT_DIR/dist/flatten.js" "$OUTPUT_FILE_MAT" --materialize

# 6. Validate output
LINE_COUNT=$(wc -l < "$OUTPUT_FILE" | tr -d ' ')
echo "[fixture-build] Output: $OUTPUT_FILE ($LINE_COUNT documents)"

# 6b. Cross-path regression: legacy and materialize must agree
if ! diff -q "$OUTPUT_FILE" "$OUTPUT_FILE_MAT" >/dev/null 2>&1; then
  echo "[fixture-build] ERROR: legacy and materialize SQL paths produced different output"
  echo "  diff $OUTPUT_FILE $OUTPUT_FILE_MAT"
  diff "$OUTPUT_FILE" "$OUTPUT_FILE_MAT" | head -40
  exit 4
fi
echo "[fixture-build] Cross-path regression: PASS (legacy ≡ materialize)"

# 7. Validate each line is valid JSON
if command -v jq &>/dev/null; then
  if ! jq -c -e '.' "$OUTPUT_FILE" > /dev/null 2>&1; then
    echo "[fixture-build] ERROR: Output contains invalid JSON lines"
    exit 3
  fi
fi

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
echo "[fixture-build] Done in ${ELAPSED}s ($LINE_COUNT documents)"

# 8. Compare with expected output if it exists
EXPECTED="$PROJECT_DIR/fixtures/expected-output.ndjson"
if [ -f "$EXPECTED" ]; then
  EXPECTED_COUNT=$(wc -l < "$EXPECTED" | tr -d ' ')
  if [ "$LINE_COUNT" -ne "$EXPECTED_COUNT" ]; then
    echo "[fixture-build] WARNING: Output has $LINE_COUNT lines, expected $EXPECTED_COUNT"
    exit 4
  fi
  if diff -q "$OUTPUT_FILE" "$EXPECTED" >/dev/null 2>&1; then
    echo "[fixture-build] Regression check: PASS (byte-for-byte match)"
  else
    echo "[fixture-build] WARNING: Output differs from expected-output.ndjson"
    echo "  Run 'diff output/fixture.ndjson fixtures/expected-output.ndjson' to inspect"
    exit 4
  fi
else
  echo "[fixture-build] No expected-output.ndjson yet — skipping regression check"
fi
