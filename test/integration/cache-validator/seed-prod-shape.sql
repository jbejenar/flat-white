-- seed-prod-shape.sql — Provisions a production-shaped database for the
-- cache-validator integration test.
--
-- Purpose: catch the regression class where validate-db-cache.sh references
-- a fixture-only table name (e.g. abs_2021_mb_lookup) instead of the table
-- name gnaf-loader actually creates in production (abs_2021_mb). PR #99
-- introduced exactly this bug; this seed gives the test a reference reality
-- that matches what gnaf-loader produces, NOT what the fixture creates.
--
-- Schemas: gnaf_202699, raw_gnaf_202699, admin_bdys_202699, raw_admin_bdys_202699
-- (uses `202699` to avoid colliding with the real `202602` fixture state if
-- both are present in the same Postgres instance).
--
-- All tables get one stub row inserted so MIN_ROWS gates pass.
--
-- Source of truth for table names:
--   - gnaf-loader/postgres-scripts/02-02a-prep-admin-bdys-tables.sql (polygon tables)
--   - gnaf-loader/postgres-scripts/02-02d-prep-census-2021-bdys-tables.sql (abs_2021_mb)
--   - gnaf-loader/load-gnaf.py (gnaf_*, raw_gnaf_*, raw_admin_bdys_* schemas)
--
-- If gnaf-loader changes a table name and this seed isn't updated to match,
-- the validator's check against this seed catches the drift before the next
-- quarterly run.

DROP SCHEMA IF EXISTS gnaf_202699 CASCADE;
DROP SCHEMA IF EXISTS raw_gnaf_202699 CASCADE;
DROP SCHEMA IF EXISTS admin_bdys_202699 CASCADE;
DROP SCHEMA IF EXISTS raw_admin_bdys_202699 CASCADE;

CREATE SCHEMA gnaf_202699;
CREATE SCHEMA raw_gnaf_202699;
CREATE SCHEMA admin_bdys_202699;
CREATE SCHEMA raw_admin_bdys_202699;

-- ─── gnaf schema ────────────────────────────────────────────────────────────

CREATE TABLE gnaf_202699.address_principals (
  gnaf_pid text NOT NULL,
  state text,
  postcode text,
  mb_2021_code bigint
);
INSERT INTO gnaf_202699.address_principals (gnaf_pid, state, postcode, mb_2021_code)
  VALUES ('GAVIC000000000', 'VIC', '3000', 20001320000);

CREATE TABLE gnaf_202699.localities (
  locality_pid text NOT NULL,
  locality_name text NOT NULL
);
INSERT INTO gnaf_202699.localities VALUES ('VIC123', 'MELBOURNE');

CREATE TABLE gnaf_202699.streets (
  street_locality_pid text NOT NULL,
  street_name text
);
INSERT INTO gnaf_202699.streets VALUES ('VIC456', 'BOURKE');

CREATE TABLE gnaf_202699.address_principal_admin_boundaries (
  gnaf_pid text NOT NULL,
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
-- Intentionally NO row inserted — the validator must accept an empty
-- admin_boundaries table because the spatial-join fallback fills it at
-- flatten time when --no-boundary-tag was used. We only require that the
-- TABLE EXISTS, not that it has rows.

-- ─── raw_gnaf schema ────────────────────────────────────────────────────────

CREATE TABLE raw_gnaf_202699.address_detail (
  address_detail_pid varchar(15) NOT NULL,
  building_name text
);
INSERT INTO raw_gnaf_202699.address_detail VALUES ('GAVIC000000000', NULL);

CREATE TABLE raw_gnaf_202699.address_site (
  address_site_pid varchar(15) NOT NULL,
  address_site_name text
);
INSERT INTO raw_gnaf_202699.address_site VALUES ('SITE000000', NULL);

-- ─── admin_bdys schema ──────────────────────────────────────────────────────

-- Mesh-block table: production gnaf-loader creates `abs_2021_mb` (NO _lookup
-- suffix). The fixture path's `abs_2021_mb_lookup` is fixture-only and MUST
-- NOT appear here — that would defeat the regression test.
CREATE TABLE admin_bdys_202699.abs_2021_mb (
  gid integer,
  mb21_code bigint,
  mb_cat text,
  sa1_21code varchar(11),
  sa2_21code varchar(9),
  sa2_21name text,
  sa3_21code varchar(5),
  sa3_21name text,
  sa4_21code varchar(3),
  sa4_21name text,
  gcc_21code text,
  gcc_21name text,
  state text
);
INSERT INTO admin_bdys_202699.abs_2021_mb (gid, mb21_code, state)
  VALUES (1, 20001320000, 'VIC');

-- Boundary polygon tables — what the spatial-join fallback in
-- address_full_prep.sql joins against. Not a polygon here (we're not testing
-- the join, just the existence and row count gates), but the table names and
-- column lists must match what gnaf-loader creates.
CREATE TABLE admin_bdys_202699.local_government_areas (
  lga_pid text NOT NULL,
  full_name text
);
INSERT INTO admin_bdys_202699.local_government_areas VALUES ('LGA001', 'MELBOURNE');

CREATE TABLE admin_bdys_202699.local_government_wards (
  ward_pid text NOT NULL,
  name text
);
INSERT INTO admin_bdys_202699.local_government_wards VALUES ('WARD001', 'CITY WARD');

CREATE TABLE admin_bdys_202699.commonwealth_electorates (
  ce_pid text NOT NULL,
  name text
);
INSERT INTO admin_bdys_202699.commonwealth_electorates VALUES ('CE001', 'MELBOURNE');

CREATE TABLE admin_bdys_202699.state_lower_house_electorates (
  se_lower_pid text NOT NULL,
  name text
);
INSERT INTO admin_bdys_202699.state_lower_house_electorates VALUES ('SE001', 'MELBOURNE');

CREATE TABLE admin_bdys_202699.state_upper_house_electorates (
  se_upper_pid text NOT NULL,
  name text
);
INSERT INTO admin_bdys_202699.state_upper_house_electorates VALUES ('SU001', 'NORTHERN METRO');

-- ─── raw_admin_bdys schema ──────────────────────────────────────────────────

CREATE TABLE raw_admin_bdys_202699.aus_lga (
  lga_pid text NOT NULL,
  lga_name text
);
INSERT INTO raw_admin_bdys_202699.aus_lga VALUES ('LGA001', 'MELBOURNE');
