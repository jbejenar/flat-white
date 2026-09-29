# Build runbook

> **Schema 1.0.0 change:** builds require ASGS 2026 census input. A populated 2021
> table is no longer sufficient. New cache validation, archive-directory checks
> and weekly discovery are covered below. Consumer upgrade steps are in the
> [migration guide](MIGRATING-TO-ASGS-2026.md).

Start with the first failing stage, not the final red workflow summary. A failure
after a successful load may be recoverable from a validated database dump; a
wrong schema needs different input or code, not repeated retries.

## Collect the evidence

```bash
gh run list --workflow quarterly-build.yml --limit 5
```

Set `RUN_ID` to the failed run shown above, then inspect it:

```bash
gh run view "$RUN_ID"
gh run view "$RUN_ID" --log-failed
```

Record the commit, resolved G-NAF and Admin Boundaries versions, schema version,
ASGS year, state, first error, cache result and attempt count. State telemetry
and attempt logs distinguish a fresh load from a restored dump. Preserve these
when reporting an incident.

## Nothing was built

The schedule checks every Monday at 02:00 UTC. A scheduled run skips a quarter
with an existing draft or published release. A manual run with
`preflight_only=true` intentionally runs setup only. These are normal outcomes.

If no run appears, inspect the workflow state and recent Actions history:

```bash
gh api repos/jbejenar/flat-white/actions/workflows/quarterly-build.yml --jq .state
```

