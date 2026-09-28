# Field Provenance — flat-white

> **Schema 1.0.0 change:** the six census fields now come from ASGS 2026.
> The `202602` suffix below belongs to the frozen address fixture; its census
> data is a synthetic overlay. Production schemas use the selected G-NAF quarter.
> See the [migration guide](MIGRATING-TO-ASGS-2026.md) and [fixture guide](../fixtures/README.md).

> Maps every output document field to its source G-NAF table, column, and transformation.
> Use this to trace any field from the NDJSON output back to its origin without database access.

---

## Table Inventory

All tables joined by `sql/address_full.sql` (the canonical flatten query) and its CTEs. `sql/address_full_main.sql` is auto-generated from this source — edit only `address_full.sql`. Row counts refer to the committed fixture after its overlays and preparation, not just the base seed. Source row counts can exceed the rows represented in output arrays.

| Schema              | Table                                | Alias in SQL | Fixture Rows | Role                                                                      |
| ------------------- | ------------------------------------ | ------------ | ------------ | ------------------------------------------------------------------------- |
| `gnaf_202602`       | `address_principals`                 | `ap`         | 451          | Driving table — one row per principal address                             |
| `gnaf_202602`       | `address_aliases`                    | `aa`         | 75           | Alternative address names (joined via lookup)                             |
| `gnaf_202602`       | `address_alias_lookup`               | `aal`        | 75           | Maps principal_pid → alias_pid + alias_type                               |
| `gnaf_202602`       | `address_secondary_lookup`           | `asl`        | 1,161        | Maps primary_pid → secondary_pid                                          |
| `gnaf_202602`       | `localities`                         | `loc`        | 267          | Locality (suburb) metadata                                                |
| `gnaf_202602`       | `locality_aliases`                   | `la`         | 500          | Alternative locality names                                                |
| `gnaf_202602`       | `locality_neighbour_lookup`          | `ln` (CTE)   | 1,709        | Adjacent locality pairs                                                   |
| `gnaf_202602`       | `streets`                            | `st`         | 405          | Street metadata                                                           |
| `gnaf_202602`       | `street_aliases`                     | `sa`         | 32           | Alternative street names                                                  |
| `gnaf_202602`       | `address_principal_admin_boundaries` | `ab`         | 451          | Spatially-joined admin boundaries per address                             |
| `raw_gnaf_202602`   | `address_detail`                     | `ad`         | 451          | Raw address detail (flat/level type codes, address_site_pid)              |
| `raw_gnaf_202602`   | `address_site`                       | `site`       | 451          | Site names (shopping centres, hospitals)                                  |
| `raw_gnaf_202602`   | `address_site_geocode`               | `asg`        | 828          | All geocode types per address site                                        |
| `raw_gnaf_202602`   | `flat_type_aut`                      | `ft`         | 54           | Code → name expansion (e.g. `UNIT` → `UNIT`)                              |
| `raw_gnaf_202602`   | `level_type_aut`                     | `lt`         | 16           | Code → name expansion (e.g. `L` → `LEVEL`)                                |
| `raw_gnaf_202602`   | `street_type_aut`                    | _unused_     | 276          | Not joined; processed street type is already expanded. See warning below. |
| `raw_gnaf_202602`   | `street_suffix_aut`                  | `ss_aut`     | 19           | Code → name expansion (e.g. `N` → `NORTH`)                                |
| `raw_gnaf_202602`   | `geocode_type_aut`                   | `gt`         | 30           | Code → name expansion (e.g. `FCS` → `FRONTAGE CENTRE SETBACK`)            |
| `raw_gnaf_202602`   | `locality_class_aut`                 | `lc_aut`     | 9            | Name-based join for locality class                                        |
| `raw_gnaf_202602`   | `street_class_aut`                   | `sc_aut`     | 2            | Name-based join for street class                                          |
| `admin_bdys_202602` | `abs_2026_mb`                        | `mb`         | 430          | Mesh block → SA1/SA2/SA3/SA4/GCCSA mapping                                |

