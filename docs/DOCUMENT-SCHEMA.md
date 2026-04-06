# Document Schema Reference — flat-white

> **Version:** 1.0.0 (pre-release draft)
> **Runtime validation:** `src/schema.ts` (Zod)
> **Breaking changes:** require a major version bump to the project.

Every line in the NDJSON output is one JSON document conforming to this schema. This document is the authoritative contract between flat-white and all downstream consumers.

---

## Top-Level Fields

| Field                | Type    | Nullable | Description                                                                               | Example                               | G-NAF Source                                                                |
| -------------------- | ------- | -------- | ----------------------------------------------------------------------------------------- | ------------------------------------- | --------------------------------------------------------------------------- |
| `_id`                | string  | No       | G-NAF address persistent identifier (PID)                                                 | `"GAVIC425181432"`                    | `gnaf.address_principals.address_detail_pid`                                |
| `_version`           | string  | No       | G-NAF data release version (YYYY.MM)                                                      | `"2026.02"`                           | Build parameter                                                             |
| `addressLabel`       | string  | No       | Canonical address label using G-NAF abbreviations                                         | `"1 MCNAB AV, FOOTSCRAY VIC 3011"`    | Composed from address components                                            |
| `addressLabelSearch` | string  | No       | Search-optimised label with expanded street/flat types                                    | `"1 MCNAB AVENUE FOOTSCRAY VIC 3011"` | Composed; street type expanded via authority codes                          |
| `addressSiteName`    | string  | Yes      | Site name (e.g. shopping centre, hospital)                                                | `"FOOTSCRAY MARKET"`                  | `gnaf.address_principals.address_site_name`                                 |
| `buildingName`       | string  | Yes      | Building name                                                                             | `"TOWER A"`                           | `gnaf.address_principals.building_name`                                     |
| `flatType`           | string  | Yes      | Flat/unit type abbreviation                                                               | `"UNIT"`                              | `gnaf.address_principals.flat_type`                                         |
| `flatNumber`         | string  | Yes      | Flat/unit number (without type prefix)                                                    | `"G1"`                                | `raw_gnaf.address_detail.flat_number` (composed from prefix+number+suffix)  |
| `levelType`          | string  | Yes      | Level type                                                                                | `"LEVEL"`                             | `gnaf.address_principals.level_type`                                        |
| `levelNumber`        | string  | Yes      | Level number (without type prefix)                                                        | `"1"`                                 | `raw_gnaf.address_detail.level_number` (composed from prefix+number+suffix) |
| `numberFirst`        | string  | Yes      | Street number (first/only)                                                                | `"1"`                                 | `gnaf.address_principals.number_first`                                      |
| `numberLast`         | string  | Yes      | Street number (last, for ranges like 1-5)                                                 | `"5"`                                 | `gnaf.address_principals.number_last`                                       |
| `lotNumber`          | string  | Yes      | Lot number (rural/unsubdivided land)                                                      | `"3"`                                 | `gnaf.address_principals.lot_number`                                        |
| `streetName`         | string  | No       | Street name                                                                               | `"MCNAB"`                             | `gnaf.address_principals.street_name`                                       |
| `streetType`         | string  | Yes      | Street type (full name)                                                                   | `"AVENUE"`                            | `gnaf.address_principals.street_type`                                       |
| `streetSuffix`       | string  | Yes      | Street suffix (N, S, E, W, etc.)                                                          | `"N"`                                 | `gnaf.address_principals.street_suffix`                                     |
| `localityName`       | string  | No       | Suburb/locality name                                                                      | `"FOOTSCRAY"`                         | `gnaf.address_principals.locality_name`                                     |
| `state`              | string  | No       | State/territory code                                                                      | `"VIC"`                               | `gnaf.address_principals.state`                                             |
| `postcode`           | string  | Yes      | Postcode                                                                                  | `"3011"`                              | `gnaf.address_principals.postcode`                                          |
| `legalParcelId`      | string  | Yes      | Legal parcel identifier                                                                   | `"1\\PS733924"`                       | `gnaf.address_principals.legal_parcel_id`                                   |
| `confidence`         | integer | No       | Address confidence level (0 = low, 2 = high)                                              | `2`                                   | `gnaf.address_principals.confidence`                                        |
| `aliasPrincipal`     | enum    | No       | `"PRINCIPAL"` or `"ALIAS"`                                                                | `"PRINCIPAL"`                         | Derived from source table (address_principals vs address_aliases)           |
| `primarySecondary`   | enum    | Yes      | `"PRIMARY"`, `"SECONDARY"`, or null                                                       | `"PRIMARY"`                           | `gnaf.address_principals.primary_secondary`                                 |
| `geocode`            | object  | Yes      | Best geocode for this address, or null if no geocode exists (see Geocode)                 | _(see below)_                         | `gnaf.address_site_geocodes` (highest reliability, preferring FCS)          |
| `allGeocodes`        | array   | No       | All geocode types for this address (see AllGeocodesItem)                                  | _(see below)_                         | `gnaf.address_site_geocodes` (all rows)                                     |
| `locality`           | object  | No       | Locality context with neighbours and aliases (see Locality)                               | _(see below)_                         | `gnaf.localities` + `gnaf.locality_neighbours` + `gnaf.locality_aliases`    |
| `street`             | object  | No       | Street metadata (see Street)                                                              | _(see below)_                         | `gnaf.streets` + `gnaf.street_aliases`                                      |
| `boundaries`         | object  | No       | Administrative and statistical boundaries (see Boundaries)                                | _(see below)_                         | `gnaf.address_principal_admin_boundaries` + ABS lookup tables               |
| `aliases`            | array   | No       | Alternative address names (see Alias). Empty array if none.                               | _(see below)_                         | `gnaf.address_aliases`                                                      |
| `secondaries`        | array   | No       | Child addresses (units/flats) for primary addresses (see Secondary). Empty array if none. | _(see below)_                         | `gnaf.address_principals` where `primary_secondary = 'SECONDARY'`           |

