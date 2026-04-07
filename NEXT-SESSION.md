# Next Session — flat-white

## Session: 2026-04-08 (session 14)

Phase: E1 — ongoing enhancements
Checkboxes checked this session: 0

### Completed

- None — all remaining roadmap items are blocked on external dependencies

### Status Verification

- **Upstream PR minus34/gnaf-loader#100:** Still OPEN (checked 2026-04-08). .gitmodules stays pointed at fork.
- **Golden commands:** All passing — lint, typecheck, 266 tests, fixture build PASS with byte-for-byte regression match.
- **All DEFERRED/BLOCKED annotations reviewed** — no items have become unblocked since session 13.

### In Progress (all BLOCKED — unchanged)

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
4. **If all above still blocked:** No actionable roadmap items remain — session can be skipped until ~May 2026

### Roadmap Progress

- E1: 11/18 tickets done, 4 in-progress (E1.06, E1.13, E1.14, E1.17) — all blocked
- P4: 3/6 tickets done, 3 in-progress — all blocked
- No phase advancement possible until external dependencies resolve

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

### In Progress

- E1.14 — 2 items BLOCKED: boundary field population (needs v2026.05), release notes update (needs v2026.04.1)
- E1.17 — 1 item BLOCKED: needs May 2026 G-NAF data
- E1.13 — 1 item BLOCKED: v2026.04.1 not published
- P4.07 — NSW memory: needs 4 more consecutive runs
- P4.03 — Build comparison: needs second release
- P4.06 — Runbook: needs human tester
- E1.06 — Build cache: needs production build

### Key Decisions

- Submodule temporarily points to jbejenar/gnaf-loader fork. **Must revert to minus34/gnaf-loader once upstream PR #100 is merged.**
- `.gitmodules` URL change is the only temporary artifact; all other changes are permanent.

### Blockers

- E1.14 boundary population: needs v2026.05 build (May 2026)
- E1.14 release notes: needs v2026.04.1 publication
- minus34/gnaf-loader#100: awaiting upstream review/merge
- All other blockers unchanged from session 12

### Next Session Should Start With

- **Check upstream PR status:** If minus34/gnaf-loader#100 is merged, update .gitmodules back to minus34 and update submodule pin
- **v2026.05 prep:** E1.14 + E1.17 are the two remaining blockers before v2026.05 can ship correctly
- **E1.13:** Update v2026.04 release notes when v2026.04.1 publishes

### Roadmap Progress

- E1: 11/18 tickets done, 4 in-progress (E1.06, E1.13, E1.14, E1.17)
  - E1.14: 6/7 functional + 2/3 docs DoD items checked (2 BLOCKED)

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

- **E1.15** DoD checkboxes formalized with evidence (3/4 checked, 1 deferred for production-scale verification):
  - Spatial join one-row-per-gnaf_pid: LATERAL + LIMIT 1 pattern verified in `sql/address_full_prep.sql`
  - UNIQUE INDEX on gnaf_pid: `address_principal_admin_boundaries_gnaf_pid_uniq` verified
  - Deterministic assignment: `ORDER BY <pid> LIMIT 1` verified
  - Performance (ACT 245k addresses): DEFERRED — needs production-scale run on GitHub Actions
- **E1.14** Root cause identified and documented (DoD checkbox checked):
  - `geoscape.py:import_shapefile_to_postgres()` never checks `process.returncode` after `shp2pgsql`
  - Silent success when `shp2pgsql` fails: empty SQL executed as no-op, returns "SUCCESS"
  - Secondary: module-level DB connection in `settings.py` is not fork-safe with psycopg3
  - Full analysis in `.claude-loop/build-notes.md`
- **E1.13** remaining item annotated as BLOCKED (v2026.04.1 not yet published)

### Ticket Status Changes

- E1.14: planned → in-progress (root cause identified, fix pending upstream PR)

### In Progress (from prior sessions)

- E1.14 — Restore boundary fields: root cause found, needs upstream PR to gnaf-loader + removal of `--no-boundary-tag`
- P4.07 — NSW Memory Optimisation: 2/3 DoD items checked. Needs 4 more consecutive NSW runs (1/5 done)
- P4.03 — Build-Over-Build Comparison: code complete, needs second release for verification (v2026.05)
- P4.06 — Runbook: 1/2 DoD items checked. BLOCKED (requires human tester)
- E1.06 — Build Cache: code complete, needs production build to verify ~30 min savings
- E1.13 — Patch release tooling: 5/6 DoD items checked, 1 BLOCKED (v2026.04.1 not published)
- E1.17 — De-hardcode G-NAF Feb 2026: 8/9 DoD items checked, 1 BLOCKED (needs May 2026 data)

### Deferred

- P3.07 data.gov.au listing: requires manual submission
- P0.07 extract-fixtures.sh: requires full VIC-loaded database
- E1.06 build time verification: needs production build (v2026.05)
- E1.15 performance criterion: needs production-scale ACT run

### Key Decisions

- E1.14 root cause is in gnaf-loader upstream code — fix must go as PR to `minus34/gnaf-loader`
- Two-part fix needed: (1) check `process.returncode` after `shp2pgsql`, (2) guard against empty SQL output

### Blockers

- E1.14 fix: requires upstream PR to minus34/gnaf-loader (can't modify submodule in-repo)
- E1.17: End-to-end test needs May 2026 G-NAF data (available ~2026-05-01)
- E1.13: v2026.04 release notes update blocked on v2026.04.1 publication
- P4.07: 5 consecutive NSW runs needed (1/5 done)
- P4.03: needs second release (v2026.05)
- P4.06: needs human tester for runbook validation
- E1.06: needs production build to verify time savings
- E1.02: blocked on P4.03

### Next Session Should Start With

- **E1.14 upstream PR:** Open PR to `minus34/gnaf-loader` fixing `process.returncode` check in `geoscape.py:import_shapefile_to_postgres()` — see `.claude-loop/build-notes.md` for the exact fix
- **After upstream merge:** Update gnaf-loader submodule pin, remove `--no-boundary-tag` from `docker-entrypoint.sh`, add `--check-boundary-coverage` to production verify
- **Before v2026.05 build (2026-05-15):** E1.17 final validation, E1.14 fix must land
- **E1.13 manual step:** Update v2026.04 release notes when v2026.04.1 publishes
- **Enable GitHub Pages** in repo settings (source: GitHub Actions) to activate E1.08 catalogue

### Roadmap Progress

- P0: 12/14 tickets done (P0.07 has 1 unchecked DoD item — BLOCKED)
- P1: all tickets done
- P2: 8/8 tickets done (PHASE COMPLETE)
- P3: 7/7 tickets done (P3.07 has 1 DEFERRED item)
- P4: 3/6 tickets done, 3 in-progress (all BLOCKED)
- E1: 11/18 tickets done, 4 in-progress (E1.06, E1.13, E1.14, E1.17), remaining planned
  - E1.15 DoD boxes checked this session (3/4 + 1 deferred)
  - E1.14 root cause identified this session
