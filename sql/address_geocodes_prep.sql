-- AUTO-GENERATED from address_full.sql. Run npm run generate:sql; do not edit.
DROP TABLE IF EXISTS tmp_address_geocodes;
CREATE TEMPORARY TABLE tmp_address_geocodes AS
WITH
-- One policy for both query paths; the materialized version is generated.
site_candidates AS (
  SELECT g.*, COALESCE(gt.name, g.geocode_type_code) AS type_name,
    COALESCE(g.latitude BETWEEN -44 AND -9 AND g.longitude BETWEEN 96 AND 168
      AND g.reliability_code BETWEEN 1 AND 6
      AND btrim(g.geocode_type_code) <> '', false) AS valid,
    CASE g.geocode_type_code WHEN 'FCS' THEN 1 WHEN 'PC' THEN 2
      WHEN 'PAP' THEN 3 ELSE 4 END AS type_rank
  FROM raw_gnaf___SCHEMA_VERSION__.address_site_geocode g
  LEFT JOIN raw_gnaf___SCHEMA_VERSION__.geocode_type_aut gt ON gt.code = g.geocode_type_code
  WHERE g.date_retired IS NULL
),
site_geocodes AS (
  SELECT address_site_pid,
    (array_agg(jsonb_build_object(
      'latitude', latitude, 'longitude', longitude, 'type', type_name,
      'typeCode', geocode_type_code, 'reliability', reliability_code
    ) ORDER BY reliability_code, type_rank, address_site_geocode_pid COLLATE "C")
      FILTER (WHERE valid))[1] AS best_geocode,
    COALESCE(jsonb_agg(jsonb_build_object(
      'lat', latitude, 'lng', longitude, 'type', type_name, 'reliability', reliability_code
    ) ORDER BY reliability_code, geocode_type_code COLLATE "C", address_site_geocode_pid COLLATE "C")
      FILTER (WHERE valid), '[]'::jsonb) AS all_geocodes,
    count(*) FILTER (WHERE NOT valid) AS invalid_site_count
  FROM site_candidates
  GROUP BY address_site_pid
),
default_candidates AS (
  SELECT g.*, COALESCE(gt.name, g.geocode_type_code) AS type_name,
    COALESCE(g.latitude BETWEEN -44 AND -9 AND g.longitude BETWEEN 96 AND 168
      AND btrim(g.geocode_type_code) <> '', false) AS valid
  FROM raw_gnaf___SCHEMA_VERSION__.address_default_geocode g
  LEFT JOIN raw_gnaf___SCHEMA_VERSION__.geocode_type_aut gt ON gt.code = g.geocode_type_code
  WHERE g.date_retired IS NULL
),
default_geocodes AS (
  SELECT address_detail_pid,
    count(*) AS active_default_count,
    count(DISTINCT (latitude, longitude, geocode_type_code)) AS distinct_default_count,
    count(*) FILTER (WHERE NOT valid) AS invalid_default_count,
    (array_agg(jsonb_build_object(
      'latitude', latitude, 'longitude', longitude,
      'typeCode', geocode_type_code, 'type', type_name, 'source', 'GNAF_DEFAULT',
      'precision', CASE geocode_type_code WHEN 'STL' THEN 'street' WHEN 'LOC' THEN 'locality' ELSE 'unknown' END
    ) ORDER BY address_default_geocode_pid COLLATE "C") FILTER (WHERE valid))[1] AS fallback_geocode
  FROM default_candidates
  GROUP BY address_detail_pid
),
address_geocodes AS (
  SELECT ad.address_detail_pid, sg.best_geocode,
    COALESCE(sg.all_geocodes, '[]'::jsonb) AS all_geocodes,
    CASE WHEN sg.best_geocode IS NULL AND dg.distinct_default_count = 1
      AND dg.invalid_default_count = 0 THEN dg.fallback_geocode ELSE NULL END AS fallback_geocode,
    COALESCE(sg.invalid_site_count, 0) AS invalid_site_count,
    COALESCE(dg.invalid_default_count, 0) AS invalid_default_count,
    COALESCE(dg.active_default_count, 0) AS active_default_count,
    COALESCE(dg.distinct_default_count, 0) AS distinct_default_count
  FROM raw_gnaf___SCHEMA_VERSION__.address_detail ad
  LEFT JOIN site_geocodes sg ON sg.address_site_pid = ad.address_site_pid
  LEFT JOIN default_geocodes dg ON dg.address_detail_pid = ad.address_detail_pid
  WHERE ad.date_retired IS NULL
)
SELECT * FROM address_geocodes;
CREATE UNIQUE INDEX ON tmp_address_geocodes (address_detail_pid);
ANALYZE tmp_address_geocodes;