---

## Nested Object: Geocode

The best available geocode for this address, selected by highest reliability then type preference (FCS > PC > PAP).

| Field         | Type    | Nullable | Description                                             | Example                     | G-NAF Source                                                             |
| ------------- | ------- | -------- | ------------------------------------------------------- | --------------------------- | ------------------------------------------------------------------------ |
| `latitude`    | number  | No       | WGS84 latitude                                          | `-37.79815294`              | `gnaf.address_site_geocodes.latitude`                                    |
| `longitude`   | number  | No       | WGS84 longitude                                         | `144.89719303`              | `gnaf.address_site_geocodes.longitude`                                   |
| `type`        | string  | No       | Geocode type description                                | `"FRONTAGE CENTRE SETBACK"` | `gnaf.address_site_geocodes.geocode_type` (expanded from authority code) |
| `reliability` | integer | No       | Reliability level (1 = survey, 6 = region). Range: 1-6. | `2`                         | `gnaf.address_site_geocodes.reliability`                                 |

---

## Nested Object: AllGeocodesItem

One entry per geocode type available for this address. Every address has at least one.

| Field         | Type    | Nullable | Description               | Example        | G-NAF Source                              |
| ------------- | ------- | -------- | ------------------------- | -------------- | ----------------------------------------- |
| `lat`         | number  | No       | WGS84 latitude            | `-37.79815294` | `gnaf.address_site_geocodes.latitude`     |
| `lng`         | number  | No       | WGS84 longitude           | `144.89719303` | `gnaf.address_site_geocodes.longitude`    |
| `type`        | string  | No       | Geocode type abbreviation | `"FCS"`        | `gnaf.address_site_geocodes.geocode_type` |
| `reliability` | integer | No       | Reliability level (1-6)   | `2`            | `gnaf.address_site_geocodes.reliability`  |

