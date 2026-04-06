# Next Work — flat-white

> Updated: 2026-04-06. Active phase: E1 (Ongoing) — P4 blocked.

## Completed This Session (2026-04-06, session 3)

### E1.09 — Self-Hosted Runner Fallback (done)

- [x] docs/SELF-HOSTED-RUNNER.md: hardware reqs, runner setup, workflow config, cost estimates
- [x] quarterly-build.yml: `runner` input for `workflow_dispatch` targeting

### E1.07 — Multi-Arch Image (done)

- [x] docker-publish.yml: ARM64 + AMD64 via QEMU + buildx
- [x] Cross-arch verification: fixture-only build + SHA-256 checksum comparison

## Remaining P4 Work (all BLOCKED)

### P4.03 — Build-Over-Build Comparison (in-progress)

- [ ] Needs second release to verify (v2026.05 expected May 2026)

### P4.06 — Runbook (in-progress)

- [ ] Tested by uninvolved person [BLOCKED: requires human tester]

### P4.07 — NSW Memory Optimisation (in-progress)

- [ ] NSW builds reliably on 7GB free runners (1/5 consecutive runs)

## Next E1 Work

### E1.01 — Parquet Output (planned, p1-high)

- [ ] `--format parquet` produces valid Parquet file
- [ ] Parquet schema matches NDJSON document schema

### E1.06 — Build Cache (planned, p1-high)

- [ ] Postgres dump cached after gnaf-loader (keyed by G-NAF version + state)
- [ ] Cache miss triggers full load
- [ ] Build time reduced ~30 min on cache hit

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
