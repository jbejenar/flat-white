#!/usr/bin/env bash
set -euo pipefail

# extract-fixtures.sh — Re-extract fixture data from a full VIC gnaf-loader load
#
# Prerequisites:
#   - docker compose up db (Postgres 16 + PostGIS 3.5 running)
#   - gnaf-loader has completed a VIC load into the 'gnaf' database
#
# Output:
#   - fixtures/seed-postgres.sql (overwritten)
#
# Usage: ./scripts/extract-fixtures.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
FIXTURE_DIR="$PROJECT_DIR/fixtures"
OUTPUT="$FIXTURE_DIR/seed-postgres.sql"
DB_NAME="gnaf"
DB_USER="postgres"
# Fixtures are frozen at the Feb 2026 G-NAF release — default to 202602
GNAF_VERSION="${GNAF_VERSION:-2026.02}"
if ! [[ "$GNAF_VERSION" =~ ^[0-9]{4}\.[0-9]{2}$ ]]; then
  echo "ERROR: GNAF_VERSION must be YYYY.MM format (got: $GNAF_VERSION)"
  exit 1
fi
SCHEMA="gnaf_$(echo "$GNAF_VERSION" | tr -d '.')"
RAW_SCHEMA="raw_${SCHEMA}"
ADMIN_SCHEMA="admin_bdys_$(echo "$GNAF_VERSION" | tr -d '.')"

echo "=== flat-white fixture extraction ==="
echo "Database: $DB_NAME"
echo "Schema: $SCHEMA"
echo "Output: $OUTPUT"

# Helper: run psql inside docker
run_psql() {
  timeout 300 docker compose exec -T db psql -U "$DB_USER" -d "$DB_NAME" "$@"
}

# Helper: run psql and get a single value
psql_val() {
  run_psql -t -A -c "$1"
}

# Helper: extract \copy data for a filtered query
# Usage: extract_copy_data "schema.table" "col1, col2, ..." "WHERE clause or empty"
# Note: SELECT * is safe here because gnaf-loader always creates tables fresh (no ALTER TABLE
# column additions), so physical column order matches \copy FROM stdin expectations exactly.
extract_copy_data() {
  local table="$1"
  local columns="$2"
  local where_clause="${3:-}"
  local query="SELECT ${columns} FROM ${table}"
  if [ -n "$where_clause" ]; then
    query="${query} ${where_clause}"
  fi
  local count
  count=$(psql_val "SELECT COUNT(*) FROM ${table} ${where_clause}")
  echo ""
  echo "-- ${table}: ${count} rows"
  echo "\\copy ${table} FROM stdin"
  run_psql -t -A -F $'\t' -c "${query}" | sed '/^$/d'
  echo "\\."
}

# Verify database is accessible
timeout 30 docker compose exec db pg_isready -U "$DB_USER" > /dev/null 2>&1 || {
  echo "ERROR: Postgres not running. Start with: docker compose up -d db"
  exit 1
}

# Verify gnaf-loader has run
COUNT=$(psql_val "SELECT COUNT(*) FROM ${SCHEMA}.address_principals WHERE state = 'VIC';")
echo "VIC address count: $COUNT"
if [ "$COUNT" -lt 1000000 ]; then
  echo "ERROR: Expected ~3.8M VIC addresses, got $COUNT. Run gnaf-loader first."
  exit 1
fi

echo "Selecting fixture addresses (~450 across all edge case categories)..."

