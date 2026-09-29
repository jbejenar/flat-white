# Release a data build

> **Schema 1.0.0 change:** production builds must use G-NAF and Admin
> Boundaries August 2026 or newer, with ASGS 2026 census data. Older quarters need
> their original code and schema. Read the [migration guide](MIGRATING-TO-ASGS-2026.md)
> before publishing or consuming the new contract.

A code version and a data release answer different questions. Schema `1.0.0`
describes the document contract. A tag such as `v2026.08.1` identifies a particular
data build. All versions below are examples; check existing releases before
choosing a tag.

## Choose the sources and release version

| Input                                                 | Behaviour                                                                                                       |
| ----------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| No version input                                      | Discover the newest G-NAF and newest Admin Boundaries releases independently. Freeze both for this run.         |
| `gnaf_version=2026.08`                                | Select August 2026 for both sources.                                                                            |
| `gnaf_version=2026.08`, `patch_version=1`             | Rebuild that source quarter as release `v2026.08.1`.                                                            |
| All three manual source overrides plus `gnaf_version` | Use the supplied URLs and extracted boundary directory; metadata records the administrative source as `manual`. |

`patch_version` is a positive integer. It never becomes part of the G-NAF version
or a document's `_version`. Always pin `gnaf_version` when making a patch: leaving
it empty discovers the latest upstream data, which may be a different quarter.

Production quarters use `YYYY.MM`, with month `02`, `05`, `08` or `11`, and must
be `2026.08` or newer. The quarterly and mini workflow setup steps, Docker entrypoint
and local build share this validation. Docker and local builds reject invalid versions before
creating output directories or starting Postgres, including when reusing data
or a database cache. The February fixture is exempt; leave its version unset.

The scheduled check runs **Monday at 02:00 UTC**. It skips quarters that already
have a draft or published release. The data remains quarterly; checking weekly
avoids missing a release that appears after a fixed day of the month. Inspect an
existing draft before assuming a skipped scheduled build is a failure.

## Start with metadata-only preflight

After the code checks pass, run setup without downloading the archives, starting
a database, building data, publishing a release or writing to S3:

```bash
gh workflow run quarterly-build.yml --ref main \
  -f gnaf_version=2026.08 -f preflight_only=true
gh run list --workflow quarterly-build.yml --limit 5
```

Use `--ref YOUR_BRANCH` to check a workflow change before merge. Then inspect the
run's setup output. Confirm the resolved G-NAF, Admin Boundaries and release
versions. With `preflight_only=true`, all downstream jobs should be skipped.

Preflight validates metadata and input eligibility. It does **not** inspect the
archive contents, prove a complete loader run, measure production memory, or test
release/S3 publication. The loaded database checks provide a later compatibility
gate for the actual sources.

The manual **Mini Quarterly** workflow also freezes and validates both source
quarters and includes both in its database cache key. An explicit quarter pins
both sources; automatic discovery may choose different compatible quarters.

## Publish a quarter

1. Land the intended code on `main` with CI passing. For a schema change, review
   the [contract](DOCUMENT-SCHEMA.md), fixture baseline and migration guide together.
