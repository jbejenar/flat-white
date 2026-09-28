# Migrating to schema 1.0.0 and ASGS 2026

Schema **1.0.0** changes the meaning of `boundaries.meshBlock`, `sa1`, `sa2`,
`sa3`, `sa4`, and `gccsa` from ABS ASGS 2021 to **ASGS 2026 (Edition 4)**.
Their JSON names and types remain the same. This is a breaking semantic change:
successful JSON validation alone does not establish compatibility with 2021 data.

The migration uses gnaf-loader release `202608`, commit
`7169957879fb3fd66e730c2d04d31adac5aaef5c`, without modifying upstream source.
The current Geoscape Administrative Boundaries archive supplies 2026 census
geography. Flatten now joins `address_principals.mb_2026_code` to
`admin_bdys.abs_2026_mb.mb_code_26`; it never substitutes the 2021 hierarchy.

## Consumer implications

| Area                          | Required action or consequence                                                                                                                                                                                                                                                                                           |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Version detection             | Check release `metadata.json`: `schemaVersion: "1.0.0"`, `asgsYear: 2026`. S3 manifests also carry `schema_version` / `asgs_year`; OpenSearch mapping `_meta` carries `schemaVersion` / `asgsYear`. Store the vintage with imported documents. `_version` remains the G-NAF quarter; release tags remain `vYYYY.MM[.N]`. |
| Search indexes and warehouses | Build a new complete index or partition, validate it, then switch consumers together. Recompute derived regional aggregates, filters, lookup tables and cached results. Mixing old and new geography under the same fields gives misleading results.                                                                     |
| Geographic joins              | Use 2026 boundary/reference datasets. A code that looks unchanged does not prove equivalent geometry or membership. Joining directly to 2021 Census geography is not a valid migration strategy.                                                                                                                         |
| Historical analysis           | Changes in regional counts can reflect boundary reassignment as well as address additions/deletions. Preserve the geography vintage in time series. Use a suitable correspondence or recode original coordinates for comparisons across editions.                                                                        |
| Scope of the contract change  | The six census fields change vintage. Address IDs, coordinates, labels, postcode and the four administrative-boundary field definitions do not change because of this migration. A new quarterly source can independently change their values.                                                                           |
| Older releases                | Previously published files retain their original 2021 meaning. They are not rewritten. Rebuilding pre-August 2026 inputs requires the original code/schema and suitable archived source files.                                                                                                                           |
| Operations                    | Old database dumps are invalidated (`v3-asgs2026` cache namespace). The first production run performs fresh loads; allow for that cost and duration. Missing 2026 tables/columns or wholly unmatched mesh-block codes fail validation.                                                                                   |
| Rollback                      | Keep the previous complete dataset/index and its metadata. Roll back the dataset and consuming queries together; do not relabel 2026 output as schema 0.x or restore old database dumps into schema 1.x.                                                                                                                 |

The S3 `manifest_version: 2` describes the transport envelope; it is independent
of the NDJSON `schema_version: "1.0.0"`. Older manifests may omit the new markers
and must not be inferred to contain the current geography.

ABS provides [2021-to-2026 correspondences](https://www.abs.gov.au/statistics/standards/australian-statistical-geography-standard-asgs/edition-4-july-2026-june-2031/access-and-downloads/correspondences)
for mesh blocks, SA1–SA4 and GCCSA. These include conversion weights and quality
indicators; they are not a universal one-to-one code rename. This migration
changes geographic classifications, not the vintage of demographic statistics.

## Upgrade procedure

1. Retain the previous release and record its schema/geography vintage.
2. Make the importer require the expected `schemaVersion` and `asgsYear` before
   ingesting schema 1.x (or the equivalent S3 manifest fields). Metadata alone does
   not block a consumer that ignores it. Consumers needing ASGS 2021 must remain on a compatible
   release until they explicitly migrate or implement their own conversion.
3. Load a complete schema 1.x release into a separate index/partition with 2026
   reference data. Review counts, census-field completeness and key regional
   aggregations against expectations for the new geography.
4. Rebuild derived results and switch the dataset and consumers together. Keep
   the previous version available for rollback and historical comparisons.

## Build repair and validation

The [15 August 2026 run](https://github.com/jbejenar/flat-white/actions/runs/31859191778)
failed in all nine states at Administrative Boundaries extraction validation.
The downloader only recognised `LocalGovernmentAreas_*`; current archives use
`LOCAL-GOVERNMENT-AREAS_*`. The repair supports both layouts, requires actual
directories, and promotes an extraction only after all required paths validate.
Permanent archive/schema failures no longer trigger network retries; transport
failures, HTTP 429 and HTTP 5xx remain retryable.

That run also selected the already released May quarter. August's current CKAN
resources were published on 17 August, after the former fixed-date trigger.
The workflow now checks weekly and skips an existing published or draft release.
A draft or failed publication requires an explicit manual retry. Manual dispatch
still supports retries and patch releases.

Use `gh workflow run quarterly-build.yml -f preflight_only=true` to check live
discovery and version eligibility without loading data or publishing artifacts.
Production workflow inputs must be August 2026 or newer. Manual URLs remain
subject to the actual post-load schema validation.

Development uses the frozen 451-address February fixture with an explicitly
synthetic 2026 overlay. The fixture executes the pinned upstream census prep SQL,
retains the old 2021 values as regression decoys, and verifies identical legacy
and materialized flatten output. All non-census document fields remain identical
to the previous baseline. These tests establish pipeline compatibility; they do
not measure nationwide address reassignment, coverage or full-build performance.