# Create fixture PID selection table + related entity tables
run_psql <<SELECTSQL
-- Step 1: Select fixture PIDs
DROP TABLE IF EXISTS ${SCHEMA}.fixture_pids;
CREATE TABLE ${SCHEMA}.fixture_pids AS SELECT DISTINCT gnaf_pid FROM (
  (SELECT gnaf_pid FROM ${SCHEMA}.address_principals WHERE state = 'VIC' AND flat_number IS NULL AND level_number IS NULL AND primary_secondary IS NULL ORDER BY md5(gnaf_pid) LIMIT 150)
  UNION ALL (SELECT gnaf_pid FROM ${SCHEMA}.address_principals WHERE flat_number IS NOT NULL ORDER BY md5(gnaf_pid) LIMIT 100)
  UNION ALL (SELECT gnaf_pid FROM ${SCHEMA}.address_principals WHERE level_number IS NOT NULL ORDER BY md5(gnaf_pid) LIMIT 50)
  UNION ALL (SELECT gnaf_pid FROM ${SCHEMA}.address_principals WHERE locality_name = 'MELBOURNE' AND postcode = '3000' ORDER BY md5(gnaf_pid) LIMIT 25)
  UNION ALL (SELECT gnaf_pid FROM ${SCHEMA}.address_principals WHERE locality_name = 'MELBOURNE' AND postcode = '3004' ORDER BY md5(gnaf_pid) LIMIT 25)
  UNION ALL (SELECT gnaf_pid FROM (SELECT DISTINCT ap.gnaf_pid FROM ${SCHEMA}.address_principals ap INNER JOIN ${SCHEMA}.address_alias_lookup aal ON ap.gnaf_pid = aal.principal_pid) sub ORDER BY md5(gnaf_pid) LIMIT 50)
  UNION ALL (SELECT gnaf_pid FROM ${SCHEMA}.address_principals WHERE primary_secondary = 'S' ORDER BY md5(gnaf_pid) LIMIT 60)
  UNION ALL (SELECT gnaf_pid FROM ${SCHEMA}.address_principals WHERE primary_secondary = 'P' ORDER BY md5(gnaf_pid) LIMIT 60)
  UNION ALL (SELECT ap.gnaf_pid FROM ${SCHEMA}.address_principals ap INNER JOIN ${RAW_SCHEMA}.address_detail ad ON ap.gnaf_pid = ad.address_detail_pid INNER JOIN (SELECT address_site_pid FROM ${RAW_SCHEMA}.address_site_geocode GROUP BY address_site_pid HAVING COUNT(*) >= 3) mg ON ad.address_site_pid = mg.address_site_pid ORDER BY md5(ap.gnaf_pid) LIMIT 50)
  UNION ALL (SELECT ap.gnaf_pid FROM ${SCHEMA}.address_principals ap INNER JOIN ${SCHEMA}.localities loc ON ap.locality_pid = loc.locality_pid WHERE loc.locality_class != 'GAZETTED LOCALITY' ORDER BY md5(ap.gnaf_pid) LIMIT 20)
  UNION ALL (SELECT ap.gnaf_pid FROM ${SCHEMA}.address_principals ap INNER JOIN ${SCHEMA}.address_principal_admin_boundaries bdy ON ap.gnaf_pid = bdy.gnaf_pid WHERE bdy.ward_name IS NOT NULL ORDER BY md5(ap.gnaf_pid) LIMIT 30)
  UNION ALL (SELECT gnaf_pid FROM ${SCHEMA}.address_principals WHERE lot_number IS NOT NULL AND number_first IS NULL ORDER BY md5(gnaf_pid) LIMIT 30)
  UNION ALL (SELECT gnaf_pid FROM ${SCHEMA}.address_principals WHERE building_name IS NOT NULL ORDER BY md5(gnaf_pid) LIMIT 30)
) all_pids;
CREATE INDEX ON ${SCHEMA}.fixture_pids (gnaf_pid);

-- Step 2: Derive related entity sets for efficient filtering
DROP TABLE IF EXISTS ${SCHEMA}.fixture_alias_pids;
CREATE TABLE ${SCHEMA}.fixture_alias_pids AS
  SELECT DISTINCT alias_pid AS gnaf_pid
  FROM ${SCHEMA}.address_alias_lookup
  WHERE principal_pid IN (SELECT gnaf_pid FROM ${SCHEMA}.fixture_pids);
CREATE INDEX ON ${SCHEMA}.fixture_alias_pids (gnaf_pid);

