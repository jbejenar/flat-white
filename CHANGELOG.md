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

### Fixed

- **README download example:** `STATE="vic"; VERSION="2026.02"` → `VERSION="2026.04"`. The previous example referenced a filename (`flat-white-2026.02-vic.ndjson.gz`) that doesn't exist in any release — copy-pasting the verification snippet would fail with "no such file". (PR #77)
- **E1.14 Root-cause identified:** gnaf-loader's `geoscape.py:import_shapefile_to_postgres()` never checks `process.returncode` after running `shp2pgsql` via `subprocess.Popen()`. When `shp2pgsql` fails, empty stdout is decoded to an empty SQL string, executed as a no-op, and the function returns "SUCCESS" — silently failing to create boundary tables. This is the root cause of all four boundary fields being null in v2026.04. Fix requires upstream PR to `minus34/gnaf-loader`.

### Added

- **E1.19 Stale `2026.02` references in user-facing docs (p3-low):** roadmap ticket. PR #77 audit found that `docs/DOCUMENT-SCHEMA.md`, `docs/RUNBOOK.md`, and `docs/COMMUNITY-ANNOUNCEMENT.md` all contain example commands and field values still referencing `v2026.02`. The README example was the highest-impact and got fixed in PR #77 directly; the rest are filed for follow-up. Schema-name references (`gnaf_202602` etc.) and external/historical references are intentionally NOT in scope. (PR #77)
- **E1.10 Shapefile fixtures + spatial join regression:** Fixture build now exercises the full boundary pipeline — raw admin boundary SQL seeding → prep SQL transformation (adapted from gnaf-loader) → spatial join derivation → flatten → verify. Pre-baked `address_principal_admin_boundaries` rows removed from `seed-postgres.sql`; boundaries are now derived from polygon geometries via `ST_Intersects`. Closes the CI blind spot that let v2026.04 wards crash and boundary regressions slip through.
- **E1.10 State upper house electorate support:** Spatial join fallback in `address_full_prep.sql` now handles `state_upper_house_electorates` (previously hardcoded to NULL). VIC Legislative Council electorates are correctly assigned.
- **E1.13 Patch release PR auto-linking:** `quarterly-build.yml` now automatically discovers merged PRs between the base version tag and HEAD for patch releases, injecting a "Fixes" section with PR titles and links into the release notes. No more manual editing after running the patch workflow.
- **E1.13 Catalogue patch grouping:** `generate-catalogue.ts` groups patch releases (e.g. `v2026.04.1`) under their parent quarterly release (`v2026.04`) in the GitHub Pages catalogue. Patches render as indented sub-entries with accent-colored left border.
- **E1.12 Hardened verify — production enum checks:** `docker-entrypoint.sh` now passes `--db-url` to `verify.js`, enabling authority-table enum validation in production builds (previously only ran in fixture builds).
- **E1.14 Boundary coverage threshold check:** `verify.ts` now supports `--check-boundary-coverage` flag that hard-fails the build when LGA (<99%), ward (<95%), state electorate (<99%), or commonwealth electorate (<99%) boundary coverage drops below threshold. Enabled in fixture builds immediately; production builds get the flag once `--no-boundary-tag` is removed (E1.14). Prevents silent shipping of all-null boundary fields like v2026.04.

### Changed

- **E1.11 Consolidate flatten SQL:** `sql/address_full.sql` is now the single source of truth for the flatten query. `sql/address_full_main.sql` is auto-generated from it by `npm run generate:sql` (integrated into `npm run build`). This eliminates the hand-maintained drift that caused the v2026.04 streetType regression. Cross-path byte-equality check retained as belt-and-braces.
- **E1.16 Geocode type consistency (BREAKING):** `allGeocodes[].type` now uses the long-form description (e.g. `"FRONTAGE CENTRE SETBACK"`) instead of the raw abbreviation (e.g. `"FCS"`), matching `geocode.type`. Consumers that hardcoded short codes like `"FCS"`, `"PC"`, or `"PAPS"` must update to use long-form values. Version bumped to 0.2.0.

### Fixed

- **E1.17 De-hardcode G-NAF Feb 2026:** removed all hardcoded `2026.02` / `202602` defaults from production code paths (`src/download.ts`, `src/load.ts`, `src/flatten.ts`, `docker-entrypoint.sh`, `scripts/build-local.sh`). `GNAF_VERSION` env var is now required for production builds — prevents v2026.05 from silently shipping Feb 2026 data. Fixture scripts retain the `2026.02` default since fixtures are frozen. SQL files were already parameterized with `__SCHEMA_VERSION__`. Download URLs for non-Feb-2026 releases are set via `DOWNLOAD_URL_GNAF` / `DOWNLOAD_URL_ADMIN_BDYS` env vars. `docs/RELEASING.md` updated with version configuration and URL discovery instructions.
- **E1.18 Workflow CHANGELOG `[Unreleased]` not cleared on release:** the Python script in `quarterly-build.yml`'s "Update CHANGELOG.md" step now extracts existing `[Unreleased]` content, moves it into the new versioned entry, and leaves `[Unreleased]` empty. Idempotent on re-run.

### Added

