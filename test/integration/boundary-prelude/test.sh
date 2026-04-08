#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
DB_SERVICE="db"
DB_NAME="gnaf"
DB_USER="postgres"
OUTPUT_FILE="$PROJECT_DIR/output/test-boundary-prelude.ndjson"
SCHEMA_VERSION="${GNAF_VERSION:-2026.02}"
SCHEMA_VERSION_FLAT="${SCHEMA_VERSION//.}"

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
    echo "[boundary-prelude] Starting Postgres on host port ${POSTGRES_PORT}..."
    docker compose up "$DB_SERVICE" -d --wait --force-recreate
    return
  fi

  if ! docker compose exec -T "$DB_SERVICE" pg_isready -U "$DB_USER" -q 2>/dev/null; then
    docker compose up "$DB_SERVICE" -d --wait
  fi
}

resolve_db_url() {
  if [[ -n "${DATABASE_URL:-}" ]]; then
    printf '%s\n' "$DATABASE_URL"
    return
  fi

  printf 'postgres://postgres:postgres@localhost:%s/gnaf\n' "$POSTGRES_PORT"
}

psql_db() {
  docker compose exec -T "$DB_SERVICE" psql -U "$DB_USER" -d "$DB_NAME" "$@"
}

echo "[boundary-prelude] Ensuring Postgres is ready..."
export POSTGRES_PORT="${POSTGRES_PORT:-$(resolve_postgres_port)}"
ensure_db_container

echo "[boundary-prelude] Seeding fixture data..."
psql_db -q -f /fixtures/seed-postgres.sql
psql_db -q -f /fixtures/seed-admin-bdys.sql
sed "s/__SCHEMA_VERSION__/${SCHEMA_VERSION_FLAT}/g" "$PROJECT_DIR/fixtures/prep-admin-bdys.sql" | \
  psql_db -q

echo "[boundary-prelude] Creating intentionally incomplete boundary table..."
psql_db -q <<SQL
DROP TABLE IF EXISTS gnaf_${SCHEMA_VERSION_FLAT}.address_principal_admin_boundaries CASCADE;
CREATE TABLE gnaf_${SCHEMA_VERSION_FLAT}.address_principal_admin_boundaries (
  gid integer,
  gnaf_pid text,
  locality_pid text,
  locality_name text,
  postcode text,
  state text,
  lga_pid text,
  lga_name text
);
SQL

echo "[boundary-prelude] Replaying shared boundary prelude..."
node "$PROJECT_DIR/scripts/extract-boundary-prelude.mjs" "$PROJECT_DIR/sql/address_full_prep.sql" | \
  sed "s/__SCHEMA_VERSION__/${SCHEMA_VERSION_FLAT}/g" | \
  psql_db -q

column_count="$(psql_db -tA <<SQL
SELECT COUNT(*)
FROM information_schema.columns
WHERE table_schema = 'gnaf_${SCHEMA_VERSION_FLAT}'
  AND table_name = 'address_principal_admin_boundaries';
SQL
)"

if [[ "$column_count" != "16" ]]; then
  echo "[boundary-prelude] ERROR: expected repaired boundary table to have 16 columns, got $column_count"
  exit 1
fi

unique_index_count="$(psql_db -tA <<SQL
SELECT COUNT(*)
FROM pg_indexes
WHERE schemaname = 'gnaf_${SCHEMA_VERSION_FLAT}'
  AND tablename = 'address_principal_admin_boundaries'
  AND indexname = 'address_principal_admin_boundaries_gnaf_pid_uniq';
SQL
)"

if [[ "$unique_index_count" != "1" ]]; then
  echo "[boundary-prelude] ERROR: expected repaired boundary table to have the unique gnaf_pid index"
  exit 1
fi

echo "[boundary-prelude] Running materialized flatten against repaired table..."
mkdir -p "$PROJECT_DIR/output"
DATABASE_URL="$(resolve_db_url)" \
GNAF_VERSION="$SCHEMA_VERSION" \
  node "$PROJECT_DIR/dist/flatten.js" "$OUTPUT_FILE" --materialize >/dev/null

line_count="$(wc -l < "$OUTPUT_FILE" | tr -d ' ')"
if [[ "$line_count" != "451" ]]; then
  echo "[boundary-prelude] ERROR: expected 451 output rows, got $line_count"
  exit 1
fi

echo "[boundary-prelude] PASS"