DROP TABLE IF EXISTS ${SCHEMA}.fixture_locality_pids;
CREATE TABLE ${SCHEMA}.fixture_locality_pids AS
  SELECT DISTINCT locality_pid FROM ${SCHEMA}.address_principals
  WHERE gnaf_pid IN (SELECT gnaf_pid FROM ${SCHEMA}.fixture_pids)
  UNION
  SELECT DISTINCT locality_pid FROM ${SCHEMA}.address_aliases
  WHERE gnaf_pid IN (SELECT gnaf_pid FROM ${SCHEMA}.fixture_alias_pids);
CREATE INDEX ON ${SCHEMA}.fixture_locality_pids (locality_pid);

DROP TABLE IF EXISTS ${SCHEMA}.fixture_street_pids;
CREATE TABLE ${SCHEMA}.fixture_street_pids AS
  SELECT DISTINCT street_locality_pid FROM ${SCHEMA}.address_principals
  WHERE gnaf_pid IN (SELECT gnaf_pid FROM ${SCHEMA}.fixture_pids)
  UNION
  SELECT DISTINCT street_locality_pid FROM ${SCHEMA}.address_aliases
  WHERE gnaf_pid IN (SELECT gnaf_pid FROM ${SCHEMA}.fixture_alias_pids);
CREATE INDEX ON ${SCHEMA}.fixture_street_pids (street_locality_pid);

DROP TABLE IF EXISTS ${SCHEMA}.fixture_site_pids;
CREATE TABLE ${SCHEMA}.fixture_site_pids AS
  SELECT DISTINCT address_site_pid FROM ${RAW_SCHEMA}.address_detail
  WHERE address_detail_pid IN (
    SELECT gnaf_pid FROM ${SCHEMA}.fixture_pids
    UNION ALL
    SELECT gnaf_pid FROM ${SCHEMA}.fixture_alias_pids
  );
CREATE INDEX ON ${SCHEMA}.fixture_site_pids (address_site_pid);
SELECTSQL

FIXTURE_COUNT=$(psql_val "SELECT COUNT(*) FROM ${SCHEMA}.fixture_pids;")
ALIAS_COUNT=$(psql_val "SELECT COUNT(*) FROM ${SCHEMA}.fixture_alias_pids;")
echo "Selected $FIXTURE_COUNT unique principal addresses, $ALIAS_COUNT aliases"

# Temporary directory for assembly
WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"; timeout 30 docker compose exec -T db psql -U '"$DB_USER"' -d '"$DB_NAME"' -c "DROP TABLE IF EXISTS '"$SCHEMA"'.fixture_pids, '"$SCHEMA"'.fixture_alias_pids, '"$SCHEMA"'.fixture_locality_pids, '"$SCHEMA"'.fixture_street_pids, '"$SCHEMA"'.fixture_site_pids;" > /dev/null 2>&1' EXIT

echo "Extracting schema DDL..."

# PART 1A: gnaf schema DDL (pre-data)
timeout 600 docker compose exec -T db pg_dump -U "$DB_USER" -d "$DB_NAME" \
  --schema="$SCHEMA" --schema-only --section=pre-data \
  --no-owner --no-privileges --no-tablespaces \
  > "$WORK_DIR/gnaf-pre-data.sql"

# PART 1B: raw_gnaf schema DDL (pre-data)
timeout 600 docker compose exec -T db pg_dump -U "$DB_USER" -d "$DB_NAME" \
  --schema="$RAW_SCHEMA" --schema-only --section=pre-data \
  --no-owner --no-privileges --no-tablespaces \
  > "$WORK_DIR/raw-pre-data.sql"

# PART 1C: admin_bdys schema DDL (abs_2021_mb only — we just need the schema)
timeout 600 docker compose exec -T db pg_dump -U "$DB_USER" -d "$DB_NAME" \
  --schema="$ADMIN_SCHEMA" --schema-only --section=pre-data \
  --no-owner --no-privileges --no-tablespaces \
  -t "${ADMIN_SCHEMA}.abs_2021_mb" \
  > "$WORK_DIR/admin-pre-data.sql"

echo "Extracting fixture data..."

