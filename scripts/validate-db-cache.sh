#!/usr/bin/env bash
set -euo pipefail

# Cache validation gate (E1.21).
#
# Runs after a database restore (and after a successful gnaf-loader load) to
# detect partially-populated or schema-mismatched caches BEFORE we burn time
# on the flatten stage.
#
# What this catches:
#   - Wrong GNAF_VERSION → schema name mismatch (the schemas don't exist)
#   - Truncated / corrupt restore (core G-NAF tables missing rows)
#   - Missing admin_bdys polygon tables → spatial-join fallback would silently
#     produce 0% boundary coverage (the v2026.04 incident class)
#   - Missing raw_admin_bdys source tables (used for late prep / debugging)
#
# What this does NOT catch:
#   - Whether address_principal_admin_boundaries is populated. By design, this
#     table can legitimately be empty after a `--no-boundary-tag` retry — the
#     spatial-join fallback in address_full_prep.sql fills it at flatten time.
#     The verify.ts boundary coverage check (--check-boundary-coverage) is the
#     gate for that, AFTER flatten.
#
# Failure mode: prints which check failed (for log inspection) and exits 1.

PGUSER="${POSTGRES_USER:-postgres}"
PGPASSWORD="${POSTGRES_PASSWORD:-postgres}"
PGDB="${POSTGRES_DB:-gnaf}"

if [[ -z "${GNAF_VERSION:-}" ]]; then
  echo "[cache-validate] ERROR: GNAF_VERSION is required" >&2
  exit 1
fi

SCHEMA_VERSION="${GNAF_VERSION//./}"
if [[ ! "$SCHEMA_VERSION" =~ ^[0-9]{6}$ ]]; then
  echo "[cache-validate] ERROR: invalid GNAF_VERSION '$GNAF_VERSION'" >&2
  exit 1
fi

GNAF_SCHEMA="gnaf_${SCHEMA_VERSION}"
RAW_SCHEMA="raw_gnaf_${SCHEMA_VERSION}"
ADMIN_SCHEMA="admin_bdys_${SCHEMA_VERSION}"
RAW_ADMIN_SCHEMA="raw_admin_bdys_${SCHEMA_VERSION}"

# Smallest production state (OT — Christmas Island, Norfolk, etc.) is ~1500
# addresses. 500 is conservative for the address-level checks; any real cache
# clears it by orders of magnitude. The polygon tables only need ≥1 because
# the count varies wildly by state (OT has ~3 LGAs, NSW has ~130).
#
# MIN_ADDRESS_ROWS is overridable via env var so the fixture container (~451
# addresses) can reuse this validator with a lower floor.
MIN_ADDRESS_ROWS="${MIN_ADDRESS_ROWS:-500}"
MIN_BOUNDARY_ROWS="${MIN_BOUNDARY_ROWS:-1}"

PSQL=(psql -h localhost -U "$PGUSER" -d "$PGDB" -v ON_ERROR_STOP=1 -tA)

query_scalar() {
  PGPASSWORD="$PGPASSWORD" "${PSQL[@]}" -c "$1"
}

require_schema() {
  local schema_name="$1"
  local exists
  exists="$(query_scalar "SELECT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = '${schema_name}');")"
  if [[ "$exists" != "t" ]]; then
    echo "[cache-validate] FAIL: required schema missing: ${schema_name}" >&2
    exit 1
  fi
}

require_table_exists() {
  local schema_name="$1"
  local table_name="$2"
  local exists
  exists="$(query_scalar "SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = '${schema_name}' AND table_name = '${table_name}');")"
  if [[ "$exists" != "t" ]]; then
    echo "[cache-validate] FAIL: required table missing: ${schema_name}.${table_name}" >&2
    exit 1
  fi
}

