-- locality_full.sql — Locality-only flatten query
-- Produces one row per unique locality with neighbours and aliases.
-- Designed to run against both fixture data and full state loads.
--
-- Usage: Called from src/flatten-localities.ts via cursor-based streaming.
-- Schema: gnaf___SCHEMA_VERSION__

WITH
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
)

SELECT
  loc.locality_pid,
  loc.locality_name,
  loc.state,
  loc.postcode,
  COALESCE(lc_aut.name, loc.locality_class)  AS locality_class_name,
  COALESCE(ln.neighbours, '[]'::json)        AS locality_neighbours,
  COALESCE(laa.aliases, '[]'::json)           AS locality_aliases,
  loc.latitude,
  loc.longitude

FROM gnaf___SCHEMA_VERSION__.localities loc

-- Locality class name expansion
LEFT JOIN raw_gnaf___SCHEMA_VERSION__.locality_class_aut lc_aut
  ON lc_aut.name = loc.locality_class

-- Neighbours
LEFT JOIN locality_neighbours ln
  ON ln.locality_pid = loc.locality_pid

-- Aliases
LEFT JOIN locality_alias_agg laa
  ON laa.locality_pid = loc.locality_pid

ORDER BY loc.locality_pid;
