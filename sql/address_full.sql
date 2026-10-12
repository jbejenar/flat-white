-- address_full.sql — Master flatten query
-- Joins 9+ G-NAF tables to produce one JSON-ready row per address.
-- Designed to run against both fixture data and full VIC+ loads.
--
-- Usage: Called from src/flatten.ts via cursor-based streaming.
-- Schema: gnaf___SCHEMA_VERSION__, raw_gnaf___SCHEMA_VERSION__, admin_bdys___SCHEMA_VERSION__

WITH
-- GEOCODE_CTES_START
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
),
-- GEOCODE_CTES_END

-- Aggregate locality neighbours
locality_neighbours AS (
  SELECT
    ln.locality_pid,
    COALESCE(
      json_agg(l2.locality_name ORDER BY l2.locality_name)
      FILTER (WHERE l2.locality_name IS NOT NULL),
      '[]'::json
    ) AS neighbours
  FROM gnaf___SCHEMA_VERSION__.locality_neighbour_lookup ln
  JOIN gnaf___SCHEMA_VERSION__.localities l2 ON l2.locality_pid = ln.neighbour_locality_pid
  GROUP BY ln.locality_pid
),

-- Aggregate locality aliases
locality_alias_agg AS (
  SELECT
    la.locality_pid,
    COALESCE(
      json_agg(la.locality_alias_name ORDER BY la.locality_alias_name)
      FILTER (WHERE la.locality_alias_name IS NOT NULL),
      '[]'::json
    ) AS aliases
  FROM gnaf___SCHEMA_VERSION__.locality_aliases la
  GROUP BY la.locality_pid
),

-- Aggregate street aliases
street_alias_agg AS (
  SELECT
    sa.street_locality_pid,
    COALESCE(
      json_agg(sa.full_alias_street_name ORDER BY sa.full_alias_street_name)
      FILTER (WHERE sa.full_alias_street_name IS NOT NULL),
      '[]'::json
    ) AS aliases
  FROM gnaf___SCHEMA_VERSION__.street_aliases sa
  GROUP BY sa.street_locality_pid
),

-- Aggregate address aliases (for principal addresses)
address_alias_agg AS (
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
  GROUP BY aal.principal_pid
),

-- Aggregate secondary addresses (for primary addresses)
address_secondary_agg AS (
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
  GROUP BY asl.primary_pid
)

SELECT
  -- Core identity
  ap.gnaf_pid                                           AS _id,
  ap.address                                            AS address_label,

  -- Address components
  site.address_site_name                                AS address_site_name,
  ap.building_name,
  ap.number_first,
  ap.number_last,
  ap.lot_number,
  ap.street_name,
  ap.street_type                                        AS street_type_name,
  ap.street_suffix                                      AS street_suffix_code,
  ap.locality_name,
  ap.state,
  ap.postcode,
  ap.legal_parcel_id,
  ap.confidence,
  ap.primary_secondary,

  -- Expanded type names
  ft.name                                               AS flat_type_name,
  lt.name                                               AS level_type_name,
  ss_aut.name                                           AS street_suffix_name,

  -- Raw flat/level number components (without type prefix)
  CASE WHEN ad.flat_number IS NOT NULL
    THEN CONCAT(COALESCE(ad.flat_number_prefix, ''), ad.flat_number::text, COALESCE(ad.flat_number_suffix, ''))
    ELSE NULL
  END                                                   AS flat_number_composed,
  CASE WHEN ad.level_number IS NOT NULL
    THEN CONCAT(COALESCE(ad.level_number_prefix, ''), ad.level_number::text, COALESCE(ad.level_number_suffix, ''))
    ELSE NULL
  END                                                   AS level_number_composed,

  -- Geocodes
  ag.best_geocode,
  ag.all_geocodes,
  ag.fallback_geocode,
  ag.invalid_site_count,
  ag.invalid_default_count,
  ag.active_default_count,
  ag.distinct_default_count,

  -- Locality
  loc.locality_pid,
  lc_aut.name                                           AS locality_class_name,
  COALESCE(ln.neighbours, '[]'::json)                   AS locality_neighbours,
  COALESCE(laa.aliases, '[]'::json)                     AS locality_aliases,

  -- Street
  st.street_locality_pid,
  sc_aut.name                                           AS street_class_name,
  COALESCE(saa.aliases, '[]'::json)                     AS street_aliases,

  -- Admin boundaries
  ab.lga_pid,
  ab.lga_name,
  CASE WHEN ap.state = 'NSW'
    THEN CASE WHEN wm.matches = 1 THEN wm.ward_name ELSE NULL END
    ELSE ab.ward_name END                               AS ward_name,
  ws.source_id                                         AS ward_source_id,
  CASE WHEN ap.state <> 'NSW' THEN 'not_applicable'
    WHEN ws.status = 'undivided' THEN 'undivided'
    WHEN ws.source_id IS NULL THEN 'unsupported'
    WHEN NOT we.eligible THEN 'insufficient_precision'
    WHEN wm.matches = 0 THEN 'unmatched'
    WHEN wm.matches > 1 THEN 'ambiguous'
    ELSE 'matched' END                                 AS ward_reason,
  ab.se_lower_name                                      AS state_electorate_name,
  ab.ce_name                                            AS commonwealth_electorate_name,

  -- ABS mesh block + statistical areas
  ap.mb_2026_code,
  mb.mb_cat_26                                          AS mesh_block_category,
  mb.s1_code_26,
  mb.s2_code_26,
  mb.s2_name_26,
  mb.s3_code_26,
  mb.s3_name_26,
  mb.s4_code_26,
  mb.s4_name_26,
  mb.gc_code_26,
  mb.gc_name_26,

  -- Aliases and secondaries (aggregated)
  COALESCE(aaa.aliases, '[]'::json)                     AS address_aliases,
  COALESCE(asa.secondaries, '[]'::json)                 AS address_secondaries

