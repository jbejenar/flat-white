# Migrate to ASGS 2026

**Schema 1.0.0 change:** six census boundary fields now describe ASGS 2026 areas.
Their JSON names and types have not changed. An importer can still parse the
files and silently join them to the wrong geography. Check the metadata before
loading a release.

This guide covers the move from schema 0.x (ASGS 2021) to schema 1.0.0
(ASGS Edition 4, 2026). It describes the new code contract; it does **not** mean
that a data release has already been published. Check the `metadata.json`
attached to the release you intend to use. Older published files keep their
original schema and geography.

[README](../README.md) · [Document schema](DOCUMENT-SCHEMA.md) · [Release procedure](RELEASING.md)

## Do I need to change anything?

| How you use flat-white                             | What to do                                                                                                                  |
| -------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| Display or search address text                     | Keep your existing field mappings. Check metadata and run your normal import checks.                                        |
| Filter by mesh block, SA1–SA4 or GCCSA             | Rebuild the index and check saved filters against ASGS 2026.                                                                |
| Join addresses to ABS statistics or boundary files | Use matching 2026 geography, or a suitable correspondence between editions.                                                 |
| Compare area totals over time                      | Record the geography year alongside each result. Review boundary changes before treating a difference as growth or decline. |
| Run the build yourself                             | Use compatible source data and the pinned loader. Expect a fresh database load because old caches are incompatible.         |

This adds **geographic assignments**, not Census population, income or other
statistical results. A change in a region's code, name or extent can change a
report even when the underlying addresses have not changed.

## What changed?

| Contract                    | Schema 0.x                                                           | Schema 1.0.0                                                          |
| --------------------------- | -------------------------------------------------------------------- | --------------------------------------------------------------------- |
| Census geography            | ASGS 2021                                                            | ASGS 2026                                                             |
| Affected fields             | `meshBlock`, `sa1`, `sa2`, `sa3`, `sa4`, `gccsa` inside `boundaries` | Same fields and JSON shapes; 2026 meanings and values                 |
| Loader join                 | `mb_2021_code` → `abs_2021_mb`                                       | `mb_2026_code` → `abs_2026_mb.mb_code_26`                             |
| Missing census input        | Older build behaviour                                                | Incompatible or missing 2026 input fails validation; no 2021 fallback |
| Production workflow sources | Older quarters                                                       | G-NAF and Admin Boundaries August 2026 or newer                       |
| Database cache              | Previous cache namespace                                             | `v3-asgs2026`; incompatible restored dumps are rejected               |

Address IDs, labels, components, geocodes, aliases and secondary relationships
retain their schema. LGA, ward and electoral fields retain their derivation from
administrative boundary polygons. The locality-only document shape is unchanged
and has no census boundary fields. These guarantees concern the migration;
normal quarterly source updates can still change address and administrative data.

Keep all area codes as **strings**. A code that exists in both editions is not
proof that its region is unchanged. Do not convert a 2021 record to 2026 by
changing a year label or copying its old codes.

## Know which version you are checking

There are several version numbers because they answer different questions:

| Value                                        | Meaning                                          | Illustrative value         |
| -------------------------------------------- | ------------------------------------------------ | -------------------------- |
| Release tag / metadata `version`             | Which flat-white download or patch is this?      | `v2026.08.1` / `2026.08.1` |
| Metadata `gnafVersion` / document `_version` | Which G-NAF address quarter was loaded?          | `2026.08`                  |
| Metadata `adminBoundariesVersion`            | Which administrative boundary source was loaded? | `2026.08`                  |
| Metadata `schemaVersion`                     | Which document contract applies?                 | `1.0.0`                    |
| Metadata `asgsYear`                          | Which census geography edition applies?          | `2026`                     |

The example is illustrative, not a claim that `v2026.08.1` exists. A patch release
changes the release version; each document's `_version` stays at the G-NAF quarter.
The two source quarters can differ when upstream publishes them at different times.
Manual URL overrides record `adminBoundariesVersion: "manual"`; retain their exact
URLs and verify the loaded schema rather than inferring a quarter from that value.

The same contract is identified differently by each distribution format:

| Where                                            | Fields to check                              |
| ------------------------------------------------ | -------------------------------------------- |
| GitHub release `metadata.json`                   | `schemaVersion: "1.0.0"`, `asgsYear: 2026`   |
| S3 manifest (`manifests/address-{version}.json`) | `schema_version: "1.0.0"`, `asgs_year: 2026` |
| OpenSearch mapping `_meta`                       | `schemaVersion: "1.0.0"`, `asgsYear: 2026`   |

S3 `manifest_version` remains **2**. That is the manifest format, not the address
schema. Historical manifests may lack both geography fields; absence must not be
interpreted as ASGS 2026. The manifest reader accepts legacy files without adding
new geography labels to them. OpenSearch `_meta` records the contract but does not
validate the geography of documents you import.

A release metadata excerpt looks like this:

```json
{
  "version": "2026.08.1",
  "gnafVersion": "2026.08",
  "adminBoundariesVersion": "2026.08",
  "schemaVersion": "1.0.0",
  "asgsYear": 2026
}
```

## Upgrade in six steps

### 1. Save the version you run today

