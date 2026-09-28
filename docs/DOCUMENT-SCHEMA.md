# Document schema

**Contract version: 1.0.0 · Census geography: ASGS 2026**

> **Schema 1.0.0 change:** `boundaries.meshBlock`, `sa1`, `sa2`, `sa3`, `sa4`
> and `gccsa` now refer to ASGS 2026. Their names, types and nullability are
> unchanged. This is a breaking change in meaning. Follow the
> [migration guide](MIGRATING-TO-ASGS-2026.md) before replacing schema 0.x data.

Each NDJSON line contains one principal address. The runtime contract is
[`src/schema.ts`](../src/schema.ts); [field provenance](FIELD-PROVENANCE.md)
explains how values are derived. The
[committed sample](../fixtures/expected-output-sample.json) shows a complete document
from the frozen address fixture with **synthetic** 2026 census assignments.

## Reading this contract

All properties listed below are required. **Nullable** means that the property
is present with the value `null` when unavailable; it does not mean the property
can be omitted. Arrays can be empty and are never `null`. A nullable boundary
object is either a complete object with the stated string fields, or `null`.

Codes, postcodes and address numbers are strings. Preserve leading zeros and
letter suffixes. The Zod schema checks structure and types, including the numeric
ranges and enums below. It does not validate every string against a geographic
code list. The verifier adds data-quality checks; external reference joins still
need the correct geography edition.

## Top-level fields

| Field                | Type    | Nullable | Meaning                                                                                         |
| -------------------- | ------- | -------- | ----------------------------------------------------------------------------------------------- |
| `_id`                | string  | No       | G-NAF persistent address identifier.                                                            |
| `_version`           | string  | No       | G-NAF data quarter, conventionally `YYYY.MM`; never the schema version or release patch number. |
| `addressLabel`       | string  | No       | Composed address label from the loader.                                                         |
| `addressLabelSearch` | string  | No       | Search label composed from expanded address components.                                         |
| `addressSiteName`    | string  | Yes      | Name of the address site.                                                                       |
| `buildingName`       | string  | Yes      | Building name.                                                                                  |
| `flatType`           | string  | Yes      | Expanded flat or unit type.                                                                     |
| `flatNumber`         | string  | Yes      | Flat number, including prefix or suffix where supplied.                                         |
| `levelType`          | string  | Yes      | Expanded level type.                                                                            |
| `levelNumber`        | string  | Yes      | Level number, including prefix or suffix where supplied.                                        |
| `numberFirst`        | string  | Yes      | Street number, or start of a number range.                                                      |
| `numberLast`         | string  | Yes      | End of a street-number range.                                                                   |
| `lotNumber`          | string  | Yes      | Lot number.                                                                                     |
| `streetName`         | string  | No       | Street name.                                                                                    |
| `streetType`         | string  | Yes      | Expanded street type, such as `AVENUE`.                                                         |
| `streetSuffix`       | string  | Yes      | Street suffix from the processed address.                                                       |
| `localityName`       | string  | No       | Locality or suburb name.                                                                        |
| `state`              | string  | No       | State or territory abbreviation.                                                                |
| `postcode`           | string  | Yes      | Postcode.                                                                                       |
| `legalParcelId`      | string  | Yes      | Legal parcel identifier.                                                                        |
| `confidence`         | integer | No       | Source confidence value, from 0 to 2.                                                           |
| `aliasPrincipal`     | enum    | No       | `PRINCIPAL` or `ALIAS`; the current address export emits `PRINCIPAL`.                           |
| `primarySecondary`   | enum    | Yes      | `PRIMARY` for a parent address, `SECONDARY` for a child, or `null` if unclassified.             |
| `geocode`            | object  | Yes      | Selected geocode; see below.                                                                    |
| `location`           | object  | Yes      | Selected geocode as `{ lat, lon }`.                                                             |
| `allGeocodes`        | array   | No       | Available non-retired site geocodes; can be empty.                                              |
| `locality`           | object  | No       | Locality identity, class, neighbours and aliases.                                               |
| `street`             | object  | No       | Street identity, class and aliases.                                                             |
| `boundaries`         | object  | No       | Ten nullable administrative and census fields.                                                  |
| `aliases`            | array   | No       | Alternative address records.                                                                    |
| `secondaries`        | array   | No       | Child addresses linked to this principal address.                                               |

## Geocode and location

