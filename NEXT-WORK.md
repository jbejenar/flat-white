# Next Work — flat-white

> Updated: 2026-04-04. Active phase: P2 (Container).

## Completed This Session (2026-04-04)

### P2.02 — Entrypoint (done)

- [x] Full pipeline orchestration: postgres → download → load → flatten → verify → split → compress
- [x] Each stage logged with start/end timestamps
- [x] Postgres started before data work, stopped via EXIT trap

### P2.04 — Exit Codes (done)

- [x] Exit codes 0-5 per failure type (download/load/flatten/verify/output)
- [x] Deterministic per stage, CI-distinguishable

### P2.05 — Volume Mount (done)

- [x] `/output` default, `VOLUME ["/output"]` in Dockerfile
- [x] File permissions: world-readable by default

## Remaining Tickets

### P2.03 — CLI Arguments (planned, unblocked — depends on P2.02 done)

- `--states`, `--output`, `--split-states`, `--compress`, `--skip-download`, `--gnaf-path`, `--admin-path`, `--fixture-only`
- `--help` with full flag docs
- Invalid flag combination errors

### P2.06 — Progress Logging (planned, unblocked — depends on P2.02 done)

- Structured JSON progress logs
- Human-readable + machine-parseable
- Updates every 30s during long stages

### P2.07 — Image Publish (planned, unblocked — depends on P2.01 done)

- GitHub Actions workflow for Docker Hub publish on tags
- Version + latest tagging

## Reference Files

| Need             | Read this                      | NOT this                     |
| ---------------- | ------------------------------ | ---------------------------- |
| Table schemas    | `fixtures/SCHEMA-REFERENCE.md` | `fixtures/seed-postgres.sql` |
| Field provenance | `docs/FIELD-PROVENANCE.md`     | —                            |
| Document schema  | `docs/DOCUMENT-SCHEMA.md`      | —                            |
| Flatten SQL      | `sql/address_full.sql`         | —                            |
| Verification     | `src/verify.ts`                | —                            |
| Metadata         | `src/metadata.ts`              | —                            |
| Split            | `src/split.ts`                 | —                            |
| Compress         | `src/compress.ts`              | —                            |
| Agent rules      | `CLAUDE.md` (auto-loaded)      | —                            |
