#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../../.."

# Run after build-fixture-only.sh. All mutations are rolled back, including on
# assertion failure when psql disconnects. Exercise both real export queries.
{
  cat <<'SQL'
BEGIN;
UPDATE raw_gnaf_202602.address_site_geocode SET date_retired='2026-02-01'
WHERE address_site_pid='411236384';
INSERT INTO raw_gnaf_202602.address_site_geocode
  (address_site_geocode_pid,date_created,address_site_pid,geocode_type_code,reliability_code,longitude,latitude)
VALUES
  ('FW_TIE_003','2026-02-01','411236384','EAS',2,145.003,-37.003),
  ('FW_TIE_002','2026-02-01','411236384','EAS',2,145.002,-37.002),
  ('FW_TIE_001','2026-02-01','411236384','PAPS',2,145.001,-37.001);
SQL
  for pass in reversed reordered; do
    if [[ "$pass" == reordered ]]; then
      cat <<'SQL'
CREATE TEMP TABLE moved_points AS
SELECT * FROM raw_gnaf_202602.address_site_geocode WHERE address_site_geocode_pid LIKE 'FW_TIE_%';
DELETE FROM raw_gnaf_202602.address_site_geocode WHERE address_site_geocode_pid LIKE 'FW_TIE_%';
INSERT INTO raw_gnaf_202602.address_site_geocode SELECT * FROM moved_points ORDER BY address_site_geocode_pid;
DROP TABLE cte_rows, materialized_rows;
SQL
    fi
    printf 'CREATE TEMP TABLE cte_rows AS\n'
    sed 's/__SCHEMA_VERSION__/202602/g' sql/address_full.sql
    sed 's/__SCHEMA_VERSION__/202602/g' sql/address_full_prep.sql
    printf 'CREATE TEMP TABLE materialized_rows AS\n'
    sed 's/__SCHEMA_VERSION__/202602/g' sql/address_full_main.sql
    cat <<'SQL'
DO $$ BEGIN
  IF EXISTS (
    SELECT 1 FROM cte_rows c FULL JOIN materialized_rows m USING (_id)
    WHERE to_jsonb(c) IS DISTINCT FROM to_jsonb(m)
  ) OR (SELECT COUNT(*) FROM cte_rows) <> 451
  THEN RAISE EXCEPTION 'CTE and materialized export paths disagree'; END IF;
  IF (SELECT (best_geocode->>'longitude')::numeric FROM cte_rows WHERE _id='GAVIC411087566') IS DISTINCT FROM 145.001
    OR (SELECT best_geocode->>'type' FROM cte_rows WHERE _id='GAVIC411087566') IS DISTINCT FROM 'PROPERTY ACCESS POINT SETBACK'
    OR (SELECT jsonb_path_query_array(all_geocodes::jsonb, '$[*].lng') FROM cte_rows WHERE _id='GAVIC411087566') IS DISTINCT FROM '[145.002,145.003,145.001]'::jsonb
  THEN RAISE EXCEPTION 'Equal-ranked types or duplicate-type points depend on physical row order'; END IF;
END $$;
SQL
  done
  printf 'ROLLBACK;\n'
} | docker compose exec -T db psql -v ON_ERROR_STOP=1 -U postgres -d gnaf -q
echo '[site-ordering] PASS: both export paths retain all 451 rows and stable selection in both insertion orders'