`geocode` contains the best available non-retired site geocode. Selection prefers
the lowest reliability number, then `FCS`, `PC`, `PAP`, then other types. If the
selected geocode is missing or its coordinates cannot be read as finite numbers,
`geocode` and `location` are both `null`. No zero-coordinate placeholder is added.

| Field within `geocode` | Type    | Meaning                                                                          |
| ---------------------- | ------- | -------------------------------------------------------------------------------- |
| `latitude`             | number  | Source latitude in decimal degrees.                                              |
| `longitude`            | number  | Source longitude in decimal degrees.                                             |
| `type`                 | string  | Expanded geocode type; the source code is retained if no authority name matches. |
| `reliability`          | integer | Source accuracy category, 1–6.                                                   |

`location.lat` copies `geocode.latitude`; `location.lon` copies
`geocode.longitude`. Its shape is suitable for an OpenSearch `geo_point` mapping.

Each `allGeocodes` item has `lat` and `lng` (numbers), `type` (string), and
`reliability` (integer, 1–6). Notice the different longitude key: **`lng`** here,
**`lon`** in `location`, and **`longitude`** in `geocode`. Items are ordered by
reliability, then source geocode type code. This array can be empty.

The source accuracy categories are:

| Value | Meaning                                                 |
| ----- | ------------------------------------------------------- |
| 1     | Surveying standard.                                     |
| 2     | Within the address site boundary or at an access point. |
| 3     | Near, or possibly within, the address site boundary.    |
| 4     | Associated with a unique road feature.                  |
| 5     | Associated with a unique locality or neighbourhood.     |
| 6     | Associated with a unique region.                        |

