# Fixture Schema Reference

> **Schema 1.0.0 change:** this reference describes the frozen seed plus the
> administrative and synthetic ASGS 2026 overlays. The `202602` suffix remains
> the address snapshot version. Use the [fixture build](README.md), not the base
> seed alone, to create the current tables.

Four schemas are used: `gnaf_202602` (processed addresses), `raw_gnaf_202602`
(raw addresses), `admin_bdys_202602` (prepared boundaries) and
`raw_admin_bdys_202602` (raw boundary fixtures). The 2021 tables listed below are
historical decoys; current census joins use `abs_2026_mb`.

## gnaf_202602 (processed tables)

### address_principals (451 rows)

Core table — one row per principal address. **Primary driving table in address_full.sql.**

| Column              | Type                 | Nullable | Notes                                                 |
| ------------------- | -------------------- | -------- | ----------------------------------------------------- |
| gid                 | integer              | NO       | PK (serial)                                           |
| gnaf_pid            | text                 | NO       | Unique address ID, e.g. GAVIC425181432                |
| street_locality_pid | text                 | NO       | FK -> streets                                         |
| locality_pid        | text                 | NO       | FK -> localities                                      |
| alias_principal     | character(1)         | NO       | Always 'P' for principals                             |
| primary_secondary   | text                 | YES      | 'P' or 'S' (single letter)                            |
| building_name       | text                 | YES      |                                                       |
| lot_number          | text                 | YES      |                                                       |
| flat_number         | text                 | YES      |                                                       |
| level_number        | text                 | YES      |                                                       |
| number_first        | text                 | YES      |                                                       |
| number_last         | text                 | YES      |                                                       |
| street_name         | text                 | NO       |                                                       |
| street_type         | text                 | YES      | Expanded name, e.g. 'AVENUE'                          |
| street_suffix       | text                 | YES      |                                                       |
| address             | text                 | NO       | Composed label                                        |
| locality_name       | text                 | NO       |                                                       |
| postcode            | text                 | YES      |                                                       |
| state               | text                 | NO       |                                                       |
| locality_postcode   | text                 | YES      |                                                       |
| confidence          | smallint             | NO       | 0-2                                                   |
| legal_parcel_id     | text                 | YES      |                                                       |
| mb_2016_code        | bigint               | YES      |                                                       |
| mb_2021_code        | bigint               | YES      | Historical 2021 fixture value                         |
| mb_2026_code        | bigint               | YES      | Added by the census overlay; current mesh-block join. |
| latitude            | numeric(10,8)        | NO       | GDA2020                                               |
| longitude           | numeric(11,8)        | NO       | GDA2020                                               |
| geocode_type        | text                 | NO       |                                                       |
| reliability         | smallint             | NO       | 1-6                                                   |
| geom                | geometry(Point,7844) | NO       | PostGIS point                                         |

**Joins in address_full.sql:**

- -> raw_gnaf_202602.address_detail ON gnaf_pid = address_detail_pid
- -> gnaf_202602.localities ON locality_pid
- -> gnaf_202602.streets ON street_locality_pid
- -> address_principal_admin_boundaries ON gnaf_pid
- -> admin_bdys_202602.abs_2026_mb ON mb_2026_code = mb_code_26 (added by `seed-census-2026.sql`)
- -> address_alias_lookup ON gnaf_pid = principal_pid
- -> address_secondary_lookup ON gnaf_pid = primary_pid

### address_aliases (75 rows)

Same schema as address_principals. Contains alias addresses linked via address_alias_lookup.

### address_alias_lookup (75 rows)

| Column        | Type | Notes                             |
| ------------- | ---- | --------------------------------- |
| principal_pid | text | FK -> address_principals.gnaf_pid |
| alias_pid     | text | FK -> address_aliases.gnaf_pid    |
| alias_type    | text | e.g. 'SYNONYM'                    |

### address_secondary_lookup (1,161 rows)

