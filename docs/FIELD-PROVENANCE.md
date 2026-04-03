# Field Provenance — flat-white

> Maps every output document field to its source G-NAF table, column, and transformation.
> Use this to trace any field from the NDJSON output back to its origin without database access.

---

## Table Inventory

All tables joined by `sql/address_full.sql` and its CTEs. Row counts are from the committed fixture (`fixtures/seed-postgres.sql`).

| Schema              | Table                                | Alias in SQL | Fixture Rows | Role                                                           |
| ------------------- | ------------------------------------ | ------------ | ------------ | -------------------------------------------------------------- |
| `gnaf_202602`       | `address_principals`                 | `ap`         | 451          | Driving table — one row per principal address                  |
| `gnaf_202602`       | `address_aliases`                    | `aa`         | 75           | Alternative address names (joined via lookup)                  |
| `gnaf_202602`       | `address_alias_lookup`               | `aal`        | 75           | Maps principal_pid → alias_pid + alias_type                    |
| `gnaf_202602`       | `address_secondary_lookup`           | `asl`        | 1,161        | Maps primary_pid → secondary_pid                               |
| `gnaf_202602`       | `localities`                         | `loc`        | 267          | Locality (suburb) metadata                                     |
| `gnaf_202602`       | `locality_aliases`                   | `la`         | 500          | Alternative locality names                                     |
| `gnaf_202602`       | `locality_neighbour_lookup`          | `ln` (CTE)   | 1,709        | Adjacent locality pairs                                        |
| `gnaf_202602`       | `streets`                            | `st`         | 405          | Street metadata                                                |
| `gnaf_202602`       | `street_aliases`                     | `sa`         | 32           | Alternative street names                                       |
| `gnaf_202602`       | `address_principal_admin_boundaries` | `ab`         | 451          | Spatially-joined admin boundaries per address                  |
| `raw_gnaf_202602`   | `address_detail`                     | `ad`         | 451          | Raw address detail (flat/level type codes, address_site_pid)   |
| `raw_gnaf_202602`   | `address_site`                       | `site`       | 451          | Site names (shopping centres, hospitals)                       |
| `raw_gnaf_202602`   | `address_site_geocode`               | `asg`        | 828          | All geocode types per address site                             |
| `raw_gnaf_202602`   | `flat_type_aut`                      | `ft`         | 54           | Code → name expansion (e.g. `UNIT` → `UNIT`)                   |
| `raw_gnaf_202602`   | `level_type_aut`                     | `lt`         | 16           | Code → name expansion (e.g. `L` → `LEVEL`)                     |
| `raw_gnaf_202602`   | `street_type_aut`                    | `st_aut`     | 276          | Code → name expansion (e.g. `AV` → `AVENUE`)                   |
| `raw_gnaf_202602`   | `street_suffix_aut`                  | `ss_aut`     | 19           | Code → name expansion (e.g. `N` → `NORTH`)                     |
| `raw_gnaf_202602`   | `geocode_type_aut`                   | `gt`         | 30           | Code → name expansion (e.g. `FCS` → `FRONTAGE CENTRE SETBACK`) |
| `raw_gnaf_202602`   | `locality_class_aut`                 | `lc_aut`     | 9            | Name-based join for locality class                             |
| `raw_gnaf_202602`   | `street_class_aut`                   | `sc_aut`     | 2            | Name-based join for street class                               |
| `admin_bdys_202602` | `abs_2021_mb_lookup`                 | `mb`         | 430          | Mesh block → SA1/SA2/SA3/SA4/GCCSA mapping                     |

**Related but not referenced by `address_full.sql`:**

| Schema            | Table                     | Fixture Rows | Note                                                                                                                            |
| ----------------- | ------------------------- | ------------ | ------------------------------------------------------------------------------------------------------------------------------- |
| `raw_gnaf_202602` | `address_default_geocode` | 451          | Contains default geocodes, but the flatten SQL sources geocodes from `address_site_geocode` via the `best_geocode` CTE instead. |

---

## Join Map

