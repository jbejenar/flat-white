# Next Work — flat-white

> Updated: 2026-04-04. Active phase: P0.

## Completed This Session

### P0.03 — G-NAF Download Script (done)

- [x] `src/download.ts` with data.gov.au URLs, sentinel validation, atomic extraction
- [x] Progress reporting (% complete, MB/s)
- [x] Retry logic (3 retries, exponential backoff, 60s stall timeout)
- [x] `--skip-download` flag with `isExtractionComplete()` validation
- [x] `DATA_DIR` env var and `resolveOutputDir()` for path configuration
- [x] 24 unit tests passing

### Geocode Sentinel Fix (P0 correctness)

- [x] `geocode` field now nullable — returns `null` instead of `{latitude: 0, longitude: 0}`
- [x] Schema triple-update: `schema.ts` + `DOCUMENT-SCHEMA.md` + tests

## Active Tickets

### P0.09 — Expected Output (in-progress)

Generate regression baseline files from the fixture build.

- [ ] `fixtures/expected-output.ndjson` committed (~451 lines, one per address)
- [ ] `fixtures/expected-output-sample.json` committed (first document, prettified)
- [ ] Line count matches `address_principals` row count in seed-postgres.sql
- **Requires**: running `./scripts/build-fixture-only.sh` against Postgres (docker required)

### P0.10 — Fixture-Only Build (in-progress, depends on P0.09)

- [x] `scripts/build-fixture-only.sh` seeds Postgres, runs flatten, outputs NDJSON
- [x] No download required — works from committed fixture data
- [x] No gnaf-loader required — seeds via psql
- [x] Completes in <30 seconds
- [ ] Regression check against `expected-output.ndjson` (pending P0.09)

### P0.12 — Zod Schema (in-progress, depends on P0.09)

- [ ] Validate every document in `fixtures/expected-output.ndjson` against schema

## Blockers

- **Docker/psql commands** may be unavailable in sandbox. If blocked: write code and unit tests only, document the blocker, move on.
- **`fixtures/expected-output.ndjson`** requires running the full fixture pipeline. Cannot be generated without docker + Postgres.

## Do NOT Touch

- `ROADMAP.md` checkboxes — update only after verification evidence exists
- `gnaf-loader/` — submodule, never modify
- `fixtures/seed-postgres.sql` — use `fixtures/SCHEMA-REFERENCE.md` for table info

## Reference Files

| Need             | Read this                      | NOT this                     |
| ---------------- | ------------------------------ | ---------------------------- |
| Table schemas    | `fixtures/SCHEMA-REFERENCE.md` | `fixtures/seed-postgres.sql` |
| Field provenance | `docs/FIELD-PROVENANCE.md`     | —                            |
| Document schema  | `docs/DOCUMENT-SCHEMA.md`      | —                            |
| Flatten SQL      | `sql/address_full.sql`         | —                            |
| Agent rules      | `CLAUDE.md` (auto-loaded)      | —                            |