# PART 2: gnaf processed table data
{
  echo ""
  echo "-- PART 2: Fixture data"
  echo "-- ============================================"

  # Localities
  extract_copy_data "${SCHEMA}.localities" "*" \
    "WHERE locality_pid IN (SELECT locality_pid FROM ${SCHEMA}.fixture_locality_pids)"

  # Locality aliases
  extract_copy_data "${SCHEMA}.locality_aliases" "*" \
    "WHERE locality_pid IN (SELECT locality_pid FROM ${SCHEMA}.fixture_locality_pids)"

  # Locality neighbour lookup
  extract_copy_data "${SCHEMA}.locality_neighbour_lookup" "*" \
    "WHERE locality_pid IN (SELECT locality_pid FROM ${SCHEMA}.fixture_locality_pids)"

  # Streets
  extract_copy_data "${SCHEMA}.streets" "*" \
    "WHERE street_locality_pid IN (SELECT street_locality_pid FROM ${SCHEMA}.fixture_street_pids)"

  # Street aliases
  extract_copy_data "${SCHEMA}.street_aliases" "*" \
    "WHERE street_locality_pid IN (SELECT street_locality_pid FROM ${SCHEMA}.fixture_street_pids)"

  # Address principals
  extract_copy_data "${SCHEMA}.address_principals" "*" \
    "WHERE gnaf_pid IN (SELECT gnaf_pid FROM ${SCHEMA}.fixture_pids)"

  # Address aliases
  extract_copy_data "${SCHEMA}.address_aliases" "*" \
    "WHERE gnaf_pid IN (SELECT gnaf_pid FROM ${SCHEMA}.fixture_alias_pids)"

  # Address alias lookup
  extract_copy_data "${SCHEMA}.address_alias_lookup" "*" \
    "WHERE principal_pid IN (SELECT gnaf_pid FROM ${SCHEMA}.fixture_pids)"

  # Address secondary lookup (both sides of the relationship)
  extract_copy_data "${SCHEMA}.address_secondary_lookup" "*" \
    "WHERE primary_pid IN (SELECT gnaf_pid FROM ${SCHEMA}.fixture_pids) OR secondary_pid IN (SELECT gnaf_pid FROM ${SCHEMA}.fixture_pids)"

  echo ""
  echo "-- ${SCHEMA}.address_principal_admin_boundaries: DERIVED via spatial join (E1.10)"
  echo "-- Data is no longer pre-baked. The spatial join fallback in address_full_prep.sql"
  echo "-- populates this table from admin_bdys boundary polygons loaded by seed-admin-bdys.sql"
  echo "-- and prepared by prep-admin-bdys.sql."
  echo ""
} > "$WORK_DIR/data-gnaf.sql"

# PART 2B: raw table data
{
  echo ""
  echo "-- ============================================"
  echo "-- PART 2B: Raw table data (for flatten pipeline)"
  echo "-- ============================================"

  # Authority tables — dump ALL rows (small reference data)
  for aut_table in flat_type_aut level_type_aut street_type_aut street_suffix_aut \
                   geocode_type_aut geocode_reliability_aut locality_class_aut \
                   address_type_aut address_alias_type_aut street_class_aut; do
    extract_copy_data "${RAW_SCHEMA}.${aut_table}" "*" ""
  done

  # Address detail
  extract_copy_data "${RAW_SCHEMA}.address_detail" "*" \
    "WHERE address_detail_pid IN (SELECT gnaf_pid FROM ${SCHEMA}.fixture_pids)"

  # Address site
  extract_copy_data "${RAW_SCHEMA}.address_site" "*" \
    "WHERE address_site_pid IN (SELECT address_site_pid FROM ${SCHEMA}.fixture_site_pids)"

  # Address site geocode
  extract_copy_data "${RAW_SCHEMA}.address_site_geocode" "*" \
    "WHERE address_site_pid IN (SELECT address_site_pid FROM ${SCHEMA}.fixture_site_pids)"

  # Address default geocode
  extract_copy_data "${RAW_SCHEMA}.address_default_geocode" "*" \
    "WHERE address_detail_pid IN (SELECT gnaf_pid FROM ${SCHEMA}.fixture_pids)"

} > "$WORK_DIR/data-raw.sql"

