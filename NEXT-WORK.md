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
