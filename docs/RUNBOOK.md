# Operational Runbook — flat-white

This runbook covers common failure scenarios for the flat-white quarterly build. Each scenario includes symptoms, diagnosis steps, resolution, and manual commands.

## Overview

flat-white runs as a GitHub Actions matrix build (`.github/workflows/quarterly-build.yml`) that:

1. Builds a Docker image containing Node.js, PostgreSQL + PostGIS, and gnaf-loader
2. Runs 9 parallel jobs (one per Australian state: VIC, NSW, QLD, SA, WA, TAS, NT, ACT, OT)
3. Each job: downloads G-NAF data → loads via gnaf-loader → flattens to NDJSON → gzips
4. Concatenates per-state files into an all-states file
5. Creates a GitHub Release with all assets

The build is triggered quarterly via cron (15th of Feb/May/Aug/Nov) or manually via `workflow_dispatch`.

## Monitoring Build Status

- **Workflow runs:** `gh run list --workflow=quarterly-build.yml`
- **Specific run:** `gh run view <run-id>`
- **Per-job logs:** `gh run view <run-id> --log`
- **GitHub UI:** Actions tab → "Quarterly Build" workflow

## Failure Scenarios

---

### 1. Download Failures

**Symptoms:**

- Job fails during Docker container execution
- Logs contain: `ETIMEDOUT`, `ECONNRESET`, `download failed`, `fetch failed`, `socket hang up`
- Exit code is non-137 (not OOM)

**Diagnosis:**

```bash
# Check the failed job's logs
gh run view <run-id> --log | grep -i -A5 'download\|timeout\|ETIMEDOUT'

# Verify data.gov.au is accessible
curl -sI https://data.gov.au/data/dataset/geocoded-national-address-file-g-naf
```

**Resolution:**

- The retry logic handles this automatically (up to 2 retries with 30s backoff)
- If all retries fail, data.gov.au may be experiencing an outage
- Wait 1-2 hours and re-trigger manually

**Manual re-run:**

```bash
# Re-run failed jobs only
gh run rerun <run-id> --failed

# Or re-trigger the entire build
gh workflow run quarterly-build.yml -f gnaf_version=YYYY.MM
```

---

### 2. gnaf-loader Errors

**Symptoms:**

- Job fails during Docker container execution
- Logs contain Python tracebacks, PostGIS errors, or gnaf-loader-specific messages
- Common errors: `psycopg2.OperationalError`, `FATAL: role does not exist`, spatial index failures

**Diagnosis:**

```bash
# Check the failed job's logs for Python errors
gh run view <run-id> --log | grep -i -A10 'traceback\|error\|fatal'

# Check the gnaf-loader submodule version
git ls-tree HEAD gnaf-loader
```

**Resolution:**

- gnaf-loader errors are classified as **persistent** — the retry logic will NOT retry them
- Check if the gnaf-loader submodule is pinned to a known-good commit
- Check if the G-NAF data format has changed (new quarterly release may have schema changes)
- If gnaf-loader needs a fix, it must go upstream via PR to `minus34/gnaf-loader`

**Common gnaf-loader issues:**
| Error | Cause | Fix |
|-------|-------|-----|
| `role "gnaf" does not exist` | PostgreSQL not initialized | Docker image issue — rebuild |
| `could not open extension control file` | PostGIS not installed | Docker image issue — rebuild |
| `invalid geometry` | Corrupted boundary data | Check Admin Boundaries download |
| Python import errors | Missing Python dependency | Check Dockerfile pip install |

---

### 3. Flatten Failures

**Symptoms:**

- Job fails after gnaf-loader succeeds (data is loaded but output generation fails)
- Logs contain: `ZodError`, `schema validation failed`, `SQL error`, assertion failures
- Exit code is non-137

**Diagnosis:**

```bash
# Check for schema validation errors
gh run view <run-id> --log | grep -i -A5 'ZodError\|schema\|validation'

# Check for SQL errors
gh run view <run-id> --log | grep -i -A5 'sql\|query\|relation.*does not exist'
```

**Resolution:**

- Flatten errors are classified as **persistent** — NOT retried
- These indicate a code bug or data format change
- Check if `src/flatten.ts` or `sql/` files were recently modified
- Run the fixture build locally to reproduce:

```bash
# Local reproduction
docker compose up db -d
psql -h localhost -U postgres -f fixtures/seed-postgres.sql
npm run build
./scripts/build-fixture-only.sh
```

**Common flatten issues:**
| Error | Cause | Fix |
|-------|-------|-----|
| `relation "gnaf_YYYYMM.xxx" does not exist` | Version mismatch in SQL | Update SQL schema references |
| `ZodError: Required at "fieldName"` | Missing field in query result | Update flatten SQL JOIN |
| `column "xxx" does not exist` | G-NAF schema change | Update SQL and schema.ts |

