# AGENTS.md — flat-white

## Project Overview

flat-white transforms Australian Government G-NAF address data into pre-joined, boundary-enriched NDJSON files. It starts ephemeral Postgres + PostGIS, uses the pinned gnaf-loader submodule (`gnaf-loader/`) to load and prepare data, derives administrative spatial assignments in flat-white, joins the ASGS 2026 census hierarchy, and streams one NDJSON document per principal address. Then Postgres stops.

> **Schema 1.0.0 change:** census fields use ASGS 2026. Production build
> sources must be August 2026 or newer; the address fixture remains February
> 2026 with a synthetic census overlay. See the
> [migration guide](docs/MIGRATING-TO-ASGS-2026.md) and [document contract](docs/DOCUMENT-SCHEMA.md).

## Architecture

```
src/
  index.ts              — package entry point, schema/package version export
  schema.ts             — TypeScript types + Zod validation; ASGS_YEAR = 2026
  download.ts           — source discovery, download and archive validation
  load.ts               — invoke the pinned gnaf-loader against Postgres
  flatten.ts            — stream rows → validate documents → write NDJSON
  flatten-localities.ts — separate locality export module
  split.ts              — split NDJSON into per-state files
  compress.ts           — streaming gzip
  verify.ts             — counts, quality and per-state boundary coverage
  verification-report.ts — full schema and quality checks on compressed state artifacts
  metadata.ts           — local build metadata helper
  manifest.ts           — S3 manifest handling
  cli.ts                — TypeScript argument parser (not the Docker entrypoint)
  parquet.ts / geoparquet.ts — optional conversion modules

docker-entrypoint.sh    — production/fixture container orchestration

sql/
  address_full.sql              — SINGLE SOURCE OF TRUTH for the flatten query (CTE-based).
                                  Edit ONLY this file when changing the flatten field set or joins.
  address_full_main.sql         — AUTO-GENERATED from address_full.sql by `npm run generate:sql`.
                                  DO NOT EDIT DIRECTLY. Production SELECT using pre-materialized
                                  temp tables (from address_full_prep.sql). build-fixture-only.sh
                                  enforces byte-equality between both paths.
  address_full_prep.sql         — pre-materializes aggregations as temp tables for the production path

  # WARNING: street_type_aut is the only G-NAF authority table with REVERSED column
  # convention (code = long form, name = abbreviation). DO NOT join it like the others.
  # ap.street_type already contains the long form. The v2026.04 streetType regression
  # (PR #67) was caused by re-introducing this join.

fixtures/
  seed-postgres.sql             — schema DDL + ~451 edge-case addresses (loads via psql <30s)
  edge-cases.md                 — catalogue of edge cases with PIDs
  seed-census-2026.sql          — synthetic ASGS 2026 overlay; keeps 2021 decoys
  expected-output.ndjson        — committed schema 1.0.0 regression baseline
```

## Key Commands

```bash
npm install                     # Install dependencies
npm run build                   # Compile TypeScript
npm test                        # Run tests (Vitest)
npm run lint                    # Lint with ESLint
npm run typecheck               # Type-check (tsc --noEmit)
./scripts/build-fixture-only.sh # Dev loop: seed → flatten → NDJSON (<30s)
docker compose up db            # Start local Postgres + PostGIS
```

**GNAF_VERSION:** Production builds require a quarter in `YYYY.MM` format, `2026.08` or newer (months `02`, `05`, `08`, `11`). Set `GNAF_VERSION` for Docker; `build-local.sh` also accepts `--version`. Invalid or older quarters fail before build side effects. Fixture builds default to `2026.02` (the frozen fixture snapshot). Leave `GNAF_VERSION` unset for fixture builds. See [releasing](docs/RELEASING.md) for source configuration.

## Principles (MUST follow)

1. **Fixture-first development.** Use `scripts/build-fixture-only.sh` for all dev work. NEVER require a 6.5GB download or gnaf-loader run for testing. The fixture build exercises the full boundary pipeline: raw admin boundary seeding → prep SQL transformation → spatial join derivation → flatten → verify.
2. **gnaf-loader is a submodule. Do NOT modify it.** Changes go upstream via PR to `minus34/gnaf-loader`.
3. **The NDJSON schema is the contract.** When changing output, update ALL THREE together: `docs/DOCUMENT-SCHEMA.md`, `src/schema.ts`, `fixtures/expected-output.ndjson`. Breaking changes require a major version bump.
4. **Postgres is ephemeral.** It lives inside the container, loads data, exports NDJSON, and dies. Do not treat it as persistent infrastructure.
5. **Regression = byte-for-byte.** Tests compare against `fixtures/expected-output.ndjson`. Any output change without a fixture update fails CI.

## Code Conventions

- **ESM only** — `"type": "module"` in package.json
- **Strict TypeScript** — `strict: true` in tsconfig
- **No `any` type** — use `unknown` and narrow
- **Streaming everywhere** — cursor-based Postgres reads, line-by-line NDJSON writes, streaming gzip. Memory must stay under 500MB.
- **Zod for runtime validation** — every document validated during flatten

## Testing

- **Framework:** Vitest
- **Unit tests:** `test/unit/` — flatten logic, schema validation, verify logic
- **Regression tests:** `test/regression/` — byte-for-byte against committed fixtures

## Do NOT

- Modify the `gnaf-loader/` submodule — PR upstream if needed
- Download G-NAF data for testing — use committed fixtures
- Use `any` type — use `unknown` with type narrowing
- Import without `.js` extension — ESM requires explicit extensions
- Store state in Postgres between runs — it's ephemeral
- Add fields to the output schema without updating DOCUMENT-SCHEMA.md + schema.ts + expected-output.ndjson
