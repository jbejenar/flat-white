#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../../.."
export GNAF_VERSION=2026.02
export DATABASE_URL="${DATABASE_URL:-postgres://postgres:postgres@localhost:${POSTGRES_PORT:-5432}/gnaf}"
scratch=$(mktemp -d)
psql_db() { docker compose exec -T db psql -v ON_ERROR_STOP=1 -U postgres -d gnaf "$@"; }
cleanup() {
  psql_db -qc "DELETE FROM raw_gnaf_202602.address_default_geocode WHERE address_default_geocode_pid = 'FW_CONFLICT'" >/dev/null
  rm -rf "$scratch"
}
trap cleanup EXIT

# Exercise the actual generated SQL inside a rollback-only transaction.
{
  printf 'BEGIN;\n'
  sed 's/__SCHEMA_VERSION__/202602/g' sql/address_geocodes_prep.sql
  cat <<'SQL'
DO $$ BEGIN
  IF (SELECT best_geocode->>'longitude' FROM tmp_address_geocodes WHERE address_detail_pid='GAVIC411087566') IS DISTINCT FROM '144.89700000'
    OR (SELECT jsonb_array_length(all_geocodes) FROM tmp_address_geocodes WHERE address_detail_pid='GAVIC411087566') IS DISTINCT FROM 3
    OR (SELECT fallback_geocode->>'precision' FROM tmp_address_geocodes WHERE address_detail_pid='GAVIC411441273') IS DISTINCT FROM 'street'
    OR (SELECT fallback_geocode->>'precision' FROM tmp_address_geocodes WHERE address_detail_pid='GAVIC411670057') IS DISTINCT FROM 'locality'
    OR (SELECT fallback_geocode FROM tmp_address_geocodes WHERE address_detail_pid='GAVIC411685451') IS NOT NULL
  THEN RAISE EXCEPTION 'Fixture selection or validity regression'; END IF;
END $$;
UPDATE raw_gnaf_202602.address_site_geocode SET reliability_code=1 WHERE address_site_geocode_pid='FW_SITE_003';
UPDATE raw_gnaf_202602.address_default_geocode SET geocode_type_code='UNK' WHERE address_detail_pid='GAVIC411670057';
SQL
  sed 's/__SCHEMA_VERSION__/202602/g' sql/address_geocodes_prep.sql
  cat <<'SQL'
DO $$ BEGIN
  IF (SELECT best_geocode->>'typeCode' FROM tmp_address_geocodes WHERE address_detail_pid='GAVIC411087566') IS DISTINCT FROM 'PC'
    OR (SELECT fallback_geocode->>'precision' FROM tmp_address_geocodes WHERE address_detail_pid='GAVIC411670057') IS DISTINCT FROM 'unknown'
  THEN RAISE EXCEPTION 'Reliability must precede type preference; unknown defaults remain explicit'; END IF;
END $$;
UPDATE raw_gnaf_202602.address_default_geocode SET date_retired='2026-02-01' WHERE address_detail_pid='GAVIC411670057';
SQL
  sed 's/__SCHEMA_VERSION__/202602/g' sql/address_geocodes_prep.sql
  cat <<'SQL'
DO $$ BEGIN
  IF (SELECT fallback_geocode FROM tmp_address_geocodes WHERE address_detail_pid='GAVIC411670057') IS NOT NULL
  THEN RAISE EXCEPTION 'Retired defaults must not escape'; END IF;
END $$;
ROLLBACK;
SQL
} | psql_db -q

# A conflict must fail the full exporter, leave its diagnosis, and never pick a default.
psql_db -q <<'SQL'
INSERT INTO raw_gnaf_202602.address_default_geocode
  (address_default_geocode_pid,date_created,address_detail_pid,geocode_type_code,longitude,latitude)
VALUES ('FW_CONFLICT','2026-02-01','GAVIC411441273','STL',145,-38);
SQL
if node dist/flatten.js "$scratch/conflict.ndjson" > "$scratch/flatten.log" 2>&1; then
  echo 'ERROR: conflicting defaults did not block export'; exit 1
fi
python3 - "$scratch" <<'PY'
import json, sys
from pathlib import Path
root=Path(sys.argv[1]); report=json.loads((root/'conflict.ndjson.geocodes.json').read_text())
assert report['passed'] is False and report['affectedAddresses']['conflictingDefaults']==1, report
assert report['samples']['conflictingDefaults']==['GAVIC411441273'], report
doc=next(d for d in map(json.loads,(root/'conflict.ndjson').read_text().splitlines()) if d['_id']=='GAVIC411441273')
assert doc['fallbackGeocode'] is None and doc['geocode'] is None and doc['location'] is None, doc
PY
echo '[geocodes] PASS: stable ties, reliability ordering, invalid/retired points, duplicate/unknown defaults and conflict publication block'