# Address alias admin boundaries data
{
  extract_copy_data "${SCHEMA}.address_alias_admin_boundaries" "*" \
    "WHERE gnaf_pid IN (SELECT gnaf_pid FROM ${SCHEMA}.fixture_alias_pids)"
} > "$WORK_DIR/data-alias-bdys.sql"

# ABS mesh block lookup data
{
  extract_copy_data "${ADMIN_SCHEMA}.abs_2021_mb" "*" \
    "WHERE mb21_code IN (SELECT DISTINCT mb_2021_code FROM ${SCHEMA}.address_principals WHERE gnaf_pid IN (SELECT gnaf_pid FROM ${SCHEMA}.fixture_pids) AND mb_2021_code IS NOT NULL)"
} > "$WORK_DIR/data-abs.sql"

echo "Extracting constraints and indexes..."

# PART 3: Post-data (constraints + indexes) — gnaf schema only
# The raw schema has no constraints in gnaf-loader's output
timeout 600 docker compose exec -T db pg_dump -U "$DB_USER" -d "$DB_NAME" \
  --schema="$SCHEMA" --schema-only --section=post-data \
  --no-owner --no-privileges --no-tablespaces \
  > "$WORK_DIR/gnaf-post-data.sql"

# Filter out FK constraints that reference rows outside the fixture subset.
# These constraints would fail because not all referenced rows are in the fixture.
# Specifically: locality_neighbour_lookup_fk2 (neighbour_locality_pid may be outside fixture)
# and address_aliases_fk2 (street FK may reference streets outside fixture if alias streets differ).
# We keep a list of constraints to exclude and filter them out.
EXCLUDE_CONSTRAINTS="locality_neighbour_lookup_fk2|address_aliases_fk2"
# Use a multi-line aware approach: remove entire constraint blocks for excluded constraints
python3 -c "
import re, sys
content = sys.stdin.read()
# Remove entire ALTER TABLE ... ADD CONSTRAINT blocks for excluded constraints
for name in '${EXCLUDE_CONSTRAINTS}'.split('|'):
    # Match the comment block + the ALTER TABLE statement
    pattern = r'--\n-- Name: \w+ ' + re.escape(name) + r'.*?;\n'
    content = re.sub(pattern, '', content, flags=re.DOTALL)
sys.stdout.write(content)
" < "$WORK_DIR/gnaf-post-data.sql" > "$WORK_DIR/gnaf-post-data-filtered.sql"

# Verify excluded FK constraints were actually removed
if grep -q 'locality_neighbour_lookup_fk2\|address_aliases_fk2' "$WORK_DIR/gnaf-post-data-filtered.sql"; then
  echo "ERROR: FK constraint filtering failed — excluded constraints still present"
  exit 1
fi

echo "Assembling $OUTPUT..."

# Determine generation date
GEN_DATE=$(date +%Y-%m-%d)