```
address_principals (ap)  ←— DRIVING TABLE
  │
  ├── JOIN address_detail (ad) ON ad.address_detail_pid = ap.gnaf_pid
  │     ├── LEFT JOIN address_site (site) ON site.address_site_pid = ad.address_site_pid
  │     ├── LEFT JOIN flat_type_aut (ft) ON ft.code = ad.flat_type_code
  │     └── LEFT JOIN level_type_aut (lt) ON lt.code = ad.level_type_code
  │
  ├── LEFT JOIN street_type_aut (st_aut) ON st_aut.code = ap.street_type
  ├── LEFT JOIN street_suffix_aut (ss_aut) ON ss_aut.code = ap.street_suffix
  │
  ├── LEFT JOIN address_geocodes (CTE) ON address_detail_pid = ap.gnaf_pid
  │     └── Uses: address_detail → address_site_geocode (via address_site_pid)
  │              + geocode_type_aut (for best_geocode type name expansion)
  │
  ├── JOIN localities (loc) ON loc.locality_pid = ap.locality_pid
  │     ├── LEFT JOIN locality_class_aut (lc_aut) ON lc_aut.name = loc.locality_class
  │     ├── LEFT JOIN locality_neighbours (CTE) ON locality_pid = ap.locality_pid
  │     │     └── Uses: locality_neighbour_lookup → localities (for neighbour names)
  │     └── LEFT JOIN locality_alias_agg (CTE) ON locality_pid = ap.locality_pid
  │           └── Uses: locality_aliases
  │
  ├── JOIN streets (st) ON st.street_locality_pid = ap.street_locality_pid
  │     ├── LEFT JOIN street_class_aut (sc_aut) ON sc_aut.name = st.street_class
  │     └── LEFT JOIN street_alias_agg (CTE) ON street_locality_pid = ap.street_locality_pid
  │           └── Uses: street_aliases
  │
  ├── LEFT JOIN address_principal_admin_boundaries (ab) ON ab.gnaf_pid = ap.gnaf_pid
  │
  ├── LEFT JOIN abs_2021_mb_lookup (mb) ON mb.mb21_code = ap.mb_2021_code
  │
  ├── LEFT JOIN address_alias_agg (CTE) ON principal_pid = ap.gnaf_pid
  │     └── Uses: address_alias_lookup → address_aliases
  │
  └── LEFT JOIN address_secondary_agg (CTE) ON primary_pid = ap.gnaf_pid
        └── Uses: address_secondary_lookup → address_principals (self-join)
```

---

## Field Provenance — Top-Level Fields

Every field in the output `AddressDocument` traced to its SQL source and any transformation applied in `src/flatten.ts`.

| Output Field         | SQL Alias            | Source Table.Column                                | Transform                                                                                                                                                                                                                               |
| -------------------- | -------------------- | -------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `_id`                | `_id`                | `gnaf_202602.address_principals.gnaf_pid`          | Direct                                                                                                                                                                                                                                  |
| `_version`           | —                    | Build parameter                                    | Set from `FlattenOptions.version`                                                                                                                                                                                                       |
| `addressLabel`       | `address_label`      | `gnaf_202602.address_principals.address`           | Direct                                                                                                                                                                                                                                  |
| `addressLabelSearch` | —                    | Composed                                           | `composeSearchLabel()` expands abbreviations using `flat_type_name`, `level_type_name`, `street_type_name`, `street_suffix_code`, plus `number_first`, `number_last`, `lot_number`, `street_name`, `locality_name`, `state`, `postcode` |
| `addressSiteName`    | `address_site_name`  | `raw_gnaf_202602.address_site.address_site_name`   | Null-coalesce (`?? null`)                                                                                                                                                                                                               |
| `buildingName`       | `building_name`      | `gnaf_202602.address_principals.building_name`     | Null-coalesce                                                                                                                                                                                                                           |
| `flatType`           | `flat_type_name`     | `raw_gnaf_202602.flat_type_aut.name`               | Joined via `ad.flat_type_code`; null-coalesce                                                                                                                                                                                           |
| `flatNumber`         | `flat_number`        | `gnaf_202602.address_principals.flat_number`       | Null-coalesce                                                                                                                                                                                                                           |
| `levelType`          | `level_type_name`    | `raw_gnaf_202602.level_type_aut.name`              | Joined via `ad.level_type_code`; null-coalesce                                                                                                                                                                                          |
| `levelNumber`        | `level_number`       | `gnaf_202602.address_principals.level_number`      | Null-coalesce                                                                                                                                                                                                                           |
| `numberFirst`        | `number_first`       | `gnaf_202602.address_principals.number_first`      | Null-coalesce                                                                                                                                                                                                                           |
| `numberLast`         | `number_last`        | `gnaf_202602.address_principals.number_last`       | Null-coalesce                                                                                                                                                                                                                           |
| `lotNumber`          | `lot_number`         | `gnaf_202602.address_principals.lot_number`        | Null-coalesce                                                                                                                                                                                                                           |
| `streetName`         | `street_name`        | `gnaf_202602.address_principals.street_name`       | Direct                                                                                                                                                                                                                                  |
| `streetType`         | `street_type_name`   | `gnaf_202602.address_principals.street_type`       | Direct from `ap.street_type` (already contains full name)                                                                                                                                                                               |
| `streetSuffix`       | `street_suffix_code` | `gnaf_202602.address_principals.street_suffix`     | Direct from `ap.street_suffix` (already contains full name); null-coalesce                                                                                                                                                              |
| `localityName`       | `locality_name`      | `gnaf_202602.address_principals.locality_name`     | Direct                                                                                                                                                                                                                                  |
| `state`              | `state`              | `gnaf_202602.address_principals.state`             | Direct                                                                                                                                                                                                                                  |
| `postcode`           | `postcode`           | `gnaf_202602.address_principals.postcode`          | Null-coalesce                                                                                                                                                                                                                           |
| `legalParcelId`      | `legal_parcel_id`    | `gnaf_202602.address_principals.legal_parcel_id`   | Null-coalesce                                                                                                                                                                                                                           |
| `confidence`         | `confidence`         | `gnaf_202602.address_principals.confidence`        | `Number()` cast                                                                                                                                                                                                                         |
| `aliasPrincipal`     | —                    | Derived                                            | Hardcoded `"PRINCIPAL"` — query only joins `address_principals`                                                                                                                                                                         |
| `primarySecondary`   | `primary_secondary`  | `gnaf_202602.address_principals.primary_secondary` | `mapPrimarySecondary()`: `'P'`→`"PRIMARY"`, `'S'`→`"SECONDARY"`, else `null`                                                                                                                                                            |

