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
SCHEMA="gnaf_$(echo "$GNAF_VERSION" | tr -d '.')"

echo "=== flat-white fixture extraction ==="
echo "Database: $DB_NAME"
echo "Schema: $SCHEMA"
echo "Output: $OUTPUT"

# Verify database is accessible
docker compose exec db pg_isready -U "$DB_USER" > /dev/null 2>&1 || {
  echo "ERROR: Postgres not running. Start with: docker compose up -d db"
  exit 1
}

# Verify gnaf-loader has run
COUNT=$(docker compose exec -T db psql -U "$DB_USER" -d "$DB_NAME" -t -A -c \
  "SELECT COUNT(*) FROM ${SCHEMA}.address_principals WHERE state = 'VIC';")
echo "VIC address count: $COUNT"
if [ "$COUNT" -lt 1000000 ]; then
  echo "ERROR: Expected ~3.8M VIC addresses, got $COUNT. Run gnaf-loader first."
  exit 1
fi

echo "Selecting fixture addresses (~450 across all edge case categories)..."

# Create fixture PID selection table
RAW_SCHEMA="raw_${SCHEMA}"
docker compose exec -T db psql -U "$DB_USER" -d "$DB_NAME" <<SELECTSQL
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
SELECTSQL

FIXTURE_COUNT=$(docker compose exec -T db psql -U "$DB_USER" -d "$DB_NAME" -t -A -c \
  "SELECT COUNT(*) FROM ${SCHEMA}.fixture_pids;")
echo "Selected $FIXTURE_COUNT unique fixture addresses"

echo "Generating $OUTPUT..."
echo "  (This extracts schema DDL + filtered data for the fixture subset)"
echo "  See fixtures/README.md for the full documentation."

# Note: The actual pg_dump + data extraction is done by the Python script
# that was used during initial generation. For re-extraction, run:
#   1. pg_dump --schema=gnaf_202602 --schema-only (pre-data + post-data)
#   2. Python script to COPY filtered data
#   3. Assemble: pre-data + data + post-data (minus cross-subset FK constraints)

echo ""
echo "WARNING: Full extraction pipeline not yet automated."
echo "  Fixture PIDs selected: $FIXTURE_COUNT"
echo "  Output NOT generated: $OUTPUT was NOT overwritten."
echo "  For now, refer to the generation commands in the PR that created this fixture."

# Cleanup temp table
docker compose exec -T db psql -U "$DB_USER" -d "$DB_NAME" -c \
  "DROP TABLE IF EXISTS ${SCHEMA}.fixture_pids;" > /dev/null 2>&1

exit 1
