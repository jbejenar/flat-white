#!/usr/bin/env bash
#
# test.sh — integration test for scripts/validate-db-cache.sh
#
# Provisions a "production-shaped" Postgres schema (one that matches what
# gnaf-loader actually creates, NOT what the fixture creates) and runs the
# cache validator against it. Catches two regression classes:
#
#   1. Validator references a fixture-only table name and fails on every
#      production state build. Original PR #99 bug — `abs_2021_mb_lookup`
#      is fixture-only; production has `abs_2021_mb`.
#
#   2. Validator's polygon-table requirements don't match gnaf-loader's
#      per-state shapefile filtering. Single-state builds for ACT/OT/etc.
#      end up with only a SUBSET of the 5 polygon tables (per the
#      `admin_bdy_list` logic in `gnaf-loader/settings.py:208-217`). The
#      validator must mirror that subset exactly via the STATES env var.
#
# Test cases:
#   1-3.   Existing checks (empty-STATES strict-all-five, abs_2021_mb regression)
#   4-12.  Per-state positive cases for ALL 9 single-state builds
#          (validates state-aware polygon requirements match settings.py)
#   13.    Multi-state positive case (NSW VIC) — verifies OR logic
#   14-15. Negative regression guards: even with STATES, the validator still
#          hard-fails when an EXPECTED polygon is missing
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
  # passing GNAF_VERSION, minimum-row overrides, and the optional STATES env
  # via -e flags. Returns the validator's exit code, propagating stderr.
  #
  # Usage: run_validator              # empty STATES → strict-all-five fallback
  #        run_validator OT           # single-state per-state mode
  #        run_validator "NSW VIC"    # multi-state space-separated
  local states="${1:-}"
  docker compose exec -T \
    -e GNAF_VERSION="$TEST_GNAF_VERSION" \
    -e MIN_ADDRESS_ROWS=1 \
    -e MIN_BOUNDARY_ROWS=1 \
    -e STATES="$states" \
    "$DB_SERVICE" bash -s < "$VALIDATOR_FILE"
}

# drop_polygons — remove the named admin_bdys polygon tables from the seed
# (used to simulate per-state gnaf-loader output where some boundary types
# don't get loaded due to filename-prefix shapefile filtering).
#
# Usage: drop_polygons local_government_wards state_upper_house_electorates
drop_polygons() {
  local table
  local sql=""
  for table in "$@"; do
    sql+="DROP TABLE IF EXISTS admin_bdys_${TEST_SCHEMA_VERSION}.${table};"
  done
  psql_db -q -c "$sql"
}

# assert_pass — exit code 0 expected
# Usage: assert_pass <test_name> <run_validator output>
assert_pass() {
  local name="$1"
  local actual="$2"
  if [[ "$actual" -eq 0 ]]; then
    echo "  PASS: $name"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $name — expected exit 0, got $actual"
    FAIL=$((FAIL + 1))
  fi
}

