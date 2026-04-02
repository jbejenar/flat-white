#!/usr/bin/env bash
set -euo pipefail

# build-fixture-only.sh — Dev loop: seed Postgres with fixtures, flatten, output NDJSON
# Target: <30 seconds, no download, no gnaf-loader
#
# Usage: ./scripts/build-fixture-only.sh
#
# Prerequisites:
#   docker compose up db  (Postgres 16 + PostGIS 3.5 running)

echo "WARNING: Flatten pipeline not yet implemented (P0.06, P0.10)"
echo "  Fixture data is ready — seed-postgres.sql loads 451 addresses in <30s."
echo "  Steps planned (once flatten SQL + TypeScript pipeline exist):"
echo "    1. Load fixtures/seed-postgres.sql into Postgres"
echo "    2. Run flatten SQL against fixture database"
echo "    3. Output to output/fixture.ndjson"
echo "    4. Validate against fixtures/expected-output.ndjson"
echo ""
echo "  To load fixture data now:"
echo "    docker compose exec -T db psql -U postgres -d gnaf -f /fixtures/seed-postgres.sql"
exit 0
