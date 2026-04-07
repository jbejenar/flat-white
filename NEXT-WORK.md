# Next Work — flat-white

> Updated: 2026-04-07. Active phase: E1 (Ongoing) — P4 blocked.

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

### E1.10 — Shapefile Fixtures + Spatial Join Regression Test (planned, p1-high)

- [ ] Commit clipped shapefile fixtures + wire shp2pgsql into fixture build
- [ ] Run gnaf-loader prep SQL against seeded raw tables; derive `admin_bdys_202602.*`
- [ ] Remove pre-baked `address_principal_admin_boundaries` rows from `seed-postgres.sql`
- Origin: PR #67 retrospective — fixture has no visibility into shapefile loading or spatial join, which is how both the v2026.04 wards crash and streetType regression slipped past CI

### E1.11 — Consolidate flatten SQL (planned, p1-high)

- [ ] Pick one of: generated materialize SQL, single-file with mode flag, templating layer
- [ ] Eliminate possibility of drift between legacy and materialize paths by construction
- Origin: PR #67 — root cause of streetType regression was hand-maintained drift between two parallel SQL files

### E1.12 — Hardened verify checks (planned, p2-medium)

- [ ] Validate `streetType`, `flatType`, `levelType`, `streetSuffix`, `localityClass`, `state` against authority tables
- [ ] Surface unknown values in verification report
- Origin: PR #67 — Zod schema only constrains type, not content; bug shipped because verify had no opinion on the _value_

### E1.13 — Patch release tooling (in-progress, p1-high)

- [x] Versioning convention for `vYYYY.MM.N` patch releases (PR #67)
- [x] `quarterly-build.yml` `patch_version` input (PR #67)
- [x] `docs/RELEASING.md` procedure (PR #67)
- [x] Build-over-build comparison skips count check for patches (PR #67)
- [ ] Catalogue grouping for patches under parent quarterly cut (E1.08 enhancement)
- [ ] Auto-link fixing PR(s) in patch release notes (currently manual)
- Origin: PR #67 — most of this ticket landed in PR #67 because the v2026.04 streetType fix needed it as a prerequisite

### E1.14 — Restore LGA / ward / state / commonwealth electorate fields (planned, **p0-critical**)

- [ ] Root-cause the gnaf-loader shapefile loading failure (suspected: worker-pool issue in `multiprocess_shapefile_load`, unconfirmed)
- [ ] Upstream fix PR to minus34/gnaf-loader OR local submodule patch with upstream PR open
- [ ] Remove `--no-boundary-tag` from `docker-entrypoint.sh`
- [ ] Hardened verify check that fails the build if any of the four boundary coverage rates drops below threshold
- [ ] Restore lga / ward / stateElectorate / commonwealthElectorate population in next release
- Origin: PR #67 audit — **all four** boundary fields are null in v2026.04 (verified in released ACT file). Bigger quality regression than the streetType bug.

### E1.17 — De-hardcode G-NAF schema version (planned, **p0-critical**, blocks v2026.05)

- [ ] `src/load.ts` accept `--geoscape-version` CLI arg (currently hardcoded to `202602`)
- [ ] `docker-entrypoint.sh` derive schema version from `GNAF_VERSION` and pass to load.ts
- [ ] Replace hardcoded `gnaf_202602` / `raw_gnaf_202602` / `admin_bdys_202602` in 3 SQL files with template substitution or `search_path`
- [ ] Add regression test against a non-Feb-2026 schema name
- Origin: PR #67 round-5 audit — found while tracing how `GNAF_VERSION` propagates. **Should land before v2026.05 quarterly cron (2026-05-15)** or every release after Feb 2026 will have implicit `_version`/schema mismatch

### E1.18 — CHANGELOG `[Unreleased]` not cleared on release (planned, p3-low)

- [ ] Workflow CHANGELOG step should MOVE Unreleased content into the new versioned section, not just insert above it
- [ ] Idempotency: re-running shouldn't duplicate entries
- Origin: PR #67 round-5 audit — pre-existing workflow bug, makes CHANGELOG accumulate stale entries

### E1.15 — Fix multi-polygon row multiplication in PR #66 spatial join (planned, p1-high)

- [ ] PR #66's spatial join fallback uses `LEFT JOIN ... ST_Intersects` four times — boundary points cartesian-multiply
- [ ] No UNIQUE constraint on `address_principal_admin_boundaries.gnaf_pid` to catch duplicates
- [ ] Currently latent (the fallback is a no-op in v2026.04 because boundary tables don't exist); becomes active the moment E1.14 lands
- [ ] Fix: `ST_Within` + `DISTINCT ON (gnaf_pid)` fallback, plus a UNIQUE constraint
- Origin: PR #67 audit — found while tracing the all-null boundary fields in v2026.04

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