---

### 4. Verification Failures

**Symptoms:**

- Build step succeeds but verification step fails
- Logs contain: `Expected output file not found`, `gzip integrity`, `Output file is empty`, count mismatch

**Diagnosis:**

```bash
# Check verification step output
gh run view <run-id> --log | grep -i -A5 'ERROR\|expected\|mismatch'
```

**Resolution:**

- **File not found:** Output naming convention may have changed — check `--output` path and filename pattern
- **Empty output:** Flatten produced 0 rows — likely a SQL or data issue (see Flatten Failures)
- **Gzip corruption:** Disk space issue on runner — check if the runner ran out of space
- **Count mismatch (concatenation):** One state may have produced partial output — check per-state logs

---

### 5. OOM Kills

**Symptoms:**

- Job killed with exit code 137
- No error message in application logs (process was killed by the kernel)
- Most common for NSW (~4.5M addresses on 7GB free runners)

**Diagnosis:**

```bash
# Check which state was OOM-killed
gh run view <run-id> --log | grep -i 'exit code 137\|OOM\|killed'
```

**Resolution:**

- The retry logic retries OOM kills up to 2 times (they can be intermittent)
- If NSW consistently OOMs, see P4.07 (NSW Memory Optimisation)
- As a workaround, consider PostgreSQL memory tuning in the Dockerfile:
  - Reduce `shared_buffers` (e.g., `256MB`)
  - Reduce `work_mem` (e.g., `64MB`)
  - Increase `maintenance_work_mem` only if gnaf-loader needs it

---

### 6. Release Creation Failures

**Symptoms:**

- Build and concatenation succeed but release job fails
- Logs contain: `gh release create` errors, permission issues

**Diagnosis:**

```bash
# Check release job logs
gh run view <run-id> --log --job=<release-job-id>

# Check if a draft release already exists
gh release list
```

**Resolution:**

- **Permission error:** Ensure the workflow has `contents: write` permission
- **Tag already exists:** The workflow has idempotency logic (`gh release delete` before create) — if this fails, manually delete the tag:
  ```bash
  gh release delete v2026.02 --yes --cleanup-tag
  ```
- **Asset too large:** GitHub has a 2GB limit per release. Check total asset size.

---

## Manual Operations

### Full Re-Run (All States)

```bash
# Trigger a fresh build for a specific version
gh workflow run quarterly-build.yml -f gnaf_version=2026.02
```

### Partial Re-Run (Failed Jobs Only)

```bash
# Re-run only the failed jobs from an existing run
gh run rerun <run-id> --failed
```

### Single State Re-Run

GitHub Actions matrix builds don't support re-running a single matrix job. Options:

1. **Re-run failed jobs:** `gh run rerun <run-id> --failed` (re-runs all failed matrix entries)
2. **Manual single-state build:** Run locally with Docker:
   ```bash
   docker build -t flat-white .
   mkdir -p output
   docker run --rm \
     -v "$(pwd)/output:/output" \
     -e "GNAF_VERSION=2026.02" \
     flat-white \
     --states VIC \
     --split-states \
     --compress \
     --output /output
   ```
3. **Upload manually to release:**
   ```bash
   gh release upload v2026.02 output/flat-white-2026.02-vic.ndjson.gz --clobber
   ```

### Manually Publishing a Draft Release

If the automated publish step failed but the draft release has all assets:

```bash
# Verify assets
gh release view v2026.02

# Publish
gh release edit v2026.02 --draft=false
```

## Retry Logic Reference

The quarterly build has built-in retry logic for the pipeline step:

| Failure Type                | Retried? | Max Attempts      | Examples                          |
| --------------------------- | -------- | ----------------- | --------------------------------- |
| OOM kill (exit 137)         | Yes      | 3 (1 + 2 retries) | NSW memory pressure               |
| Container killed (exit 143) | Yes      | 3                 | Runner preemption                 |
| Network errors              | Yes      | 3                 | data.gov.au timeout, DNS failures |
| Resource exhaustion         | Yes      | 3                 | Disk full, shared memory          |
| Schema validation           | No       | 1                 | ZodError, assertion failure       |
| Flatten/SQL errors          | No       | 1                 | Missing table, bad JOIN           |
| gnaf-loader errors          | No       | 1                 | Python traceback                  |

**Alerting:**

- Retried and succeeded: `::warning::` annotation in GitHub Actions
- Retried and failed: `::error::` annotation after all retries exhausted
- Persistent failure: `::error::` annotation, immediate failure (no retry)
