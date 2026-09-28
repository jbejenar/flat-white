# Fixtures — flat-white

## Overview

This directory contains committed test data for fixture-first development. The address snapshot contains 451 VIC addresses from February 2026. Administrative polygons and the ASGS 2026 census overlay are synthetic test data; they are not authoritative geographic assignments.

**Load time:** <30 seconds on commodity hardware (no gnaf-loader, no download required).

## Files

| File                     | Purpose                                                                           |
| ------------------------ | --------------------------------------------------------------------------------- |
| `seed-postgres.sql`      | Schema DDL + fixture data. Load into fresh Postgres + PostGIS.                    |
| `seed-census-2026.sql`   | Synthetic raw census rows and 2026 mesh-block assignments; preserves 2021 decoys. |
| `expected-output.ndjson` | Byte-for-byte schema 1.0.0 regression baseline.                                   |
| `edge-cases.md`          | Catalogue of edge case categories with specific PIDs.                             |
| `README.md`              | This file.                                                                        |

## How to load

```bash
# Requires Docker. Seeds raw fixtures, runs prep SQL, flattens and verifies.
./scripts/build-fixture-only.sh
```

Loading `seed-postgres.sql` alone only restores the historical address snapshot;
the fixture script also applies administrative and census overlays.

## Source data

| Field               | Value                               |
| ------------------- | ----------------------------------- |
| G-NAF version       | February 2026                       |
| Datum               | GDA2020 (SRID 7844)                 |
| gnaf-loader version | Submodule commit at generation time |
| Geoscape version    | 202602                              |
| State               | VIC only                            |
| Address count       | 451                                 |

## Schema (gnaf-loader output)

The base fixture captures the historical loader output. `seed-census-2026.sql` adds the current census columns and synthetic raw rows, and `scripts/extract-census-prep.mjs` executes the mesh-block section from the pinned upstream 202608 SQL. Key base tables:

| Schema      | Table                              | Rows | Description                           |
| ----------- | ---------------------------------- | ---- | ------------------------------------- |
| gnaf_202602 | address_principals                 | 451  | Principal addresses                   |
| gnaf_202602 | address_aliases                    | 75   | Alias addresses                       |
| gnaf_202602 | address_alias_lookup               | 75   | Principal ↔ alias mapping             |
| gnaf_202602 | address_secondary_lookup           | 1161 | Primary ↔ secondary mapping           |
| gnaf_202602 | address_principal_admin_boundaries | 451  | Boundary tags (LGA, electorate, etc.) |
| gnaf_202602 | localities                         | 267  | Localities with geocodes              |
| gnaf_202602 | locality_aliases                   | 500  | Locality alternative names            |
| gnaf_202602 | locality_neighbour_lookup          | 1709 | Locality neighbour relationships      |
| gnaf_202602 | streets                            | 405  | Streets with geocodes                 |
| gnaf_202602 | street_aliases                     | 32   | Street alternative names              |

## Drift detection

This fixture detects schema drift:

- The census fixture executes upstream prep SQL, so incompatible census columns or transforms fail CI. The historical base seed does not simulate a full loader run.
- Flatten output must match `expected-output.ndjson` byte for byte and match between the CTE and materialized SQL paths.
- `extract-fixtures.sh` is restricted to the frozen February 2026 snapshot and its original loader/schema. Do not run a full production load for development; a new address snapshot needs a separate, reviewed fixture migration.

## FK constraints

Two FK constraints are excluded because they reference rows outside the fixture subset:

- `address_aliases_fk2` (alias street → streets): some aliases reference streets not in the fixture
- `locality_neighbour_lookup_fk2` (neighbour → localities): some neighbours are localities not in the fixture

All other constraints and indexes are present and enforced.

## Raw tables (for flatten pipeline)

The fixture also includes raw G-NAF tables needed by the flatten pipeline for:

- `allGeocodes[]` array: `raw_gnaf_202602.address_site_geocode` (828 rows — multiple geocode types per address)
- `addressLabelSearch` field: `raw_gnaf_202602.flat_type_aut` (54 types), `level_type_aut` (16), `street_type_aut` (276), `street_suffix_aut` (19) for abbreviation expansion
- `geocode.type` names: `raw_gnaf_202602.geocode_type_aut` (30 types)
- Address detail: `raw_gnaf_202602.address_detail` (451 rows — flat_type_code, level_type_code, date fields)

| Schema          | Table                   | Rows | Purpose                                              |
| --------------- | ----------------------- | ---- | ---------------------------------------------------- |
| raw_gnaf_202602 | address_detail          | 451  | Flat/level type codes, dates, address_site_pid link  |
| raw_gnaf_202602 | address_site            | 451  | Links address_detail to geocodes                     |
| raw_gnaf_202602 | address_site_geocode    | 828  | All geocode types per address (for allGeocodes[])    |
| raw_gnaf_202602 | address_default_geocode | 451  | Default geocode per address                          |
| raw_gnaf_202602 | flat_type_aut           | 54   | Flat type code → name (UNIT, APT, SHOP, etc.)        |
| raw_gnaf_202602 | level_type_aut          | 16   | Level type code → name (LEVEL, FLOOR, etc.)          |
| raw_gnaf_202602 | street_type_aut         | 276  | Street type code → name (AV→AVENUE, ST→STREET, etc.) |
| raw_gnaf_202602 | street_suffix_aut       | 19   | Street suffix code → name                            |
| raw_gnaf_202602 | geocode_type_aut        | 30   | Geocode type code → name (FCS, PC, PAP, etc.)        |
| raw_gnaf_202602 | geocode_reliability_aut | 6    | Geocode reliability code → description               |
| raw_gnaf_202602 | locality_class_aut      | 9    | Locality class code → name                           |
| raw_gnaf_202602 | address_type_aut        | 3    | Address type code → name                             |
| raw_gnaf_202602 | address_alias_type_aut  | 8    | Alias type code → name                               |
| raw_gnaf_202602 | street_class_aut        | 2    | Street class code → name                             |

## Schema versioning

The fixture uses versioned schema names from gnaf-loader:

- `gnaf_202602` — processed output tables (Feb 2026 release)
- `raw_gnaf_202602` — raw imported data

The flatten pipeline code must reference these schema names. When a new G-NAF quarterly release is loaded, gnaf-loader creates new versioned schemas (e.g., `gnaf_202605`). The fixture always uses the version it was generated from.

## ABS statistical area lookup

`seed-census-2026.sql` creates 430 synthetic raw mesh-block rows in
`raw_admin_bdys_202602.aus_mb_2026`, including small synthetic polygons. It adds
and populates `mb_2026_code` on the frozen principal/alias address tables.
The pinned upstream `02-02e-prep-census-2026-bdys-tables.sql` creates the actual
processed `admin_bdys_202602.abs_2026_mb` table. Both flatten paths join it:

```
address_principals.mb_2026_code → abs_2026_mb.mb_code_26
  → mb_cat_26
  → s1_code_26
  → s2_code_26, s2_name_26
  → s3_code_26, s3_name_26
  → s4_code_26, s4_name_26
  → gc_code_26, gc_name_26
```

Codes and names deliberately differ from the retained 2021 tables. Accidentally
reading `mb_2021_code` or joining `abs_2021_mb` therefore fails regression rather
than silently passing. The original 2021 tables remain historical fixture data;
production schema 1.x never falls back to them.

The G-NAF fixture `_version` remains `2026.02`. Its synthetic census overlay does
not imply that the real February 2026 release contains ASGS 2026 geography.