**Street-type warning:** this authority table reverses the usual convention: `code` is the long form and `name` is the abbreviation. `ap.street_type` already contains the long form. Reintroducing an expansion join caused the v2026.04 regression (PR #67).

**Related but not referenced by `address_full.sql`:**

| Schema            | Table                     | Fixture Rows | Note                                                                                                                                |
| ----------------- | ------------------------- | ------------ | ----------------------------------------------------------------------------------------------------------------------------------- |
| `raw_gnaf_202602` | `address_default_geocode` | 451          | Contains default geocodes, but the flatten SQL sources geocodes from `address_site_geocode` via the `address_geocodes` CTE instead. |

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
  ├── (street_type_aut intentionally NOT joined — see table above)
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
  ├── LEFT JOIN abs_2026_mb (mb) ON mb.mb_code_26 = ap.mb_2026_code
  │
  ├── LEFT JOIN address_alias_agg (CTE) ON principal_pid = ap.gnaf_pid
  │     └── Uses: address_alias_lookup → address_aliases
  │
  └── LEFT JOIN address_secondary_agg (CTE) ON primary_pid = ap.gnaf_pid
        └── Uses: address_secondary_lookup → address_principals (self-join)
```

---

## Field Provenance — Top-Level Fields

The source column uses the short SQL aliases in the table inventory and join map above. For example, `ap` is the processed principal address and `mb` is the ASGS 2026 mesh-block lookup. `ap2` denotes a second principal-address row in the child-address self-join. Transformations happen in `src/flatten.ts` unless stated as SQL.

| Output Field         | SQL Alias               | Source Table.Column                  | Transform                                                                    |
| -------------------- | ----------------------- | ------------------------------------ | ---------------------------------------------------------------------------- |
| `_id`                | `_id`                   | `ap.gnaf_pid`                        | Direct                                                                       |
| `_version`           | —                       | Build parameter                      | Set from `FlattenOptions.version`                                            |
| `addressLabel`       | `address_label`         | `ap.address`                         | Direct                                                                       |
| `addressLabelSearch` | —                       | Composed in TypeScript               | See the [composition sequence](#addresslabelsearch-composition).             |
| `addressSiteName`    | `address_site_name`     | `site.address_site_name`             | Null-coalesce (`?? null`)                                                    |
| `buildingName`       | `building_name`         | `ap.building_name`                   | Null-coalesce                                                                |
| `flatType`           | `flat_type_name`        | `ft.name`                            | Joined via `ad.flat_type_code`; null-coalesce                                |
| `flatNumber`         | `flat_number_composed`  | `ad.flat_number` plus prefix/suffix  | Concatenate prefix, number and suffix; null when the number is absent.       |
| `levelType`          | `level_type_name`       | `lt.name`                            | Joined via `ad.level_type_code`; null-coalesce                               |
| `levelNumber`        | `level_number_composed` | `ad.level_number` plus prefix/suffix | Concatenate prefix, number and suffix; null when the number is absent.       |
| `numberFirst`        | `number_first`          | `ap.number_first`                    | Null-coalesce                                                                |
| `numberLast`         | `number_last`           | `ap.number_last`                     | Null-coalesce                                                                |
| `lotNumber`          | `lot_number`            | `ap.lot_number`                      | Null-coalesce                                                                |
| `streetName`         | `street_name`           | `ap.street_name`                     | Direct                                                                       |
| `streetType`         | `street_type_name`      | `ap.street_type`                     | Direct from `ap.street_type` (already contains full name)                    |
| `streetSuffix`       | `street_suffix_code`    | `ap.street_suffix`                   | Direct from `ap.street_suffix` (already contains full name); null-coalesce   |
| `localityName`       | `locality_name`         | `ap.locality_name`                   | Direct                                                                       |
| `state`              | `state`                 | `ap.state`                           | Direct                                                                       |
| `postcode`           | `postcode`              | `ap.postcode`                        | Null-coalesce                                                                |
| `legalParcelId`      | `legal_parcel_id`       | `ap.legal_parcel_id`                 | Null-coalesce                                                                |
| `confidence`         | `confidence`            | `ap.confidence`                      | `Number()` cast                                                              |
| `aliasPrincipal`     | —                       | Derived                              | Hardcoded `"PRINCIPAL"` — query only joins `address_principals`              |
| `primarySecondary`   | `primary_secondary`     | `ap.primary_secondary`               | `mapPrimarySecondary()`: `'P'`→`"PRIMARY"`, `'S'`→`"SECONDARY"`, else `null` |

---

## Field Provenance — `geocode` Object

Best geocode selected per address. Determined inside the `address_geocodes` CTE.

| Output Field          | SQL Alias                  | Source Table.Column    | Transform                                                               |
| --------------------- | -------------------------- | ---------------------- | ----------------------------------------------------------------------- |
| `geocode.latitude`    | `best_geocode.latitude`    | `asg.latitude`         | Parse a finite number; the whole geocode is null if missing or invalid. |
| `geocode.longitude`   | `best_geocode.longitude`   | `asg.longitude`        | Parse a finite number; the whole geocode is null if missing or invalid. |
| `geocode.type`        | `best_geocode.type`        | `gt.name`              | Authority name, falling back to the source type code when unmatched.    |
| `geocode.reliability` | `best_geocode.reliability` | `asg.reliability_code` | `Number()` cast; validation requires an integer from 1 to 6.            |

**Selection logic (SQL):** `ORDER BY reliability_code ASC, CASE geocode_type_code WHEN 'FCS' THEN 1 WHEN 'PC' THEN 2 WHEN 'PAP' THEN 3 ELSE 4 END ASC LIMIT 1`. Only non-retired geocodes (`date_retired IS NULL`).

**Join path:** `address_principals.gnaf_pid` → `address_detail.address_detail_pid` → `address_detail.address_site_pid` → `address_site_geocode.address_site_pid`

`src/flatten.ts` emits `geocode: null` when no best geocode exists or its coordinates are missing/non-finite. Coordinates are copied from the GDA2020 source without reprojection.

## Field Provenance — `location` Object

OpenSearch-ready geo point derived directly from the primary `geocode` object during document composition.

| Output field   | Derived from        | Transform |
| -------------- | ------------------- | --------- |
| `location.lat` | `geocode.latitude`  | copied    |
| `location.lon` | `geocode.longitude` | copied    |

`location` is `null` whenever `geocode` is `null` or the coordinates are non-finite.

---

## Field Provenance — `allGeocodes[]` Array

All geocode types for an address, aggregated in the `address_geocodes` CTE.

| Output Field                | SQL Source                   | Source Table.Column    | Transform                                                                      |
| --------------------------- | ---------------------------- | ---------------------- | ------------------------------------------------------------------------------ |
| `allGeocodes[].lat`         | `all_geocodes[].lat`         | `asg.latitude`         | `Number()` cast                                                                |
| `allGeocodes[].lng`         | `all_geocodes[].lng`         | `asg.longitude`        | `Number()` cast                                                                |
| `allGeocodes[].type`        | `all_geocodes[].type`        | `gt.name`              | Authority name, or the source type code if unmatched (same as `geocode.type`). |
| `allGeocodes[].reliability` | `all_geocodes[].reliability` | `asg.reliability_code` | `Number()` cast                                                                |

**Note:** Both `allGeocodes[].type` and `geocode.type` use the authority name when matched, otherwise the source code. Matched values use the expanded long form (e.g. `"FRONTAGE CENTRE SETBACK"`), joined from `geocode_type_aut.name`. This was made consistent in E1.16 — prior to v0.2.0, `allGeocodes[].type` used the raw abbreviation (e.g. `"FCS"`).

**Ordering:** `ORDER BY reliability_code, geocode_type_code` (within `json_agg`).

---

## Field Provenance — `locality` Object

| Output Field          | SQL Alias             | Source Table.Column                                           | Transform                                                                                               |
| --------------------- | --------------------- | ------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| `locality.pid`        | `locality_pid`        | `loc.locality_pid`                                            | Direct                                                                                                  |
| `locality.class`      | `locality_class_name` | `lc_aut.name`                                                 | Joined via `lc_aut.name = loc.locality_class`. Fallback: `"UNKNOWN"`                                    |
| `locality.neighbours` | `locality_neighbours` | `gnaf_202602.locality_neighbour_lookup` → `loc.locality_name` | CTE aggregates neighbour names via `json_agg(... ORDER BY locality_name)`. Empty `[]` if no neighbours. |
| `locality.aliases`    | `locality_aliases`    | `la.locality_alias_name`                                      | CTE aggregates via `json_agg(... ORDER BY locality_alias_name)`. Empty `[]` if no aliases.              |

**Join path for neighbours:** `address_principals.locality_pid` → `locality_neighbour_lookup.locality_pid` → `locality_neighbour_lookup.neighbour_locality_pid` → `localities.locality_name`

**Join path for aliases:** `address_principals.locality_pid` → `locality_aliases.locality_pid`

---

## Field Provenance — `street` Object

| Output Field     | SQL Alias             | Source Table.Column         | Transform                                                                                     |
| ---------------- | --------------------- | --------------------------- | --------------------------------------------------------------------------------------------- |
| `street.pid`     | `street_locality_pid` | `st.street_locality_pid`    | Direct                                                                                        |
| `street.class`   | `street_class_name`   | `sc_aut.name`               | Joined via `sc_aut.name = st.street_class`. Fallback: `"UNKNOWN"`                             |
| `street.aliases` | `street_aliases`      | `sa.full_alias_street_name` | CTE aggregates via `json_agg(... ORDER BY full_alias_street_name)`. Empty `[]` if no aliases. |

**Join path:** `address_principals.street_locality_pid` → `streets.street_locality_pid` → `street_aliases.street_locality_pid`

---

## Field Provenance — `boundaries` Object

Schema 1.x uses ASGS 2026. The `202602` schema suffix below identifies the frozen address fixture; its census data is an explicit synthetic 2026 overlay. Production uses the selected G-NAF quarter as its schema suffix.

All boundary fields sourced from two tables: the spatially-joined admin boundaries table and the ABS mesh block lookup.

| Output Field                             | SQL Alias                      | Source Table.Column | Transform                                               |
| ---------------------------------------- | ------------------------------ | ------------------- | ------------------------------------------------------- |
| `boundaries.lga.name`                    | `lga_name`                     | `ab.lga_name`       | Null if either name or code is null                     |
| `boundaries.lga.code`                    | `lga_pid`                      | `ab.lga_pid`        | Used as `code` in output                                |
| `boundaries.ward.name`                   | `ward_name`                    | `ab.ward_name`      | Null if null                                            |
| `boundaries.stateElectorate.name`        | `state_electorate_name`        | `ab.se_lower_name`  | SQL alias: `ab.se_lower_name AS state_electorate_name`  |
| `boundaries.commonwealthElectorate.name` | `commonwealth_electorate_name` | `ab.ce_name`        | SQL alias: `ab.ce_name AS commonwealth_electorate_name` |
| `boundaries.meshBlock.code`              | `mb_2026_code`                 | `ap.mb_2026_code`   | `String()` cast. Null if code or category is null.      |
| `boundaries.meshBlock.category`          | `mesh_block_category`          | `mb.mb_cat_26`      | SQL alias: `mb.mb_cat_26 AS mesh_block_category`        |
| `boundaries.sa1`                         | `s1_code_26`                   | `mb.s1_code_26`     | Null-coalesce                                           |
| `boundaries.sa2.code`                    | `s2_code_26`                   | `mb.s2_code_26`     | Null if either code or name is null                     |
| `boundaries.sa2.name`                    | `s2_name_26`                   | `mb.s2_name_26`     |                                                         |
| `boundaries.sa3.code`                    | `s3_code_26`                   | `mb.s3_code_26`     | Null if either code or name is null                     |
| `boundaries.sa3.name`                    | `s3_name_26`                   | `mb.s3_name_26`     |                                                         |
| `boundaries.sa4.code`                    | `s4_code_26`                   | `mb.s4_code_26`     | Null if either code or name is null                     |
| `boundaries.sa4.name`                    | `s4_name_26`                   | `mb.s4_name_26`     |                                                         |
| `boundaries.gccsa.code`                  | `gc_code_26`                   | `mb.gc_code_26`     | Null if either code or name is null                     |
| `boundaries.gccsa.name`                  | `gc_name_26`                   | `mb.gc_name_26`     |                                                         |

**Join path (admin):** `address_principals.gnaf_pid` → `address_principal_admin_boundaries.gnaf_pid`

**Join path (ABS):** `address_principals.mb_2026_code` → `abs_2026_mb.mb_code_26`

---

## Field Provenance — `aliases[]` Array

| Output Field      | SQL Source                | Source Table.Column | Transform                         |
| ----------------- | ------------------------- | ------------------- | --------------------------------- |
| `aliases[].pid`   | `address_aliases[].pid`   | `aa.gnaf_pid`       | Via CTE `address_alias_agg`       |
| `aliases[].label` | `address_aliases[].label` | `aa.address`        | Composed label from alias address |
| `aliases[].type`  | `address_aliases[].type`  | `aal.alias_type`    | e.g. `"SYNONYM"`                  |

**Join path:** `address_principals.gnaf_pid` → `address_alias_lookup.principal_pid` → `address_alias_lookup.alias_pid` → `address_aliases.gnaf_pid`

**Ordering:** `ORDER BY aa.gnaf_pid` (within `json_agg`).

---

## Field Provenance — `secondaries[]` Array

| Output Field          | SQL Source                    | Source Table.Column | Transform                             |
| --------------------- | ----------------------------- | ------------------- | ------------------------------------- |
| `secondaries[].pid`   | `address_secondaries[].pid`   | `ap2.gnaf_pid`      | Self-join via secondary lookup        |
| `secondaries[].label` | `address_secondaries[].label` | `ap2.address`       | Composed label from secondary address |

**Join path:** `address_principals.gnaf_pid` (as primary) → `address_secondary_lookup.primary_pid` → `address_secondary_lookup.secondary_pid` → `address_principals.gnaf_pid` (self-join for secondary row)

**Ordering:** `ORDER BY ap2.gnaf_pid` (within `json_agg`).

---

## `addressLabelSearch` Composition

The search-optimised label is composed in `src/flatten.ts:composeSearchLabel()` from expanded SQL columns. It is NOT a SQL column — it is built in TypeScript.

**Component parts (in order):**

1. `flat_type_name` + `flat_number_composed` (if both present; just the number if no type)
2. `level_type_name` + `level_number_composed` (if both present; `"LEVEL"` + number if no type)
3. `number_first` + `-` + `number_last` (range) or just `number_first`
4. `"LOT"` + `lot_number` (only if no `number_first`)
5. `street_name` + `street_type_name` + `street_suffix_code` (space-joined, nulls filtered)
6. `locality_name` + `state` + `postcode` (space-joined, nulls filtered)

All parts joined with spaces. Types are the expanded authority names (e.g. `AVENUE` not `AV`).

---

## Data Licensing

See [source attribution and licensing](../README.md#data-sources-and-attribution). Source-data terms are separate from the code licence.

- **G-NAF** (Geocoded National Address File) — Geoscape Australia (formerly PSMA)
- **Administrative Boundaries** — Geoscape Australia / ABS