FROM gnaf___SCHEMA_VERSION__.address_principals ap

-- Raw address_detail for flat_type_code, level_type_code, address_site_pid
JOIN raw_gnaf___SCHEMA_VERSION__.address_detail ad
  ON ad.address_detail_pid = ap.gnaf_pid

-- Address site for site name
LEFT JOIN raw_gnaf___SCHEMA_VERSION__.address_site site
  ON site.address_site_pid = ad.address_site_pid

-- Authority code expansions
LEFT JOIN raw_gnaf___SCHEMA_VERSION__.flat_type_aut ft
  ON ft.code = ad.flat_type_code
LEFT JOIN raw_gnaf___SCHEMA_VERSION__.level_type_aut lt
  ON lt.code = ad.level_type_code
LEFT JOIN raw_gnaf___SCHEMA_VERSION__.street_suffix_aut ss_aut
  ON ss_aut.code = ap.street_suffix

-- Geocodes
LEFT JOIN address_geocodes ag
  ON ag.address_detail_pid = ap.gnaf_pid

-- Locality
JOIN gnaf___SCHEMA_VERSION__.localities loc
  ON loc.locality_pid = ap.locality_pid
LEFT JOIN raw_gnaf___SCHEMA_VERSION__.locality_class_aut lc_aut
  ON lc_aut.name = loc.locality_class
LEFT JOIN locality_neighbours ln
  ON ln.locality_pid = ap.locality_pid
LEFT JOIN locality_alias_agg laa
  ON laa.locality_pid = ap.locality_pid

-- Street
JOIN gnaf___SCHEMA_VERSION__.streets st
  ON st.street_locality_pid = ap.street_locality_pid
LEFT JOIN raw_gnaf___SCHEMA_VERSION__.street_class_aut sc_aut
  ON sc_aut.name = st.street_class
LEFT JOIN street_alias_agg saa
  ON saa.street_locality_pid = ap.street_locality_pid

-- Admin boundaries
LEFT JOIN gnaf___SCHEMA_VERSION__.address_principal_admin_boundaries ab
  ON ab.gnaf_pid = ap.gnaf_pid

-- Council sources require an exact Geoscape LGA crosswalk and a precise selected
-- site point. Default/street/locality points never enter this assignment.
LEFT JOIN tmp_ward_sources ws ON ap.state = 'NSW' AND ws.lga_code = ab.lga_pid
LEFT JOIN LATERAL (
  SELECT COALESCE((ag.best_geocode->>'reliability')::integer IN (1,2)
    AND EXISTS (SELECT 1 FROM tmp_ward_types WHERE code = ag.best_geocode->>'typeCode'), false) AS eligible
) we ON ap.state = 'NSW'
LEFT JOIN LATERAL (
  SELECT count(DISTINCT w.ward_id) AS matches, min(w.name) AS ward_name
  FROM tmp_ward_polygons w
  WHERE ws.status = 'enabled' AND we.eligible AND w.source_id = ws.source_id
    AND ST_Covers(w.geom, ST_SetSRID(ST_MakePoint(
      (ag.best_geocode->>'longitude')::double precision,
      (ag.best_geocode->>'latitude')::double precision),7844))
) wm ON ap.state = 'NSW'

-- ASGS 2026 lookup, created by upstream 02-02e-prep-census-2026-bdys-tables.sql.
-- Schema 1.x must never substitute the 2021 codes or hierarchy here.
LEFT JOIN admin_bdys___SCHEMA_VERSION__.abs_2026_mb mb
  ON mb.mb_code_26 = ap.mb_2026_code

-- Aliases and secondaries
LEFT JOIN address_alias_agg aaa
  ON aaa.principal_pid = ap.gnaf_pid
LEFT JOIN address_secondary_agg asa
  ON asa.primary_pid = ap.gnaf_pid

ORDER BY ap.gnaf_pid;