2. Check [existing releases](https://github.com/jbejenar/flat-white/releases), including
   drafts. Choose an unused release version and run preflight.
3. Start the **production** workflow. This downloads the source archives and can
   publish data after the gates pass:

   ```bash
   gh workflow run quarterly-build.yml --ref main -f gnaf_version=2026.08
   ```

4. Inspect all nine state jobs, concatenation and release verification. Use the
   [runbook](RUNBOOK.md) for failures; do not bypass failed checks.
5. Review the release assets and metadata. Confirm `schemaVersion: "1.0.0"`,
   `asgsYear: 2026`, the intended source versions, per-state counts and total count.
   Read the verification and build-over-build comparison reports, especially for
   unexplained count drops or missing geographic assignments.
6. Confirm the release is public and check the separate S3 mirror job. A successful
   GitHub release does not mean S3 succeeded. Review the workflow's generated
   CHANGELOG PR as a separate repository change.

The workflow first creates a draft, verifies its assets and a programmatic
download, then publishes it unless the comparison check reports anomalies. An
anomaly leaves the release as a draft for investigation. A draft is not a
consumer-ready release.

The release verification report validates every document in each compressed state
file. It checks state membership, coordinates and duplicates, and reports coverage
through GCCSA. Each census field must reach 99% coverage in each state by default;
the load/restore gate also requires 99% complete census hierarchies per state.
Review the actual null rates and source compatibility as part of the migration
checks. These floors detect incomplete enrichment; they do not certify each
individual geographic assignment.

Publication also checks [GitHub's limit of less than 2 GiB per asset](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases).
The combined size of valid state files can exceed that limit. A comparison-tool
error stops publication rather than being treated as a clean comparison.

Both setup and the final publication step check whether the release already
exists. Scheduled runs skip existing releases; manual runs stop with an error.
No run deletes an existing release or tag. New releases point to the exact commit
used by the build. A pre-existing tag pointing elsewhere is rejected.

## Publish a correction

Use a new patch release when correcting already published data. For example,
`v2026.08.1` has filenames such as `flat-white-2026.08.1-vic.ndjson.gz`, while its
documents retain `_version: "2026.08"`.

```bash
# Production publication: first check that this tag is unused.
gh workflow run quarterly-build.yml --ref main \
  -f gnaf_version=2026.08 -f patch_version=1
```

A patch tag does not make a breaking schema change backward compatible. Review
the schema version separately. Documentation-only corrections do not need a new
data release. Do not delete a published release or overwrite its assets to hide
a correction; consumers need stable files and a clear reason to download a new version.

## Configure downloads

The data.gov.au package identifiers are stable; individual resource identifiers
and archive filenames change. Normal workflow runs resolve the matching GDA2020
G-NAF ZIP and Administrative Boundaries shapefile ZIP automatically. The downloader
fails if it cannot resolve the requested source, rather than silently using the
old February URL constants for a schema 1.x build.

To inspect available G-NAF resource metadata without downloading the archives:

```bash
curl --fail --silent --show-error \
  'https://data.gov.au/data/api/3/action/package_show?id=19432f89-dc3a-4ef3-b943-5326ef1dbecc' \
  | jq '.result.resources[] | {name, url}'
```

The Admin Boundaries package is `bdcf5b09-89bc-47ec-9281-6b8e9ee147aa`.

When an operator needs explicit sources, provide **all three** workflow inputs
and `gnaf_version` together:

- `download_url_gnaf`: the intended GDA2020 address ZIP.
- `download_url_admin_bdys`: the intended GDA2020 boundary ZIP.
- `admin_bdys_extracted_dir`: its extracted root, such as `AUG26_AdminBounds_GDA_2020_SHP`.

The equivalent container environment names are `DOWNLOAD_URL_GNAF`,
`DOWNLOAD_URL_ADMIN_BDYS` and `ADMIN_BDYS_EXTRACTED_DIR`. Record the exact URLs with
the build evidence. Manual sources use `adminBoundariesVersion: "manual"` because
a URL override does not establish the source's quarter. The actual loaded tables
must still contain the required 2026 census columns and matching mesh-block codes.

## Build locally

Production container builds require `GNAF_VERSION`; fixture builds default to the
frozen `2026.02` address snapshot. Follow the [README build instructions](../README.md#build-it-yourself)
for both. Leave `GNAF_VERSION` unset when using the fixture script.

Use the fixture for code development. A national download or loader run is not a
prerequisite for checking a change. The older `scripts/build-local.sh` is a lower-level
helper for an already configured local database and source paths; it is not a
replacement for the documented container setup.

## What gets published

| Artifact                      | Purpose                                                                                                   |
| ----------------------------- | --------------------------------------------------------------------------------------------------------- |
| Nine state `.ndjson.gz` files | Address documents, each from the same resolved build.                                                     |
| `metadata.json`               | Release version, both source versions, schema version, ASGS year, timestamp and counts.                   |
| `DOCUMENT-SCHEMA.md`          | Contract shipped with the release.                                                                        |
| `verification-report.md`      | Verification evidence for the release.                                                                    |
| Combined national file        | Workflow artifact and S3 output; excluded from GitHub release assets because of the per-asset size limit. |

A GitHub metadata excerpt for an illustrative patch is:

```json
{
  "version": "2026.08.1",
  "gnafVersion": "2026.08",
  "adminBoundariesVersion": "2026.08",
  "schemaVersion": "1.0.0",
  "asgsYear": 2026
}
```

S3 uses paths such as `data/address/2026-08-1/` and
`manifests/address-2026-08-1.json`. Its manifest keeps `manifest_version: 2` and adds
`schema_version: "1.0.0"` and `asgs_year: 2026`. See the
[migration guide's metadata table](MIGRATING-TO-ASGS-2026.md#know-which-version-you-are-checking)
for the differences between release, source, schema and manifest versions.

## Recover a draft or incomplete mirror

For a draft, inspect the failed verification or comparison evidence first. Record
why the anomaly is expected or fix the data and choose the appropriate new build.
Only publish a reviewed draft when its contents satisfy the release checks.
Manually making a draft public does not by itself run a previously skipped S3 job.
After reviewing and publishing it, use the explicit mirror-only mode:

```bash
gh workflow run quarterly-build.yml --ref main -f mirror_release_tag=v2026.08.1
```

This is a publication action that writes to S3. Use it only for the public release
you intend to mirror. Leave preflight, source-version, patch and download inputs
at their defaults. The setup step rejects mixed modes and draft/prerelease tags.
The build, concatenation and GitHub release jobs are skipped.

Recovery checks the release metadata, geography, schema and tag commit. It then
downloads the nine **published state files**, checks their sizes and SHA-256
digests against GitHub's release records, and reconstructs the national gzip by
concatenating those exact bytes. The original tag supplies the OpenSearch mapping
and schema version. Seven-day workflow artifact expiry does not prevent recovery.
Public status and asset metadata are checked again after downloading, before AWS
credentials are configured. The manifest's pipeline fields identify the recovery
run and its publishing code; its saved recovery plan records the release commit.

Rerunning release creation will not replace an existing draft. Review that draft's
assets and reports, then either publish the reviewed draft or use a new patch
version for a corrected build. This also protects public releases from accidental
deletion during a manual rerun.

For a **failed S3 job after a public release**, inspect its logs and OIDC
configuration. Use the same mirror-only command, or rerun the failed job while
its original artifacts remain available. A normal build dispatch still rejects
existing releases; it does not replace the release or bypass a held draft.

Both mirror paths share a per-version concurrency group and the same S3 gates.
An existing manifest skips every write. Only a confirmed missing object permits
upload; permission, authentication and transport errors stop the job. Staged and
published sizes and SHA-256 checksums must match, including the mapping file.
The manifest is written last with a
[conditional write](https://docs.aws.amazon.com/AmazonS3/latest/userguide/conditional-writes.html)
that refuses to replace an existing key. A corrected dataset needs a new release
version; do not remove or rewrite a published manifest to force a retry.

For read-only diagnosis, compare the public release metadata, workflow logs and
S3 manifest/object metadata. Keep any publication or repair action separate from
that inspection. See the [runbook](RUNBOOK.md#release-or-s3-failure).
