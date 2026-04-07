-- address_full_main.sql — Main flatten SELECT using pre-materialized temp tables.
-- Run address_full_prep.sql first to create the temp tables.
-- This query is a simple multi-join — efficient for cursor-based streaming at scale.
--
-- Usage: Called from src/flatten.ts via cursor-based streaming.
-- Schema: gnaf_202602, raw_gnaf_202602, admin_bdys_202602

SELECT
  -- Core identity
  ap.gnaf_pid                                           AS _id,
  ap.address                                            AS address_label,

  -- Address components
  site.address_site_name                                AS address_site_name,
  ap.building_name,
  CASE WHEN ad.flat_number IS NOT NULL
    THEN CONCAT(COALESCE(ad.flat_number_prefix, ''), ad.flat_number::text, COALESCE(ad.flat_number_suffix, ''))
    ELSE NULL
  END                                                   AS flat_number_composed,
  CASE WHEN ad.level_number IS NOT NULL
    THEN CONCAT(COALESCE(ad.level_number_prefix, ''), ad.level_number::text, COALESCE(ad.level_number_suffix, ''))
    ELSE NULL
  END                                                   AS level_number_composed,
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

  -- Expanded type names (for addressLabelSearch)
  ft.name                                               AS flat_type_name,
  lt.name                                               AS level_type_name,
  ss_aut.name                                           AS street_suffix_name,

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

FROM gnaf_202602.address_principals ap

-- Raw address_detail for flat_type_code, level_type_code, address_site_pid
JOIN raw_gnaf_202602.address_detail ad
  ON ad.address_detail_pid = ap.gnaf_pid

-- Address site for site name
LEFT JOIN raw_gnaf_202602.address_site site
  ON site.address_site_pid = ad.address_site_pid

-- Authority code expansions
LEFT JOIN raw_gnaf_202602.flat_type_aut ft
  ON ft.code = ad.flat_type_code
LEFT JOIN raw_gnaf_202602.level_type_aut lt
  ON lt.code = ad.level_type_code
-- NOTE: street_type_aut is NOT joined here. Its `code` column holds the long form
-- (e.g. "STREET") and `name` holds the abbreviation (e.g. "ST") — the reverse of every
-- other authority table. ap.street_type already contains the resolved long form, so we
-- alias it directly above. Joining street_type_aut would yield the abbreviation and was
-- the cause of the v2026.04 streetType regression (PR #29 → fixed in this PR).
LEFT JOIN raw_gnaf_202602.street_suffix_aut ss_aut
  ON ss_aut.code = ap.street_suffix

-- Pre-materialized geocodes
LEFT JOIN tmp_address_geocodes ag
  ON ag.address_detail_pid = ap.gnaf_pid

-- Locality
JOIN gnaf_202602.localities loc
  ON loc.locality_pid = ap.locality_pid
LEFT JOIN raw_gnaf_202602.locality_class_aut lc_aut
  ON lc_aut.name = loc.locality_class
LEFT JOIN tmp_locality_neighbours ln
  ON ln.locality_pid = ap.locality_pid
LEFT JOIN tmp_locality_alias_agg laa
  ON laa.locality_pid = ap.locality_pid

-- Street
JOIN gnaf_202602.streets st
  ON st.street_locality_pid = ap.street_locality_pid
LEFT JOIN raw_gnaf_202602.street_class_aut sc_aut
  ON sc_aut.name = st.street_class
LEFT JOIN tmp_street_alias_agg saa
  ON saa.street_locality_pid = ap.street_locality_pid

-- Admin boundaries
LEFT JOIN gnaf_202602.address_principal_admin_boundaries ab
  ON ab.gnaf_pid = ap.gnaf_pid

-- ABS mesh block (use abs_2021_mb from gnaf-loader; abs_2021_mb_lookup is fixture-only)
LEFT JOIN admin_bdys_202602.abs_2021_mb mb
  ON mb.mb21_code = ap.mb_2021_code

-- Pre-materialized aliases and secondaries
LEFT JOIN tmp_address_alias_agg aaa
  ON aaa.principal_pid = ap.gnaf_pid
LEFT JOIN tmp_address_secondary_agg asa
  ON asa.primary_pid = ap.gnaf_pid

ORDER BY ap.gnaf_pid;
