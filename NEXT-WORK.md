# Next Work — flat-white

> Updated: 2026-04-04. Active phase: P1 (P0 blocked on P0.04).

## Completed This Session (2026-04-04)

### P4.05 — gnaf-loader Tracking (done)

- [x] `.github/workflows/gnaf-loader-update.yml` — weekly check for upstream releases, auto-PR on update
- [x] All 3 DoD items verified with evidence from workflow file

### P2.08 — Fixture CI (done)

- [x] `.github/workflows/ci.yml` — runs lint, typecheck, test, build-fixture-only.sh on every PR
- [x] CI completes in 39-42s (under 60s target)
- [x] Schema changes caught via byte-for-byte diff + regression tests

## Remaining Tickets

### P0.04 — gnaf-loader VIC Load (planned, blocked)

- Requires 6.5GB download + Python gnaf-loader. Cannot be done in sandbox.
- Blocks: P1.11, P1.16, P2.01-P2.07, P3.x, P4.x

### P1.11 — Full VIC Build (blocked on P0.04)

- End-to-end pipeline at production scale (~3.8M addresses)

### P1.16 — Performance Baseline (blocked on P1.11)

- Docs: VIC build time, peak memory, output file sizes

### E1.03 — Locality-Only Output (unblocked, depends on P1.05 done)

- `--locality-only` flag produces `localities.ndjson`
- Only unblocked feature work remaining

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
