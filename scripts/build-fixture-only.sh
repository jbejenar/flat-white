#!/usr/bin/env bash
set -euo pipefail

# build-fixture-only.sh — Dev loop: seed Postgres with fixtures, flatten, output NDJSON
# Target: <30 seconds, no download, no gnaf-loader
#
# Usage: ./scripts/build-fixture-only.sh
#
# Prerequisites:
#   docker compose up db  (Postgres 16 + PostGIS 3.5 running)

echo "WARNING: Fixture build not yet implemented (P0.10)"
echo "  This script will be implemented when the flatten pipeline is built."
echo "  Steps planned:"
echo "    1. Seed Postgres from fixtures/seed-postgres.sql"
echo "    2. Run flatten against fixture database"
echo "    3. Output to output/fixture.ndjson"
echo "    4. Validate against fixtures/expected-output.ndjson"
exit 0