| Column        | Type | Notes                             |
| ------------- | ---- | --------------------------------- |
| primary_pid   | text | FK -> address_principals.gnaf_pid |
| secondary_pid | text | FK -> address_principals.gnaf_pid |
| join_type     | text |                                   |

### address_principal_admin_boundaries (451 rows) — DERIVED

**This table is now derived via spatial join (E1.10), not pre-seeded.**
The administrative spatial join in `address_full_prep.sql` populates it from boundary polygons
in `admin_bdys_202602.*`, which are themselves derived from `raw_admin_bdys_202602.aus_*`
tables by `fixtures/prep-admin-bdys.sql`.

| Column                                       | Type    | Notes                    |
| -------------------------------------------- | ------- | ------------------------ |
| gid                                          | integer | PK                       |
| gnaf_pid                                     | text    | FK -> address_principals |
| locality_pid, locality_name, postcode, state | text    |                          |
| ce_pid, ce_name                              | text    | Commonwealth electorate  |
| lga_pid, lga_name                            | text    | Local government area    |
| ward_pid, ward_name                          | text    |                          |
| se_lower_pid, se_lower_name                  | text    | State electorate         |
| se_upper_pid, se_upper_name                  | text    |                          |

### address_alias_admin_boundaries (75 rows)

Same schema as address_principal_admin_boundaries.

### localities (267 rows)

| Column              | Type     | Notes                                                  |
| ------------------- | -------- | ------------------------------------------------------ |
| gid                 | integer  | PK                                                     |
| locality_pid        | text     | Unique ID                                              |
| locality_name       | text     |                                                        |
| postcode            | text     | YES                                                    |
| state               | text     |                                                        |
| locality_class      | text     | Expanded name, e.g. 'GAZETTED LOCALITY' (not the code) |
| latitude, longitude | numeric  |                                                        |
| address_count       | integer  |                                                        |
| geom                | geometry |                                                        |

### locality_aliases (500 rows)

| Column              | Type | Notes            |
| ------------------- | ---- | ---------------- |
| locality_pid        | text | FK -> localities |
| locality_alias_name | text |                  |
| alias_type          | text |                  |

### locality_neighbour_lookup (1,709 rows)

| Column                 | Type | Notes            |
| ---------------------- | ---- | ---------------- |
| locality_pid           | text | FK -> localities |
| neighbour_locality_pid | text | FK -> localities |

### streets (405 rows)

| Column              | Type     | Notes                                          |
| ------------------- | -------- | ---------------------------------------------- |
| gid                 | integer  | PK                                             |
| street_locality_pid | text     | Unique ID                                      |
| locality_pid        | text     | FK -> localities                               |
| street_name         | text     |                                                |
| street_type         | text     | Expanded name, e.g. PARADE                     |
| full_street_name    | text     |                                                |
| street_class        | text     | Expanded name, e.g. 'CONFIRMED' (not the code) |
| latitude, longitude | numeric  |                                                |
| geom                | geometry |                                                |

### street_aliases (32 rows)

| Column                               | Type | Notes         |
| ------------------------------------ | ---- | ------------- |
| street_locality_pid                  | text | FK -> streets |
| alias_street_name, alias_street_type | text |               |
| full_alias_street_name               | text |               |

### qa (row counts per state)

QA table with per-state row counts. Not used in flatten pipeline.

---

## raw_gnaf_202602 (raw tables)

### address_detail (451 rows)

Raw address detail — linked to address_principals via `address_detail_pid = gnaf_pid`.

| Column              | Type         | Notes                             |
| ------------------- | ------------ | --------------------------------- |
| address_detail_pid  | varchar(15)  | PK, = address_principals.gnaf_pid |
| building_name       | varchar(100) |                                   |
| flat_type_code      | varchar(7)   | FK -> flat_type_aut.code          |
| flat_number         | numeric(5,0) |                                   |
| level_type_code     | varchar(4)   | FK -> level_type_aut.code         |
| level_number        | numeric(3,0) |                                   |
| number_first        | numeric(6,0) |                                   |
| number_last         | numeric(6,0) |                                   |
| street_locality_pid | varchar(15)  |                                   |
| locality_pid        | varchar(15)  |                                   |
| postcode            | varchar(4)   |                                   |
| legal_parcel_id     | varchar(20)  |                                   |
| confidence          | numeric(1,0) |                                   |
| address_site_pid    | varchar(15)  | FK -> address_site                |
| primary_secondary   | varchar(1)   | 'P' or 'S'                        |

