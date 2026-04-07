-- prep-admin-bdys.sql — Prepare admin boundary tables from raw data (E1.10)
--
-- Adapted from gnaf-loader's 02-02a-prep-admin-bdys-tables.sql for fixture use.
-- Transforms raw_admin_bdys___SCHEMA_VERSION__.aus_* tables (populated by shp2pgsql
-- or SQL fixture seed) into admin_bdys___SCHEMA_VERSION__.* boundary tables used
-- by the spatial join fallback in address_full_prep.sql.
--
-- Schema placeholders: __SCHEMA_VERSION__ is replaced by the build script.
-- SRID: 7844 (GDA2020) — matches the fixture address point data.

SET search_path TO public;

-- Ensure target schema exists
CREATE SCHEMA IF NOT EXISTS admin_bdys___SCHEMA_VERSION__;

-- ---------------------------------------------------------------------------------
-- Commonwealth electoral boundaries
-- ---------------------------------------------------------------------------------

DROP TABLE IF EXISTS admin_bdys___SCHEMA_VERSION__.commonwealth_electorates CASCADE;
CREATE TABLE admin_bdys___SCHEMA_VERSION__.commonwealth_electorates AS
SELECT bdy.gid,
       tab.ce_pid,
       tab.name,
       tab.dt_gazetd,
       ste.st_abbrev AS state,
       bdy.geom
  FROM raw_admin_bdys___SCHEMA_VERSION__.aus_comm_electoral AS tab
  INNER JOIN raw_admin_bdys___SCHEMA_VERSION__.aus_comm_electoral_polygon AS bdy ON tab.ce_pid = bdy.ce_pid
  INNER JOIN raw_admin_bdys___SCHEMA_VERSION__.aus_state AS ste ON tab.state_pid = ste.state_pid;

ALTER TABLE admin_bdys___SCHEMA_VERSION__.commonwealth_electorates ADD CONSTRAINT commonwealth_electorates_pk PRIMARY KEY (gid);
CREATE INDEX commonwealth_electorates_geom_idx ON admin_bdys___SCHEMA_VERSION__.commonwealth_electorates USING gist(geom);

-- ---------------------------------------------------------------------------------
-- State lower house electoral boundaries
-- ---------------------------------------------------------------------------------

DROP TABLE IF EXISTS admin_bdys___SCHEMA_VERSION__.state_lower_house_electorates CASCADE;
CREATE TABLE admin_bdys___SCHEMA_VERSION__.state_lower_house_electorates AS
SELECT bdy.gid,
       tab.se_pid AS se_lower_pid,
       tab.name,
       tab.dt_gazetd,
       tab.eff_start,
       tab.eff_end,
       aut.name AS electorate_class,
       ste.st_abbrev AS state,
       bdy.geom
  FROM raw_admin_bdys___SCHEMA_VERSION__.aus_state_electoral AS tab
  INNER JOIN raw_admin_bdys___SCHEMA_VERSION__.aus_state_electoral_polygon AS bdy ON tab.se_pid = bdy.se_pid
  INNER JOIN raw_admin_bdys___SCHEMA_VERSION__.aus_state AS ste ON tab.state_pid = ste.state_pid
  INNER JOIN raw_admin_bdys___SCHEMA_VERSION__.aus_state_electoral_class_aut AS aut ON tab.secl_code = aut.code
  WHERE (tab.eff_end > now() + interval '3 months'
    OR (tab.eff_start <= now() + interval '3 months' AND tab.eff_end IS NULL))
  AND tab.secl_code <> '3';

ALTER TABLE admin_bdys___SCHEMA_VERSION__.state_lower_house_electorates ADD CONSTRAINT state_lower_house_electorates_pk PRIMARY KEY (gid);
CREATE INDEX state_lower_house_electorates_geom_idx ON admin_bdys___SCHEMA_VERSION__.state_lower_house_electorates USING gist(geom);

-- ---------------------------------------------------------------------------------
-- Local government areas
-- ---------------------------------------------------------------------------------

