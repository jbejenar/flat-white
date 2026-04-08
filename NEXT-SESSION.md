# Next Session — flat-white

## Session: 2026-04-08 (session 20)

Phase: P0 (active — 1 unchecked DoD item found) + E1 (ongoing)
Checkboxes checked this session: 1 (P0.07 extract-fixtures.sh)

### Completed

- **P0.07** — `scripts/extract-fixtures.sh` fully automated: selects fixture PIDs, derives related entity sets, extracts DDL + filtered data for all 25 tables via pg_dump/psql, filters cross-subset FK constraints, assembles complete `seed-postgres.sql`. Script cannot be end-to-end verified without a full VIC gnaf-loader load (6.5 GB dataset not in dev), but bash syntax is valid and logic matches the existing hand-assembled file structure.

### Ticket Status Changes

- P0.07: done (all 4 DoD items now checked — was missing the extract-fixtures.sh automation)

### In Progress (all BLOCKED — unchanged since session 13)

- E1.14 — 2 items BLOCKED: boundary field population (needs v2026.05), release notes update (needs v2026.04.1)
- E1.17 — 1 item BLOCKED: needs May 2026 G-NAF data
- E1.13 — 1 item BLOCKED: v2026.04.1 not published
- P4.07 — NSW memory: needs 4 more consecutive runs
- P4.03 — Build comparison: needs second release
- P4.06 — Runbook: needs human tester
- E1.06 — Build cache: needs production build

### Key Dates

- **2026-05-01 (approx):** May 2026 G-NAF data available — unblocks E1.17 final validation
- **2026-05-15:** Quarterly cron fires — E1.14 + E1.17 must be validated by then or v2026.05 ships with same issues as v2026.04

### Next Session Should Start With

1. **Check upstream PR status:** If minus34/gnaf-loader#100 is merged, update .gitmodules back to minus34/gnaf-loader and update submodule pin
2. **v2026.05 prep:** E1.14 + E1.17 are the two critical blockers. Once May data is available, run a test build to validate both
3. **E1.13:** Update v2026.04 release notes when v2026.04.1 publishes
4. **If all above still blocked:** No actionable roadmap items remain — skip sessions until ~May 2026

### Roadmap Progress

- P0: All DoD items checked (P0.07 extract-fixtures.sh was the last unchecked)
- E1: 11/18 tickets done, 4 in-progress (E1.06, E1.13, E1.14, E1.17) — all blocked
- P4: 3/6 tickets done, 3 in-progress — all blocked
- No further phase advancement possible until external dependencies resolve

---

## Sessions: 2026-04-08 (sessions 14-18) — consolidated

Phase: E1 — ongoing enhancements
Checkboxes checked: 0 (across all 5 sessions)

All 5 sessions were identical status checks with no progress. All remaining roadmap items were blocked on the same external dependencies listed above. Upstream PR minus34/gnaf-loader#100 remained OPEN with no reviews. Golden commands passed in every session.

---

## Session: 2026-04-08 (session 13)

Phase: E1 — ongoing enhancements
Checkboxes checked this session: 4 (E1.14: fix landed, --no-boundary-tag removed, CHANGELOG, RUNBOOK)

### Completed

- **E1.14** — gnaf-loader shp2pgsql fix landed + --no-boundary-tag removed:
  - Upstream PR [minus34/gnaf-loader#100](https://github.com/minus34/gnaf-loader/pull/100): checks `process.returncode` after shp2pgsql, guards against empty SQL output
  - Submodule pinned to fork commit 45bd25f (jbejenar/gnaf-loader)
  - `.gitmodules` updated to point to fork (temporary until upstream merges)
  - `--no-boundary-tag` removed from `docker-entrypoint.sh`
  - `--check-boundary-coverage` enabled in production verify
  - `noBoundaryTag` option removed from `src/load.ts` + test updated
  - CHANGELOG entry added under `[Unreleased] > Fixed`
  - Pre-commit hook fixed to skip submodule entries (mode 160000)

### Ticket Status Changes

- E1.14: in-progress (4/7 functional DoD + 2/3 docs DoD checked; 2 remaining BLOCKED)

### Key Decisions

- Submodule temporarily points to jbejenar/gnaf-loader fork. **Must revert to minus34/gnaf-loader once upstream PR #100 is merged.**
- `.gitmodules` URL change is the only temporary artifact; all other changes are permanent.

---

## Session: 2026-04-08 (session 12)

Phase: E1 — ongoing enhancements
Checkboxes checked this session: 5 (E1.19 — all 5 DoD items)

### Completed

- **E1.19** — Stale `2026.02` references in user-facing docs (all 5 DoD items checked):
  - DOCUMENT-SCHEMA.md `_version` examples → `2026.04`, parquet/geoparquet filenames → `flat-white-2026.04.*`
  - RUNBOOK.md commands → `${VERSION}` shell variable placeholders with usage note
  - COMMUNITY-ANNOUNCEMENT.md target version → v2026.04 shipped
  - Two-tier convention documented in RELEASING.md (consumer-facing = current version, operational = `${VERSION}`)

### Ticket Status Changes

- E1.19: planned → done (completed 2026-04-08)

---

## Session: 2026-04-07 (session 11)

Phase: E1 — ongoing enhancements
Checkboxes checked this session: 5 (3 E1.15 DoD items checked + 1 deferred, 1 E1.14 root-cause item)

### Completed

- **E1.15** DoD checkboxes formalized with evidence (3/4 checked, 1 deferred for production-scale verification)
- **E1.14** Root cause identified and documented
- **E1.13** remaining item annotated as BLOCKED

### Ticket Status Changes

- E1.14: planned → in-progress (root cause identified, fix pending upstream PR)

### Roadmap Progress

- E1: 11/18 tickets done, 4 in-progress (E1.06, E1.13, E1.14, E1.17)