{
  cat <<HEADER
-- flat-white fixture data (seed-postgres.sql)
-- Generated: ${GEN_DATE}
-- Source: G-NAF February 2026 (GDA2020), gnaf-loader v202602
-- Fixture: ${FIXTURE_COUNT} VIC addresses covering all edge case categories
--
-- Load: docker compose exec db psql -U postgres -d gnaf -f /fixtures/seed-postgres.sql
-- Time: <30 seconds on commodity hardware
--
-- This file captures gnaf-loader's exact output schema + a subset of data.
-- If gnaf-loader changes its schema, this file becomes incompatible -> drift detected.
--
-- Structure:
--   1. Drop existing schemas (clean slate)
--   1A. Schema + table creation — gnaf_202602 (processed)
--   1B. Schema + table creation — raw_gnaf_202602 (raw, for flatten pipeline)
--   2. Data load (COPY) — processed tables
--   2B. Data load (COPY) — raw tables
--   3. Constraints + indexes

-- Clean slate — drop if exists
DROP SCHEMA IF EXISTS ${SCHEMA} CASCADE;
DROP SCHEMA IF EXISTS ${RAW_SCHEMA} CASCADE;
DROP SCHEMA IF EXISTS ${ADMIN_SCHEMA} CASCADE;

-- ============================================
-- PART 1: Schema + table creation
-- ============================================
HEADER

  cat "$WORK_DIR/gnaf-pre-data.sql"

  cat <<PART1B_HEADER

-- ============================================
-- ============================================
-- PART 1B: Raw tables schema (for flatten pipeline)
-- (from pg_dump of ${RAW_SCHEMA})
-- ============================================
PART1B_HEADER

  cat "$WORK_DIR/raw-pre-data.sql"

  cat <<PART1C_HEADER

-- ============================================
-- ============================================
-- PART 1C: ABS mesh block lookup (for SA1-SA4, GCCSA, MB category)
-- (from pg_dump of ${ADMIN_SCHEMA})
-- ============================================
PART1C_HEADER

  cat "$WORK_DIR/admin-pre-data.sql"

  echo ""
  echo "-- ============================================"
  echo "-- ============================================"

  cat "$WORK_DIR/data-gnaf.sql"

  echo ""
  echo "-- ============================================"

  cat "$WORK_DIR/data-raw.sql"

  cat "$WORK_DIR/data-alias-bdys.sql"

  cat "$WORK_DIR/data-abs.sql"

  # E1.22: mirror block removed — abs_2021_mb is now the canonical name
  # everywhere (fixture seed, production gnaf-loader, extract-fixtures).
  # The old abs_2021_mb_lookup → abs_2021_mb mirror is no longer needed.

  echo ""
  echo ""

  # Reset sequences
  cat <<SEQRESET
-- Reset sequences to match loaded data
SELECT setval('${SCHEMA}.address_principals_gid_seq', (SELECT COALESCE(MAX(gid), 0) FROM ${SCHEMA}.address_principals));
SELECT setval('${SCHEMA}.address_aliases_gid_seq', (SELECT COALESCE(MAX(gid), 0) FROM ${SCHEMA}.address_aliases));
SELECT setval('${SCHEMA}.streets_gid_seq', (SELECT COALESCE(MAX(gid), 0) FROM ${SCHEMA}.streets));
SELECT setval('${SCHEMA}.street_aliases_gid_seq', (SELECT COALESCE(MAX(gid), 0) FROM ${SCHEMA}.street_aliases));
SELECT setval('${SCHEMA}.address_principal_admin_boundaries_gid_seq', GREATEST(1, (SELECT COALESCE(MAX(gid), 0) FROM ${SCHEMA}.address_principal_admin_boundaries)));
SELECT setval('${SCHEMA}.address_alias_admin_boundaries_gid_seq', (SELECT COALESCE(MAX(gid), 0) FROM ${SCHEMA}.address_alias_admin_boundaries));
SEQRESET

  echo ""
  echo "-- PART 3: Constraints + indexes"
  echo "-- (FK constraints referencing rows outside the fixture subset are excluded:"
  echo "--  address_aliases_fk2, locality_neighbour_lookup_fk2)"
  echo "-- ============================================"

  cat "$WORK_DIR/gnaf-post-data-filtered.sql"

  echo ""
  echo ""
  echo ""
  echo ""
  echo "-- ============================================"

} > "$OUTPUT"

LINE_COUNT=$(wc -l < "$OUTPUT")
FILE_SIZE=$(du -h "$OUTPUT" | cut -f1)
echo ""
echo "=== Extraction complete ==="
echo "  Output: $OUTPUT"
echo "  Lines: $LINE_COUNT"
echo "  Size: $FILE_SIZE"
echo "  Fixture addresses: $FIXTURE_COUNT"
echo "  Alias addresses: $ALIAS_COUNT"
echo ""
echo "Next steps:"
echo "  1. Verify: docker compose exec db psql -U postgres -d gnaf -f /fixtures/seed-postgres.sql"
echo "  2. Run: ./scripts/build-fixture-only.sh"
echo "  3. Compare output against expected-output.ndjson"
