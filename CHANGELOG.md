# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

**Versioning rules for flat-white:**

- **Major (1.0.0):** Breaking changes to the NDJSON output schema (field removal, type change, rename)
- **Minor (0.2.0):** New fields, new output formats, new states, additive changes
- **Patch (0.1.1):** Bug fixes, performance improvements, internal refactors, documentation

The NDJSON schema is the contract. See `docs/DOCUMENT-SCHEMA.md`.

## [Unreleased]

## [v2026.02.1] - 2026-04-09

> **Patch release** — supersedes the deleted v2026.04 release. The underlying G-NAF data is unchanged (still G-NAF 2026.02). v2026.04 was published 2026-04-05 with all-null boundary fields (lga, ward, stateElectorate, commonwealthElectorate) due to a chain of upstream and downstream issues (E1.14 gnaf-loader `shp2pgsql` silently failing; E1.17 hardcoded download URL labeling 2026.02 data as 2026.04). v2026.02.1 ships the same address data with correct, populated boundary fields via the new bulk-join spatial fallback (E1.21 / PR #106), the state-aware verify thresholds (PR #105), and the cache validator (PR #104). v2026.04 was deleted from GitHub Releases on 2026-04-09; its git tag survives for history.

### Release

- **Release version:** 2026.02.1
- **G-NAF data version:** 2026.02
- **Schema version:** 0.2.0
- **Total addresses:** 15,015,573
- **Per-state counts:** ACT 245,362 · NSW 4,619,401 · NT 110,079 · OT 3,805 · QLD 3,100,481 · SA 1,123,131 · TAS 346,248 · VIC 3,940,659 · WA 1,526,407
- **Quarterly run:** [24163471133](https://github.com/jbejenar/flat-white/actions/runs/24163471133)

### Added

- **P0.07 Fixture extraction automation:** `scripts/extract-fixtures.sh` now generates `fixtures/seed-postgres.sql` end-to-end from a full VIC gnaf-loader load. Selects ~450 fixture PIDs, derives related entities, extracts DDL + filtered data for all 25 tables, and assembles the complete fixture file.
- **E1.10 Shapefile fixtures + spatial join regression:** Fixture build now exercises the full boundary pipeline — raw admin boundary SQL seeding → prep SQL transformation (adapted from gnaf-loader) → spatial join derivation → flatten → verify. Pre-baked `address_principal_admin_boundaries` rows removed from `seed-postgres.sql`; boundaries are now derived from polygon geometries via `ST_Intersects`. Closes the CI blind spot that let v2026.04 wards crash and boundary regressions slip through.
- **E1.10 State upper house electorate support:** Spatial join fallback in `address_full_prep.sql` now handles `state_upper_house_electorates` (previously hardcoded to NULL). VIC Legislative Council electorates are correctly assigned.
- **E1.13 Patch release tooling:** `quarterly-build.yml` accepts a `patch_version` input that splits `version` (G-NAF data version) from `release_version` (tag and asset filenames). Asset filenames become `flat-white-2026.04.1-{state}.ndjson.gz`. `docs/RELEASING.md` documents the full procedure. (PR #67)
- **E1.13 Patch release PR auto-linking:** `quarterly-build.yml` now automatically discovers merged PRs between the base version tag and HEAD for patch releases, injecting a "Fixes" section with PR titles and links into the release notes.
- **E1.13 Catalogue patch grouping:** `generate-catalogue.ts` groups patch releases (e.g. `v2026.04.1`) under their parent quarterly release (`v2026.04`) in the GitHub Pages catalogue. Patches render as indented sub-entries with accent-colored left border.
- **E1.12 Hardened verify — production enum checks:** `docker-entrypoint.sh` now passes `--db-url` to `verify.js`, enabling authority-table enum validation in production builds (previously only ran in fixture builds).
- **E1.14 Boundary coverage threshold check:** `verify.ts` now supports `--check-boundary-coverage` flag that hard-fails the build when boundary coverage drops below threshold. Prevents silent shipping of all-null boundary fields like v2026.04.
- Cross-path regression guard in `scripts/build-fixture-only.sh`: both flatten paths (legacy and `--materialize`) must produce byte-identical output. (PR #67)
- Defense-in-depth regression test in `test/regression/expected-output.test.ts`: asserts no document has `streetType` in a known-abbreviation set. Catches the v2026.04 bug class even if the SQL guard is bypassed. (PR #67)

### Changed

- **E1.11 Consolidate flatten SQL:** `sql/address_full.sql` is now the single source of truth for the flatten query. `sql/address_full_main.sql` is auto-generated from it by `npm run generate:sql` (integrated into `npm run build`). Eliminates the hand-maintained drift that caused the v2026.04 streetType regression. (PR #67)
- **E1.16 Geocode type consistency (BREAKING):** `allGeocodes[].type` now uses long-form descriptions (e.g. `"FRONTAGE CENTRE SETBACK"` instead of `"FCS"`), matching `geocode.type`. Consumers that hardcoded short codes must update. Version bumped to 0.2.0. (PR #70)
- **E1.19 Doc version references updated:** `DOCUMENT-SCHEMA.md` examples now show `2026.04`; `RUNBOOK.md` commands use `${VERSION}` shell variable placeholders; `COMMUNITY-ANNOUNCEMENT.md` reflects v2026.04 shipped. Convention documented in `RELEASING.md`.

### Fixed

- **E1.21 — Bulk spatial-join fallback (PR #106):** Replaced the LATERAL+LIMIT spatial join in `sql/address_full_prep.sql` with insert-then-5-updates against unsubdivided polygon tables. Empirical NSW spatial join time: 67 min → 7.5 min on M5 64GB (~9× speedup). The new shape is plain INNER JOIN with `DISTINCT ON (gnaf_pid) ... ORDER BY gnaf_pid, {pid}` per boundary table — frees the planner to pick its preferred parallel-aware spatial join shape (same plan gnaf-loader Part 5 gets). Five INDEPENDENT UPDATE passes preserve the LATERAL+LIMIT semantics exactly (each table's lowest pid picked independently), so byte-for-byte regression against `fixtures/expected-output.ndjson` stays clean. Multi-polygon row multiplication safety (E1.15) preserved via DISTINCT ON. The implementation considered and rejected `_analysis`-tables-with-ST_Subdivide (would have lost LGA's `full_name` column) and joint-INSERT-with-DISTINCT-ON (would have changed cartesian-tuple tiebreak semantics). See PR #106 commit message and ROADMAP entry E1.21 for the full reasoning.

- **E1.21 quarterly impact:** Quarterly build run [24163471133](https://github.com/jbejenar/flat-white/actions/runs/24163471133) is the **first quarterly run with all 9 states green**. Per-state job times for the three previously-failing states: NSW 1h56m (failed flatten) → 29m20s (clean pass with cache hit); SA 55m15s (failed) → 12m54s; TAS 1h19m45s (failed) → 11m30s. The OLD LATERAL+LIMIT code was crashing 3 of 9 states (NSW/SA/TAS) due to a separate latent flatten-session bug (E1.24, masked by E1.21 making the spatial join fast enough to avoid the timing window).

- **PR #107 — Latent quarterly release asset-count ordering bug:** The `.github/workflows/quarterly-build.yml` release job's "Verify asset count and size" step counted assets and asserted ≥12 (9 per-state + metadata + schema + verification-report.md), but the verification-report.md is generated by a later step. Fired today on quarterly run 24159739501 — the first quarterly run where all 9 state builds succeeded thanks to E1.21 (PR #106). Failed at the release stage 55s in with `Expected at least 12 assets, got 11`. This bug had been latent forever; every previous quarterly run failed earlier in per-state builds and never reached the release stage to expose it. **Fix:** split into two checks — `Verify upstream artifacts present` (early fail-fast at 11 before report generation) and `Verify final asset bundle and size` (post-report check at 12 with explicit `-f` check for `verification-report.md`).

- **Quarterly build "permanent fix" — two unrelated bugs causing all 9 build jobs to fail:**

  **Bug A — gnaf-loader hardcoded SQL vs dynamic schema (column-mismatch).** `gnaf-loader/settings.py` filters `admin_bdy_list` per-state (omits LGA for ACT, wards for non-NT/SA/VIC/WA, etc.) but `04-06-bdy-tags-for-alias-addresses.sql` is hardcoded to reference all 5 boundary `*_pid`/`*_name` columns. When a single-state build excludes any of them, the dynamic CREATE TABLE doesn't make those columns and the hardcoded INSERT fails with `psycopg.errors.UndefinedColumn`. Affects ACT (lga_pid), NSW/QLD (ward_pid), OT (ce_pid, se_lower_pid), TAS (se_upper_pid), NT (se_upper_pid). **7 of 9 states fail.** Latent in v2026.04 because gnaf-loader ran with `--no-boundary-tag` (Part 5 skipped). Exposed when the upstream shp2pgsql fix landed and the workaround was removed.

  **Bug B — Postgres `/dev/shm` exhaustion at flatten.** Postgres parallel hash joins allocate dynamic shared memory chunks in `/dev/shm` by default. Docker default `/dev/shm` is 64MB which is exhausted by a single 64MB parallel hash table. Affects VIC and WA (the 2 states with all 5 boundary types that get past Bug A). Latent in v2026.04 because `address_principal_admin_boundaries` was empty (no boundary tagging) → no parallel plans → no shm pressure. Exposed when boundary tables became populated.

  **Permanent fixes (no band-aids):**
  1. **Replaced narrow `grep -qE 'address_alias_admin_boundaries.*(ward_pid|se_upper_pid)'` retry hack in `docker-entrypoint.sh` with a precise Part-5 detection** (`scripts/detect-load-failure.sh`). Detection condition: gnaf-loader exits non-zero AND log contains `Part 5 of 6 : Start boundary tagging` AND log does NOT contain `Part 5 of 6 : Addresses boundary tagged` (the success marker). The third condition is a false-positive guard — without it, a Part 6 (or later) failure that happened to follow a successful Part 5 would be incorrectly retried with `--no-boundary-tag`, masking unrelated errors. When detection fires, retry with `--no-boundary-tag` and let flat-white's spatial-join fallback in `address_full_prep.sql` populate boundaries. Catches any future Part 5 error (not just specific column names) without leaking into unrelated phases. When upstream `minus34/gnaf-loader` ships a fix (E1.20), the first attempt succeeds and the fallback never fires. **Tested** by `test/integration/load-detection/test.sh` against 9 sample log fixtures: success, all 5 known column failures, 1 hypothetical future failure, 1 false-positive guard (Part 5 succeeded → Part 6 failed), and 2 pre-Part-5 negative cases.

  2. **`dynamic_shared_memory_type = sysv`** added to the Postgres tuning block in `docker-entrypoint.sh`. Removes the dependency on Docker `/dev/shm` entirely; SysV shared memory is bounded by kernel `SHMMAX`/`SHMALL` which Docker leaves at host defaults (very high). **No `--shm-size` insurance flag, no magic numbers** — this is the structural fix.

  3. **Build job timeout 90 → 360 min** in `quarterly-build.yml`. The spatial-join fallback can take 30 min - 3 hr for NSW (~4.6M addresses) when it's the primary path. 360 is GitHub Actions free-tier maximum. Escalation if even that's insufficient: switch to self-hosted runner via `runner` workflow input (E1.09 documents the procedure).

  4. **Schema-validating stub for `address_principal_admin_boundaries`** in `address_full_prep.sql`. When gnaf-loader's Part 5 fails partway through (today's bug), it leaves the boundary tag table with a state-filtered (incomplete) schema — only the columns for boundary types in `admin_bdy_list`. The retry with `--no-boundary-tag` does NOT clean up this stale table because gnaf-loader's `01-01-drop-tables.sql` doesn't drop boundary tag tables (only Part 5 does, and Part 5 is now skipped). flatten then fails with `column "ab.ward_name" does not exist` querying the broken stub. The fix: a `DO $$ ... $$` block at the top of the prep SQL detects if the table is missing any of the 10 required boundary columns and drops it, letting `CREATE TABLE IF NOT EXISTS` create a clean stub with the full schema. Verified end-to-end against a manually-corrupted table (8-column filtered schema → DO block detects 8 missing columns → drops → CREATE makes full 16-column stub → flatten succeeds, 451 rows).

  **Layered defence**: (1) gnaf-loader's tagging tried first → (2) flat-white spatial-join fallback if Part 5 fails → (3) E1.14 boundary coverage threshold check hard-fails verify if both produced mostly-NULL output. Three independent layers, two of them ours. No single point of failure.

  Roadmap follow-ups: E1.20 (push upstream gnaf-loader fix — nice-to-have, not load-bearing) and E1.21 (optimise the spatial-join fallback to bulk hash joins instead of `LATERAL+LIMIT 1`, only matters if free runners can't handle NSW within 360 min).

- **E1.14 gnaf-loader shapefile fix:** Upstream PR [minus34/gnaf-loader#100](https://github.com/minus34/gnaf-loader/pull/100) adds `process.returncode` check after `shp2pgsql`. Submodule pinned to fork commit with the fix. `docker-entrypoint.sh` now also has a narrow `--no-boundary-tag` retry for the known alias-boundary upstream crash, so flat-white's fallback can still populate boundaries. Production verify runs `--check-boundary-coverage`. A rebuilt patch release on `2026.04` data should now either populate boundary fields or fail verification instead of silently shipping nulls.
- **E1.17 De-hardcode G-NAF Feb 2026:** removed all hardcoded `2026.02` / `202602` defaults from production code paths. Direct production builds require `GNAF_VERSION`, and the workflow now auto-discovers the latest published overlapping quarterly G-NAF/Admin Boundaries release from data.gov.au when `gnaf_version` is omitted. Manual URL overrides remain available for one-off runs.
- **E1.18 Workflow CHANGELOG `[Unreleased]` not cleared on release:** the Python script in `quarterly-build.yml` now extracts existing `[Unreleased]` content, moves it into the new versioned entry, and leaves `[Unreleased]` empty. Idempotent on re-run.
- **E1.15 Multi-polygon row multiplication in spatial join:** Replaced `LEFT JOIN ... ST_Intersects(...)` with `LEFT JOIN LATERAL (... ORDER BY pid LIMIT 1)` per boundary table, plus `UNIQUE INDEX` on `gnaf_pid`. Verified: 451 fixture rows in, 451 unique PIDs out, zero duplicates. (PR #66)
- **streetType abbreviation regression:** `sql/address_full_main.sql` joined `street_type_aut` (reversed column convention), returning abbreviations instead of long forms. Affects v2026.04. (PR #67)
- **README download example:** `VERSION="2026.02"` → `VERSION="2026.04"`. Previous example referenced a non-existent filename. (PR #77)
- Documentation drift in `docs/FIELD-PROVENANCE.md` and `AGENTS.md` regarding `street_type_aut` join. (PR #67)

### v2026.02.1 release notes

- This is a **patch release**. The underlying G-NAF data is unchanged from v2026.02. v2026.04 had been published with the same 2026.02 G-NAF data (because of the E1.17 hardcoded download URL bug) but with all-null boundary fields (because of E1.14's silent shapefile loading failure). v2026.02.1 ships the corrected boundary data via the new bulk-join spatial fallback. Asset filenames are versioned as `flat-white-2026.02.1-{state}.ndjson.gz` so consumers can detect that previous downloads are stale.
- **v2026.04 was deleted on 2026-04-09.** It shipped with all-null boundary fields and was superseded by this release. Git tag `v2026.04` survives for history; the GitHub release page is gone (404). Anyone with a hardcoded `v2026.04` download URL gets a 404 and should update to `v2026.02.1`.
- Build-over-build comparison report shipped with this release compared against `v2026.04` (which was still published at the time the release job ran). The comparison shows "no changes" because counts match — but the boundary field content changed massively (null → populated for 7 of 9 states). The comparison report is therefore misleading; this is a known limitation of P4.03 (counts only, not content) and is being tracked separately.
- **Discovered side effects (filed for follow-up):**
  - **E1.24** — pre-existing flatten-session bug (`tmp_address_geocodes does not exist`) was masked by E1.21 making the spatial join fast enough to avoid the timing window. Latent.
  - **E1.25** — `docker-entrypoint.sh` `--skip-download` env-var gap. Trivial 2-line fix.
  - **E1.26** — WA cursor stream is 40-75× slower when restored from cache vs fresh build. Hypothesis: missing planner statistics after `pg_restore`.
  - **E1.27** — Release workflow CHANGELOG push fails on branch protection. **This very entry was manually added to the CHANGELOG via PR because of that bug.**
  - **E1.28** — Catalogue workflow has not been triggered for any release because of GitHub Actions GITHUB_TOKEN recursion prevention. Catalogue site is currently stale.
  - **E1.29** — Node.js 20 deprecation in GitHub Actions; needs upgrade to Node 24-compatible action versions before 2026-09-16.

## [v2026.04] - 2026-04-05

### Added

- E1.06 Build Cache: `--dump-db` and `--restore-db` flags in docker-entrypoint.sh for gnaf-loader database dump caching. `quarterly-build.yml` uses `actions/cache@v4` keyed by G-NAF version + state + gnaf-loader hash. Cache hit skips download + gnaf-loader (~30 min per state).
- E1.08 GitHub Pages Catalogue: `src/generate-catalogue.ts` generates static HTML site from GitHub Release API data. `.github/workflows/catalogue.yml` deploys to GitHub Pages on release publish. Includes release history, per-state counts, download links, schema reference, dark mode.
- E1.05 Geoparquet Output: `--format geoparquet` option via `src/geoparquet.ts`. WKB-encoded POINT geometry column, Geoparquet v1.1.0 metadata (WGS 84 CRS, bbox), null geocode handling. 7 unit tests including 451-row fixture regression.
- E1.01 Parquet Output: `--format parquet` option via `src/parquet.ts`. Converts NDJSON to Parquet with native scalar columns and JSON-serialized complex fields. CLI and unit tests included.
- E1.09 Self-Hosted Runner Fallback: `docs/SELF-HOSTED-RUNNER.md` with hardware requirements, runner setup, workflow configuration, cost estimates. `quarterly-build.yml` supports `runner` input for targeting self-hosted runners via `workflow_dispatch`.
- E1.07 Multi-Arch Image: `docker-publish.yml` builds and publishes ARM64 + AMD64 Docker images via QEMU. Includes `verify-multi-arch` and `verify-identical` CI jobs to ensure byte-for-byte output parity across architectures.
- P4.07 NSW Memory Optimisation: PostgreSQL memory tuning in docker-entrypoint.sh (shared_buffers=256MB, work_mem=64MB, maintenance_work_mem=256MB, max_connections=20). Margin analysis in `docs/NSW-MEMORY-ANALYSIS.md`. Per-state production timing added to `docs/PERFORMANCE.md`.
- P4.01 First Production Release: v2026.04 published with 15,015,573 addresses across all 9 Australian states. 23m55s wall-clock on free runners.
- P4.02 Verification Report: per-state schema validation, boundary coverage %, quality checks, PID uniqueness. All 9 states PASS. Uploaded as release asset.
- P4.04 Retry Logic: up to 2 automatic retries on transient failures (OOM kill, network timeout, resource exhaustion) in quarterly-build.yml with failure classification — persistent failures (schema validation, flatten errors) fail immediately without retry
- P4.06 Runbook: `docs/RUNBOOK.md` with 6 failure scenarios (download, gnaf-loader, flatten, verification, OOM, release creation), manual re-run procedures, and retry logic reference table
- P3.05 Downstream Dispatch: `repository_dispatch` notification to `geocode-au` after release publish, with version + asset URL payload
- P3.06 Download Docs: programmatic download examples (gh CLI, curl, GitHub API), consumer verification one-liner in README
- P3.07 Community Announcement: `docs/COMMUNITY-ANNOUNCEMENT.md` with 6 target channels and draft messaging

### Changed

- P3.03 GitHub Release Creation: verified existing implementation in quarterly-build.yml (tagged release, asset verification, CHANGELOG update, programmatic download test)
- P3.04 Release Notes: verified auto-generated notes with total/per-state counts, delta from prior release, schema version, gnaf-loader version

- Progress logging in flatten pipeline: ProgressLogger integrated with 30s debounced progress events during cursor streaming (P2.06)
- P2.03 CLI Arguments: all 8 flags implemented in `src/cli.ts` and `docker-entrypoint.sh` with validation and `--help` output
- P2.07 Image Publish: GitHub Actions workflow for Docker Hub publish on v\* tags with version + latest tagging
- `docs/PERFORMANCE.md` — VIC build performance baseline: timing, memory, output sizes, hardware specs (P1.16)
- `Dockerfile` — multi-stage self-contained image: Postgres 16 + PostGIS 3.5, Python 3, gnaf-loader, Node.js 22, TypeScript flattener (P2.01)
- `.dockerignore` — excludes dev artifacts, tests, docs from Docker build context
- `docker-entrypoint.sh` — minimal entrypoint supporting `--help` and `--fixture-only` modes (P2.01)
- `scripts/build-local.sh` — full local build orchestrator: load → flatten → verify (P1.11)
- `sql/address_full_prep.sql` — pre-materializes aggregation CTEs as temp tables for production-scale flattening
- `sql/address_full_main.sql` — streamable multi-join query using temp tables (no CTEs)
- `--materialize` flag for flatten.ts — enables pre-materialization for production runs
- `src/load.ts` — gnaf-loader wrapper with PGPASSWORD env var, path resolution, logging (P0.04)
- Full VIC build verified: 3,940,659 documents, 0 schema errors, ~5 min total (P1.11)
- `src/schema-compat.ts` — schema compatibility checker: compares JSON Schema snapshots, classifies breaking vs non-breaking changes (E1.04)
- `src/check-schema-compat-cli.ts` — CI entry point for schema evolution checks
- `src/generate-schema-baseline.ts` — generates `fixtures/schema-baseline.json` from Zod schemas
- `fixtures/schema-baseline.json` — committed schema baseline for CI comparison
- `test/unit/schema-compat.test.ts` — 10 unit tests for schema comparison logic
- CI schema compatibility check step in `.github/workflows/ci.yml` (E1.04)
- `src/metadata.ts` — build metadata generator: per-state counts, version, schema version, build timestamp, gnaf-loader version (P1.12)
- `src/split.ts` — streaming per-state NDJSON splitter with backpressure support (P1.13)
- `src/compress.ts` — streaming gzip compression using Node.js pipeline (P1.14)
- `test/unit/metadata.test.ts` — 7 unit tests for metadata generation
- `test/unit/split.test.ts` — 4 unit tests for per-state splitting
- `test/unit/compress.test.ts` — 5 unit tests for gzip compression
- `src/verify.ts` — row count verification + data quality checks: coordinate bounds, PID uniqueness, state/postcode cross-validation, boundary coverage reporting (P1.10, P1.10A)
- `test/unit/verify.test.ts` — 22 unit tests for verify module including fixture validation
- Enhanced `test/regression/expected-output.test.ts` — geocode bounds check, full verify suite integration (P1.15)
- `src/download.ts` — G-NAF + Admin Boundaries downloader with progress, retry, skip-download (P0.03)
- `sql/address_full.sql` — master 9+ table JOIN query for flatten pipeline (P0.06)
- `src/flatten.ts` — streaming Postgres → NDJSON flattener with Zod validation (P0.06)
- `scripts/build-fixture-only.sh` — fixture-only build script: docker → seed → flatten (P0.10)
- Unit tests for document composition: composeDocument, composeSearchLabel, composeBoundaries

### Changed

- Recognized P1.01–P1.09 as already implemented during P0 work — updated ROADMAP.md with evidence

### Changed

- `geocode` field is now nullable — returns `null` instead of `{0,0}` sentinel when no geocode exists (schema triple-update: schema.ts + DOCUMENT-SCHEMA.md + tests)

### Fixed

- Use cursor-based streaming (.cursor(500)) instead of loading all rows into memory
- Add .gitignore exception for `fixtures/expected-output.ndjson` (unblocks P0.09)
- Export composition helpers from flatten.ts; tests now import real code instead of duplicating it
- Robust jq NDJSON validation in build-fixture-only.sh
- Remove silent sentinel geocode `{latitude: 0, longitude: 0}` — violates "no sentinel values" rule

### Added (prior)

- Project scaffold: ROADMAP.md, AGENTS.md, package.json, tsconfig.json, CI workflow
- docker-compose.yml with PostgreSQL 16 + PostGIS 3.5
- gnaf-loader pinned as Git submodule
- `src/schema.ts` — Zod runtime schema with full address document validation and TypeScript type exports (P0.12)
- `test/unit/schema.test.ts` — 11 unit tests for schema validation (valid docs, invalid fields, enum values, range checks)
- `docs/DOCUMENT-SCHEMA.md` — complete field reference: 28 top-level fields + 8 nested object types with type, nullability, description, example, G-NAF source (P0.11)
- Decision records DEC-001 through DEC-007 in `docs/decisions/` (P0.14)
