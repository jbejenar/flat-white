#!/usr/bin/env bash
set -euo pipefail

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
PSQL=(psql -h localhost -U "$PGUSER" -d "$PGDB" -v ON_ERROR_STOP=1 -tA)

query_scalar() {
  PGPASSWORD="$PGPASSWORD" "${PSQL[@]}" -c "$1"
}

require_schema() {
  local schema_name="$1"
  local exists
  exists="$(query_scalar "SELECT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = '${schema_name}');")"
  if [[ "$exists" != "t" ]]; then
    echo "[cache-validate] ERROR: required schema missing: ${schema_name}" >&2
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
    echo "[cache-validate] ERROR: failed to count ${schema_name}.${table_name}" >&2
    exit 1
  fi
  if (( count < min_rows )); then
    echo "[cache-validate] ERROR: ${schema_name}.${table_name} has ${count} rows (< ${min_rows})" >&2
    exit 1
  fi
}

require_schema "$GNAF_SCHEMA"
require_schema "$RAW_SCHEMA"
require_schema "$ADMIN_SCHEMA"

# These are the minimum viable tables for a post-load cache dump.
require_min_rows "$GNAF_SCHEMA" "address_principals" 1
require_min_rows "$GNAF_SCHEMA" "localities" 1
require_min_rows "$GNAF_SCHEMA" "streets" 1
require_min_rows "$RAW_SCHEMA" "address_detail" 1
require_min_rows "$RAW_SCHEMA" "address_site" 1
require_min_rows "$ADMIN_SCHEMA" "abs_2021_mb_lookup" 1

echo "[cache-validate] OK: restored database passed sanity checks for ${GNAF_VERSION}" >&2