---

## Nested Object: Locality

Locality (suburb) context including neighbouring localities and known aliases.

| Field        | Type     | Nullable | Description                                        | Example                        | G-NAF Source                                       |
| ------------ | -------- | -------- | -------------------------------------------------- | ------------------------------ | -------------------------------------------------- |
| `pid`        | string   | No       | Locality persistent identifier                     | `"loc67a11408d754"`            | `gnaf.localities.locality_pid`                     |
| `class`      | string   | No       | Locality classification                            | `"GAZETTED LOCALITY"`          | `gnaf.localities.locality_class_code` (expanded)   |
| `neighbours` | string[] | No       | Names of adjacent localities. Empty array if none. | `["ASCOT VALE", "FLEMINGTON"]` | `gnaf.locality_neighbours.neighbour_locality_name` |
| `aliases`    | string[] | No       | Alternative locality names. Empty array if none.   | `["FOOTSCRAY WEST"]`           | `gnaf.locality_aliases.alias_name`                 |

---

## Nested Object: Street

Street-level metadata and aliases.

| Field     | Type     | Nullable | Description                                    | Example        | G-NAF Source                                |
| --------- | -------- | -------- | ---------------------------------------------- | -------------- | ------------------------------------------- |
| `pid`     | string   | No       | Street persistent identifier                   | `"VIC2104831"` | `gnaf.streets.street_locality_pid`          |
| `class`   | string   | No       | Street confirmation status                     | `"CONFIRMED"`  | `gnaf.streets.street_class_code` (expanded) |
| `aliases` | string[] | No       | Alternative street names. Empty array if none. | `[]`           | `gnaf.street_aliases`                       |

---

## Nested Object: Boundaries

Administrative and ABS statistical area boundaries. All sub-fields are nullable — an address may lack boundary data if it falls outside mapped boundaries (e.g. some rural/remote areas).

| Field                    | Type   | Nullable | Description                                             | Example                                               | G-NAF Source                                                                                |
| ------------------------ | ------ | -------- | ------------------------------------------------------- | ----------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| `lga`                    | object | Yes      | Local Government Area: `{ name, code }`                 | `{ "name": "MARIBYRNONG", "code": "LGA24650" }`       | `admin_bdys.address_principal_admin_boundaries.lga_name`, `.lga_code`                       |
| `ward`                   | object | Yes      | Council ward: `{ name }`                                | `{ "name": "RIVER WARD" }`                            | `admin_bdys.address_principal_admin_boundaries.ward_name`                                   |
| `stateElectorate`        | object | Yes      | State electorate: `{ name }`                            | `{ "name": "FOOTSCRAY" }`                             | `admin_bdys.address_principal_admin_boundaries.state_electorate_name`                       |
| `commonwealthElectorate` | object | Yes      | Federal electorate: `{ name }`                          | `{ "name": "GELLIBRAND" }`                            | `admin_bdys.address_principal_admin_boundaries.commonwealth_electorate_name`                |
| `meshBlock`              | object | Yes      | ABS Mesh Block: `{ code, category }`                    | `{ "code": "20663890000", "category": "COMMERCIAL" }` | ABS 2021 mesh block lookup via `admin_bdys.address_principal_admin_boundaries.mb_2021_code` |
| `sa1`                    | string | Yes      | ABS Statistical Area Level 1 code                       | `"20604102614"`                                       | ABS 2021 lookup via mesh block                                                              |
| `sa2`                    | object | Yes      | ABS Statistical Area Level 2: `{ code, name }`          | `{ "code": "20604", "name": "FOOTSCRAY" }`            | ABS 2021 lookup via mesh block                                                              |
| `sa3`                    | object | Yes      | ABS Statistical Area Level 3: `{ code, name }`          | `{ "code": "206", "name": "MARIBYRNONG" }`            | ABS 2021 lookup via mesh block                                                              |
| `sa4`                    | object | Yes      | ABS Statistical Area Level 4: `{ code, name }`          | `{ "code": "2", "name": "MELBOURNE - WEST" }`         | ABS 2021 lookup via mesh block                                                              |
| `gccsa`                  | object | Yes      | Greater Capital City Statistical Area: `{ code, name }` | `{ "code": "2GMEL", "name": "GREATER MELBOURNE" }`    | ABS 2021 lookup via mesh block                                                              |

