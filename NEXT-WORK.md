# Next Work — flat-white

> Updated: 2026-04-06. Active phase: P4 (Hardening).

## Completed This Session (2026-04-06)

### P4.01 — All-States Production Release (done)

- [x] All 9 states built successfully (15,015,573 total, 23m55s wall-clock)
- [x] GitHub Release v2026.04 published with 12 assets
- [x] All assets valid (schema, quality, PID uniqueness all PASS)

### P4.02 — Verification Report (done)

- [x] Report generated: per-state row counts, boundary coverage %, schema validation
- [x] Report uploaded as release asset (verification-report.md)

### P3.01 — Matrix Build Workflow (wall-clock verified)

- [x] Total wall-clock time 23m55s (under 60 minute target)

## Remaining P4 Work

### P4.03 — Build-Over-Build Comparison (in-progress)

- Code complete and integrated into workflow
- [ ] Needs second release to verify (v2026.05 expected May 2026)
- [ ] Anomaly detection >1% verified by unit tests only

### P4.06 — Runbook (in-progress)

- [x] Runbook written (docs/RUNBOOK.md)
- [ ] Tested by uninvolved person [BLOCKED: requires human tester]

### P4.07 — NSW Memory Optimisation (planned)

- [ ] NSW builds reliably on 7GB free runners (5 consecutive runs)
- [ ] Peak memory usage documented
- [ ] Build time under 60 minutes

## Known Data Quality Note

LGA/ward/electorate boundaries are NULL (0% coverage) due to `--no-boundary-tag` in Docker build.
Cause: gnaf-loader crashes on Feb 2026 admin boundaries wards table naming change.
ABS boundaries (meshBlock/SA1/SA2) at 100%. Tracked by P4.05 gnaf-loader update check.

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