---

## Field Provenance — `geocode` Object

Best geocode selected per address. Determined inside the `address_geocodes` CTE.

| Output Field          | SQL Alias                  | Source Table.Column                                     | Transform                                                                    |
| --------------------- | -------------------------- | ------------------------------------------------------- | ---------------------------------------------------------------------------- |
| `geocode.latitude`    | `best_geocode.latitude`    | `raw_gnaf_202602.address_site_geocode.latitude`         | `Number()` cast. Fallback: `0` if no geocode (see note)                      |
| `geocode.longitude`   | `best_geocode.longitude`   | `raw_gnaf_202602.address_site_geocode.longitude`        | `Number()` cast. Fallback: `0` if no geocode                                 |
| `geocode.type`        | `best_geocode.type`        | `raw_gnaf_202602.geocode_type_aut.name`                 | Expanded from `geocode_type_code` via authority table. Fallback: `"UNKNOWN"` |
| `geocode.reliability` | `best_geocode.reliability` | `raw_gnaf_202602.address_site_geocode.reliability_code` | `Number()` cast. Fallback: `6`                                               |

**Selection logic (SQL):** `ORDER BY reliability_code ASC, CASE geocode_type_code WHEN 'FCS' THEN 1 WHEN 'PC' THEN 2 WHEN 'PAP' THEN 3 ELSE 4 END ASC LIMIT 1`. Only non-retired geocodes (`date_retired IS NULL`).

**Join path:** `address_principals.gnaf_pid` → `address_detail.address_detail_pid` → `address_detail.address_site_pid` → `address_site_geocode.address_site_pid`

> **⚠️ Known technical debt:** The fallback values (`latitude: 0`, `longitude: 0`, `type: "UNKNOWN"`, `reliability: 6`) when no geocode exists violate the repo's "no silent sentinel values" rule (see AGENTS.md, Immutable Rule 3). Coordinates of `0,0` place the address in the Atlantic Ocean. This fallback exists in the current `src/flatten.ts` implementation but **must not be copied into new code**. The intended fix is to either make the `geocode` field nullable across the schema (`src/schema.ts`, `docs/DOCUMENT-SCHEMA.md`, fixtures, and tests) or fail validation when no geocode is present.

---

## Field Provenance — `allGeocodes[]` Array

All geocode types for an address, aggregated in the `address_geocodes` CTE.

| Output Field                | SQL Source                   | Source Table.Column                                      | Transform                       |
| --------------------------- | ---------------------------- | -------------------------------------------------------- | ------------------------------- |
| `allGeocodes[].lat`         | `all_geocodes[].lat`         | `raw_gnaf_202602.address_site_geocode.latitude`          | `Number()` cast                 |
| `allGeocodes[].lng`         | `all_geocodes[].lng`         | `raw_gnaf_202602.address_site_geocode.longitude`         | `Number()` cast                 |
| `allGeocodes[].type`        | `all_geocodes[].type`        | `raw_gnaf_202602.address_site_geocode.geocode_type_code` | Raw abbreviation (not expanded) |
| `allGeocodes[].reliability` | `all_geocodes[].reliability` | `raw_gnaf_202602.address_site_geocode.reliability_code`  | `Number()` cast                 |

