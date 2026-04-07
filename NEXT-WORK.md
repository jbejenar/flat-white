# Next Work — flat-white

> Updated: 2026-04-08. Active phase: E1 (Ongoing) — P4 blocked. Per-session log lives in `NEXT-SESSION.md`.

## Completed This Session (2026-04-07, session 5)

### E1.05 — Geoparquet Output (done — roadmap updated)

- [x] Roadmap updated: code already existed, checkboxes checked with evidence

### E1.08 — GitHub Pages Catalogue (done)

- [x] `src/generate-catalogue.ts` + 14 unit tests
- [x] `.github/workflows/catalogue.yml` deploys on release publish
- Note: GitHub Pages must be enabled in repo settings (source: GitHub Actions)

## Completed Prior Sessions

### E1.06 — Build Cache (in-progress)

- [x] `--dump-db` / `--restore-db` flags in docker-entrypoint.sh
- [x] `actions/cache@v4` integration in quarterly-build.yml
- [ ] Build time reduction verified in production (DEFERRED: v2026.05)

### E1.01 — Parquet Output (done — roadmap updated)

- [x] Roadmap updated to reflect PR #57 merge

## Remaining P4 Work (all BLOCKED)

### P4.03 — Build-Over-Build Comparison (in-progress)

- [ ] Needs second release to verify (v2026.05 expected May 2026)

### P4.06 — Runbook (in-progress)

- [ ] Tested by uninvolved person [BLOCKED: requires human tester]

### P4.07 — NSW Memory Optimisation (in-progress)

- [ ] NSW builds reliably on 7GB free runners (1/5 consecutive runs)

## Next E1 Work

### E1.10 — Shapefile Fixtures + Spatial Join Regression Test (done, PR #74)

- [x] Shapefile fixtures committed under `fixtures/admin-bdys/` + SQL seed at `fixtures/seed-admin-bdys.sql`
- [x] gnaf-loader prep SQL adapted to `fixtures/prep-admin-bdys.sql`; runs against seeded raw tables
- [x] Pre-baked `address_principal_admin_boundaries` block removed from `seed-postgres.sql`; boundaries derived via spatial join in fixture build
- Origin: PR #67 retrospective — fixture has no visibility into shapefile loading or spatial join, which is how both the v2026.04 wards crash and streetType regression slipped past CI

### E1.11 — Consolidate flatten SQL (done)

- [x] Single source of truth: `address_full.sql` → auto-generated `address_full_main.sql`

### E1.12 — Hardened verify checks (done)

- [x] All 6 enum-ish fields validated against authority tables in verify.ts
- [x] verification-report.ts includes per-field unknown value counts
- [x] Production builds now pass `--db-url` to verify (docker-entrypoint.sh)

### E1.13 — Patch release tooling (in-progress, p1-high)