DROP TABLE IF EXISTS admin_bdys___SCHEMA_VERSION__.local_government_areas CASCADE;
CREATE TABLE admin_bdys___SCHEMA_VERSION__.local_government_areas AS
SELECT gid,
       lga_pid,
       abb_name AS name,
       lga_name AS full_name,
       state,
       st_multi(st_union(st_buffer(geom, 0.0)))::geometry(Multipolygon, 7844) AS geom
  FROM raw_admin_bdys___SCHEMA_VERSION__.aus_lga
  GROUP BY
       gid,
       lga_pid,
       abb_name,
       lga_name,
       state;

ALTER TABLE admin_bdys___SCHEMA_VERSION__.local_government_areas ADD CONSTRAINT local_government_areas_pk PRIMARY KEY (gid);
CREATE INDEX local_government_areas_geom_idx ON admin_bdys___SCHEMA_VERSION__.local_government_areas USING gist(geom);

-- ---------------------------------------------------------------------------------
-- Local government wards
-- ---------------------------------------------------------------------------------

DROP TABLE IF EXISTS admin_bdys___SCHEMA_VERSION__.local_government_wards CASCADE;
CREATE TABLE admin_bdys___SCHEMA_VERSION__.local_government_wards AS
SELECT bdy.gid,
       bdy.ward_pid,
       bdy.lga_pid,
       bdy.ward_name AS name,
       lga.lga_name AS lga_name,
       bdy.state,
       st_multi(st_union(st_buffer(bdy.geom, 0.0)))::geometry(Multipolygon, 7844) AS geom
  FROM raw_admin_bdys___SCHEMA_VERSION__.aus_wards AS bdy
  INNER JOIN raw_admin_bdys___SCHEMA_VERSION__.aus_lga AS lga ON bdy.lga_pid = lga.lga_pid
  GROUP BY bdy.gid,
           bdy.ward_pid,
           bdy.lga_pid,
           bdy.ward_name,
           lga.lga_name,
           bdy.state;

ALTER TABLE admin_bdys___SCHEMA_VERSION__.local_government_wards ADD CONSTRAINT local_government_wards_pk PRIMARY KEY (gid);
CREATE INDEX local_government_wards_geom_idx ON admin_bdys___SCHEMA_VERSION__.local_government_wards USING gist(geom);

-- ---------------------------------------------------------------------------------
-- State upper house electoral boundaries
-- ---------------------------------------------------------------------------------

DROP TABLE IF EXISTS admin_bdys___SCHEMA_VERSION__.state_upper_house_electorates CASCADE;
CREATE TABLE admin_bdys___SCHEMA_VERSION__.state_upper_house_electorates AS
SELECT bdy.gid,
       tab.se_pid AS se_upper_pid,
       tab.name,
       tab.dt_gazetd,
       tab.eff_start,
       tab.eff_end,
       aut.name AS electorate_class,
       ste.st_abbrev AS state,
       bdy.geom
  FROM raw_admin_bdys___SCHEMA_VERSION__.aus_state_electoral AS tab
  INNER JOIN raw_admin_bdys___SCHEMA_VERSION__.aus_state_electoral_polygon AS bdy ON tab.se_pid = bdy.se_pid
  INNER JOIN raw_admin_bdys___SCHEMA_VERSION__.aus_state AS ste ON tab.state_pid = ste.state_pid
  INNER JOIN raw_admin_bdys___SCHEMA_VERSION__.aus_state_electoral_class_aut AS aut ON tab.secl_code = aut.code
  WHERE (tab.eff_end > now() + interval '3 months'
    OR (tab.eff_start <= now() AND tab.eff_end IS NULL))
  AND tab.secl_code = '3'
  AND ste.st_abbrev NOT IN ('NSW', 'SA');

ALTER TABLE admin_bdys___SCHEMA_VERSION__.state_upper_house_electorates ADD CONSTRAINT state_upper_house_electorates_pk PRIMARY KEY (gid);
CREATE INDEX state_upper_house_electorates_geom_idx ON admin_bdys___SCHEMA_VERSION__.state_upper_house_electorates USING gist(geom);