**Note:** `allGeocodes[].type` uses the raw code (e.g. `"FCS"`), while `geocode.type` uses the expanded name (e.g. `"FRONTAGE CENTRE SETBACK"`). This is intentional — the array is compact; the primary geocode is descriptive.

**Ordering:** `ORDER BY reliability_code, geocode_type_code` (within `json_agg`).

---

## Field Provenance — `locality` Object

| Output Field          | SQL Alias             | Source Table.Column                                                              | Transform                                                                                               |
| --------------------- | --------------------- | -------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| `locality.pid`        | `locality_pid`        | `gnaf_202602.localities.locality_pid`                                            | Direct                                                                                                  |
| `locality.class`      | `locality_class_name` | `raw_gnaf_202602.locality_class_aut.name`                                        | Joined via `lc_aut.name = loc.locality_class`. Fallback: `"UNKNOWN"`                                    |
| `locality.neighbours` | `locality_neighbours` | `gnaf_202602.locality_neighbour_lookup` → `gnaf_202602.localities.locality_name` | CTE aggregates neighbour names via `json_agg(... ORDER BY locality_name)`. Empty `[]` if no neighbours. |
| `locality.aliases`    | `locality_aliases`    | `gnaf_202602.locality_aliases.locality_alias_name`                               | CTE aggregates via `json_agg(... ORDER BY locality_alias_name)`. Empty `[]` if no aliases.              |

**Join path for neighbours:** `address_principals.locality_pid` → `locality_neighbour_lookup.locality_pid` → `locality_neighbour_lookup.neighbour_locality_pid` → `localities.locality_name`

**Join path for aliases:** `address_principals.locality_pid` → `locality_aliases.locality_pid`

---

## Field Provenance — `street` Object

| Output Field     | SQL Alias             | Source Table.Column                                 | Transform                                                                                     |
| ---------------- | --------------------- | --------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| `street.pid`     | `street_locality_pid` | `gnaf_202602.streets.street_locality_pid`           | Direct                                                                                        |
| `street.class`   | `street_class_name`   | `raw_gnaf_202602.street_class_aut.name`             | Joined via `sc_aut.name = st.street_class`. Fallback: `"UNKNOWN"`                             |
| `street.aliases` | `street_aliases`      | `gnaf_202602.street_aliases.full_alias_street_name` | CTE aggregates via `json_agg(... ORDER BY full_alias_street_name)`. Empty `[]` if no aliases. |

**Join path:** `address_principals.street_locality_pid` → `streets.street_locality_pid` → `street_aliases.street_locality_pid`

---

## Field Provenance — `boundaries` Object

All boundary fields sourced from two tables: the spatially-joined admin boundaries table and the ABS mesh block lookup.

| Output Field                             | SQL Alias                      | Source Table.Column                                            | Transform                                               |
| ---------------------------------------- | ------------------------------ | -------------------------------------------------------------- | ------------------------------------------------------- |
| `boundaries.lga.name`                    | `lga_name`                     | `gnaf_202602.address_principal_admin_boundaries.lga_name`      | Null if either name or code is null                     |
| `boundaries.lga.code`                    | `lga_pid`                      | `gnaf_202602.address_principal_admin_boundaries.lga_pid`       | Used as `code` in output                                |
| `boundaries.ward.name`                   | `ward_name`                    | `gnaf_202602.address_principal_admin_boundaries.ward_name`     | Null if null                                            |
| `boundaries.stateElectorate.name`        | `state_electorate_name`        | `gnaf_202602.address_principal_admin_boundaries.se_lower_name` | SQL alias: `ab.se_lower_name AS state_electorate_name`  |
| `boundaries.commonwealthElectorate.name` | `commonwealth_electorate_name` | `gnaf_202602.address_principal_admin_boundaries.ce_name`       | SQL alias: `ab.ce_name AS commonwealth_electorate_name` |
| `boundaries.meshBlock.code`              | `mb_2021_code`                 | `gnaf_202602.address_principals.mb_2021_code`                  | `String()` cast. Null if code or category is null.      |
| `boundaries.meshBlock.category`          | `mesh_block_category`          | `admin_bdys_202602.abs_2021_mb_lookup.mb_cat`                  | SQL alias: `mb.mb_cat AS mesh_block_category`           |
| `boundaries.sa1`                         | `sa1_21code`                   | `admin_bdys_202602.abs_2021_mb_lookup.sa1_21code`              | Null-coalesce                                           |
| `boundaries.sa2.code`                    | `sa2_21code`                   | `admin_bdys_202602.abs_2021_mb_lookup.sa2_21code`              | Null if either code or name is null                     |
| `boundaries.sa2.name`                    | `sa2_21name`                   | `admin_bdys_202602.abs_2021_mb_lookup.sa2_21name`              |                                                         |
| `boundaries.sa3.code`                    | `sa3_21code`                   | `admin_bdys_202602.abs_2021_mb_lookup.sa3_21code`              | Null if either code or name is null                     |
| `boundaries.sa3.name`                    | `sa3_21name`                   | `admin_bdys_202602.abs_2021_mb_lookup.sa3_21name`              |                                                         |
| `boundaries.sa4.code`                    | `sa4_21code`                   | `admin_bdys_202602.abs_2021_mb_lookup.sa4_21code`              | Null if either code or name is null                     |
| `boundaries.sa4.name`                    | `sa4_21name`                   | `admin_bdys_202602.abs_2021_mb_lookup.sa4_21name`              |                                                         |
| `boundaries.gccsa.code`                  | `gcc_21code`                   | `admin_bdys_202602.abs_2021_mb_lookup.gcc_21code`              | Null if either code or name is null                     |
| `boundaries.gccsa.name`                  | `gcc_21name`                   | `admin_bdys_202602.abs_2021_mb_lookup.gcc_21name`              |                                                         |

