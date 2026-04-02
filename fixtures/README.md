# Fixtures — flat-white

## Overview

This directory contains committed test data for fixture-first development. The fixture is a self-consistent subset of the full VIC G-NAF + Administrative Boundaries dataset — 451 addresses covering all edge case categories.

**Load time:** <30 seconds on commodity hardware (no gnaf-loader, no download required).

## Files

| File | Purpose |
|---|---|
| `seed-postgres.sql` | Schema DDL + fixture data. Load into fresh Postgres + PostGIS. |
| `edge-cases.md` | Catalogue of edge case categories with specific PIDs. |
| `README.md` | This file. |

## How to load

```bash
# Requires: Docker running, Postgres + PostGIS via docker-compose
docker compose up -d db
docker compose exec db psql -U postgres -d gnaf -c "CREATE EXTENSION IF NOT EXISTS postgis;"
docker compose exec -T db psql -U postgres -d gnaf -f /fixtures/seed-postgres.sql
```

## Source data

| Field | Value |
|---|---|
| G-NAF version | February 2026 |
| Datum | GDA2020 (SRID 7844) |
| gnaf-loader version | Submodule commit at generation time |
| Geoscape version | 202602 |
| State | VIC only |
| Address count | 451 |

## Schema (gnaf-loader output)

The fixture captures gnaf-loader's exact output schema. Key tables:

| Schema | Table | Rows | Description |
|---|---|---|---|
| gnaf_202602 | address_principals | 451 | Principal addresses |
| gnaf_202602 | address_aliases | 75 | Alias addresses |
| gnaf_202602 | address_alias_lookup | 75 | Principal ↔ alias mapping |
| gnaf_202602 | address_secondary_lookup | 1161 | Primary ↔ secondary mapping |
| gnaf_202602 | address_principal_admin_boundaries | 451 | Boundary tags (LGA, electorate, etc.) |
| gnaf_202602 | localities | 267 | Localities with geocodes |
| gnaf_202602 | locality_aliases | 500 | Locality alternative names |
| gnaf_202602 | locality_neighbour_lookup | 1709 | Locality neighbour relationships |
| gnaf_202602 | streets | 405 | Streets with geocodes |
| gnaf_202602 | street_aliases | 32 | Street alternative names |

## Drift detection

This fixture detects schema drift:
- If gnaf-loader changes table names, column names, or column types → `seed-postgres.sql` fails to load → CI catches it.
- If the flatten pipeline changes output → `expected-output.ndjson` (once committed) differs → regression test catches it.
- To regenerate: `./scripts/extract-fixtures.sh` against a full VIC load.

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

| Schema | Table | Rows | Purpose |
|---|---|---|---|
| raw_gnaf_202602 | address_detail | 451 | Flat/level type codes, dates, address_site_pid link |
| raw_gnaf_202602 | address_site | 451 | Links address_detail to geocodes |
| raw_gnaf_202602 | address_site_geocode | 828 | All geocode types per address (for allGeocodes[]) |
| raw_gnaf_202602 | address_default_geocode | 451 | Default geocode per address |
| raw_gnaf_202602 | flat_type_aut | 54 | Flat type code → name (UNIT, APT, SHOP, etc.) |
| raw_gnaf_202602 | level_type_aut | 16 | Level type code → name (LEVEL, FLOOR, etc.) |
| raw_gnaf_202602 | street_type_aut | 276 | Street type code → name (AV→AVENUE, ST→STREET, etc.) |
| raw_gnaf_202602 | street_suffix_aut | 19 | Street suffix code → name |
| raw_gnaf_202602 | geocode_type_aut | 30 | Geocode type code → name (FCS, PC, PAP, etc.) |
| raw_gnaf_202602 | geocode_reliability_aut | 6 | Geocode reliability code → description |
| raw_gnaf_202602 | locality_class_aut | 9 | Locality class code → name |
| raw_gnaf_202602 | address_type_aut | 3 | Address type code → name |
| raw_gnaf_202602 | address_alias_type_aut | 8 | Alias type code → name |
| raw_gnaf_202602 | street_class_aut | 2 | Street class code → name |

## Schema versioning

The fixture uses versioned schema names from gnaf-loader:
- `gnaf_202602` — processed output tables (Feb 2026 release)
- `raw_gnaf_202602` — raw imported data

The flatten pipeline code must reference these schema names. When a new G-NAF quarterly release is loaded, gnaf-loader creates new versioned schemas (e.g., `gnaf_202605`). The fixture always uses the version it was generated from.

## ABS statistical area lookup

The fixture includes a lightweight `admin_bdys_202602.abs_2021_mb_lookup` table (430 rows, no geometry) that maps mesh block codes to the full ABS statistical area hierarchy:

```
address_principals.mb_2021_code → abs_2021_mb_lookup.mb21_code
  → mb_cat (mesh block category: Residential, Commercial, etc.)
  → sa1_21code
  → sa2_21code, sa2_21name
  → sa3_21code, sa3_21name
  → sa4_21code, sa4_21name
  → gcc_21code, gcc_21name (GCCSA: Greater Melbourne, Rest of Vic., etc.)
```

This is a derived table (not from gnaf-loader directly) — it extracts non-geometry columns from `admin_bdys_202602.abs_2021_mb` to avoid committing multi-megabyte polygon data. The flatten pipeline should join on `mb21_code` to populate the `boundaries.meshBlock`, `boundaries.sa1` through `boundaries.gccsa` output fields.
