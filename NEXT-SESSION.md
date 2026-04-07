# Next Session — flat-white

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
