-- Synthetic ASGS 2026 overlay on the frozen February 2026 address fixture.
-- These deliberately different codes/names are test data, not geographic truth.
-- Keep the original 2021 lookup as a decoy: rejoining it must fail regression.
-- Column names match Geoscape's AUG26 raw MB shapefile and upstream 202608 SQL.
\set ON_ERROR_STOP on
BEGIN;

CREATE TEMP TABLE fixture_census_map AS
SELECT (row_number() OVER (ORDER BY mb21_code))::integer AS gid,
       mb21_code,
       29900000000 + row_number() OVER (ORDER BY mb21_code) AS mb_2026_code,
       mb_cat
  FROM admin_bdys_202602.abs_2021_mb;
ALTER TABLE fixture_census_map ADD PRIMARY KEY (mb21_code);

ALTER TABLE gnaf_202602.address_principals ADD COLUMN mb_2026_code bigint;
ALTER TABLE gnaf_202602.address_aliases ADD COLUMN mb_2026_code bigint;
UPDATE gnaf_202602.address_principals ap
   SET mb_2026_code = map.mb_2026_code
  FROM fixture_census_map map WHERE map.mb21_code = ap.mb_2021_code;
UPDATE gnaf_202602.address_aliases ap
   SET mb_2026_code = map.mb_2026_code
  FROM fixture_census_map map WHERE map.mb21_code = ap.mb_2021_code;

CREATE TABLE raw_admin_bdys_202602.aus_mb_2026 (
  gid integer PRIMARY KEY,
  mb_ply_26 varchar(15), dt_create date, mb_pid_26 varchar(15), mb_code_26 varchar(11),
  mb_cat_26 varchar(30), chn_flg_26 varchar(1), chn_lbl_26 varchar(11), s1_pid_26 varchar(15),
  s1_code_26 varchar(11), s2_code_26 varchar(9), s2_name_26 varchar(50),
  s3_code_26 varchar(5), s3_name_26 varchar(50), s4_code_26 varchar(3), s4_name_26 varchar(50),
  gc_code_26 varchar(5), gc_name_26 varchar(50), state varchar(3), mb_ar_sqkm numeric(11,2),
  geom geometry(MultiPolygon, 7844)
);
INSERT INTO raw_admin_bdys_202602.aus_mb_2026
SELECT gid,
       'test-poly-' || gid, DATE '2026-08-01', 'fixture-mb-' || gid,
       mb_2026_code::text, mb_cat, '0', 'Unchanged', 'fixture-sa1-' || (gid % 20),
       (29901000100 + gid % 20)::text,
       '299010001', 'Fixture 2026 SA2', '29901', 'Fixture 2026 SA3',
       '299', 'Fixture 2026 SA4', '2TEST', 'Fixture 2026 GCCSA', 'VIC', 1,
       ST_Multi(ST_MakeEnvelope(144.9, -37.9, 145.0, -37.8, 7844))
  FROM fixture_census_map;

DROP TABLE fixture_census_map;
COMMIT;
