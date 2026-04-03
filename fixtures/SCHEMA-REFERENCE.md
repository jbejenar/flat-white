# Fixture Schema Reference

> Generated from `fixtures/seed-postgres.sql`. Use this file instead of reading the 10k-line SQL file.
> Three schemas: `gnaf_202602` (processed), `raw_gnaf_202602` (raw G-NAF), `admin_bdys_202602` (ABS boundaries).

## gnaf_202602 (processed tables)

### address_principals (451 rows)

Core table — one row per principal address. **Primary driving table in address_full.sql.**

| Column              | Type                 | Nullable | Notes                                  |
| ------------------- | -------------------- | -------- | -------------------------------------- |
| gid                 | integer              | NO       | PK (serial)                            |
| gnaf_pid            | text                 | NO       | Unique address ID, e.g. GAVIC425181432 |
| street_locality_pid | text                 | NO       | FK -> streets                          |
| locality_pid        | text                 | NO       | FK -> localities                       |
| alias_principal     | character(1)         | NO       | Always 'P' for principals              |
| primary_secondary   | text                 | YES      | 'P' or 'S' (single letter)             |
| building_name       | text                 | YES      |                                        |
| lot_number          | text                 | YES      |                                        |
| flat_number         | text                 | YES      |                                        |
| level_number        | text                 | YES      |                                        |
| number_first        | text                 | YES      |                                        |
| number_last         | text                 | YES      |                                        |
| street_name         | text                 | NO       |                                        |
| street_type         | text                 | YES      | Abbreviation code, e.g. 'AV'           |
| street_suffix       | text                 | YES      |                                        |
| address             | text                 | NO       | Composed label                         |
| locality_name       | text                 | NO       |                                        |
| postcode            | text                 | YES      |                                        |
| state               | text                 | NO       |                                        |
| locality_postcode   | text                 | YES      |                                        |
| confidence          | smallint             | NO       | 0-2                                    |
| legal_parcel_id     | text                 | YES      |                                        |
| mb_2016_code        | bigint               | YES      |                                        |
| mb_2021_code        | bigint               | YES      | FK -> abs_2021_mb_lookup               |
| latitude            | numeric(10,8)        | NO       | GDA2020                                |
| longitude           | numeric(11,8)        | NO       | GDA2020                                |
| geocode_type        | text                 | NO       |                                        |
| reliability         | smallint             | NO       | 1-6                                    |
| geom                | geometry(Point,7844) | NO       | PostGIS point                          |

**Joins in address_full.sql:**

- -> raw_gnaf_202602.address_detail ON gnaf_pid = address_detail_pid
- -> gnaf_202602.localities ON locality_pid
- -> gnaf_202602.streets ON street_locality_pid
- -> address_principal_admin_boundaries ON gnaf_pid
- -> admin_bdys_202602.abs_2021_mb_lookup ON mb_2021_code = mb21_code
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

### address_principal_admin_boundaries (451 rows)

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
| street_type         | text     | Abbreviation                                   |
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

| Table                   | Rows | Code Column       | Example                                |
| ----------------------- | ---- | ----------------- | -------------------------------------- |
| flat_type_aut           | 54   | code varchar(7)   | 'UNIT' -> 'UNIT'                       |
| level_type_aut          | 16   | code varchar(4)   | 'L' -> 'LEVEL'                         |
| street_type_aut         | 276  | code varchar(15)  | 'AV' -> 'AVENUE'                       |
| street_suffix_aut       | 19   | code varchar(15)  | 'N' -> 'NORTH'                         |
| geocode_type_aut        | 30   | code varchar(4)   | 'FCS' -> 'FRONTAGE CENTRE SETBACK'     |
| geocode_reliability_aut | 6    | code numeric(1,0) | 2 -> 'WITHIN ADDRESS SITE BOUNDARY...' |
| locality_class_aut      | 9    | code character(1) | 'G' -> 'GAZETTED LOCALITY'             |
| street_class_aut        | 2    | code character(1) | 'C' -> 'CONFIRMED'                     |
| address_type_aut        | 3    | code varchar(8)   |                                        |
| address_alias_type_aut  | 8    | code varchar(10)  |                                        |

All authority tables have: `code` (PK), `name` (varchar 50), `description`.

---

## admin_bdys_202602

### abs_2021_mb_lookup (430 rows)

ABS mesh block to statistical area mapping.

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
