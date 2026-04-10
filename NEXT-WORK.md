# Next Work — flat-white

> Updated: 2026-04-10. All implementation work complete. Next event: v2026.05 cron fires 2026-05-15.

## Completed (2026-04-10, session 6)

### E1.21 — Bulk spatial join optimisation (done, PR #106)

- [x] NSW spatial join 67min → 7.5min; all 9 states under budget

### E1.22 — Fix extract-fixtures.sh naming (done, PR #120)

- [x] `abs_2021_mb_lookup` → `abs_2021_mb` (matches production gnaf-loader)

### E1.23 — Collapse dual-path architecture (done, PR #120)

- [x] Always `--no-boundary-tag`, deleted detect-load-failure.sh + retry branch

### E1.24–E1.29 — Latent bug fixes (done, PRs #112–#117, #120)

- [x] E1.24: flatten.ts session management (sql.reserve + max_lifetime: null)
- [x] E1.25: docker-entrypoint.sh env-var gap
- [x] E1.26: ANALYZE after cache restore
- [x] E1.27: CHANGELOG PR instead of direct push
- [x] E1.28: Catalogue workflow trigger fix
- [x] E1.29: GitHub Actions Node.js 24 upgrade

### P5.01 — S3 upload (done, PR #111)

- [x] Staging → verify → promote → manifest ordering

### P5.03 — OIDC auth (done, PR #120)

- [x] aws-actions/configure-aws-credentials with role-to-assume

### P5.02 — S3 latest pointer (wont-do, removed in PR #131)

- [x] Not part of original design; versioned manifests are canonical

### P5.04 — SNS notification (wont-do, removed in PR #131)

- [x] No topic subscribers exist; can re-add when demand emerges

### S3 convention fix (PR #131)

- [x] All-states file uploaded to data/address/{version}/all.ndjson.gz
- [x] Latest pointer removed
- [x] SNS step removed

### Deps rollup (PR #129)

- [x] postgres 3.4.9, vitest 4.1.4, @types/node 25.5.2, eslint 10.2.0, typescript-eslint 8.58.1

## Completed (2026-04-07, session 5)

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

## Awaiting v2026.05 (cron fires 2026-05-15, no action needed until then)

### P4.03 — Build-Over-Build Comparison

- [ ] Needs second release to verify (v2026.05)

### P4.06 — Runbook

- [ ] Tested by uninvolved person [BLOCKED: requires human tester]

### P4.07 — NSW Memory Optimisation

- [ ] NSW builds reliably on 7GB free runners (2/5 consecutive; needs 3 more clean cron cycles)

### E1.14 — Restore boundary field population

- [x] All code shipped (gnaf-loader fix, verify gate, CHANGELOG)
- [ ] Awaiting v2026.05 build to confirm fields populate in production

### E1.17 — De-hardcode G-NAF version

- [x] All code shipped (download.ts, load.ts, SQL placeholders, entrypoint)
- [ ] Awaiting v2026.05 cron to validate against new G-NAF data
- [x] Convention documented in `docs/RELEASING.md` (two-tier: consumer-facing uses current version, operational uses `${VERSION}`)
- Origin: PR #77 audit — README VERSION example was the highest-impact and got fixed in #77; rest filed for follow-up

### E1.20 — Push gnaf-loader settings.py / 04-06 fix upstream (deferred, p4-defer) — **wont-do**

- [ ] **2026-04-09: downgraded.** Obsoleted by E1.21 (PR #106 — flat-white spatial join is now fast enough) and E1.23 (queued — collapse Path 1/2 means we never call gnaf-loader Part 5). Revisit only if E1.23 is cancelled OR for community-contribution reasons.
- **2026-04-09: marked wont-do in ROADMAP.** E1.23 is now complete — flat-white never calls gnaf-loader Part 5, so this upstream fix has no load-bearing value for flat-white.

### E1.21 — Optimise spatial-join fallback for NSW scale (DONE 2026-04-09, PR #106)

- [x] Rewrite `address_full_prep.sql` spatial join fallback as **insert-then-5-updates against unsubdivided polygon tables** (NOT the DISTINCT ON or ST_Subdivide approaches in the original ticket — see ROADMAP entry for full reasoning)
- [x] Preserve one-row-per-address guarantee (E1.15 multi-polygon safety)
- [x] Performance: NSW spatial join 67 min → 7.5 min on M5; CI quarterly run 24163471133 NSW total job time 29m20s with cache hit
- [x] Output byte-identical to LATERAL approach (fixture cross-path PASS, all 9 states in v2026.02.1 verify-PASS)
- [x] Quarterly run 24163471133 publishes v2026.02.1 with all 9 states green for the first time
- Origin: "permanent fix" PR. See ROADMAP entry E1.21 for empirical evidence table and full implementation reasoning.

### E1.23 — Collapse Path 1 and Path 2 into a single path (DONE 2026-04-09)

- [x] Always pass `--no-boundary-tag`; never call gnaf-loader Part 5
- [x] Delete `scripts/detect-load-failure.sh` + `test/integration/load-detection/`
- [x] Remove `--no-boundary-tag` retry branch from `docker-entrypoint.sh`
- [x] Rewrite `docs/BOUNDARIES.md` for single path
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