- [x] Versioning convention for `vYYYY.MM.N` patch releases (PR #67)
- [x] `quarterly-build.yml` `patch_version` input (PR #67)
- [x] `docs/RELEASING.md` procedure (PR #67)
- [x] Build-over-build comparison skips count check for patches (PR #67)
- [x] Catalogue grouping for patches under parent quarterly cut
- [x] Auto-link fixing PR(s) in patch release notes
- [ ] Existing v2026.04 release notes updated to point at the patch (manual one-time edit)
- Origin: PR #67 — most of this ticket landed in PR #67 because the v2026.04 streetType fix needed it as a prerequisite

### E1.14 — Restore LGA / ward / state / commonwealth electorate fields (in-progress, **p0-critical**)

- [x] Root-cause the gnaf-loader shapefile loading failure — **FOUND:** `geoscape.py:import_shapefile_to_postgres()` never checks `process.returncode` after `shp2pgsql`. Empty stdout → empty SQL → no-op → returns "SUCCESS". Secondary: module-level DB connection in `settings.py` is not fork-safe with psycopg3.
- [x] Upstream fix PR to minus34/gnaf-loader OR local submodule patch with upstream PR open — **DONE:** [minus34/gnaf-loader#100](https://github.com/minus34/gnaf-loader/pull/100), submodule pinned to fork commit 45bd25f
- [x] Remove `--no-boundary-tag` from `docker-entrypoint.sh` — **DONE:** commit b9c07e8
- [x] Hardened verify check that fails the build if any of the four boundary coverage rates drops below threshold
- [x] CHANGELOG entry + RUNBOOK updated
- [ ] Restore lga / ward / stateElectorate / commonwealthElectorate population in next release [BLOCKED: needs v2026.05 build]
- [ ] v2026.04 release notes updated [BLOCKED: v2026.04.1 not published]
- Origin: PR #67 audit — **all four** boundary fields are null in v2026.04 (verified in released ACT file). Bigger quality regression than the streetType bug.

### E1.17 — De-hardcode G-NAF Feb 2026 (in-progress, **p0-critical**, blocks v2026.05) — code shipped, awaiting production validation

- [x] `src/download.ts` `resolveDataSources()` reads `DOWNLOAD_URL_GNAF` / `DOWNLOAD_URL_ADMIN_BDYS` env overrides (PRs #68/#69)
- [x] `src/load.ts` accepts `--geoscape-version` CLI arg, falls back to `GNAF_VERSION` env (PR #68)
- [x] `docker-entrypoint.sh` requires `GNAF_VERSION` for production builds (PR #69)
- [x] All 3 SQL files use `__SCHEMA_VERSION__` placeholder; `flatten.ts` substitutes at load time (PR #68)
- [x] Format validation added (`^[0-9]{6}$`) (PR #68)
- [ ] **Awaiting v2026.05 production validation** — the cron will fire on 2026-05-15 and prove the change works against new G-NAF data
- Origin: PR #67 rounds 5 + 6 — found by tracing `GNAF_VERSION` propagation. **Should land before v2026.05 quarterly cron (2026-05-15)** or every release after Feb 2026 will silently ship stale data labeled as new. **Download URL hardcoding is the worst — strictly worse than mislabeling, because it ships wrong data.**

### E1.18 — CHANGELOG `[Unreleased]` not cleared on release (done, PR #69 — verified by simulation)

- [x] Workflow Python script in `quarterly-build.yml` "Update CHANGELOG.md" step now extracts `[Unreleased]` body via regex, removes it from original position, re-inserts under the new versioned entry, leaves `[Unreleased]` empty
- [x] Idempotent on re-run (script removes any existing entry for the target version before inserting)
- Verified by simulating the script against current CHANGELOG with `release_version=2026.04.1` — output is correctly structured
- Origin: PR #67 round-5 audit — pre-existing workflow bug, makes CHANGELOG accumulate stale entries

### E1.16 — Geocode type field consistency (done, PR #70 — BREAKING)

- [x] Both `geocode.type` and `allGeocodes[].type` now use long-form names (e.g. `"FRONTAGE CENTRE SETBACK"` instead of `"FCS"`)
- [x] `address_full.sql` joins `geocode_type_aut gt_all` for the `all_geocodes` aggregation
- [x] BREAKING — `package.json` bumped to `0.2.0`. Consumers hardcoding `"FCS"`/`"PC"`/etc. must update.
- [x] `docs/DOCUMENT-SCHEMA.md` updated
- Origin: PR #67 round-3 field audit — found during comprehensive v2026.04 ACT inspection

### E1.15 — Fix multi-polygon row multiplication in PR #66 spatial join (DONE in PR #66, p1-high)

- [x] LEFT JOIN LATERAL (...) LIMIT 1 — guarantees one row per (address, boundary table)
- [x] UNIQUE INDEX on `gnaf_pid` — structural guarantee against duplicates
- [x] Verified end-to-end against empty target with stub boundary tables (451 rows in, 451 rows out, 0 duplicates)
- Resolution: fixed in PR #66 itself before merging — chosen over LEFT JOIN+DISTINCT ON because LATERAL+LIMIT scopes the deduplication to each boundary table independently and is more readable

### E1.19 — Stale `2026.02` references in user-facing docs (done)

- [x] DOCUMENT-SCHEMA.md `_version` examples + parquet/geoparquet code examples (~6 instances)
- [x] RUNBOOK.md failure-recovery command examples → `${VERSION}` placeholders
- [x] COMMUNITY-ANNOUNCEMENT.md target version reference updated
- [x] Convention documented in `docs/RELEASING.md` (two-tier: consumer-facing uses current version, operational uses `${VERSION}`)
- Origin: PR #77 audit — README VERSION example was the highest-impact and got fixed in #77; rest filed for follow-up

### E1.02 — Delta Builds (planned, p2-medium)

- [ ] Depends on P4.03

## Reference Files

| Need               | Read this                               | NOT this                     |
| ------------------ | --------------------------------------- | ---------------------------- |
| Table schemas      | `fixtures/SCHEMA-REFERENCE.md`          | `fixtures/seed-postgres.sql` |
| Field provenance   | `docs/FIELD-PROVENANCE.md`              | —                            |
| Document schema    | `docs/DOCUMENT-SCHEMA.md`               | —                            |
| Flatten SQL        | `sql/address_full.sql`                  | —                            |
| Self-hosted runner | `docs/SELF-HOSTED-RUNNER.md`            | —                            |
| Quarterly build    | `.github/workflows/quarterly-build.yml` | —                            |
| Docker publish     | `.github/workflows/docker-publish.yml`  | —                            |
| Catalogue          | `.github/workflows/catalogue.yml`       | —                            |
| Agent rules        | `CLAUDE.md` (auto-loaded)               | —                            |
