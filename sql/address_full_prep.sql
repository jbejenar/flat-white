-- address_full_prep.sql — Pre-materialize aggregation tables for production-scale flattening.
-- Creates temporary tables for geocode, locality, street, and address aggregations
-- so the main SELECT (address_full_main.sql) is a simple multi-join that streams efficiently.
--
-- Usage: Run once before cursor-based streaming of address_full_main.sql.
-- Schema: gnaf_202602, raw_gnaf_202602, admin_bdys_202602

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
