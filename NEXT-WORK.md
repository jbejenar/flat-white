# Next Work — flat-white

> Updated: 2026-04-05. Active phase: P3 (1 ticket remaining).

## Completed This Session (2026-04-05)

### P3.03 — GitHub Release Creation (done — verified existing implementation)

- [x] Tagged release with all 12 assets (9 per-state + all-states + metadata + schema)
- [x] Total asset size under 2GB verified
- [x] All states present — 12-asset count check
- [x] Programmatic download test
- [x] CHANGELOG.md auto-updated

### P3.04 — Release Notes (done — verified existing implementation)

- [x] Auto-generated: total/per-state counts, delta, schema version, gnaf-loader version
- [x] Human-readable markdown with formatted numbers

### P3.05 — Downstream Dispatch (done)

- [x] `repository_dispatch` to geocode-au with version payload
- [x] Payload: version, tag, asset URL pattern, metadata URL, release URL

### P3.06 — Download Docs (done)

- [x] README: gh CLI, curl, CI/API download examples
- [x] Consumer verification one-liner

## Remaining P3 Work

### P3.07 — Adoption & Discovery (planned)

- [ ] Quick Start section in README (partially exists — may need DuckDB example expansion)
- [ ] data.gov.au derivative dataset listing
- [ ] Community announcement plan

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
