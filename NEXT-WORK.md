# Next Work — flat-white

> Updated: 2026-04-04. Active phase: P2 complete → P3 next.

## Completed This Session (2026-04-04)

### P2.02 — Entrypoint (done)

- [x] Full pipeline orchestration: postgres → download → load → flatten → verify → split → compress
- [x] Each stage logged with start/end timestamps
- [x] Postgres started before data work, stopped via EXIT trap

### P2.03 — CLI Arguments (done)

- [x] All 8 flags: --states, --output, --split-states, --compress, --skip-download, --gnaf-path, --admin-path, --fixture-only
- [x] --help with full flag docs, exit codes, pipeline stages
- [x] Invalid flag combination errors (4 combos validated)

### P2.04 — Exit Codes (done)

- [x] Exit codes 0-5 per failure type (download/load/flatten/verify/output)
- [x] Deterministic per stage, CI-distinguishable

### P2.05 — Volume Mount (done)

- [x] `/output` default, `VOLUME ["/output"]` in Dockerfile
- [x] File permissions: world-readable by default

### P2.06 — Progress Logging (done)

- [x] Structured JSON progress logs (ProgressLogger class + bash log_json)
- [x] Human-readable + machine-parseable (message field + jq-compatible)
- [x] 30s debounced progress updates during flatten stage

### P2.07 — Image Publish (done)

- [x] GitHub Actions workflow for Docker Hub publish on v\* tags
- [x] Version + latest tagging

## P2 Phase Status: COMPLETE

All 8 P2 tickets done (P2.01–P2.08). Next phase: P3.

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
