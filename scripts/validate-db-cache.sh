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
#    address_full_prep.sql joins against. If any required table is missing or
#    empty, the fallback silently produces 0% coverage for that boundary type.
#    THIS is the gate that should have caught the v2026.04 incident class.
#
# STATE-AWARE FILTERING — important. Production gnaf-loader filters which
# polygon tables it loads based on which states are being built. The rules
# come from `gnaf-loader/settings.py:208-217` (the `admin_bdy_list` block):
#
#   - ce: NOT loaded if states_to_load == ["OT"]
#   - lga: NOT loaded if states_to_load == ["ACT"]
#   - ward: ONLY loaded if any of NT/SA/VIC/WA in states_to_load
#   - se_lower: NOT loaded if states_to_load == ["OT"]
#   - se_upper: ONLY loaded if any of TAS/VIC/WA in states_to_load
#
# The shapefile loader at `gnaf-loader/load-gnaf.py:325-330` enforces this
# physically: it only loads shapefiles whose filename starts with the
# lowercase state prefix (`act_*.shp`, `ot_*.shp`, etc.), and the Geoscape
# admin boundaries archive only ships shapefiles for boundary types each
# state actually has. The prep SQL (`02-02a-prep-admin-bdys-tables.sql`)
# then INNER JOINs against the raw tables — if the raw table doesn't
# exist, the prep silently fails (`geoscape.multiprocess_list` logs but
# continues), and the polygon table doesn't get created.
#
# Result: a single-state build of OT-only ends up with ONLY local_government_areas
# in admin_bdys_*. ACT-only has ce + se_lower. NSW/QLD have ce + lga + se_lower.
# NT has ce + lga + ward + se_lower. SA same as NT. TAS has ce + lga + se_lower
# + se_upper. Only VIC and WA have all 5.
#
# The validator must mirror this exactly. Take a STATES env var from the
# entrypoint (whitespace-separated, matching gnaf-loader's --states format,
# e.g. "OT" or "VIC NSW") and only require the polygon tables that gnaf-loader
# would have loaded for that state set. When STATES is unset or empty (the
# docker-smoke fixture path and any all-states production caller), fall back
# to strict-all-five — both of those callers DO have all 5 polygon tables,
# and the strict default catches future per-state callers that forget to
# pass STATES.

# Tokenize STATES on shell whitespace into a bash array. Mirrors Python's
# `states_to_load` list (set from `--states VIC NSW` → `["VIC","NSW"]`).
# Whitespace-only or empty STATES produces an empty array (length 0).
read -ra states_arr <<< "${STATES:-}"

# Validate every token against the known set of state codes from
# gnaf-loader/settings.py (--states choices). Reject unknown tokens with a
# loud error so a typo (e.g. STATES="vic") or wrong delimiter
# (e.g. STATES="VIC,NSW" — gnaf-loader uses space, not comma) cannot
# silently bypass all polygon validation. This is the post-load /
# post-restore safety gate; failing closed on malformed input is the only
# correct direction.
KNOWN_STATES=(ACT NSW NT OT QLD SA TAS VIC WA)
for token in "${states_arr[@]}"; do
  found=false
  for known in "${KNOWN_STATES[@]}"; do
    if [[ "$token" == "$known" ]]; then
      found=true
      break
    fi
  done
  if [[ "$found" == "false" ]]; then
    echo "[cache-validate] ERROR: invalid STATES token '${token}'" >&2
    echo "[cache-validate] STATES must be a whitespace-separated list of state codes from: ${KNOWN_STATES[*]}" >&2
    echo "[cache-validate] Got: '${STATES:-(unset)}'" >&2
    exit 1
  fi
done

# state_in_list — mirrors Python's `"X" in states_to_load`
state_in_list() {
  local needle="$1"
  local s
  for s in "${states_arr[@]}"; do
    [[ "$s" == "$needle" ]] && return 0
  done
  return 1
}

# is_only_X — mirrors Python's `states_to_load == ["X"]` (length-1 list equality)
is_only_ot()  { [[ "${#states_arr[@]}" -eq 1 && "${states_arr[0]}" == "OT"  ]]; }
is_only_act() { [[ "${#states_arr[@]}" -eq 1 && "${states_arr[0]}" == "ACT" ]]; }

need_ce=false
need_lga=false
need_ward=false
need_se_lower=false
need_se_upper=false

# Empty parsed array → strict all-five fallback. Keys off the array length
# (not a substring strip on $STATES) so any whitespace-only input — spaces,
# tabs, newlines, etc. — collapses to the same fallback. Matches the
# fixture path (which has all 5) and any all-states production caller.
if [[ "${#states_arr[@]}" -eq 0 ]]; then
  need_ce=true
  need_lga=true
  need_ward=true
  need_se_lower=true
  need_se_upper=true
else
  # Per-state logic — line-by-line mirror of settings.py:208-217.
  if ! is_only_ot; then
    need_ce=true
    need_se_lower=true
  fi
  if ! is_only_act; then
    need_lga=true
  fi
  if state_in_list NT || state_in_list SA || state_in_list VIC || state_in_list WA; then
    need_ward=true
  fi
  if state_in_list TAS || state_in_list VIC || state_in_list WA; then
    need_se_upper=true
  fi
fi

[[ "$need_ce"       == true ]] && require_min_rows "$ADMIN_SCHEMA" "commonwealth_electorates"      "$MIN_BOUNDARY_ROWS"
[[ "$need_lga"      == true ]] && require_min_rows "$ADMIN_SCHEMA" "local_government_areas"        "$MIN_BOUNDARY_ROWS"
[[ "$need_ward"     == true ]] && require_min_rows "$ADMIN_SCHEMA" "local_government_wards"        "$MIN_BOUNDARY_ROWS"
[[ "$need_se_lower" == true ]] && require_min_rows "$ADMIN_SCHEMA" "state_lower_house_electorates" "$MIN_BOUNDARY_ROWS"
[[ "$need_se_upper" == true ]] && require_min_rows "$ADMIN_SCHEMA" "state_upper_house_electorates" "$MIN_BOUNDARY_ROWS"

# 6. The raw admin boundary tables (raw_admin_bdys_*.aus_*) are intermediate
#    products of gnaf-loader's shp2pgsql step. They feed into the prep SQL
#    that builds admin_bdys_*.{commonwealth_electorates, local_government_areas,
#    ...}. We don't validate them directly because:
#
#    - The prep'd polygon tables checked above (section 5) are the actual
#      consumers of the raw data. If a raw table is missing, the corresponding
#      polygon table won't get prep'd → caught by section 5 already.
#    - Production gnaf-loader's per-state shapefile filtering means the raw
#      table presence is per-state-conditional. Coupling raw checks to the
#      same `need_*` gates as the polygon checks reuses logic that was meant
#      for a different concern, and the two could legitimately diverge in
#      future (e.g. if gnaf-loader adds an intermediate that the polygon
#      doesn't directly consume).
#
#    If a future failure mode needs raw-table validation, add a separate
#    `need_raw_*` rule set distinct from the polygon `need_*` rules.

echo "[cache-validate] OK: database passed sanity checks for ${GNAF_VERSION}" >&2