### address_site (451 rows)

| Column            | Type        | Notes |
| ----------------- | ----------- | ----- |
| address_site_pid  | varchar(15) | PK    |
| address_type      | varchar(8)  |       |
| address_site_name | varchar(45) |       |

### address_site_geocode (828 rows)

Multiple geocodes per address site.

| Column                   | Type          | Notes                       |
| ------------------------ | ------------- | --------------------------- |
| address_site_geocode_pid | varchar(15)   | PK                          |
| address_site_pid         | varchar(15)   | FK -> address_site          |
| geocode_type_code        | varchar(4)    | FK -> geocode_type_aut.code |
| reliability_code         | numeric(1,0)  | 1-6                         |
| longitude                | numeric(11,8) |                             |
| latitude                 | numeric(10,8) |                             |

### address_default_geocode (451 rows)

| Column              | Type        | Notes                |
| ------------------- | ----------- | -------------------- |
| address_detail_pid  | varchar(15) | FK -> address_detail |
| geocode_type_code   | varchar(4)  |                      |
| longitude, latitude | numeric     |                      |

### Authority Tables (code -> name lookups)

| Table                   | Rows | Code Column       | Example                                                       |
| ----------------------- | ---- | ----------------- | ------------------------------------------------------------- |
| flat_type_aut           | 54   | code varchar(7)   | 'UNIT' -> 'UNIT'                                              |
| level_type_aut          | 16   | code varchar(4)   | 'L' -> 'LEVEL'                                                |
| street_type_aut         | 276  | code varchar(15)  | 'AVENUE' -> 'AV' (reversed convention; not joined by flatten) |
| street_suffix_aut       | 19   | code varchar(15)  | 'N' -> 'NORTH'                                                |
| geocode_type_aut        | 30   | code varchar(4)   | 'FCS' -> 'FRONTAGE CENTRE SETBACK'                            |
| geocode_reliability_aut | 6    | code numeric(1,0) | 2 -> 'WITHIN ADDRESS SITE BOUNDARY...'                        |
| locality_class_aut      | 9    | code character(1) | 'G' -> 'GAZETTED LOCALITY'                                    |
| street_class_aut        | 2    | code character(1) | 'C' -> 'CONFIRMED'                                            |
| address_type_aut        | 3    | code varchar(8)   |                                                               |
| address_alias_type_aut  | 8    | code varchar(10)  |                                                               |

Authority tables provide `code`, `name` and description columns. `street_type_aut` reverses the usual code/name meaning; do not use it to expand the already-expanded processed street type.

---

## admin_bdys_202602

### abs_2026_mb (430 synthetic rows; schema 1.x)

Created by the mesh-block section of the pinned upstream 202608 census SQL,
executed by `scripts/extract-census-prep.mjs`. The raw input is
`raw_admin_bdys_202602.aus_mb_2026` from `seed-census-2026.sql`.
The same overlay adds `mb_2026_code bigint` to principal and alias addresses.

| Column                     | Purpose                                                               |
| -------------------------- | --------------------------------------------------------------------- |
| `mb_code_26`               | Mesh block code; joined from `address_principals.mb_2026_code`        |
| `mb_cat_26`                | Mesh block category                                                   |
| `s1_code_26`               | SA1 code                                                              |
| `s2_code_26`, `s2_name_26` | SA2 code and name                                                     |
| `s3_code_26`, `s3_name_26` | SA3 code and name                                                     |
| `s4_code_26`, `s4_name_26` | SA4 code and name                                                     |
| `gc_code_26`, `gc_name_26` | GCCSA code and name                                                   |
| `geom`                     | Synthetic MultiPolygon, SRID 7844; census enrichment uses code lookup |

