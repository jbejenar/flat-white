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

### E1.13 — Patch release tooling (planned, p2-medium)

- [ ] Versioning convention for `vYYYY.MM.N` patch releases
- [ ] `quarterly-build.yml` `patch_version` input
- [ ] Catalogue grouping for patches under parent quarterly cut
- Origin: PR #67 — v2026.04 needs a patch release for the streetType fix but there is no tooling for it

### E1.14 — Remove `--no-boundary-tag` workaround (planned, p1-high)

- [ ] Root-cause the gnaf-loader wards loading failure (suspected: worker-pool issue in `multiprocess_shapefile_load`, unconfirmed)
- [ ] Upstream fix PR to minus34/gnaf-loader OR local submodule patch with upstream PR open
- [ ] Remove `--no-boundary-tag` from `docker-entrypoint.sh`
- [ ] Restore `wardName` population in next release
- Origin: PR #67 audit — every v2026.04 document has `wardName: null` because of this workaround

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
