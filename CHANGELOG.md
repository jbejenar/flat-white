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
