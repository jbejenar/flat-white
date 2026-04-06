# Next Work — flat-white

> Updated: 2026-04-06. Active phase: E1 (Ongoing) — P4 blocked.

## Completed This Session (2026-04-06, session 4)

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

### E1.05 — Geoparquet Output (planned, p2-medium)

- [ ] `--format geoparquet` produces valid Geoparquet file with POINT geometry
- [ ] Geoparquet metadata follows spec

### E1.02 — Delta Builds (planned, p2-medium)

- [ ] Depends on P4.03

### E1.08 — GitHub Pages Catalogue (planned, p2-medium)

- [ ] Static site with release history, stats, schema docs, download links

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
| Agent rules        | `CLAUDE.md` (auto-loaded)               | —                            |
