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

### Added

- P3.05 Downstream Dispatch: `repository_dispatch` step in quarterly-build.yml notifies geocode-au after release publication with version, tag, and asset URL payload
- P3.06 Download Docs: expanded README Distribution section with `gh`, `curl`, CI/API download examples, and consumer verification one-liner

### Changed

- P3.03 GitHub Release Creation: verified existing implementation in quarterly-build.yml — all 5 DoD items met (tagged release, size check, state verification, programmatic download, CHANGELOG update)
- P3.04 Release Notes: verified existing implementation — auto-generated markdown with total/per-state counts, delta from prior release, schema version, gnaf-loader version

### Added (prior)

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
