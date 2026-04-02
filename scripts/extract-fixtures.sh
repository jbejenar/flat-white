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
SCHEMA="gnaf_202602"

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
docker compose exec -T db psql -U "$DB_USER" -d "$DB_NAME" << 'SELECTSQL'
DROP TABLE IF EXISTS gnaf_202602.fixture_pids;
CREATE TABLE gnaf_202602.fixture_pids AS SELECT DISTINCT gnaf_pid FROM (
  (SELECT gnaf_pid FROM gnaf_202602.address_principals WHERE state = 'VIC' AND flat_number IS NULL AND level_number IS NULL AND primary_secondary IS NULL ORDER BY md5(gnaf_pid) LIMIT 150)
  UNION ALL (SELECT gnaf_pid FROM gnaf_202602.address_principals WHERE flat_number IS NOT NULL ORDER BY md5(gnaf_pid) LIMIT 100)
  UNION ALL (SELECT gnaf_pid FROM gnaf_202602.address_principals WHERE level_number IS NOT NULL ORDER BY md5(gnaf_pid) LIMIT 50)
  UNION ALL (SELECT gnaf_pid FROM gnaf_202602.address_principals WHERE locality_name = 'MELBOURNE' AND postcode = '3000' ORDER BY md5(gnaf_pid) LIMIT 25)
  UNION ALL (SELECT gnaf_pid FROM gnaf_202602.address_principals WHERE locality_name = 'MELBOURNE' AND postcode = '3004' ORDER BY md5(gnaf_pid) LIMIT 25)
  UNION ALL (SELECT gnaf_pid FROM (SELECT DISTINCT ap.gnaf_pid FROM gnaf_202602.address_principals ap INNER JOIN gnaf_202602.address_alias_lookup aal ON ap.gnaf_pid = aal.principal_pid) sub ORDER BY md5(gnaf_pid) LIMIT 50)
  UNION ALL (SELECT gnaf_pid FROM gnaf_202602.address_principals WHERE primary_secondary = 'S' ORDER BY md5(gnaf_pid) LIMIT 60)
  UNION ALL (SELECT gnaf_pid FROM gnaf_202602.address_principals WHERE primary_secondary = 'P' ORDER BY md5(gnaf_pid) LIMIT 60)
  UNION ALL (SELECT ap.gnaf_pid FROM gnaf_202602.address_principals ap INNER JOIN raw_gnaf_202602.address_detail ad ON ap.gnaf_pid = ad.address_detail_pid INNER JOIN (SELECT address_site_pid FROM raw_gnaf_202602.address_site_geocode GROUP BY address_site_pid HAVING COUNT(*) >= 3) mg ON ad.address_site_pid = mg.address_site_pid ORDER BY md5(ap.gnaf_pid) LIMIT 50)
  UNION ALL (SELECT ap.gnaf_pid FROM gnaf_202602.address_principals ap INNER JOIN gnaf_202602.localities loc ON ap.locality_pid = loc.locality_pid WHERE loc.locality_class != 'GAZETTED LOCALITY' ORDER BY md5(ap.gnaf_pid) LIMIT 20)
  UNION ALL (SELECT ap.gnaf_pid FROM gnaf_202602.address_principals ap INNER JOIN gnaf_202602.address_principal_admin_boundaries bdy ON ap.gnaf_pid = bdy.gnaf_pid WHERE bdy.ward_name IS NOT NULL ORDER BY md5(ap.gnaf_pid) LIMIT 30)
  UNION ALL (SELECT gnaf_pid FROM gnaf_202602.address_principals WHERE lot_number IS NOT NULL AND number_first IS NULL ORDER BY md5(gnaf_pid) LIMIT 30)
  UNION ALL (SELECT gnaf_pid FROM gnaf_202602.address_principals WHERE building_name IS NOT NULL ORDER BY md5(gnaf_pid) LIMIT 30)
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
echo "TODO: Automate the full extraction pipeline."
echo "For now, refer to the generation commands in the PR that created this fixture."
echo ""
echo "Fixture PIDs selected: $FIXTURE_COUNT"
echo "Done."
