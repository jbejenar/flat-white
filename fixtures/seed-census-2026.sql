-- Synthetic ASGS 2026 overlay on the frozen February 2026 address fixture.
-- Reuse historical values as synthetic test data, not real 2026 assignments.
-- Two explicit migration cases differ from the retained 2021 lookup, so a
-- legacy join fails regression without rewriting every unrelated test record.
-- Column names match Geoscape's AUG26 raw MB shapefile and upstream 202608 SQL.
\set ON_ERROR_STOP on
BEGIN;

CREATE TEMP TABLE fixture_census_map AS
SELECT *, mb21_code AS mb_2026_code
  FROM admin_bdys_202602.abs_2021_mb;
ALTER TABLE fixture_census_map ADD PRIMARY KEY (mb21_code);

-- GAVIC411087566: a new mesh-block code and a new census hierarchy.
UPDATE fixture_census_map SET mb_2026_code = 29900000083
 WHERE mb21_code = 20192490000;

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
       mb_2026_code::text, mb_cat, '0', 'Unchanged', 'sa1-' || sa1_21code,
       sa1_21code, sa2_21code, sa2_21name, sa3_21code, sa3_21name,
       sa4_21code, sa4_21name, gcc_21code, gcc_21name, state, 1,
       ST_Multi(ST_MakeEnvelope(144.9, -37.9, 145.0, -37.8, 7844))
  FROM fixture_census_map;

-- GAVIC411441273: the mesh-block code stays the same, but its hierarchy changes.
-- This catches a legacy hierarchy lookup even when the join key still matches.
UPDATE raw_admin_bdys_202602.aus_mb_2026
   SET s1_pid_26 = 'sa1-' || migration.sa1,
       s1_code_26 = migration.sa1,
       s2_code_26 = migration.sa2, s2_name_26 = migration.sa2_name,
       s3_code_26 = '29901', s3_name_26 = 'Fixture 2026 SA3',
       s4_code_26 = '299', s4_name_26 = 'Fixture 2026 SA4',
       gc_code_26 = '2TEST', gc_name_26 = 'Fixture 2026 GCCSA',
       chn_flg_26 = '1', chn_lbl_26 = 'Changed'
  FROM (VALUES
    ('29900000083', '29901000103', '299010001', 'Fixture 2026 SA2'),
    ('20555940000', '29901000201', '299010002', 'Fixture 2026 reassignment')
  ) AS migration(mb, sa1, sa2, sa2_name)
 WHERE mb_code_26 = migration.mb;

DROP TABLE fixture_census_map;
COMMIT;
