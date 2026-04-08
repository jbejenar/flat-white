-- address_full_prep.sql — Pre-materialize aggregation tables for production-scale flattening.
-- Creates temporary tables for geocode, locality, street, and address aggregations
-- so the main SELECT (address_full_main.sql) is a simple multi-join that streams efficiently.
--
-- Usage: Run once before cursor-based streaming of address_full_main.sql.
-- Schema: gnaf___SCHEMA_VERSION__, raw_gnaf___SCHEMA_VERSION__, admin_bdys___SCHEMA_VERSION__

-- FIXTURE_BOUNDARY_PRELUDE_START
-- 0. Ensure admin boundary tables exist (empty stubs if --no-boundary-tag or partial load).
-- Both schemas (gnaf___SCHEMA_VERSION__ and admin_bdys___SCHEMA_VERSION__) are created by gnaf-loader.
CREATE SCHEMA IF NOT EXISTS admin_bdys___SCHEMA_VERSION__;
CREATE TABLE IF NOT EXISTS admin_bdys___SCHEMA_VERSION__.abs_2021_mb (
  gid integer,
  mb21_code bigint,
  mb_cat text,
  sa1_21code character varying(11),
  sa2_21code character varying(9),
  sa2_21name text,
  sa3_21code character varying(5),
  sa3_21name text,
  sa4_21code character varying(3),
  sa4_21name text,
  gcc_21code text,
  gcc_21name text,
  state text
);

-- 0a. address_principal_admin_boundaries: drop-and-recreate stub if the existing
-- table has a state-filtered (incomplete) schema from a partially-failed gnaf-loader
-- Part 5. gnaf-loader's `boundary_tag_gnaf()` dynamically creates this table with
-- only the columns for boundary types in `admin_bdy_list` (which is per-state
-- filtered). When Part 5 fails partway through (e.g. for ACT/OT/NT/SA/TAS where
-- 04-06-bdy-tags-for-alias-addresses.sql crashes on a missing column), the table
-- is left in this incomplete state. Since gnaf-loader's `01-01-drop-tables.sql`
-- does NOT drop these tables on the next attempt (only Part 5 drops them), and
-- since the retry runs with `--no-boundary-tag` (skipping Part 5 entirely), the
-- broken table from the first attempt persists. Without this guard, flatten then
-- fails with `column "ab.ward_name" does not exist` (or similar).
--
-- Logic: if the table exists but is missing ANY of the 10 required boundary
-- columns, drop it and let the CREATE TABLE IF NOT EXISTS below recreate the
-- full stub. If gnaf-loader completed Part 5 successfully, all 10 columns are
-- present and the table is preserved (with its data).
DO $$
DECLARE
  missing_cols int;
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'gnaf___SCHEMA_VERSION__'
      AND table_name = 'address_principal_admin_boundaries'
  ) THEN
    SELECT COUNT(*) INTO missing_cols
    FROM (VALUES
      ('ce_pid'), ('ce_name'),
      ('lga_pid'), ('lga_name'),
      ('ward_pid'), ('ward_name'),
      ('se_lower_pid'), ('se_lower_name'),
      ('se_upper_pid'), ('se_upper_name')
    ) AS required(col)
    WHERE NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'gnaf___SCHEMA_VERSION__'
        AND table_name = 'address_principal_admin_boundaries'
        AND column_name = required.col
    );

    IF missing_cols > 0 THEN
      RAISE NOTICE 'address_principal_admin_boundaries is missing % required column(s) — dropping (was likely left in a partial state by a failed gnaf-loader Part 5)', missing_cols;
      DROP TABLE gnaf___SCHEMA_VERSION__.address_principal_admin_boundaries CASCADE;
    END IF;
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS gnaf___SCHEMA_VERSION__.address_principal_admin_boundaries (
  gid integer,
  gnaf_pid text,
  locality_pid text,
  locality_name text,
  postcode text,
  state text,
  ce_pid text,
  ce_name text,
  lga_pid text,
  lga_name text,
  ward_pid text,
  ward_name text,
  se_lower_pid text,
  se_lower_name text,
  se_upper_pid text,
  se_upper_name text
);

