#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../../.."
export GNAF_VERSION=2099.02
export DATABASE_URL="${DATABASE_URL:-postgres://postgres:postgres@localhost:${POSTGRES_PORT:-5432}/gnaf}"
scratch=$(mktemp -d)
psql_db() { docker compose exec -T db psql -v ON_ERROR_STOP=1 -U postgres -d gnaf "$@"; }
cleanup() {
  psql_db -qc 'DROP SCHEMA IF EXISTS raw_gnaf_209902 CASCADE; DROP SCHEMA IF EXISTS gnaf_209902 CASCADE' >/dev/null
  rm -rf "$scratch"
}
trap cleanup EXIT
psql_db -q <<'SQL'
CREATE SCHEMA raw_gnaf_209902;
CREATE SCHEMA gnaf_209902;
CREATE TABLE raw_gnaf_209902.address_detail (address_detail_pid text, confidence integer, alias_principal text, date_retired date);
INSERT INTO raw_gnaf_209902.address_detail VALUES
 ('a', 0, 'P', NULL), ('b', 1, 'P', NULL), ('c', 2, 'P', NULL),
 ('retired', 1, 'P', '2026-01-01'), ('alias', 1, 'A', NULL), ('negative', -1, 'P', NULL);
CREATE TABLE gnaf_209902.address_principals (gnaf_pid text);
INSERT INTO gnaf_209902.address_principals VALUES ('a'), ('b'), ('c');
SQL
output="$scratch/output.ndjson"
printf '%s\n' '{"_id":"c"}' '{"_id":"a"}' '{"_id":"b"}' > "$output"
node dist/reconcile.js "$output"
expect_failure() {
  if node dist/reconcile.js "$output" > "$scratch/result.log" 2>&1; then
    echo "ERROR: expected reconciliation failure: $1"; exit 1
  fi
  python3 - "$output.reconciliation.json" "$1" "$2" <<'PY'
import json, sys
report = json.load(open(sys.argv[1]))
value = report
for key in sys.argv[2].split('.'): value = value[key]
assert report['passed'] is False and value == int(sys.argv[3]), report
PY
}
printf '%s\n' '{"_id":"a"}' '{"_id":"b"}' '{"_id":"x"}' > "$output"
expect_failure loadedToOutput.missing 1
printf '%s\n' '{"_id":"a"}' '{"_id":"a"}' '{"_id":"c"}' > "$output"
expect_failure output.duplicateCount 1
printf '%s\n' '{"_id":"a"}' '{"_id":"b"}' '{"_id":"c"}' > "$output"
psql_db -qc "UPDATE gnaf_209902.address_principals SET gnaf_pid = 'substitute' WHERE gnaf_pid = 'b'"
expect_failure sourceToLoaded.missing 1
psql_db -qc "UPDATE gnaf_209902.address_principals SET gnaf_pid = 'b' WHERE gnaf_pid = 'substitute'; INSERT INTO gnaf_209902.address_principals VALUES ('b')"
expect_failure loaded.duplicateCount 1
echo '[reconciliation] PASS: eligibility, equal-count substitution, output and loaded duplicates'