- Cross-path regression guard in `scripts/build-fixture-only.sh`: both flatten paths (legacy and `--materialize`) now run against the fixture and must produce byte-identical output. Future drift between `sql/address_full.sql` and `sql/address_full_main.sql` fails CI immediately. (PR #67)
- Defense-in-depth regression test in `test/regression/expected-output.test.ts`: asserts no document has `streetType` in a known-abbreviation set (`ST`, `AV`, `PL`, `RD`, `CR`, `CL`, `DR`, `CT`, `CCT`, `TCE`, `PDE`, `GDNS`, …). Catches the v2026.04 bug class even if the SQL guard is bypassed. (PR #67)
- `fixtures/seed-postgres.sql` mirrors `abs_2021_mb_lookup` into a stub `admin_bdys_202602.abs_2021_mb` so the materialize path (which reads the table name gnaf-loader populates in production) sees the same SA1–4/GCC data the legacy path reads from `abs_2021_mb_lookup`. Mirror has no `geom` column — to be added by E1.10 (shapefile fixtures). (PR #67)
- E1.10 Shapefile Fixtures + Spatial Join Regression Test: roadmap ticket for clipped shapefile fixtures + shp2pgsql wiring + derivation of admin boundary tables, so CI exercises gnaf-loader's shapefile loading and spatial join. (PR #67)
- E1.11 Consolidate flatten SQL: roadmap ticket to eliminate hand-maintained drift between `address_full.sql` and `address_full_main.sql` by construction. (PR #67)
- E1.12 Hardened verify checks: roadmap ticket to validate enum-ish output fields (`streetType`, `flatType`, `levelType`, `streetSuffix`, `localityClass`, `state`) against authority tables in `verify.ts`. (PR #67)
- **E1.13 Patch release tooling — most of it landed in PR #67**: `quarterly-build.yml` accepts a `patch_version` input that splits `version` (G-NAF data version, used for build) from `release_version` (used for tag and asset filenames). Asset filenames become `flat-white-2026.04.1-{state}.ndjson.gz` so consumers can detect that previous downloads are stale by filename comparison alone. metadata.json has both `version` (release) and `gnafVersion` (data). `docs/RELEASING.md` documents the full procedure. Remaining: catalogue grouping and PR auto-linking in patch release notes (still manual). (PR #67)
- E1.16 Geocode type field consistency: roadmap ticket — `geocode.type` is long form (`"FRONTAGE CENTRE SETBACK"`) but `allGeocodes[].type` is short form (`"FCS"`). Pre-existing inconsistency in both legacy and materialize SQL — not a drift bug. Found during PR #67 round-3 field audit. (PR #67)
- **E1.17 De-hardcode G-NAF Feb 2026 (p0-critical, blocks v2026.05)**: roadmap ticket. Found while tracing `GNAF_VERSION` propagation in rounds 5–6. The G-NAF Feb 2026 release is hardcoded in FOUR places: (1) `src/download.ts` URLs are pinned to Feb 2026 with `version` parameter documented as "informational only" — **strictly worst because it ships wrong data**, (2) `src/load.ts:111` defaults `geoscapeVersion` to `"202602"` with no CLI override, (3) `sql/address_full*.sql` schema names hardcoded ~30 times, (4) `fixtures/seed-postgres.sql` is intentionally frozen. Without the fix, the v2026.05 quarterly cron (2026-05-15) will silently ship Feb 2026 data labeled as 2026.05. (PR #67)
- E1.18 Workflow CHANGELOG `[Unreleased]` not cleared on release (p3-low): pre-existing workflow bug. The Python script in the "Update CHANGELOG.md" step inserts a new versioned entry after `[Unreleased]` but doesn't move existing content into it. Visible in this CHANGELOG today — all v2026.04 entries are still under `[Unreleased]` from when v2026.04 was published. (PR #67)
- `docs/RELEASING.md`: documented procedure for quarterly releases and patch releases with worked example using v2026.04.1. (PR #67)
- **E1.14 Restore LGA / ward / stateElectorate / commonwealthElectorate boundary fields (p0-critical)**: roadmap ticket to root-cause the gnaf-loader shapefile loading failure and restore all four boundary fields in the next release. **All four are null in v2026.04** — verified by inspecting the released ACT file. This is a much bigger quality regression than the streetType bug. (PR #67)

### Fixed

- `streetType` field returned the abbreviation (e.g. `"PL"`) instead of the long form (e.g. `"PLACE"`) in the production (`--materialize`) flatten path. `sql/address_full_main.sql` joined `raw_gnaf_202602.street_type_aut`, which is the only G-NAF authority table with a reversed convention (`code` = long form, `name` = abbreviation). The legacy CTE-based path was fixed in PR #23 but `address_full_main.sql` (added in PR #29) carried the pre-fix join logic. **Affects v2026.04** — release needs to be republished. `addressLabelSearch` was also affected since `composeSearchLabel` reads `streetTypeName` — verified in v2026.04 ACT file (`"9 WYNN ST"` instead of `"9 WYNN STREET"`). (PR #67)
- **E1.15** Multi-polygon row multiplication in spatial join fallback: `sql/address_full_prep.sql` used four `LEFT JOIN ... ST_Intersects(...)` clauses to populate `address_principal_admin_boundaries`. Points lying on a polygon edge match BOTH adjacent polygons; cartesian-multiplied across four joins produced up to 16 duplicate rows per address. Latent in v2026.04 because `--no-boundary-tag` means the boundary tables don't exist, so the fallback inserts NULL — but would have activated the moment E1.14 lands. Replaced with `LEFT JOIN LATERAL (... ORDER BY pid LIMIT 1)` per boundary table (one row per address per table by construction) and added a `UNIQUE INDEX` on `gnaf_pid` as a structural guard. Verified end-to-end: 451 fixture rows in, 451 unique PIDs out, zero duplicates. (PR #66)
- Documentation drift in `docs/FIELD-PROVENANCE.md` and `AGENTS.md`: both files described or implied the broken `street_type_aut` join. Updated to clearly document that `street_type_aut` is intentionally NOT joined, and that it has reversed column conventions. (PR #67)

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
