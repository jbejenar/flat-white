#!/usr/bin/env bash
#
# test.sh — integration test for scripts/validate-db-cache.sh
#
# Provisions a "production-shaped" Postgres schema (one that matches what
# gnaf-loader actually creates, NOT what the fixture creates) and runs the
# cache validator against it. Catches the regression class where the
# validator references a fixture-only table name and silently fails on
# every production state build (PR #99 introduced exactly this bug —
# `abs_2021_mb_lookup` is fixture-only; production has `abs_2021_mb`).
#
# Test cases:
#   1. Positive: full prod-shape schema → validator exits 0
#   2. Negative: drop a polygon table → validator exits 1
#   3. Negative: drop the mesh-block table → validator exits 1 (the regression
#      guard for the bug PR A fixes)
#
# Schemas: 202699 (avoids colliding with the real 202602 fixture state).
#
# Run via: bash test/integration/cache-validator/test.sh
# Wired into CI via .github/workflows/ci.yml (quality job).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
DB_SERVICE="db"
DB_USER="postgres"
DB_NAME="gnaf"
SEED_FILE="$SCRIPT_DIR/seed-prod-shape.sql"
VALIDATOR_FILE="$PROJECT_DIR/scripts/validate-db-cache.sh"

# Test schemas — use 202699 to avoid colliding with the real 202602 fixture
# state if both are present in the same Postgres instance.
TEST_GNAF_VERSION="2026.99"
TEST_SCHEMA_VERSION="202699"

resolve_postgres_port() {
  if [[ -n "${POSTGRES_PORT:-}" ]]; then
    printf '%s\n' "$POSTGRES_PORT"
    return
  fi
  local checksum
  checksum="$(printf '%s' "$PROJECT_DIR" | cksum | awk '{print $1}')"
  printf '%s\n' "$((20000 + (checksum % 20000)))"
}

ensure_db_container() {
  local ps_json
  ps_json="$(docker compose ps --format json 2>/dev/null || true)"
  if [[ "$ps_json" != *"\"PublishedPort\":${POSTGRES_PORT}"* ]]; then
    echo "[cache-validator-test] Starting Postgres on host port ${POSTGRES_PORT}..."
    docker compose up "$DB_SERVICE" -d --wait --force-recreate
    return
  fi
  if ! docker compose exec -T "$DB_SERVICE" pg_isready -U "$DB_USER" -q 2>/dev/null; then
    docker compose up "$DB_SERVICE" -d --wait
  fi
}

psql_db() {
  docker compose exec -T "$DB_SERVICE" psql -U "$DB_USER" -d "$DB_NAME" "$@"
}

run_validator() {
  # Pipe the validator script into bash inside the docker compose db container,
  # passing GNAF_VERSION and minimum-row overrides via env. Returns the
  # validator's exit code, propagating stderr.
  docker compose exec -T \
    -e GNAF_VERSION="$TEST_GNAF_VERSION" \
    -e MIN_ADDRESS_ROWS=1 \
    -e MIN_BOUNDARY_ROWS=1 \
    "$DB_SERVICE" bash -s < "$VALIDATOR_FILE"
}

cleanup_test_schemas() {
  psql_db -q <<SQL
DROP SCHEMA IF EXISTS gnaf_${TEST_SCHEMA_VERSION} CASCADE;
DROP SCHEMA IF EXISTS raw_gnaf_${TEST_SCHEMA_VERSION} CASCADE;
DROP SCHEMA IF EXISTS admin_bdys_${TEST_SCHEMA_VERSION} CASCADE;
DROP SCHEMA IF EXISTS raw_admin_bdys_${TEST_SCHEMA_VERSION} CASCADE;
SQL
}

reseed() {
  psql_db -q < "$SEED_FILE"
}

# ─── main ───────────────────────────────────────────────────────────────────

echo "[cache-validator-test] Ensuring Postgres is ready..."
export POSTGRES_PORT="${POSTGRES_PORT:-$(resolve_postgres_port)}"
ensure_db_container

trap cleanup_test_schemas EXIT

PASS=0
FAIL=0

# Test 1 — positive case: full prod-shape schema → validator exits 0
echo
echo "[cache-validator-test] Test 1/3 — positive case (full prod-shape schema)"
reseed
set +e
run_validator >/dev/null
actual=$?
set -e
if [[ "$actual" -eq 0 ]]; then
  echo "  PASS: validator exited 0 against full prod-shape schema"
  PASS=$((PASS + 1))
else
  echo "  FAIL: validator exited $actual against full prod-shape schema (expected 0)"
  FAIL=$((FAIL + 1))
fi

# Test 2 — negative case: missing polygon table → validator exits 1
echo
echo "[cache-validator-test] Test 2/3 — negative (drop local_government_areas)"
reseed
psql_db -q -c "DROP TABLE admin_bdys_${TEST_SCHEMA_VERSION}.local_government_areas;"
set +e
stderr_capture="$(run_validator 2>&1 1>/dev/null)"
actual=$?
set -e
if [[ "$actual" -eq 1 && "$stderr_capture" == *"local_government_areas"* ]]; then
  echo "  PASS: validator exited 1 with local_government_areas in error"
  PASS=$((PASS + 1))
else
  echo "  FAIL: expected exit 1 with local_government_areas error, got exit $actual"
  echo "  stderr: $stderr_capture"
  FAIL=$((FAIL + 1))
fi

# Test 3 — REGRESSION GUARD: drop the production mesh-block table.
# This is the bug PR A fixes — the original validator referenced
# `abs_2021_mb_lookup` (fixture-only) instead of `abs_2021_mb` (production).
# If anyone re-introduces the wrong name, this test catches it because
# the seed only creates `abs_2021_mb`.
echo
echo "[cache-validator-test] Test 3/3 — regression guard (drop abs_2021_mb)"
reseed
psql_db -q -c "DROP TABLE admin_bdys_${TEST_SCHEMA_VERSION}.abs_2021_mb;"
set +e
stderr_capture="$(run_validator 2>&1 1>/dev/null)"
actual=$?
set -e
if [[ "$actual" -eq 1 && "$stderr_capture" == *"abs_2021_mb"* ]]; then
  echo "  PASS: validator exited 1 with abs_2021_mb in error"
  PASS=$((PASS + 1))
else
  echo "  FAIL: expected exit 1 with abs_2021_mb error, got exit $actual"
  echo "  stderr: $stderr_capture"
  FAIL=$((FAIL + 1))
fi

echo
echo "[cache-validator-test] Result: $PASS passed, $FAIL failed"

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi

exit 0