A disabled schedule needs operator attention. A green preflight proves metadata
setup, not archive compatibility or production readiness. See [release preflight](RELEASING.md#start-with-metadata-only-preflight).

For a setup authorization error, check its `contents: write` job permission. A
read-only token cannot reliably see held drafts. The built-in Actions token is
sufficient; no separate release App is needed. Production setup reserves the
exact release tag before building. If that fails, the state jobs must stay skipped.

A failed build can leave an unused reserved tag. Rerun the same commit, or choose
a new patch version when the fix changes code. Do not move the reserved tag to
make a different commit pass. See [release permissions](RELEASING.md#how-release-permissions-work).

## Source discovery failed

Check the resolved versions and data.gov.au resource metadata. G-NAF and Admin
Boundaries can be published at different times. An explicit `gnaf_version` pins
both to that quarter; an unpinned run discovers each independently.

Schema 1.x rejects either automatically selected source older than `2026.08`.
Do not rename an older quarter to satisfy the check. Use the old release's code
for an old-data rebuild, or select compatible sources. Manual overrides require
both URLs, the extracted boundary directory and an explicit G-NAF version.

Docker and local production builds apply the same quarter check before starting
Postgres or downloading anything. Use `YYYY.MM` with month `02`, `05`, `08` or
`11`; a release patch such as `2026.08.1` is not a valid `GNAF_VERSION`.

## Download or extraction failed

Read the error immediately before `Download failed`:

| Evidence                                        | Interpretation and response                                                                               |
| ----------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| Timeout, connection reset, HTTP 408, 429 or 5xx | A transport or service failure can be retried. Check the earlier attempts before rerunning.               |
| HTTP 404                                        | Check the resource URL and quarter. Both the downloader and container wrapper stop on permanent failures. |
| Missing extraction directory or sentinel        | Inspect the archive layout and source selection. Retrying the same layout will not fix it.                |
| Truncated or invalid archive                    | Check transport evidence and archive integrity; do not promote a partial extraction.                      |
| Disk exhaustion                                 | Check available space and retained files before retrying.                                                 |

Admin archives may use `LocalGovernmentAreas_*` or `LOCAL-GOVERNMENT-AREAS_*`.
The validator accepts either, plus the required state-boundary directory, and
requires actual directories. A filename matching the pattern is insufficient.
G-NAF's `Standard` and `Authority Code` must be directories under the same release
folder. New extraction is validated before replacing existing extracted data.

The downloader's final `Failure kind` line distinguishes transient failures from
permanent ones. The wrapper uses this result and the failed stage, so a recovered
network error earlier in the log does not cause a later schema or archive error
to retry. Telemetry still records those earlier network errors for diagnosis.

To repair a layout change, inspect bounded archive metadata where possible and
add a small synthetic ZIP regression case. Do not download the national dataset
for development tests or weaken checks to accept incomplete archives.

## Load or cache validation failed

The loader is pinned to a committed revision. Check its commit and Python/runtime
error first. Do not patch source files inside `gnaf-loader/`; loader changes belong
upstream. See [loader update checks](GNAF-LOADER-UPDATES.md).

The `202608` release alone skips authority cleanup. Use the documented repair pin,
which is submitted upstream, and run the small
[authority integration check](GNAF-LOADER-UPDATES.md#current-pin-and-upstream-repair)
when changing it. `aut.code`/`aut.name` errors or duplicate electoral polygon IDs
can indicate that raw DBF columns or duplicate authority rows were not normalized.

For ASGS 2026, validation requires:

- The expected versioned G-NAF and raw schemas with populated core tables.
- `address_principals.mb_2026_code` and the prepared `abs_2026_mb` lookup.
- The required 2026 mesh-block and hierarchy columns.
- At least 99% of addresses in **each state** matching a 2026 mesh block with
  populated SA1–SA4 and GCCSA codes. Null or blank hierarchy values do not count.
- Populated raw and prepared administrative tables appropriate to the selected states.

The error `ASGS 2026 census coverage below 99%` reports the affected state and its
complete/total address counts. Check incompatible quarters, incomplete loads and
missing hierarchy values. A table containing 2021 data is not a fallback. A large
healthy state cannot hide a broken smaller state, and duplicate reference rows
cannot inflate the matching count.

`Restored database failed validation` makes the state wrapper discard that local
dump and retry from source within its attempt budget. Schema 1.0.0 also uses cache
namespace `v3-asgs2026`. Do not restore an old dump under the new key or remove
validation to make it pass. If a fresh load fails the same check, investigate the
source/loader compatibility rather than repeatedly clearing caches.

## Flatten or verification failed

Use the source count, rejected PID, validation message and coverage report to
separate missing rows, malformed values and legitimate null assignments. The
current [boundary guide](BOUNDARIES.md) lists which state-specific gaps are expected.
Do not set every missing value to a placeholder or lower thresholds to hide a
missing table.

The release report checks every document against the schema, including rows that
would have fallen between the former sample checks. Wrong-state records and
out-of-range primary or alternative geocodes fail verification. Missing or damaged
gzip files also fail, with their streams closed cleanly.

Both production verifiers apply a 99% default floor to mesh block, SA1–SA4 and
GCCSA coverage in each state. The release report's optional `--boundary-thresholds`
values use percentages and are evaluated before rounding. Isolated nulls remain
valid; a green report still does not prove each geographic assignment is correct.
See [the coverage policy](BOUNDARIES.md#coverage-and-verification) for the evidence
and limits behind this safeguard.

Reproduce code changes with the fixture:

```bash
npm ci
./scripts/build-fixture-only.sh
npm test
```

Leave `GNAF_VERSION` unset; the fixture's address snapshot is `2026.02` and its
census overlay is synthetic ASGS 2026. The fixture script loads all overlays and
checks both flatten paths. Loading only `seed-postgres.sql` does not exercise the
current pipeline.

Edit the flatten field set in `sql/address_full.sql`, then run `npm run generate:sql`.
Do not edit the generated `address_full_main.sql` directly. Any intentional
output change needs the contract, Zod schema and fixture baseline reviewed together.

## Memory or disk exhaustion

Exit `137` often indicates a killed process; corroborate it with runner/container
logs before calling it an OOM. Inspect the failed stage and available memory and
disk. Concurrent state jobs on one machine share its resources. Increasing
Postgres `work_mem` can increase total memory across concurrent operations.

The wrapper retries resource exhaustion, but repeated failure at the same stage
needs a capacity or implementation fix. April measurements in
[performance](PERFORMANCE.md) and [NSW memory analysis](NSW-MEMORY-ANALYSIS.md) are
historical evidence, not a guarantee for an ASGS 2026 cold load. See
[self-hosted runners](SELF-HOSTED-RUNNER.md) for capacity planning.

## What is retried automatically?

[`run-quarterly-state.sh`](../scripts/run-quarterly-state.sh) defaults to three
container attempts in total (`MAX_RETRIES=2`). Transient failures wait 30 seconds
before another attempt. A rejected restored dump takes the separate fresh-load
recovery path. Both paths share the same attempt budget.

| Failure                                                           | Wrapper behaviour                              |
| ----------------------------------------------------------------- | ---------------------------------------------- |
| Recognised transport errors, HTTP 408/429/5xx                     | Retry within the budget.                       |
| Container exit 137/143 or recognised resource exhaustion          | Retry within the budget.                       |
| Rejected restored database                                        | Discard that local dump and retry from source. |
| Permanent archive/schema error or generic `Download failed` alone | Stop; require investigation.                   |

Within each container, an archive download has at most four request attempts,
with 1, 2 and 4 second delays after transient failures. Permanent HTTP, certificate
and local file errors stop immediately. CKAN metadata lookups have a 60 second
timeout; their transient failures use the container retry budget.

After fixing a transient external problem, rerun failed jobs from the existing
run if the inputs and retained artifacts are still appropriate:

```bash
gh run rerun "$RUN_ID" --failed
```

A code fix needs a new run on the corrected commit. Rerunning an old run does not
pick up a new commit from `main`.

## Release or S3 failure

An existing-release error is an intentional publication guard. Manual runs cannot
replace a public release or an existing draft. Inspect the existing assets and
reports, then choose an unused patch version for corrected data. A tag pointing
to a different commit is also rejected. See [release recovery](RELEASING.md#recover-a-draft-or-incomplete-mirror).

First establish whether the GitHub release is absent, draft or public. A comparison
anomaly deliberately keeps it as a draft. Inspect the verification and comparison
reports before deciding whether the change is expected. Follow the
[release recovery procedure](RELEASING.md#recover-a-draft-or-incomplete-mirror).

A public GitHub release can coexist with a failed S3 mirror. Inspect the S3 job's
OIDC, upload and object-verification logs without changing AWS state during
triage. If a manifest already exists, the workflow treats that version as
published and skips upload. Do not overwrite it to force a rerun.

After approving and publishing a held draft, or when repairing a missing mirror,
dispatch `quarterly-build.yml` with only `mirror_release_tag` set to that public
tag. Follow the [mirror-only procedure](RELEASING.md#recover-a-draft-or-incomplete-mirror).
It reads the published state assets rather than expired workflow artifacts and
checks their digests before any S3 writes. This is a publishing operation, not a
read-only diagnostic. A 403 while checking for a manifest is an access failure;
it is never treated as proof that the manifest is absent.

The national file is a workflow artifact and S3 output, not a GitHub release asset.
The GitHub size limit applies per asset, not to the release's combined size.
A correction to published data needs a new patch version; deleting the old tag
or using `--clobber` loses that distinction and can strand consumers.

## Before closing an incident

Confirm the corrected commit's relevant checks, the intended source/schema
metadata, and the affected workflow outcome. State separately whether the release
is public and whether the S3 mirror completed. Link the run and explain the root
cause, change and verification. Do not describe a passing fixture or preflight as
a completed production build.
