# Use a self-hosted build runner

> **Schema 1.0.0 change:** the ASGS 2026 migration invalidates old database
> caches. Plan for a fresh source load. Earlier build timings and memory estimates
> do not establish the capacity needed by the new sources.

Use a dedicated runner when hosted jobs repeatedly run out of memory, disk or
time, or when you need controlled hardware for measurements. Start by identifying
the failing stage in the [runbook](RUNBOOK.md); changing runners will not repair
an incompatible archive or census schema.

## Size the machine for the work it will actually run

A state build needs room for downloaded archives, extracted data, Postgres, a
possible database dump, uncompressed output and compressed artifacts. Plan for
these to coexist. Measure the first ASGS 2026 cold build before relying on an old
capacity estimate.

One runner process accepts one job at a time. Installing several runners on one
host makes jobs compete for the same memory and disk. The nine-state workflow
can therefore run serially on one runner or concurrently across a pool. Size the
pool and set concurrency deliberately; do not assume a nine-job matrix gives one
machine nine independent resource budgets.

The [April performance baseline](PERFORMANCE.md) and
[NSW memory analysis](NSW-MEMORY-ANALYSIS.md) are historical starting points. Record
current machine costs separately; this guide does not promise a build price or
completion time.

## Prepare and register the runner

1. Use a dedicated Linux host with Docker, Git, Python 3, `jq` and the GitHub CLI
   available to the runner account. The workflow builds the Node/Python/Postgres
   runtime inside Docker; other jobs also use setup actions for Node.
2. In the repository's **Settings → Actions → Runners**, choose **New self-hosted
   runner**. Follow GitHub's generated commands for the current runner version and
   platform. Do not copy an old runner archive URL from a historical guide.
3. Add a label such as `flat-white-build`. Confirm the account can use Docker and
   the workspace has enough free disk. Keep registration tokens out of files
   committed to the repository.
4. Install the runner as a service if it must remain available for scheduled work.
   Confirm its status in GitHub before dispatching a job.

Keep this build host isolated from unrelated workloads. Repository jobs execute
code on it, so its credentials and filesystem access should match that purpose.

## Test the setup before a production build

First check the small fixture locally on the runner:

```bash
git submodule update --init --recursive
npm ci
./scripts/build-fixture-only.sh
```

These commands require Node.js 22.22.1 or newer and Docker Compose on the host.
Leave `GNAF_VERSION` unset for the frozen fixture.

Then dispatch a metadata-only workflow run to the runner label:

```bash
gh workflow run quarterly-build.yml --ref main \
  -f runner=flat-white-build -f gnaf_version=2026.08 -f preflight_only=true
```

A passing preflight verifies setup and discovery on that runner. It does not
validate the production load, available capacity or S3 credentials.

## Select the runner for production

After reviewing the intended release and passing preflight, a production dispatch
can use the same label:

```bash
gh workflow run quarterly-build.yml --ref main \
  -f runner=flat-white-build -f gnaf_version=2026.08
```

This can publish data after verification; follow the [release procedure](RELEASING.md).
The `runner` input applies to setup, state builds, concatenation and release jobs.
The S3 job currently stays on `ubuntu-latest`.

Scheduled events have no dispatch inputs. To move scheduled builds, review the
`inputs.runner || 'ubuntu-latest'` fallbacks in the workflow; changing only the
manual input's default does not change the scheduled fallback.

## Keep it reliable

Monitor peak memory and disk use by stage, alongside the commit, source versions,
schema version, ASGS year and whether a cache was restored. Preserve logs and
artifacts until verification and any recovery are complete.

Clean up completed task artifacts and obsolete caches deliberately. Avoid broad
Docker volume cleanup on a host shared with other work. A cache may speed up a
build, but the pipeline must still validate it and be able to rebuild from source.
See [cache recovery](RUNBOOK.md#load-or-cache-validation-failed).