-- 0b. FALLBACK: spatial join for admin boundaries (E1.21 bulk-join rewrite)
-- Runs ONLY if gnaf-loader's boundary tagging didn't populate the table
-- (e.g. when --no-boundary-tag was used or upstream tagging crashed).
--
-- Each boundary table is checked independently — missing tables (legitimately
-- absent for some states per gnaf-loader's per-state shapefile filter) are
-- silently skipped, leaving the corresponding columns NULL.
--
-- SHAPE: insert one shell row per address with NULL boundary fields, then run
-- five INDEPENDENT UPDATE passes — one per boundary table — each picking the
-- lowest-pid intersecting polygon via DISTINCT ON.
--
-- Why this shape (E1.21 — replaces the prior LATERAL+LIMIT loop):
--
--   The prior `LEFT JOIN LATERAL (... ORDER BY pid LIMIT 1)` form forced
--   per-outer-row evaluation: Postgres executed the inner subquery against
--   the GIST index once per address, in serial. The planner could not batch,
--   parallelize, or reorder the join. NSW empirically crashed at ~55 min
--   producing 0 bytes on local M5 64GB.
--
--   Plain INNER JOIN (no LATERAL wrapper) frees the planner to pick its
--   preferred shape — parallel sequential scan over address_principals plus
--   per-row GIST index seek into the polygon table. This is the same plan
--   gnaf-loader Part 5 gets (postgres-scripts/04-01b-bdy-tag-template.sql)
--   and which completes VIC's full address set in ~2 min on the same hardware.
--
-- Why FIVE independent UPDATE passes instead of one joint INSERT with five
-- LEFT JOINs + DISTINCT ON:
--
--   A single joint INSERT would compute the cartesian product of all five
--   boundary tables for each address, then pick one tuple via DISTINCT ON.
--   For an address sitting on a polygon edge in multiple boundary tables,
--   the joint tiebreak picks the lowest-cartesian-tuple, which can choose
--   a different (lga, ward) combination than the prior LATERAL form (which
--   picked each table's lowest pid INDEPENDENTLY). Five separate UPDATE
--   passes preserve the per-table independence exactly, so the byte-for-byte
--   regression against fixtures/expected-output.ndjson stays clean.
--
-- Multi-polygon row multiplication safety (E1.15):
--
--   DISTINCT ON (ap.gnaf_pid) ORDER BY ap.gnaf_pid, {pid} guarantees AT MOST
--   ONE source row per address per UPDATE. The UNIQUE INDEX on gnaf_pid
--   below makes this structural — any future code path that inserts
--   duplicates fails fast instead of silently producing duplicate addresses.
DO $$
DECLARE
  bdy_count bigint;
  has_ce boolean;
  has_lga boolean;
  has_ward boolean;
  has_se boolean;
  has_se_upper boolean;
BEGIN
  SELECT COUNT(*) INTO bdy_count FROM gnaf___SCHEMA_VERSION__.address_principal_admin_boundaries;

  IF bdy_count > 0 THEN
    RAISE NOTICE 'admin_boundaries already populated (% rows) — skipping spatial join fallback', bdy_count;
    RETURN;
  END IF;

  SELECT EXISTS (SELECT 1 FROM information_schema.tables
                 WHERE table_schema = 'admin_bdys___SCHEMA_VERSION__' AND table_name = 'commonwealth_electorates') INTO has_ce;
  SELECT EXISTS (SELECT 1 FROM information_schema.tables
                 WHERE table_schema = 'admin_bdys___SCHEMA_VERSION__' AND table_name = 'local_government_areas') INTO has_lga;
  SELECT EXISTS (SELECT 1 FROM information_schema.tables
                 WHERE table_schema = 'admin_bdys___SCHEMA_VERSION__' AND table_name = 'local_government_wards') INTO has_ward;
  SELECT EXISTS (SELECT 1 FROM information_schema.tables
                 WHERE table_schema = 'admin_bdys___SCHEMA_VERSION__' AND table_name = 'state_lower_house_electorates') INTO has_se;
  SELECT EXISTS (SELECT 1 FROM information_schema.tables
                 WHERE table_schema = 'admin_bdys___SCHEMA_VERSION__' AND table_name = 'state_upper_house_electorates') INTO has_se_upper;

  IF NOT (has_ce OR has_lga OR has_ward OR has_se OR has_se_upper) THEN
    RAISE NOTICE 'No admin boundary tables found — skipping spatial join fallback';
    RETURN;
  END IF;

  RAISE NOTICE 'Running bulk spatial join fallback (ce=%, lga=%, ward=%, se_lower=%, se_upper=%)', has_ce, has_lga, has_ward, has_se, has_se_upper;

  -- Step 1 — INSERT one shell row per address with NULL boundary fields.
  -- Subsequent UPDATE passes set the boundary columns where there's a match;
  -- non-matching rows keep NULL (same as the prior LEFT JOIN LATERAL form).
  INSERT INTO gnaf___SCHEMA_VERSION__.address_principal_admin_boundaries
    (gnaf_pid, locality_pid, locality_name, postcode, state)
  SELECT ap.gnaf_pid, ap.locality_pid, ap.locality_name, ap.postcode, ap.state
  FROM gnaf___SCHEMA_VERSION__.address_principals ap;

  -- Reuse bdy_count for the inserted-row count (the early-return value above
  -- is no longer needed past this point).
  GET DIAGNOSTICS bdy_count = ROW_COUNT;
  RAISE NOTICE 'Spatial join fallback inserted % shell rows', bdy_count;

  -- Step 2 — five independent UPDATEs, one per boundary table.
  -- Each picks the lowest-pid polygon for each address INDEPENDENTLY of the
  -- other boundary tables. Plain INNER JOIN (no LATERAL wrapper) lets the
  -- planner pick its preferred parallel-aware spatial join plan.

  IF has_ce THEN
    UPDATE gnaf___SCHEMA_VERSION__.address_principal_admin_boundaries dst
       SET ce_pid = src.ce_pid, ce_name = src.name
      FROM (
        SELECT DISTINCT ON (ap.gnaf_pid)
               ap.gnaf_pid, ce.ce_pid, ce.name
          FROM gnaf___SCHEMA_VERSION__.address_principals ap
          JOIN admin_bdys___SCHEMA_VERSION__.commonwealth_electorates ce
            ON ST_Intersects(ap.geom, ce.geom)
         ORDER BY ap.gnaf_pid, ce.ce_pid
      ) src
     WHERE dst.gnaf_pid = src.gnaf_pid;
  END IF;

  IF has_lga THEN
    UPDATE gnaf___SCHEMA_VERSION__.address_principal_admin_boundaries dst
       SET lga_pid = src.lga_pid, lga_name = src.full_name
      FROM (
        SELECT DISTINCT ON (ap.gnaf_pid)
               ap.gnaf_pid, lga.lga_pid, lga.full_name
          FROM gnaf___SCHEMA_VERSION__.address_principals ap
          JOIN admin_bdys___SCHEMA_VERSION__.local_government_areas lga
            ON ST_Intersects(ap.geom, lga.geom)
         ORDER BY ap.gnaf_pid, lga.lga_pid
      ) src
     WHERE dst.gnaf_pid = src.gnaf_pid;
  END IF;

  IF has_ward THEN
    UPDATE gnaf___SCHEMA_VERSION__.address_principal_admin_boundaries dst
       SET ward_pid = src.ward_pid, ward_name = src.name
      FROM (
        SELECT DISTINCT ON (ap.gnaf_pid)
               ap.gnaf_pid, ward.ward_pid, ward.name
          FROM gnaf___SCHEMA_VERSION__.address_principals ap
          JOIN admin_bdys___SCHEMA_VERSION__.local_government_wards ward
            ON ST_Intersects(ap.geom, ward.geom)
         ORDER BY ap.gnaf_pid, ward.ward_pid
      ) src
     WHERE dst.gnaf_pid = src.gnaf_pid;
  END IF;

  IF has_se THEN
    UPDATE gnaf___SCHEMA_VERSION__.address_principal_admin_boundaries dst
       SET se_lower_pid = src.se_lower_pid, se_lower_name = src.name
      FROM (
        SELECT DISTINCT ON (ap.gnaf_pid)
               ap.gnaf_pid, se.se_lower_pid, se.name
          FROM gnaf___SCHEMA_VERSION__.address_principals ap
          JOIN admin_bdys___SCHEMA_VERSION__.state_lower_house_electorates se
            ON ST_Intersects(ap.geom, se.geom)
         ORDER BY ap.gnaf_pid, se.se_lower_pid
      ) src
     WHERE dst.gnaf_pid = src.gnaf_pid;
  END IF;

  IF has_se_upper THEN
    UPDATE gnaf___SCHEMA_VERSION__.address_principal_admin_boundaries dst
       SET se_upper_pid = src.se_upper_pid, se_upper_name = src.name
      FROM (
        SELECT DISTINCT ON (ap.gnaf_pid)
               ap.gnaf_pid, se_up.se_upper_pid, se_up.name
          FROM gnaf___SCHEMA_VERSION__.address_principals ap
          JOIN admin_bdys___SCHEMA_VERSION__.state_upper_house_electorates se_up
            ON ST_Intersects(ap.geom, se_up.geom)
         ORDER BY ap.gnaf_pid, se_up.se_upper_pid
      ) src
     WHERE dst.gnaf_pid = src.gnaf_pid;
  END IF;
END $$;

-- UNIQUE index on gnaf_pid (E1.15 — structural guard against multi-polygon
-- row multiplication and any future code path that might insert duplicates).
-- Created OUTSIDE the DO block so it runs whether or not the fallback fired —
-- the constraint protects gnaf-loader-populated rows too. Idempotent: re-runs
-- against an already-indexed table are no-ops.
CREATE UNIQUE INDEX IF NOT EXISTS address_principal_admin_boundaries_gnaf_pid_uniq
  ON gnaf___SCHEMA_VERSION__.address_principal_admin_boundaries (gnaf_pid);
-- FIXTURE_BOUNDARY_PRELUDE_END

-- 1a. Best geocode per address (using window function instead of correlated subquery)
DROP TABLE IF EXISTS tmp_best_geocode;
CREATE TEMPORARY TABLE tmp_best_geocode AS
SELECT address_detail_pid, best_geocode
FROM (
  SELECT
    ad.address_detail_pid,
    json_build_object(
      'latitude', g.latitude,
      'longitude', g.longitude,
      'type', COALESCE(gt.name, g.geocode_type_code),
      'reliability', g.reliability_code
    ) AS best_geocode,
    ROW_NUMBER() OVER (
      PARTITION BY ad.address_detail_pid
      ORDER BY
        g.reliability_code ASC,
        CASE g.geocode_type_code
          WHEN 'FCS' THEN 1
          WHEN 'PC'  THEN 2
          WHEN 'PAP' THEN 3
          ELSE 4
        END ASC
    ) AS rn
  FROM raw_gnaf___SCHEMA_VERSION__.address_detail ad
  JOIN raw_gnaf___SCHEMA_VERSION__.address_site_geocode g
    ON g.address_site_pid = ad.address_site_pid
    AND g.date_retired IS NULL
  LEFT JOIN raw_gnaf___SCHEMA_VERSION__.geocode_type_aut gt ON gt.code = g.geocode_type_code
  WHERE ad.date_retired IS NULL
) ranked
WHERE rn = 1;

CREATE INDEX ON tmp_best_geocode (address_detail_pid);

-- 1b. All geocodes per address
DROP TABLE IF EXISTS tmp_all_geocodes;
CREATE TEMPORARY TABLE tmp_all_geocodes AS
SELECT
  ad.address_detail_pid,
  json_agg(
    json_build_object(
      'lat', asg.latitude,
      'lng', asg.longitude,
      'type', COALESCE(gt_all.name, asg.geocode_type_code),
      'reliability', asg.reliability_code
    )
    ORDER BY asg.reliability_code, asg.geocode_type_code
  ) AS all_geocodes
FROM raw_gnaf___SCHEMA_VERSION__.address_detail ad
JOIN raw_gnaf___SCHEMA_VERSION__.address_site_geocode asg
  ON asg.address_site_pid = ad.address_site_pid
  AND asg.date_retired IS NULL
LEFT JOIN raw_gnaf___SCHEMA_VERSION__.geocode_type_aut gt_all
  ON gt_all.code = asg.geocode_type_code
WHERE ad.date_retired IS NULL
GROUP BY ad.address_detail_pid;

CREATE INDEX ON tmp_all_geocodes (address_detail_pid);

-- 1c. Combined geocode table
DROP TABLE IF EXISTS tmp_address_geocodes;
CREATE TEMPORARY TABLE tmp_address_geocodes AS
SELECT
  bg.address_detail_pid,
  bg.best_geocode,
  COALESCE(ag.all_geocodes, '[]'::json) AS all_geocodes
FROM tmp_best_geocode bg
LEFT JOIN tmp_all_geocodes ag ON ag.address_detail_pid = bg.address_detail_pid;

CREATE INDEX ON tmp_address_geocodes (address_detail_pid);
DROP TABLE IF EXISTS tmp_best_geocode;
DROP TABLE IF EXISTS tmp_all_geocodes;
ANALYZE tmp_address_geocodes;

-- 2. Locality neighbours
DROP TABLE IF EXISTS tmp_locality_neighbours;
CREATE TEMPORARY TABLE tmp_locality_neighbours AS
SELECT
  ln.locality_pid,
  COALESCE(
    json_agg(l2.locality_name ORDER BY l2.locality_name)
    FILTER (WHERE l2.locality_name IS NOT NULL),
    '[]'::json
  ) AS neighbours
FROM gnaf___SCHEMA_VERSION__.locality_neighbour_lookup ln
JOIN gnaf___SCHEMA_VERSION__.localities l2 ON l2.locality_pid = ln.neighbour_locality_pid
GROUP BY ln.locality_pid;

CREATE INDEX ON tmp_locality_neighbours (locality_pid);

-- 3. Locality aliases
DROP TABLE IF EXISTS tmp_locality_alias_agg;
CREATE TEMPORARY TABLE tmp_locality_alias_agg AS
SELECT
  la.locality_pid,
  COALESCE(
    json_agg(la.locality_alias_name ORDER BY la.locality_alias_name)
    FILTER (WHERE la.locality_alias_name IS NOT NULL),
    '[]'::json
  ) AS aliases
FROM gnaf___SCHEMA_VERSION__.locality_aliases la
GROUP BY la.locality_pid;

CREATE INDEX ON tmp_locality_alias_agg (locality_pid);

-- 4. Street aliases
DROP TABLE IF EXISTS tmp_street_alias_agg;
CREATE TEMPORARY TABLE tmp_street_alias_agg AS
SELECT
  sa.street_locality_pid,
  COALESCE(
    json_agg(sa.full_alias_street_name ORDER BY sa.full_alias_street_name)
    FILTER (WHERE sa.full_alias_street_name IS NOT NULL),
    '[]'::json
  ) AS aliases
FROM gnaf___SCHEMA_VERSION__.street_aliases sa
GROUP BY sa.street_locality_pid;

CREATE INDEX ON tmp_street_alias_agg (street_locality_pid);

-- 5. Address aliases
DROP TABLE IF EXISTS tmp_address_alias_agg;
CREATE TEMPORARY TABLE tmp_address_alias_agg AS
SELECT
  aal.principal_pid,
  json_agg(
    json_build_object(
      'pid', aa.gnaf_pid,
      'label', aa.address,
      'type', aal.alias_type
    )
    ORDER BY aa.gnaf_pid
  ) AS aliases
FROM gnaf___SCHEMA_VERSION__.address_alias_lookup aal
JOIN gnaf___SCHEMA_VERSION__.address_aliases aa ON aa.gnaf_pid = aal.alias_pid
GROUP BY aal.principal_pid;

CREATE INDEX ON tmp_address_alias_agg (principal_pid);

-- 6. Secondary addresses
DROP TABLE IF EXISTS tmp_address_secondary_agg;
CREATE TEMPORARY TABLE tmp_address_secondary_agg AS
SELECT
  asl.primary_pid,
  json_agg(
    json_build_object(
      'pid', ap2.gnaf_pid,
      'label', ap2.address
    )
    ORDER BY ap2.gnaf_pid
  ) AS secondaries
FROM gnaf___SCHEMA_VERSION__.address_secondary_lookup asl
JOIN gnaf___SCHEMA_VERSION__.address_principals ap2 ON ap2.gnaf_pid = asl.secondary_pid
GROUP BY asl.primary_pid;

CREATE INDEX ON tmp_address_secondary_agg (primary_pid);
