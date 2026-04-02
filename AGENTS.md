# AGENTS.md — flat-white

## Project Overview

flat-white transforms Australian Government G-NAF address data into pre-joined, boundary-enriched NDJSON files. It spins up ephemeral Postgres + PostGIS, runs `minus34/gnaf-loader` to load and spatially join 15.9M addresses with administrative boundaries, flattens the relational model via a 9+ table SQL JOIN, and outputs one document per address. Then it dies.

## Architecture

```
src/
  build.ts              — orchestrator: download → load → flatten → output
  download.ts           — fetch G-NAF + Admin Bdys from data.gov.au
  load.ts               — invoke gnaf-loader against local Postgres
  flatten.ts            — stream Postgres → compose docs → write NDJSON
  split.ts              — split all-states NDJSON into per-state files
  compress.ts           — streaming gzip (~85-90% ratio)
  schema.ts             — TypeScript types + Zod validation
  verify.ts             — row count, schema validation, completeness
  metadata.ts           — generate build metadata JSON
  cli.ts                — CLI: --states, --output, --split-states, --compress

sql/
  address_full.sql              — master 9+ table JOIN
  address_full_with_arrays.sql  — with aggregated aliases + secondaries
  locality_full.sql             — locality with neighbours + aliases
  create_views.sql              — materialised views for fast export

fixtures/
  seed-postgres.sql             — ~500 edge-case addresses (committed)
  expected-output.ndjson        — regression baseline
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

## Principles (MUST follow)

1. **Fixture-first development.** Use `scripts/build-fixture-only.sh` for all dev work. NEVER require a 6.5GB download or gnaf-loader run for testing.
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
- **Integration tests:** `test/integration/` — full fixture → NDJSON pipeline
- **Regression tests:** `test/regression/` — byte-for-byte against committed fixtures

## Do NOT

- Modify the `gnaf-loader/` submodule — PR upstream if needed
- Download G-NAF data for testing — use committed fixtures
- Use `any` type — use `unknown` with type narrowing
- Import without `.js` extension — ESM requires explicit extensions
- Store state in Postgres between runs — it's ephemeral
- Add fields to the output schema without updating DOCUMENT-SCHEMA.md + schema.ts + expected-output.ndjson
