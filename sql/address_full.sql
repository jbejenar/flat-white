-- address_full.sql — Master flatten query
-- Joins 9+ G-NAF tables to produce one JSON-ready row per address.
-- Designed to run against both fixture data and full VIC+ loads.
--
-- Usage: Called from src/flatten.ts via cursor-based streaming.
-- Schema: gnaf___SCHEMA_VERSION__, raw_gnaf___SCHEMA_VERSION__, admin_bdys___SCHEMA_VERSION__

WITH
-- Aggregate all geocodes per address (via address_site)
address_geocodes AS (
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
    ) AS all_geocodes,
    -- Best geocode: lowest reliability_code (= best), prefer FCS > PC > PAP
    (
      SELECT json_build_object(
        'latitude', g.latitude,
        'longitude', g.longitude,
        'type', COALESCE(gt.name, g.geocode_type_code),
        'reliability', g.reliability_code
      )
      FROM raw_gnaf___SCHEMA_VERSION__.address_site_geocode g
      LEFT JOIN raw_gnaf___SCHEMA_VERSION__.geocode_type_aut gt ON gt.code = g.geocode_type_code
      WHERE g.address_site_pid = ad.address_site_pid
        AND g.date_retired IS NULL
      ORDER BY
        g.reliability_code ASC,
        CASE g.geocode_type_code
          WHEN 'FCS' THEN 1
          WHEN 'PC'  THEN 2
          WHEN 'PAP' THEN 3
          ELSE 4
        END ASC
      LIMIT 1
    ) AS best_geocode
  FROM raw_gnaf___SCHEMA_VERSION__.address_detail ad
  JOIN raw_gnaf___SCHEMA_VERSION__.address_site_geocode asg
    ON asg.address_site_pid = ad.address_site_pid
    AND asg.date_retired IS NULL
  WHERE ad.date_retired IS NULL
  GROUP BY ad.address_detail_pid, ad.address_site_pid
),

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
  ab.ward_name,
  ab.se_lower_name                                      AS state_electorate_name,
  ab.ce_name                                            AS commonwealth_electorate_name,

  -- ABS mesh block + statistical areas
  ap.mb_2021_code,
  mb.mb_cat                                             AS mesh_block_category,
  mb.sa1_21code,
  mb.sa2_21code,
  mb.sa2_21name,
  mb.sa3_21code,
  mb.sa3_21name,
  mb.sa4_21code,
  mb.sa4_21name,
  mb.gcc_21code,
  mb.gcc_21name,

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

-- ABS mesh block lookup
LEFT JOIN admin_bdys___SCHEMA_VERSION__.abs_2021_mb_lookup mb
  ON mb.mb21_code = ap.mb_2021_code

-- Aliases and secondaries
LEFT JOIN address_alias_agg aaa
  ON aaa.principal_pid = ap.gnaf_pid
LEFT JOIN address_secondary_agg asa
  ON asa.primary_pid = ap.gnaf_pid

ORDER BY ap.gnaf_pid;