---

## Nested Object: Alias

An alternative name for this address. Present in the `aliases[]` array.

| Field   | Type   | Nullable | Description              | Example                                          | G-NAF Source                              |
| ------- | ------ | -------- | ------------------------ | ------------------------------------------------ | ----------------------------------------- |
| `pid`   | string | No       | Alias address PID        | `"MA13517230"`                                   | `gnaf.address_aliases.address_detail_pid` |
| `label` | string | No       | Full alias address label | `"SHOP 1 GROUND 1 MCNAB AV, FOOTSCRAY VIC 3011"` | Composed from alias address components    |
| `type`  | string | No       | Alias type               | `"SYNONYM"`                                      | `gnaf.address_aliases.alias_type`         |

---

## Nested Object: Secondary

A child address (unit/flat) belonging to a primary (building) address. Present in the `secondaries[]` array.

| Field   | Type   | Nullable | Description                  | Example                                   | G-NAF Source                                 |
| ------- | ------ | -------- | ---------------------------- | ----------------------------------------- | -------------------------------------------- |
| `pid`   | string | No       | Secondary address PID        | `"GAVIC425495838"`                        | `gnaf.address_principals.address_detail_pid` |
| `label` | string | No       | Full secondary address label | `"SHOP 1 1 MCNAB AV, FOOTSCRAY VIC 3011"` | Composed from address components             |

---

## Enums

### `aliasPrincipal`

| Value       | Description                                     |
| ----------- | ----------------------------------------------- |
| `PRINCIPAL` | This is the primary/canonical address record    |
| `ALIAS`     | This is an alternative name for another address |

### `primarySecondary`

| Value       | Description                             |
| ----------- | --------------------------------------- |
| `PRIMARY`   | This is a parent/building-level address |
| `SECONDARY` | This is a child/unit-level address      |
| `null`      | Relationship not classified             |

### `confidence`

| Value | Description       |
| ----- | ----------------- |
| `0`   | Low confidence    |
| `1`   | Medium confidence |
| `2`   | High confidence   |

### `geocode.reliability`

| Value | Description                     |
| ----- | ------------------------------- |
| `1`   | Surveyed (highest accuracy)     |
| `2`   | GNSS or within-address-site     |
| `3`   | Within locality                 |
| `4`   | Within neighbourhood            |
| `5`   | Within LGA                      |
| `6`   | Within region (lowest accuracy) |

---

---

## Locality-Only Document Schema

When running with `--locality-only`, flat-white produces a `localities.ndjson` file with one document per unique locality. This is a lightweight alternative to the full address dataset for use cases like suburb search, service area lookup, or locality-to-electorate mapping.

### Locality Document Fields

