# Next Work — flat-white

> Updated: 2026-04-05. Active phase: P3 nearly complete → P4 next.

## Completed This Session (2026-04-05)

### P3.03 — GitHub Release Creation (done)

- [x] Tagged release with all assets (per-state + all-states + metadata + schema)
- [x] Asset size verification (under 2GB)
- [x] 12-asset count verification
- [x] Programmatic download test
- [x] CHANGELOG auto-update

### P3.04 — Release Notes (done)

- [x] Auto-generated notes with total/per-state counts, delta, schema version, gnaf-loader version
- [x] Readable markdown format

### P3.05 — Downstream Dispatch (done)

- [x] `repository_dispatch` to geocode-au with version payload
- [x] Asset URLs in payload

### P3.06 — Download Docs (done)

- [x] gh CLI + curl download examples in README
- [x] API-based download for CI/scripts
- [x] Consumer verification one-liner

### P3.07 — Adoption & Discovery (in-progress)

- [x] Quick Start in README
- [ ] data.gov.au listing [DEFERRED: manual submission after first release]
- [x] Community announcement plan in docs/COMMUNITY-ANNOUNCEMENT.md

## P3 Phase Status: 6/7 done, 1 in-progress

All functional tickets complete. P3.07 has 1 DEFERRED item (data.gov.au listing). Next phase: P4.

## Reference Files

| Need             | Read this                               | NOT this                     |
| ---------------- | --------------------------------------- | ---------------------------- |
| Table schemas    | `fixtures/SCHEMA-REFERENCE.md`          | `fixtures/seed-postgres.sql` |
| Field provenance | `docs/FIELD-PROVENANCE.md`              | —                            |
| Document schema  | `docs/DOCUMENT-SCHEMA.md`               | —                            |
| Flatten SQL      | `sql/address_full.sql`                  | —                            |
| Verification     | `src/verify.ts`                         | —                            |
| Metadata         | `src/metadata.ts`                       | —                            |
| Split            | `src/split.ts`                          | —                            |
| Compress         | `src/compress.ts`                       | —                            |
| Quarterly build  | `.github/workflows/quarterly-build.yml` | —                            |
| Community plan   | `docs/COMMUNITY-ANNOUNCEMENT.md`        | —                            |
| Agent rules      | `CLAUDE.md` (auto-loaded)               | —                            |
