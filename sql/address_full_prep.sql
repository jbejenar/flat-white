-- address_full_prep.sql — Pre-materialize aggregation tables for production-scale flattening.
-- Creates temporary tables for geocode, locality, street, and address aggregations
-- so the main SELECT (address_full_main.sql) is a simple multi-join that streams efficiently.
--
-- Usage: Run once before cursor-based streaming of address_full_main.sql.
-- Schema: gnaf_202602, raw_gnaf_202602, admin_bdys_202602

-- 0. Ensure admin boundary tables exist (empty stubs if --no-boundary-tag or partial load).
-- Both schemas (gnaf_202602 and admin_bdys_202602) are created by gnaf-loader.
CREATE SCHEMA IF NOT EXISTS admin_bdys_202602;
CREATE TABLE IF NOT EXISTS admin_bdys_202602.abs_2021_mb (
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
CREATE TABLE IF NOT EXISTS gnaf_202602.address_principal_admin_boundaries (
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

-- 0b. FALLBACK: spatial join for admin boundaries
-- Runs ONLY if gnaf-loader's boundary tagging didn't populate the table
-- (e.g. when --no-boundary-tag was used or upstream tagging crashed).
-- Uses ST_Intersects against the boundary shapefiles that gnaf-loader loaded.
-- Each boundary table is checked independently — missing tables (e.g. wards)
-- are silently skipped, populating only what's available.
DO $$
DECLARE
  bdy_count bigint;
  has_ce boolean;
  has_lga boolean;
  has_ward boolean;
  has_se boolean;
BEGIN
  SELECT COUNT(*) INTO bdy_count FROM gnaf_202602.address_principal_admin_boundaries;

  IF bdy_count > 0 THEN
    RAISE NOTICE 'admin_boundaries already populated (% rows) — skipping spatial join fallback', bdy_count;
    RETURN;
  END IF;

  SELECT EXISTS (SELECT 1 FROM information_schema.tables
                 WHERE table_schema = 'admin_bdys_202602' AND table_name = 'commonwealth_electorates') INTO has_ce;
  SELECT EXISTS (SELECT 1 FROM information_schema.tables
                 WHERE table_schema = 'admin_bdys_202602' AND table_name = 'local_government_areas') INTO has_lga;
  SELECT EXISTS (SELECT 1 FROM information_schema.tables
                 WHERE table_schema = 'admin_bdys_202602' AND table_name = 'local_government_wards') INTO has_ward;
  SELECT EXISTS (SELECT 1 FROM information_schema.tables
                 WHERE table_schema = 'admin_bdys_202602' AND table_name = 'state_lower_house_electorates') INTO has_se;

  IF NOT (has_ce OR has_lga OR has_ward OR has_se) THEN
    RAISE NOTICE 'No admin boundary tables found — skipping spatial join fallback';
    RETURN;
  END IF;

  RAISE NOTICE 'Running spatial join fallback (ce=%, lga=%, ward=%, se=%)', has_ce, has_lga, has_ward, has_se;

  -- Build the insert dynamically based on which tables exist
  EXECUTE format($sql$
    INSERT INTO gnaf_202602.address_principal_admin_boundaries
      (gnaf_pid, locality_pid, locality_name, postcode, state,
       ce_pid, ce_name, lga_pid, lga_name, ward_pid, ward_name,
       se_lower_pid, se_lower_name, se_upper_pid, se_upper_name)
    SELECT
      ap.gnaf_pid,
      ap.locality_pid,
      ap.locality_name,
      ap.postcode,
      ap.state,
      %s AS ce_pid, %s AS ce_name,
      %s AS lga_pid, %s AS lga_name,
      %s AS ward_pid, %s AS ward_name,
      %s AS se_lower_pid, %s AS se_lower_name,
      NULL::text AS se_upper_pid, NULL::text AS se_upper_name
    FROM gnaf_202602.address_principals ap
    %s
    %s
    %s
    %s
  $sql$,
    -- ce_pid, ce_name
    CASE WHEN has_ce THEN 'ce.ce_pid' ELSE 'NULL::text' END,
    CASE WHEN has_ce THEN 'ce.name' ELSE 'NULL::text' END,
    -- lga_pid, lga_name
    CASE WHEN has_lga THEN 'lga.lga_pid' ELSE 'NULL::text' END,
    CASE WHEN has_lga THEN 'lga.full_name' ELSE 'NULL::text' END,
    -- ward_pid, ward_name
    CASE WHEN has_ward THEN 'ward.ward_pid' ELSE 'NULL::text' END,
    CASE WHEN has_ward THEN 'ward.name' ELSE 'NULL::text' END,
    -- se_lower_pid, se_lower_name
    CASE WHEN has_se THEN 'se.se_lower_pid' ELSE 'NULL::text' END,
    CASE WHEN has_se THEN 'se.name' ELSE 'NULL::text' END,
    -- joins
    CASE WHEN has_ce THEN 'LEFT JOIN admin_bdys_202602.commonwealth_electorates ce ON ST_Intersects(ap.geom, ce.geom)' ELSE '' END,
    CASE WHEN has_lga THEN 'LEFT JOIN admin_bdys_202602.local_government_areas lga ON ST_Intersects(ap.geom, lga.geom)' ELSE '' END,
    CASE WHEN has_ward THEN 'LEFT JOIN admin_bdys_202602.local_government_wards ward ON ST_Intersects(ap.geom, ward.geom)' ELSE '' END,
    CASE WHEN has_se THEN 'LEFT JOIN admin_bdys_202602.state_lower_house_electorates se ON ST_Intersects(ap.geom, se.geom)' ELSE '' END
  );

  GET DIAGNOSTICS bdy_count = ROW_COUNT;
  RAISE NOTICE 'Spatial join fallback inserted % rows into address_principal_admin_boundaries', bdy_count;

  -- Index for the main flatten join
  CREATE INDEX IF NOT EXISTS address_principal_admin_boundaries_gnaf_pid_idx
    ON gnaf_202602.address_principal_admin_boundaries (gnaf_pid);
END $$;

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
  FROM raw_gnaf_202602.address_detail ad
  JOIN raw_gnaf_202602.address_site_geocode g
    ON g.address_site_pid = ad.address_site_pid
    AND g.date_retired IS NULL
  LEFT JOIN raw_gnaf_202602.geocode_type_aut gt ON gt.code = g.geocode_type_code
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
      'type', asg.geocode_type_code,
      'reliability', asg.reliability_code
    )
    ORDER BY asg.reliability_code, asg.geocode_type_code
  ) AS all_geocodes
FROM raw_gnaf_202602.address_detail ad
JOIN raw_gnaf_202602.address_site_geocode asg
  ON asg.address_site_pid = ad.address_site_pid
  AND asg.date_retired IS NULL
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
FROM gnaf_202602.locality_neighbour_lookup ln
JOIN gnaf_202602.localities l2 ON l2.locality_pid = ln.neighbour_locality_pid
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
FROM gnaf_202602.locality_aliases la
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
FROM gnaf_202602.street_aliases sa
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
FROM gnaf_202602.address_alias_lookup aal
JOIN gnaf_202602.address_aliases aa ON aa.gnaf_pid = aal.alias_pid
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
FROM gnaf_202602.address_secondary_lookup asl
JOIN gnaf_202602.address_principals ap2 ON ap2.gnaf_pid = asl.secondary_pid
GROUP BY asl.primary_pid;

CREATE INDEX ON tmp_address_secondary_agg (primary_pid);
