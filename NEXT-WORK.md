# Next Work — flat-white

> Updated: 2026-04-04. Active phase: P1 (P0 blocked on P0.04).

## Completed This Session (2026-04-04)

### P1.12 — Output Metadata (done)

- [x] `src/metadata.ts` — generates metadata JSON with version, per-state counts, schema version, build timestamp, gnaf-loader version
- [x] `test/unit/metadata.test.ts` — 7 unit tests including fixture validation

### P1.13 — Per-State Split (done)

- [x] `src/split.ts` — streaming per-state NDJSON splitter with backpressure handling
- [x] `test/unit/split.test.ts` — 4 unit tests: multi-state split, single-state, count sum, content preservation

### P1.14 — Gzip Compression (done)

- [x] `src/compress.ts` — streaming gzip compression using Node.js pipeline
- [x] `test/unit/compress.test.ts` — 5 unit tests: valid gzip, size metrics, ratio, levels, fixture compression

### Prior Session Work (still valid)

- P1.01–P1.09 — Core flatten pipeline (recognized as done)
- P1.10 + P1.10A — Verification & data quality checks
- P1.15 — Regression tests (enhanced)

## Remaining Tickets

### P0.04 — gnaf-loader VIC Load (planned, blocked)

- Requires 6.5GB download + Python gnaf-loader. Cannot be done in sandbox.
- Blocks: P1.11 (Full VIC Build), P1.16 (Performance Baseline)

### P1.11 — Full VIC Build (blocked on P0.04)

- End-to-end pipeline at production scale (~3.8M addresses)

### P1.16 — Performance Baseline (blocked on P1.11)

- Docs: VIC build time, peak memory, output file sizes

### P2.01+ — Container & Distribution (blocked on P1.11)

- Dockerfile, entrypoint, CLI, exit codes, CI

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
