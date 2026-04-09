# Next Work — flat-white

> Updated: 2026-04-09. Active phase: E1 (Ongoing) — P4 blocked. Per-session log lives in `NEXT-SESSION.md`.

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

- [ ] NSW builds reliably on 7GB free runners (**2/5** consecutive runs as of 2026-04-09; quarterly run 24163471133 added the second clean cycle. E1.21 made the spatial join fast enough that the pressure scenarios that motivated this ticket may no longer fire — but the literal 5/5 acceptance criterion needs 3 more clean cron cycles to count down naturally.)

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
- [x] ~~Existing v2026.04 release notes updated to point at the patch (manual one-time edit)~~ **CLOSED-OBSOLETE 2026-04-09:** v2026.04 release was deleted entirely on 2026-04-09 (it shipped with all-null boundary fields and was superseded by v2026.02.1). There are no v2026.04 release notes to update. The git tag `v2026.04` survives for history; the release page is gone.
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

### E1.20 — Push gnaf-loader settings.py / 04-06 fix upstream (deferred, p4-defer)

- [ ] **2026-04-09: downgraded.** Obsoleted by E1.21 (PR #106 — flat-white spatial join is now fast enough) and E1.23 (queued — collapse Path 1/2 means we never call gnaf-loader Part 5). Revisit only if E1.23 is cancelled OR for community-contribution reasons.

### E1.21 — Optimise spatial-join fallback for NSW scale (DONE 2026-04-09, PR #106)

- [x] Rewrite `address_full_prep.sql` spatial join fallback as **insert-then-5-updates against unsubdivided polygon tables** (NOT the DISTINCT ON or ST_Subdivide approaches in the original ticket — see ROADMAP entry for full reasoning)
- [x] Preserve one-row-per-address guarantee (E1.15 multi-polygon safety)
- [x] Performance: NSW spatial join 67 min → 7.5 min on M5; CI quarterly run 24163471133 NSW total job time 29m20s with cache hit
- [x] Output byte-identical to LATERAL approach (fixture cross-path PASS, all 9 states in v2026.02.1 verify-PASS)
- [x] Quarterly run 24163471133 publishes v2026.02.1 with all 9 states green for the first time
- Origin: "permanent fix" PR. See ROADMAP entry E1.21 for empirical evidence table and full implementation reasoning.

### E1.23 — Collapse Path 1 and Path 2 into a single path (planned, p2-medium)

- [ ] Always pass `--no-boundary-tag`; never call gnaf-loader Part 5
- [ ] Delete `scripts/detect-load-failure.sh` + `test/integration/load-detection/`
- [ ] Remove `--no-boundary-tag` retry branch from `docker-entrypoint.sh`
- [ ] Rewrite `docs/BOUNDARIES.md` for single path
- Origin: now possible because E1.21 made Path 2 as fast as Path 1. Removes ~100 lines and a whole class of failure modes. Depends on E1.24 (do that first since it touches `src/flatten.ts` which E1.23 will also coordinate with).

### E1.24 — Flatten temp tables disappear when prep SQL runs twice (planned, p2-medium)

- [ ] Read `src/flatten.ts` to understand connection/session management
- [ ] Confirm or reject "two postgres clients" hypothesis
- [ ] Fix root cause (refactor to single client OR transaction wrapping OR keep-alive ping)
- [ ] Add regression test
- Origin: `tmp_address_geocodes does not exist` crashes hit during the E1.21 implementation session against the OLD LATERAL code (NSW2, NSW3) and in failed quarterly run 24138309484 (NSW/SA/TAS exit 3 in flatten). Currently masked by E1.21 making the spatial join fast; will re-emerge if Path 2 ever slows again. **Should fix BEFORE E1.23.**

### E1.25 — docker-entrypoint.sh `--skip-download` env-var gap (planned, p3-low)

- [ ] Move `GNAF_DATA_PATH` / `ADMIN_BDYS_PATH` exports outside the download branch
- Origin: discovered during E1.21 implementation session. 2-line fix; bundle into any small workflow PR.

### E1.26 — WA flatten 40-75× slower when restored from cache (planned, p2-medium)

- [ ] Repro on M5 (fresh build → pg_dump → restore → measure cursor stream)
- [ ] Validate ANALYZE-after-restore hypothesis (or dig deeper if wrong)
- [ ] Add ANALYZE step to `docker-entrypoint.sh` cache restore path (or `validate-db-cache.sh`)
- [ ] Verify via quarterly workflow_dispatch
- Origin: forensic scan of quarterly run 24163471133 (2026-04-09). WA cursor stream rate 442 rows/sec vs other states' 15-33k rows/sec. Same code, same data; only difference is cache restore. **Should fix BEFORE 2026-05-15 cron.**

### E1.27 — Release CHANGELOG.md push fails on branch protection (planned, p3-low)

- [ ] Workflow opens a PR (`gh pr create --auto-merge`) instead of pushing direct
- [ ] Smoke test via workflow_dispatch
- [ ] Verify no infinite-loop risk from PR-merge → main-push → re-trigger
- Origin: forensic scan of quarterly run 24163471133. The release publishes successfully but CHANGELOG.md drift accumulates on main. **Should fix BEFORE 2026-05-15 cron.**

### E1.28 — Catalogue workflow never triggered (planned, p3-low)

- [ ] Switch trigger from `release.published` to `workflow_run` listening to "Quarterly Build" completed
- [ ] Manually trigger catalogue workflow against v2026.02.1 to backfill
- [ ] Verify GitHub Pages catalogue updates correctly
- Origin: forensic scan. Catalogue workflow has 0 runs since creation 2026-04-07 because GitHub Actions doesn't fire workflow events from GITHUB_TOKEN-created releases (recursion prevention). **Should fix BEFORE 2026-05-15 cron.**

### E1.29 — Upgrade GitHub Actions to Node.js 24 (DONE 2026-04-09, PR #117)

- [x] Bump `actions/cache@v4`, `actions/checkout@v4`, `actions/upload-artifact@v4`, `actions/download-artifact@v4`, `actions/setup-node@v4`, `docker/build-push-action@v6`, `docker/setup-buildx-action@v3` to Node 24-compatible versions
- [x] Verify zero "Node.js 20 deprecated" annotations on a fresh workflow run
- [x] Smoke test via workflow_dispatch
- All 12 JavaScript actions bumped to node24-native versions. No env var workaround — proper version bumps. Verified by CI on PR #117 (all checks pass on Node 24) + post-merge s3-smoke run (zero deprecation warnings).
- Origin: GitHub Actions deprecation. Node 20 forced default 2026-06-02; full removal 2026-09-16.

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