| Field          | Type     | Nullable | Description                                                    | Example                        | G-NAF Source                                    |
| -------------- | -------- | -------- | -------------------------------------------------------------- | ------------------------------ | ----------------------------------------------- |
| `_id`          | string   | No       | Locality persistent identifier                                 | `"loc67a11408d754"`            | `gnaf.localities.locality_pid`                  |
| `_version`     | string   | No       | G-NAF data release version (YYYY.MM)                           | `"2026.02"`                    | Build parameter                                 |
| `localityName` | string   | No       | Suburb/locality name                                           | `"FOOTSCRAY"`                  | `gnaf.localities.locality_name`                 |
| `state`        | string   | No       | State/territory code                                           | `"VIC"`                        | `gnaf.localities.state`                         |
| `postcode`     | string   | Yes      | Postcode                                                       | `"3011"`                       | `gnaf.localities.postcode`                      |
| `class`        | string   | No       | Locality classification                                        | `"GAZETTED LOCALITY"`          | `gnaf.localities.locality_class` (expanded)     |
| `neighbours`   | string[] | No       | Names of adjacent localities. Empty array if none.             | `["ASCOT VALE", "FLEMINGTON"]` | `gnaf.locality_neighbour_lookup` + `localities` |
| `aliases`      | string[] | No       | Alternative locality names. Empty array if none.               | `["FOOTSCRAY WEST"]`           | `gnaf.locality_aliases`                         |
| `latitude`     | number   | Yes      | WGS84 latitude of locality centroid, or null if not available  | `-37.7998`                     | `gnaf.localities.latitude`                      |
| `longitude`    | number   | Yes      | WGS84 longitude of locality centroid, or null if not available | `144.8991`                     | `gnaf.localities.longitude`                     |

---

## Output Formats

### NDJSON (default)

The default output format. One JSON document per line, conforming to the schema above. Produced by `--format ndjson` (or omitting `--format`).

### Parquet

Available via `--format parquet`. Produces an Apache Parquet file with the same data as the NDJSON output.

**Column mapping:**

- Scalar fields (`_id`, `addressLabel`, `state`, `confidence`, etc.) are stored as native Parquet types (`UTF8`, `INT32`).
- Nullable scalar fields use Parquet's optional repetition level.
- Complex fields (`geocode`, `allGeocodes`, `locality`, `street`, `boundaries`, `aliases`, `secondaries`) are serialized as **JSON strings** (UTF8 columns) for maximum compatibility across Parquet readers.

**Reading complex fields from Parquet:**

```python
import pandas as pd
import json

df = pd.read_parquet("flat-white-2026.02.parquet")
# Scalar fields work directly
print(df["state"].value_counts())

# Complex fields need JSON parsing
df["geocode_parsed"] = df["geocode"].apply(lambda x: json.loads(x) if x else None)
```

```sql
-- DuckDB
SELECT _id, state, json_extract(geocode, '$.latitude') as lat
FROM 'flat-white-2026.02.parquet';
```

### Geoparquet

Available via `--format geoparquet`. Produces a [Geoparquet v1.1.0](https://geoparquet.org/releases/v1.1.0/) file — a standard Parquet file with an additional `geometry` column containing WKB-encoded POINT geometries and spec-compliant file-level metadata.

**What's different from standard Parquet:**

- Adds a `geometry` column (BYTE_ARRAY) with WKB-encoded POINT for each address geocode.
- Addresses without a geocode have a null geometry.
- File-level `"geo"` metadata declares WGS 84 (EPSG:4326) CRS, encoding, geometry types, and bounding box.
- All other columns remain identical to the standard Parquet format.

**Reading Geoparquet:**

```python
import geopandas as gpd

gdf = gpd.read_parquet("flat-white-2026.02.geoparquet")
# geometry column is automatically parsed as shapely Points
print(gdf.geometry.head())
# Spatial queries work natively
melbourne = gdf.cx[144.9:145.0, -37.9:-37.7]
```

```sql
-- DuckDB with spatial extension
INSTALL spatial; LOAD spatial;
SELECT _id, state, ST_AsText(geometry) as wkt
FROM 'flat-white-2026.02.geoparquet'
WHERE ST_Within(geometry, ST_GeomFromText('POLYGON((144 -38, 145 -38, 145 -37, 144 -37, 144 -38))'));
```

```
# QGIS: Open directly as a vector layer via drag-and-drop or Layer → Add Layer → Add Vector Layer
```

---

## Data Licensing

All data sourced from data.gov.au under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Source datasets:

- **G-NAF** (Geocoded National Address File) — PSMA Australia
- **Administrative Boundaries** — PSMA Australia / ABS
