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

| Input                                                                 | Behaviour                                                                                                       |
| --------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| No version input                                                      | Discover the newest G-NAF and newest Admin Boundaries releases independently. Freeze both for this run.         |
| `gnaf_version=2026.08`                                                | Select August 2026 for both sources.                                                                            |
| `gnaf_version=2026.08`, `patch_version=1`                             | Rebuild that source quarter as release `v2026.08.1`.                                                            |
| Manual source overrides, `gnaf_version` and `boundary_reference_date` | Use the supplied URLs and extracted boundary directory; metadata records the administrative source as `manual`. |

`patch_version` is a positive integer. It never becomes part of the G-NAF version
or a document's `_version`. Always pin `gnaf_version` when making a patch: leaving
it empty discovers the latest upstream data, which may be a different quarter.

Production quarters use `YYYY.MM`, with month `02`, `05`, `08` or `11`, and must
be `2026.08` or newer. The quarterly and mini workflow setup steps, Docker entrypoint
and local build share this validation. Docker and local builds reject invalid versions before
creating output directories or starting Postgres, including when reusing data
or a database cache. The February fixture is exempt; leave its version unset.
Production containers and local builds require a source lock. Acquire it using the
[README example](../README.md#build-it-yourself), or let the workflow's `sources`
job do that once for all states. During acquisition, `ADMIN_BDYS_VERSION` can pin
a different compatible boundary quarter; otherwise it defaults to `GNAF_VERSION`.
The resulting lock determines the actual sources and boundary reference date.

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
release/S3 publication. It does not reserve a release tag. The loaded database checks provide a later compatibility
gate for the actual sources.

The manual **Mini Quarterly** workflow also freezes and validates both source
quarters, acquires the archives once and includes their content identity in its database cache key. An explicit quarter pins
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

**New full comparison:** after verification, the release job streams every PID and
field against the preceding published release, one state at a time. It verifies
the downloaded baseline checksums and rejects duplicates or unordered PIDs.
`comparison.md` summarizes the result; `comparison-STATE.jsonl.gz` records every
added, removed or changed document without keeping them all in memory.

For a same-quarter patch, every added/removed PID and every field change must be
accounted for. The current reviewed exception is August OT's missing federal
assignment becoming Bean, Fenner or Lingiari; the independent OT snapshot gate
checks the exact counts and remaining gaps. Other changes hold the release as a
draft for investigation. Different quarters naturally change records; the report
still captures every difference and the 1% count anomaly gate remains in place.
A failed baseline download or comparison stops publication. An older release with
no archive lock is explicitly identified as lacking historical source-byte evidence.

The release verification report validates every document in each compressed state
file. Build and release verification use the same per-state coverage floors,
including 99% federal coverage for OT. The release gate also checks the source
quarter, schema version, state and exact metadata counts.

**New integrity evidence:** each build compares every eligible raw principal PID
with the loaded principals and exported PIDs. Equal counts alone cannot pass a
missing or substituted address. The gate rejects duplicates and publishes a
`reconciliation-STATE.json` report for each state. Release verification checks
the compressed artifact's PID digest against that evidence. PID sorting spills
to disk with a 32 MiB buffer; diagnostic samples are bounded while totals remain
exact. Allow scratch disk space for these ledgers. The fixture-only smoke has an
explicit exemption from production evidence and is restricted to February 2026.

Publication also checks [GitHub's limit of less than 2 GiB per asset](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases).
The combined size of valid state files can exceed that limit. A comparison-tool
error stops publication rather than being treated as a clean comparison.

Both setup and the final publication step check whether the release already
exists. Scheduled runs skip existing releases; manual runs stop with an error.
No run deletes an existing release or tag. New releases point to the exact commit
used by the build. A pre-existing tag pointing elsewhere is rejected.

## How release permissions work

The workflow uses GitHub's built-in `GITHUB_TOKEN`; no extra App or release secret
is required. Setup and publication have `contents: write`. Setup needs that access
even for its read checks because GitHub hides drafts from a read-only token.

After checking availability, a production run reserves the release tag at its
exact commit **before** starting the state builds. Publication rechecks that tag
and uses `gh release create --verify-tag`, then checks the commit again before
publishing. It never substitutes the current tip of `main`. This also avoids
asking GitHub to create a historical tag after workflow files have changed during
the long build, which can require permissions unavailable to `GITHUB_TOKEN`.

If a build fails, the reserved tag remains but no data release is published.
Rerun the same commit to reuse that reservation. If the repair changes the commit,
choose an unused patch version; the workflow will not move or delete the old tag.
Tag creation or authorization failures stop in setup, before the expensive build.
Metadata-only preflight and mirror recovery do not reserve tags.

Keeping the built-in token also preserves the existing event behaviour: release
tags do not launch another tag-triggered Docker publication. The catalogue runs
from completion of Quarterly Build, and downstream notifications require a public
release. A held draft is not announced as ready.

## Check the catalogue

The [public catalogue](https://jbejenar.github.io/flat-white/) updates automatically
when a successful Quarterly Build on `main` completes. Check its release version,
address total, state counts, schema version and ASGS year against `metadata.json`.
The generator reads and validates that published asset; it does not derive current
release facts from the wording of the release notes. Older metadata can omit the
ASGS year, which is then left unstated.

A missing asset on a legacy release permits a release-note fallback. An advertised
metadata asset that cannot be downloaded, is invalid, names another release, or
has inconsistent counts stops generation, preserving the last deployed page.
Unknown legacy counts are shown as unavailable, never as zero addresses.

After a catalogue code fix or a reviewed metadata correction, regenerate the site
without rebuilding or republishing the address data:

```bash
gh workflow run catalogue.yml --ref main
```

Confirm both Catalogue jobs succeed and inspect the live page. A green deployment
alone does not prove that the displayed numbers are correct.

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

When an operator needs explicit sources, provide these workflow inputs together:

- `gnaf_version`: the address quarter being built.
- `download_url_gnaf`: the intended GDA2020 address ZIP.
- `download_url_admin_bdys`: the intended GDA2020 boundary ZIP.
- `admin_bdys_extracted_dir`: its extracted root, such as `AUG26_AdminBounds_GDA_2020_SHP`.
- `boundary_reference_date`: the administrative snapshot date, in `YYYY-MM-DD` format.

For local acquisition, the URL and directory variables are `DOWNLOAD_URL_GNAF`,
`DOWNLOAD_URL_ADMIN_BDYS` and `ADMIN_BDYS_EXTRACTED_DIR`. Set
`ADMIN_BDYS_VERSION=manual` **for acquisition only**, and provide
`BOUNDARY_REFERENCE_DATE`. The marker does not establish the package quarter;
loaded data must still pass the ASGS 2026 checks. Do not pass `manual` to the
container's quarter selector. The container reads it from the validated lock.

## Locked sources and boundary dates

**New build requirement:** `source-lock.json` records the selected URLs, resource
IDs where available, source editions, complete archive SHA-256 checksums, archive
inventories and the code used to acquire them. The workflow downloads each archive
once. Every state verifies those same bytes before extraction. A changed or damaged
archive stops the build; an old directory name is not proof of a valid source.

State and upper-house boundaries are evaluated at **00:00 UTC on the last day of
the administrative package month**. A start date is inclusive; an end date is
exclusive. Missing endpoints are unbounded. For August 2026, the reference is
`2026-08-31`, regardless of when the build runs. This removes the previous dependency
on the machine's current date. Manual packages require an explicit reference date.
The frozen address fixture uses `2026-02-28`.

For an exact-source rebuild, choose a new patch number and reuse a published lock:

```bash
gh workflow run quarterly-build.yml --ref main \
  -f source_lock_release_tag=v2026.08.1 -f patch_version=2
```

These tags are examples, not a claim that those releases exist. The selected lock
supplies the source quarters and URLs; do not combine it with URL overrides. The
acquisition job downloads those URLs again and rejects changed bytes. A historical
release without a lock cannot prove byte-identical upstream inputs. Its document
files can still be compared, but do not invent missing archive checksums.

Database caches now use namespace `v4-locked-sources`. The workflow computes the
tracked build fingerprint once, before Python or Docker can create extra files,
and reuses it for cache restore and save. Generated `__pycache__` files do not
change that identity. Each dump also has a `.provenance.json` sidecar containing
the source identity, selected states, boundary date, runtime/code fingerprint and
dump checksum. Restore checks all of these, then verifies the database's own source
record and its table/coverage checks. Old, incomplete or mismatched caches are rebuilt.
Only the base G-NAF and Geoscape load belongs in this cache.

Archives remain workflow artifacts for seven days; the small lock and release
evidence persist as release assets. Keep sufficient scratch space for archives,
extraction and database dumps. Retention of a lock does not guarantee that an
upstream download URL will remain available forever.

## Build locally

Production container builds require `GNAF_VERSION`; fixture builds default to the
frozen `2026.02` address snapshot. Follow the [README build instructions](../README.md#build-it-yourself)
for both. Leave `GNAF_VERSION` unset when using the fixture script.

Use the fixture for code development. A national download or loader run is not a
prerequisite for checking a change. The older `scripts/build-local.sh` is a lower-level
helper that also requires `sources/source-lock.json` and its archives; it is not a
replacement for the documented container setup.

## What gets published

**New publication evidence:** the release's evidence index also travels through S3
staging, checksum verification and mirror recovery. In the S3 manifest, `artifacts`
contains evidence separately from `files`. Evidence never enters
`index.source_keys` or address counts. Recovery downloads the selected release's
assets and mappings; it does not substitute today's documentation or configuration.
The manifest is still published last, after every data and evidence object is verified.

| Artifact                      | Purpose                                                                                                   |
| ----------------------------- | --------------------------------------------------------------------------------------------------------- |
| Nine state `.ndjson.gz` files | Address documents, each from the same resolved build.                                                     |
| `metadata.json`               | Release version, both source versions, schema version, ASGS year, timestamp and counts.                   |
| `DOCUMENT-SCHEMA.md`          | Contract shipped with the release.                                                                        |
| `verification-report.md`      | Verification evidence for every compressed state file.                                                    |
| `source-lock.json`            | Exact source checksums, inventories and administrative reference date.                                    |
| `reconciliation-STATE.json`   | Exact eligible-source, loaded and exported PID comparison.                                                |
| `build-provenance-STATE.json` | The state's source identity and database dump/runtime provenance.                                         |
| `evidence-index.json`         | Release commit, version and SHA-256 checksums of the evidence files.                                      |
| `MIGRATING-TO-ASGS-2026.md`   | Migration guidance shipped with that release.                                                             |
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
The documented `adminBoundariesVersion: "manual"` marker is accepted for releases
built from explicit source overrides. Recovery preserves that provenance; it does
not invent a source quarter. Explicit quarter values must still satisfy the
production version policy, and schema, geography, counts and asset checks still apply.
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
