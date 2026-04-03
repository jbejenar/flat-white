# Next Work — flat-white

> Updated: 2026-04-04. Active phase: P1 (P0 blocked on P0.04).

## Completed This Session

### P1.01–P1.09 — Core Flatten Pipeline (recognized as done)

All core flatten features were already implemented during P0.09/P0.10 work:

- Streaming cursor-based flatten (P1.01)
- Alias, secondary, multi-geocode aggregation (P1.02–P1.04)
- Locality, boundary, street enrichment (P1.05–P1.07)
- addressLabelSearch with expanded types (P1.08)
- Zod schema validation during flatten (P1.09)

### P1.10 + P1.10A — Verification & Data Quality (new code)

- [x] `src/verify.ts` — row count verification + data quality checks
- [x] Coordinate bounding box, PID uniqueness, state/postcode, boundary coverage
- [x] 22 unit tests + fixture integration tests passing

### P1.15 — Regression Tests (enhanced)

- [x] Enhanced with coordinate bounds check and full verify() suite

## Remaining Tickets

### P0.04 — gnaf-loader VIC Load (planned, blocked)

- Requires 6.5GB download + Python gnaf-loader. Cannot be done in sandbox.
- Blocks: P1.11 (Full VIC Build), P1.12–P1.14, P1.16

### P1.11 — Full VIC Build (blocked on P0.04)

- End-to-end pipeline at production scale (~3.8M addresses)

### P1.12–P1.14, P1.16 — Output pipeline (blocked on P1.11)

- Output metadata, per-state split, gzip compression, performance baseline

## Reference Files

| Need             | Read this                      | NOT this                     |
| ---------------- | ------------------------------ | ---------------------------- |
| Table schemas    | `fixtures/SCHEMA-REFERENCE.md` | `fixtures/seed-postgres.sql` |
| Field provenance | `docs/FIELD-PROVENANCE.md`     | —                            |
| Document schema  | `docs/DOCUMENT-SCHEMA.md`      | —                            |
| Flatten SQL      | `sql/address_full.sql`         | —                            |
| Verification     | `src/verify.ts`                | —                            |
| Agent rules      | `CLAUDE.md` (auto-loaded)      | —                            |