# assert_fail_with — exit code 1 expected, stderr must contain the substring
# Usage: assert_fail_with <test_name> <actual_exit> <stderr> <substring>
assert_fail_with() {
  local name="$1"
  local actual="$2"
  local stderr="$3"
  local needle="$4"
  if [[ "$actual" -eq 1 && "$stderr" == *"$needle"* ]]; then
    echo "  PASS: $name"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $name — expected exit 1 with '$needle' in error, got exit $actual"
    echo "  stderr: $stderr"
    FAIL=$((FAIL + 1))
  fi
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

# Test 1 — empty STATES → strict-all-five fallback → validator exits 0
echo
echo "[cache-validator-test] Test 1/15 — empty STATES (strict-all-five fallback)"
reseed
set +e; run_validator >/dev/null; actual=$?; set -e
assert_pass "validator exited 0 against full prod-shape schema (no STATES)" "$actual"

# Test 2 — empty STATES, drop a polygon → validator exits 1
echo
echo "[cache-validator-test] Test 2/15 — empty STATES + drop local_government_areas"
reseed
drop_polygons local_government_areas
set +e; stderr_capture="$(run_validator 2>&1 1>/dev/null)"; actual=$?; set -e
assert_fail_with "validator exited 1 with local_government_areas error" \
  "$actual" "$stderr_capture" "local_government_areas"

# Test 3 — REGRESSION GUARD: drop the production mesh-block table.
# This is the original PR #101 bug — the validator referenced
# `abs_2021_mb_lookup` (fixture-only) instead of `abs_2021_mb` (production).
# If anyone re-introduces the wrong name, this test catches it because
# the seed only creates `abs_2021_mb`.
echo
echo "[cache-validator-test] Test 3/15 — regression guard (drop abs_2021_mb)"
reseed
drop_polygons abs_2021_mb
set +e; stderr_capture="$(run_validator 2>&1 1>/dev/null)"; actual=$?; set -e
if [[ "$actual" -eq 1 \
   && "$stderr_capture" == *"abs_2021_mb"* \
   && "$stderr_capture" != *"abs_2021_mb_lookup"* ]]; then
  # Negation check distinguishes `abs_2021_mb` from `abs_2021_mb_lookup`.
  # If the validator regresses to checking the fixture-only `_lookup` table,
  # the seed (which has `abs_2021_mb` but NOT `_lookup`) makes the validator
  # error mention `abs_2021_mb_lookup` — and the negation catches it.
  echo "  PASS: validator exited 1 with abs_2021_mb (not _lookup) in error"
  PASS=$((PASS + 1))
else
  echo "  FAIL: expected exit 1 with abs_2021_mb (not _lookup) in error, got exit $actual"
  echo "  stderr: $stderr_capture"
  FAIL=$((FAIL + 1))
fi

# ─── Per-state positive cases ───────────────────────────────────────────────
# Each test simulates what gnaf-loader actually leaves in admin_bdys_* after
# a single-state load. The polygon set per state comes from the truth table
# in `gnaf-loader/settings.py:208-217`.

# Test 4 — STATES=OT (Other Territories: Christmas Island, Norfolk, etc.)
# OT has only LGA. Drop everything else.
echo
echo "[cache-validator-test] Test 4/15 — STATES=OT (lga only)"
reseed
drop_polygons commonwealth_electorates local_government_wards \
  state_lower_house_electorates state_upper_house_electorates
set +e; run_validator OT >/dev/null; actual=$?; set -e
assert_pass "STATES=OT accepts lga-only schema" "$actual"

# Test 5 — STATES=ACT (Australian Capital Territory)
# ACT has ce + se_lower (no lga, no ward, no se_upper).
echo
echo "[cache-validator-test] Test 5/15 — STATES=ACT (ce, se_lower)"
reseed
drop_polygons local_government_areas local_government_wards state_upper_house_electorates
set +e; run_validator ACT >/dev/null; actual=$?; set -e
assert_pass "STATES=ACT accepts ce+se_lower schema" "$actual"

# Test 6 — STATES=NSW (New South Wales)
# NSW has ce + lga + se_lower (no ward, no se_upper). NSW councils don't
# have wards in the Geoscape data set.
echo
echo "[cache-validator-test] Test 6/15 — STATES=NSW (ce, lga, se_lower)"
reseed
drop_polygons local_government_wards state_upper_house_electorates
set +e; run_validator NSW >/dev/null; actual=$?; set -e
assert_pass "STATES=NSW accepts ce+lga+se_lower schema" "$actual"

# Test 7 — STATES=NT (Northern Territory)
# NT has ce + lga + ward + se_lower (no se_upper — NT is unicameral).
echo
echo "[cache-validator-test] Test 7/15 — STATES=NT (ce, lga, ward, se_lower)"
reseed
drop_polygons state_upper_house_electorates
set +e; run_validator NT >/dev/null; actual=$?; set -e
assert_pass "STATES=NT accepts ce+lga+ward+se_lower schema" "$actual"

# Test 8 — STATES=TAS (Tasmania)
# TAS has ce + lga + se_lower + se_upper (no ward — TAS LGAs aren't subdivided
# into wards in the Geoscape data set).
echo
echo "[cache-validator-test] Test 8/15 — STATES=TAS (ce, lga, se_lower, se_upper)"
reseed
drop_polygons local_government_wards
set +e; run_validator TAS >/dev/null; actual=$?; set -e
assert_pass "STATES=TAS accepts ce+lga+se_lower+se_upper schema" "$actual"

# Test 9 — STATES=QLD (Queensland)
# QLD has the same polygon set as NSW (ce + lga + se_lower). Tests redundant
# branch coverage of the truth table for the third state in this class.
echo
echo "[cache-validator-test] Test 9/15 — STATES=QLD (ce, lga, se_lower)"
reseed
drop_polygons local_government_wards state_upper_house_electorates
set +e; run_validator QLD >/dev/null; actual=$?; set -e
assert_pass "STATES=QLD accepts ce+lga+se_lower schema" "$actual"

# Test 10 — STATES=SA (South Australia)
# SA has ce + lga + ward + se_lower (no se_upper). Same polygon set as NT but
# tests the SA branch in the OR conditions.
echo
echo "[cache-validator-test] Test 10/15 — STATES=SA (ce, lga, ward, se_lower)"
reseed
drop_polygons state_upper_house_electorates
set +e; run_validator SA >/dev/null; actual=$?; set -e
assert_pass "STATES=SA accepts ce+lga+ward+se_lower schema" "$actual"

# Test 11 — STATES=VIC (Victoria, full coverage)
# VIC has all 5 polygon tables. No drops needed.
echo
echo "[cache-validator-test] Test 11/15 — STATES=VIC (all 5)"
reseed
set +e; run_validator VIC >/dev/null; actual=$?; set -e
assert_pass "STATES=VIC accepts full all-five schema" "$actual"

# Test 12 — STATES=WA (Western Australia, full coverage)
# WA has all 5 polygon tables. Like VIC, no drops needed.
echo
echo "[cache-validator-test] Test 12/15 — STATES=WA (all 5)"
reseed
set +e; run_validator WA >/dev/null; actual=$?; set -e
assert_pass "STATES=WA accepts full all-five schema" "$actual"

# Test 13 — Multi-state STATES="NSW VIC"
# Union of NSW (ce, lga, se_lower) and VIC (all 5) = all 5 (because VIC
# triggers ward and se_upper via the OR conditions in settings.py).
echo
echo '[cache-validator-test] Test 13/15 — STATES="NSW VIC" (multi-state, union has all 5)'
reseed
set +e; run_validator "NSW VIC" >/dev/null; actual=$?; set -e
assert_pass 'STATES="NSW VIC" accepts full all-five schema (multi-state OR logic)' "$actual"

# ─── Negative regression guards ─────────────────────────────────────────────
# These prove that even with state-aware logic, the validator still hard-fails
# when an EXPECTED polygon is missing for the state being built.

# Test 14 — STATES=VIC, drop ward → should fail (VIC requires ward)
echo
echo "[cache-validator-test] Test 14/15 — NEG: STATES=VIC missing ward"
reseed
drop_polygons local_government_wards
set +e; stderr_capture="$(run_validator VIC 2>&1 1>/dev/null)"; actual=$?; set -e
assert_fail_with "STATES=VIC fails when ward is missing" \
  "$actual" "$stderr_capture" "local_government_wards"

# Test 15 — STATES=OT, drop lga → should fail (OT requires lga)
echo
echo "[cache-validator-test] Test 15/15 — NEG: STATES=OT missing lga"
reseed
drop_polygons commonwealth_electorates local_government_wards \
  state_lower_house_electorates state_upper_house_electorates local_government_areas
set +e; stderr_capture="$(run_validator OT 2>&1 1>/dev/null)"; actual=$?; set -e
assert_fail_with "STATES=OT fails when lga is missing" \
  "$actual" "$stderr_capture" "local_government_areas"

echo
echo "[cache-validator-test] Result: $PASS passed, $FAIL failed"

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi

exit 0