Record the release tag, metadata, source files and reference datasets. Keep the
old index or tables available until the new import passes your checks. Inventory
uses of all six affected fields, including saved searches, dashboards, joins,
exports, caches and scheduled reports.

### 2. Choose and check one release

Download metadata first. Use the same explicit tag for metadata and data; do not
resolve `latest` separately for each download. The [README quick start](../README.md#quick-start)
shows this sequence.

For a consumer that supports exactly schema 1.0.0 and ASGS 2026, this check rejects
older releases, missing values and unreviewed future schema versions:

```bash
jq -e '.schemaVersion == "1.0.0" and .asgsYear == 2026' metadata.json
```

This is a **metadata compatibility check**, not document validation. Check gzip
integrity and counts, then validate documents against the matching schema as
shown in the [download checks](../README.md#verify-your-download).

### 3. Update geographic references

Use ASGS 2026 codes, names and boundary files for new joins. Test join success and
unmatched codes explicitly; a successful SQL statement is not evidence of a
correct match. Keep missing assignments as `null` rather than filling them with
2021 values.

For comparisons with 2021 statistics, choose a method appropriate to the measure.
ABS publishes [2021-to-2026 correspondences](https://www.abs.gov.au/statistics/standards/australian-statistical-geography-standard-asgs/edition-4-july-2026-june-2031/access-and-downloads/correspondences)
with conversion ratios and quality indicators. These can split contributions
between regions; they are not simple code-renaming tables. Check the weights,
quality flags and unmatched regions before using converted totals.

### 4. Build a separate import

Create new tables or an index, then import the complete selected release. Rebuild
geographic aggregates and caches from that import. Keeping the same OpenSearch
field mapping does not update existing documents or saved area filters. Use the
[current mapping](../opensearch/address-mappings.json) and retain the release
metadata alongside your import.

Do not combine state files from different releases or geography editions into one
unlabelled dataset. If you need both editions for historical work, keep them
separate or carry the edition explicitly with every derived result.

### 5. Check before switching readers

Compare the imported state counts with release metadata. Validate documents and
check representative addresses, geographic join rates, null rates, saved filters
and key reports. Investigate changed area totals with both the source quarter and
boundary edition in view. Expected geography changes are not a reason to ignore
unexplained missing addresses or broken joins.

Switch application readers only after these checks pass. Keep a record of the
release tag, schema version, ASGS year and reference data used.

### 6. Keep rollback complete

If checks fail after cutover, switch back to the previous data **and** its matching
index, geographic references and derived results. Rolling back only the files
can leave queries using the wrong edition. Keep older release assets intact;
corrections should receive a new release version.

## If you operate the build

Schema 1.0.0 pins the unmodified gnaf-loader `202608` release. The quarterly
workflow, Docker entrypoint and local build require a production quarter in
`YYYY.MM` format, August 2026 or newer (months `02`, `05`, `08` or `11`).
Invalid or older quarters fail before a build starts, including cached builds.
Manual URL overrides
still have to pass the loaded 2026 schema checks; a URL or folder name alone is
not proof of compatibility.

Loads and restored caches must match at least 99% of each state's addresses to a
complete 2026 census hierarchy. Both output verification paths apply a 99% default
minimum to every census level, separately for each state. Individual missing
assignments remain `null`; the checks reject widespread loss without filling
gaps with old geography. See [the coverage policy](BOUNDARIES.md#coverage-and-verification).

The first build uses a new database cache namespace. Plan for a full source load
and measure its duration, memory and disk use. April 2026 performance reports in
this repository describe older data and are not ASGS 2026 capacity guarantees.
Postgres remains temporary build infrastructure; there is no persistent database
to migrate in place.

Use [the release guide](RELEASING.md) for metadata-only preflight and production
release steps, and [the runbook](RUNBOOK.md) if extraction or cache validation fails.

## If you contribute code

Run `./scripts/build-fixture-only.sh`; do not download the national dataset for
migration testing. The fixture keeps its **February 2026 address snapshot** and
`_version: "2026.02"`. A separate, deliberately synthetic census overlay exercises
ASGS 2026 column names and the pinned upstream mesh-block preparation SQL.

The old 2021 tables remain as regression decoys. Two explicit migration cases
ensure an incorrect 2021 join fails: one changes the mesh-block code and hierarchy,
and one keeps the code but changes the hierarchy. Other historical values are
reused only as synthetic fixture data. None of these assignments establish real
ASGS 2026 geography. All 451 documents still undergo complete byte-for-byte checks.
See the [fixture guide](../fixtures/README.md).

## Where the documentation changed

Each affected current guide has a **Schema 1.0.0 change** notice. Start with:

- [Document schema](DOCUMENT-SCHEMA.md): field meanings, nulls and version metadata.
- [Field provenance](FIELD-PROVENANCE.md) and [boundaries](BOUNDARIES.md): the 2026 lookup and current preparation path.
- [Release guide](RELEASING.md) and [runbook](RUNBOOK.md): compatible sources, weekly discovery and cache recovery.
- [Fixture guide](../fixtures/README.md): frozen addresses, synthetic census overlay and regression checks.

The [documentation index](README.md) separates current guidance from historical
plans, incidents and measurements. Historical release records are preserved;
they are not relabelled as ASGS 2026.
