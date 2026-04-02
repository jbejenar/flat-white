#!/usr/bin/env bash
set -euo pipefail

# build-fixture-only.sh — Dev loop: seed Postgres with fixtures, flatten, output NDJSON
# Target: <30 seconds, no download, no gnaf-loader
#
# Usage: ./scripts/build-fixture-only.sh
#
# Prerequisites:
#   docker compose up db  (Postgres 16 + PostGIS 3.5 running)

echo "TODO: Implement fixture-only build (P0.10)"
echo "  1. Seed Postgres from fixtures/seed-postgres.sql"
echo "  2. Run flatten against fixture database"
echo "  3. Output to output/fixture.ndjson"
echo "  4. Validate against fixtures/expected-output.ndjson"
exit 1