**Coordinate reference:** builds use GDA2020 source data. Flattening copies the
source coordinate numbers; it does not reproject them. The ASGS migration changes
census area assignments, not the coordinate datum. See the GeoParquet limitation
under [output formats](#output-formats) if your use case needs precise CRS handling.

## Locality

All four fields in `locality` are non-null:

| Field        | Type     | Meaning                                         |
| ------------ | -------- | ----------------------------------------------- |
| `pid`        | string   | G-NAF locality identifier.                      |
| `class`      | string   | Expanded locality classification, or `UNKNOWN`. |
| `neighbours` | string[] | Adjacent locality names, sorted by name.        |
| `aliases`    | string[] | Alternative locality names, sorted by name.     |

## Street

All three fields in `street` are non-null:

| Field     | Type     | Meaning                                        |
| --------- | -------- | ---------------------------------------------- |
| `pid`     | string   | G-NAF street-locality identifier.              |
| `class`   | string   | Expanded street classification, or `UNKNOWN`.  |
| `aliases` | string[] | Alternative full street names, sorted by name. |

## Boundaries

The `boundaries` object always contains all ten fields. **Every field in this
table is nullable.** State-specific boundary availability and unmatched addresses
can produce nulls. A missing assignment is different from an incompatible source
dataset, which fails the build's input validation.

| Field                    | Shape when present                   | Meaning and source                                                                                     |
| ------------------------ | ------------------------------------ | ------------------------------------------------------------------------------------------------------ |
| `lga`                    | `{ name: string, code: string }`     | Council area, assigned by spatial join. `code` is the Geoscape LGA identifier, not an ABS census code. |
| `ward`                   | `{ name: string }`                   | Local government ward, assigned by spatial join.                                                       |
| `stateElectorate`        | `{ name: string }`                   | State lower-house electorate, assigned by spatial join.                                                |
| `commonwealthElectorate` | `{ name: string }`                   | Federal electorate, assigned by spatial join.                                                          |
| `meshBlock`              | `{ code: string, category: string }` | **Changed in 1.0.0:** ASGS 2026 mesh block and category.                                               |
| `sa1`                    | string                               | **Changed in 1.0.0:** ASGS 2026 Statistical Area Level 1 code.                                         |
| `sa2`                    | `{ name: string, code: string }`     | **Changed in 1.0.0:** ASGS 2026 Statistical Area Level 2.                                              |
| `sa3`                    | `{ name: string, code: string }`     | **Changed in 1.0.0:** ASGS 2026 Statistical Area Level 3.                                              |
| `sa4`                    | `{ name: string, code: string }`     | **Changed in 1.0.0:** ASGS 2026 Statistical Area Level 4.                                              |
| `gccsa`                  | `{ name: string, code: string }`     | **Changed in 1.0.0:** ASGS 2026 Greater Capital City Statistical Area.                                 |

Census enrichment follows `address_principals.mb_2026_code` to
`abs_2026_mb.mb_code_26`. It does not fall back to the 2021 lookup. These fields
contain geography, not population or other Census statistics.

See [boundary processing](BOUNDARIES.md) for the current pipeline and
[migration implications](MIGRATING-TO-ASGS-2026.md) for joins and historical analysis.

## Aliases and secondaries

Each `aliases` item contains three required strings: `pid` (alias address ID),
`label` (address label), and `type` (alias relationship type). The array is sorted
by alias PID.

Each `secondaries` item contains two required strings: `pid` (child address ID)
and `label` (address label). The array is sorted by secondary PID. Both arrays
are empty when there are no corresponding joined records.

## Locality-only document schema

The separate [`flattenLocalities`](../src/flatten-localities.ts) module produces
one document per locality. Its shape is unchanged in 1.0.0 and contains **no census
boundaries or electoral assignments**. The Docker entrypoint does not expose a
`--locality-only` flag; call the module from code when using this export.

| Field          | Type     | Nullable | Meaning                                         |
| -------------- | -------- | -------- | ----------------------------------------------- |
| `_id`          | string   | No       | G-NAF locality identifier.                      |
| `_version`     | string   | No       | G-NAF data quarter.                             |
| `localityName` | string   | No       | Locality name.                                  |
| `state`        | string   | No       | State or territory abbreviation.                |
| `postcode`     | string   | Yes      | Locality postcode.                              |
| `class`        | string   | No       | Expanded locality classification, or `UNKNOWN`. |
| `neighbours`   | string[] | No       | Adjacent locality names.                        |
| `aliases`      | string[] | No       | Alternative locality names.                     |
| `latitude`     | number   | Yes      | Source locality latitude.                       |
| `longitude`    | number   | Yes      | Source locality longitude.                      |

## Version metadata

A document's `_version` identifies the G-NAF quarter. It does not identify the
schema, ASGS year, administrative source quarter or release patch. Keep the
release metadata with downloaded files.

| Surface                        | Contract fields                                                                                                                 |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------- |
| GitHub release `metadata.json` | `schemaVersion`, `asgsYear`; also `version`, `gnafVersion`, `adminBoundariesVersion`, `buildTimestamp`, `states`, `totalCount`. |
| S3 `manifest.json`             | `schema_version`, `asgs_year`; `manifest_version: 2` describes the manifest envelope.                                           |
| OpenSearch mapping `_meta`     | `schemaVersion`, `asgsYear`.                                                                                                    |

The local [`BuildMetadata`](../src/metadata.ts) helper is a separate shape: it
emits `version`, `schemaVersion`, `asgsYear`, `buildTimestamp`, `gnafLoaderVersion`,
`states`, `totalCount` and `outputFiles`. Do not assume it contains every field
that the GitHub release workflow adds.

See [version examples and compatibility checks](MIGRATING-TO-ASGS-2026.md#know-which-version-you-are-checking).
Missing geography metadata in an older artifact is not evidence of ASGS 2026.

## Output formats

**NDJSON** is the default and the published quarterly format. Each UTF-8 line
contains one JSON document. State files are gzip-compressed for distribution.
The [README](../README.md#verify-your-download) explains integrity and schema checks.

**Parquet** conversion is available through [`convertToParquet`](../src/parquet.ts).
Scalar fields use native columns. Nested objects and arrays, including
`boundaries`, are JSON strings; decode them before querying nested fields. Nullable
objects use Parquet nulls. These representations retain the same ASGS 2026 meanings.

**GeoParquet** conversion is available through
[`convertToGeoparquet`](../src/geoparquet.ts), with the same columns plus a WKB Point
geometry when a geocode exists. **Existing limitation:** the converter declares
WGS 84 metadata but copies the source coordinate numbers without a datum
transformation. Do not treat that declaration as proof that GDA2020 coordinates
were reprojected. This is separate from the ASGS migration and is tracked in
[current work](../NEXT-WORK.md).

The Docker entrypoint and quarterly workflow publish NDJSON; a `--format` option
in the TypeScript argument parser does not make it a supported Docker flag.

## Attribution

See [source data and attribution](../README.md#data-sources-and-attribution).
The code licence does not replace the source data's licensing terms.