These are synthetic 2026 assignments. Most reuse historical values to keep the
fixture varied; two deliberate changes test a new mesh-block code and a reassigned
hierarchy. See the [complete change inventory](SCHEMA-1.0-CHANGES.md).
The following 2021 tables remain as source data and regression decoys, not runtime joins.

### abs_2021_mb (430 rows)

**Historical mesh-block table.** Populated by `seed-postgres.sql` from the
original lookup. Used only to construct deterministic synthetic 2026 fixture
assignments. Production schema 1.x joins `abs_2026_mb`.

| Column     | Type        | Notes                                   |
| ---------- | ----------- | --------------------------------------- |
| gid        | int         | Synthetic, ROW_NUMBER over mb21_code    |
| mb21_code  | bigint      | FK from address_principals.mb_2021_code |
| mb_cat     | text        | Mesh block category, e.g. 'COMMERCIAL'  |
| sa1_21code | varchar(11) |                                         |
| sa2_21code | varchar(9)  |                                         |
| sa2_21name | text        |                                         |
| sa3_21code | varchar(5)  |                                         |
| sa3_21name | text        |                                         |
| sa4_21code | varchar(3)  |                                         |
| sa4_21name | text        |                                         |
| gcc_21code | text        | Greater capital city statistical area   |
| gcc_21name | text        |                                         |
| state      | text        |                                         |

This historical table has no geometry. The current 2026 fixture includes
synthetic geometry and executes upstream prep SQL.

### abs_2021_mb_lookup (430 rows — back-compat shim)

Original fixture-only denormalized lookup table. Same column data as
`abs_2021_mb` but without the synthetic `gid`. Retained as a back-compat shim
for any external tooling that historically referenced the lookup name. Schema 1.x flatten reads `abs_2026_mb`; this table is retained only in the frozen base seed.

| Column     | Type        | Notes                                       |
| ---------- | ----------- | ------------------------------------------- |
| mb21_code  | bigint      | PK, FK from address_principals.mb_2021_code |
| mb_cat     | text        | Mesh block category, e.g. 'COMMERCIAL'      |
| sa1_21code | varchar(11) |                                             |
| sa2_21code | varchar(9)  |                                             |
| sa2_21name | text        |                                             |
| sa3_21code | varchar(5)  |                                             |
| sa3_21name | text        |                                             |
| sa4_21code | varchar(3)  |                                             |
| sa4_21name | text        |                                             |
| gcc_21code | text        | Greater capital city statistical area       |
| gcc_21name | text        |                                             |
| state      | text        |                                             |

---

## raw_admin_bdys_202602 (raw boundary tables — E1.10)

Populated by `fixtures/seed-admin-bdys.sql`. These mirror the tables that `shp2pgsql`
normally creates from Admin Boundary shapefiles. Geometries are tiny rectangular buffers
(ST_Expand 0.00005°) around each fixture address point, grouped by boundary assignment.

The prep SQL (`fixtures/prep-admin-bdys.sql`) transforms these into `admin_bdys_202602.*`
boundary tables, which the spatial join in `address_full_prep.sql` uses to derive
`address_principal_admin_boundaries`.

### aus_state (1 row)

| Column    | Type | Notes              |
| --------- | ---- | ------------------ |
| state_pid | text | PK, e.g. 'STE-VIC' |
| st_abbrev | text | e.g. 'VIC'         |

### aus_comm_electoral (38 rows)

| Column    | Type | Notes                    |
| --------- | ---- | ------------------------ |
| ce_pid    | text | PK                       |
| name      | text | e.g. 'ASTON'             |
| state_pid | text | FK -> aus_state          |
| dt_gazetd | text | Gazettal date (nullable) |

### aus_comm_electoral_polygon (38 rows)

| Column | Type                        | Notes                    |
| ------ | --------------------------- | ------------------------ |
| gid    | integer                     | PK                       |
| ce_pid | text                        | FK -> aus_comm_electoral |
| geom   | geometry(MultiPolygon,7844) | GDA2020                  |