require_min_rows() {
  local schema_name="$1"
  local table_name="$2"
  local min_rows="$3"
  local count
  count="$(query_scalar "SELECT COUNT(*) FROM ${schema_name}.${table_name};")"
  if [[ ! "$count" =~ ^[0-9]+$ ]]; then
    echo "[cache-validate] FAIL: failed to count ${schema_name}.${table_name}" >&2
    exit 1
  fi
  if (( count < min_rows )); then
    echo "[cache-validate] FAIL: ${schema_name}.${table_name} has ${count} rows (< ${min_rows})" >&2
    exit 1
  fi
}

# 1. Schemas exist (catches wrong GNAF_VERSION + truncated restore).
require_schema "$GNAF_SCHEMA"
require_schema "$RAW_SCHEMA"
require_schema "$ADMIN_SCHEMA"
require_schema "$RAW_ADMIN_SCHEMA"

# 2. Core G-NAF tables populated.
require_min_rows "$GNAF_SCHEMA" "address_principals" "$MIN_ADDRESS_ROWS"
require_min_rows "$GNAF_SCHEMA" "localities" 1
require_min_rows "$GNAF_SCHEMA" "streets" 1
require_min_rows "$RAW_SCHEMA" "address_detail" "$MIN_ADDRESS_ROWS"
require_min_rows "$RAW_SCHEMA" "address_site" 1

# 3. address_principal_admin_boundaries TABLE must exist (rows may be empty
#    if --no-boundary-tag fallback path is in play; the spatial-join fallback
#    fills it at flatten time).
require_table_exists "$GNAF_SCHEMA" "address_principal_admin_boundaries"

# 4. Mesh-block table — non-derived, populated by gnaf-loader's
#    `02-02d-prep-census-2021-bdys-tables.sql` during the load stage. The flatten
#    SQL joins this table by `mb21_code` to expand mesh block codes into
#    SA1/SA2/SA3/SA4/GCCSA. If it's missing or empty, the join silently produces
#    NULL for every mesh-block-derived field.
#
# WARNING — fixture/prod naming gotcha (E1.22):
#   Production gnaf-loader creates `admin_bdys.abs_2021_mb` (no `_lookup` suffix).
#   The fixture also creates `admin_bdys.abs_2021_mb_lookup` (a denormalized
#   no-geometry sibling) AND a mirror `abs_2021_mb` table. The validator MUST
#   check `abs_2021_mb` (the production name), NOT `abs_2021_mb_lookup`,
#   otherwise it works against the fixture but fails on every production state
#   build because the lookup table doesn't exist there. The original PR #99
#   validator referenced the wrong name and crashed all 9 quarterly states in
#   run #24127161800. Verified against gnaf-loader/postgres-scripts/02-02d
#   line 7 — the table name is unambiguous.
require_min_rows "$ADMIN_SCHEMA" "abs_2021_mb" 1

# 5. Boundary polygon tables — these are what the spatial-join fallback in
#    address_full_prep.sql joins against. If any are missing or empty, the
#    fallback silently produces 0% coverage for that boundary type. THIS is
#    the gate that should have caught the v2026.04 incident class.
require_min_rows "$ADMIN_SCHEMA" "local_government_areas" "$MIN_BOUNDARY_ROWS"
require_min_rows "$ADMIN_SCHEMA" "local_government_wards" "$MIN_BOUNDARY_ROWS"
require_min_rows "$ADMIN_SCHEMA" "commonwealth_electorates" "$MIN_BOUNDARY_ROWS"
require_min_rows "$ADMIN_SCHEMA" "state_lower_house_electorates" "$MIN_BOUNDARY_ROWS"
require_min_rows "$ADMIN_SCHEMA" "state_upper_house_electorates" "$MIN_BOUNDARY_ROWS"

# 6. Raw admin boundary source tables — used by fixtures/prep-admin-bdys.sql
#    in fixture mode and as a debugging fallback in production.
require_min_rows "$RAW_ADMIN_SCHEMA" "aus_lga" "$MIN_BOUNDARY_ROWS"

echo "[cache-validate] OK: database passed sanity checks for ${GNAF_VERSION}" >&2