**Join path (admin):** `address_principals.gnaf_pid` → `address_principal_admin_boundaries.gnaf_pid`

**Join path (ABS):** `address_principals.mb_2021_code` → `abs_2021_mb_lookup.mb21_code`

---

## Field Provenance — `aliases[]` Array

| Output Field      | SQL Source                | Source Table.Column                           | Transform                         |
| ----------------- | ------------------------- | --------------------------------------------- | --------------------------------- |
| `aliases[].pid`   | `address_aliases[].pid`   | `gnaf_202602.address_aliases.gnaf_pid`        | Via CTE `address_alias_agg`       |
| `aliases[].label` | `address_aliases[].label` | `gnaf_202602.address_aliases.address`         | Composed label from alias address |
| `aliases[].type`  | `address_aliases[].type`  | `gnaf_202602.address_alias_lookup.alias_type` | e.g. `"SYNONYM"`                  |

**Join path:** `address_principals.gnaf_pid` → `address_alias_lookup.principal_pid` → `address_alias_lookup.alias_pid` → `address_aliases.gnaf_pid`

**Ordering:** `ORDER BY aa.gnaf_pid` (within `json_agg`).

---

## Field Provenance — `secondaries[]` Array

| Output Field          | SQL Source                    | Source Table.Column                       | Transform                             |
| --------------------- | ----------------------------- | ----------------------------------------- | ------------------------------------- |
| `secondaries[].pid`   | `address_secondaries[].pid`   | `gnaf_202602.address_principals.gnaf_pid` | Self-join via secondary lookup        |
| `secondaries[].label` | `address_secondaries[].label` | `gnaf_202602.address_principals.address`  | Composed label from secondary address |

**Join path:** `address_principals.gnaf_pid` (as primary) → `address_secondary_lookup.primary_pid` → `address_secondary_lookup.secondary_pid` → `address_principals.gnaf_pid` (self-join for secondary row)

**Ordering:** `ORDER BY ap2.gnaf_pid` (within `json_agg`).

---

## `addressLabelSearch` Composition

The search-optimised label is composed in `src/flatten.ts:composeSearchLabel()` from expanded SQL columns. It is NOT a SQL column — it is built in TypeScript.

**Component parts (in order):**

1. `flat_type_name` + `flat_number` (if both present; just `flat_number` if no type)
2. `level_type_name` + `level_number` (if both present; `"LEVEL"` + number if no type)
3. `number_first` + `-` + `number_last` (range) or just `number_first`
4. `"LOT"` + `lot_number` (only if no `number_first`)
5. `street_name` + `street_type_name` + `street_suffix_code` (space-joined, nulls filtered)
6. `locality_name` + `state` + `postcode` (space-joined, nulls filtered)

All parts joined with spaces. Types are the expanded authority names (e.g. `AVENUE` not `AV`).

---

## Data Licensing

All data sourced from data.gov.au under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).

- **G-NAF** (Geocoded National Address File) — Geoscape Australia (formerly PSMA)
- **Administrative Boundaries** — Geoscape Australia / ABS