### aus_lga (70 rows)

| Column   | Type                        | Notes            |
| -------- | --------------------------- | ---------------- |
| gid      | integer                     | PK               |
| lga_pid  | text                        | e.g. 'VIC209'    |
| abb_name | text                        | Abbreviated name |
| lga_name | text                        | Full name        |
| state    | text                        | e.g. 'VIC'       |
| geom     | geometry(MultiPolygon,7844) | GDA2020          |

### aus_wards (244 rows)

| Column    | Type                        | Notes              |
| --------- | --------------------------- | ------------------ |
| gid       | integer                     | PK                 |
| ward_pid  | text                        | e.g. 'WRD-VIC-100' |
| lga_pid   | text                        | FK -> aus_lga      |
| ward_name | text                        |                    |
| state     | text                        |                    |
| geom      | geometry(MultiPolygon,7844) | GDA2020            |

### aus_state_electoral_class_aut (2 rows)

| Column | Type | Notes                                     |
| ------ | ---- | ----------------------------------------- |
| code   | text | PK: '1' = Lower House, '3' = Upper House  |
| name   | text | e.g. 'Legislative Assembly (Lower House)' |

### aus_state_electoral (94 rows — lower + upper combined)

| Column    | Type      | Notes                    |
| --------- | --------- | ------------------------ |
| se_pid    | text      | PK                       |
| name      | text      | Electorate name          |
| dt_gazetd | text      | Nullable                 |
| eff_start | timestamp | Default now()            |
| eff_end   | timestamp | NULL = current           |
| secl_code | text      | '1' = lower, '3' = upper |
| state_pid | text      | FK -> aus_state          |

### aus_state_electoral_polygon (94 rows)

| Column | Type                        | Notes                     |
| ------ | --------------------------- | ------------------------- |
| gid    | integer                     | PK                        |
| se_pid | text                        | FK -> aus_state_electoral |
| geom   | geometry(MultiPolygon,7844) | GDA2020                   |

### aus_mb_2026 (430 synthetic rows; schema 1.0.0 overlay)

**Schema 1.0.0 change:** seeded by `seed-census-2026.sql`, then transformed by the
mesh-block section of the pinned upstream census preparation SQL. The resulting
`abs_2026_mb` table is documented above. Codes and names are synthetic test values.

| Raw column(s)              | Type                        | Purpose                                                                |
| -------------------------- | --------------------------- | ---------------------------------------------------------------------- |
| `gid`                      | integer                     | Primary key.                                                           |
| `mb_ply_26`, `mb_pid_26`   | varchar(15)                 | Mesh-block polygon and feature identifiers.                            |
| `dt_create`                | date                        | Synthetic creation date.                                               |
| `mb_code_26`               | varchar(11)                 | 2026 mesh-block code; upstream prep converts the lookup key to bigint. |
| `mb_cat_26`                | varchar(30)                 | Mesh-block category.                                                   |
| `chn_flg_26`, `chn_lbl_26` | varchar(1), varchar(11)     | Change flag and label.                                                 |
| `s1_pid_26`, `s1_code_26`  | varchar(15), varchar(11)    | SA1 identifier and code.                                               |
| `s2_code_26`, `s2_name_26` | varchar(9), varchar(50)     | SA2 code and name.                                                     |
| `s3_code_26`, `s3_name_26` | varchar(5), varchar(50)     | SA3 code and name.                                                     |
| `s4_code_26`, `s4_name_26` | varchar(3), varchar(50)     | SA4 code and name.                                                     |
| `gc_code_26`, `gc_name_26` | varchar(5), varchar(50)     | GCCSA code and name.                                                   |
| `state`                    | varchar(3)                  | VIC in this fixture.                                                   |
| `mb_ar_sqkm`               | numeric(11,2)               | Synthetic area value.                                                  |
| `geom`                     | geometry(MultiPolygon,7844) | Synthetic GDA2020 geometry.                                            |
