# Next Session — flat-white

## Session: 2026-04-07 (session 10)

Phase: E1 — ongoing enhancements
Checkboxes checked this session: 8 (all E1.10 DoD items)

### Completed

- **E1.10** Shapefile Fixtures + Spatial Join Regression Test (8/8 DoD items checked):
  - Created `fixtures/seed-admin-bdys.sql` (339KB) with raw admin boundary tables + geometries
    - 8 tables: aus_state, aus_comm_electoral, aus_comm_electoral_polygon, aus_lga, aus_wards, aus_state_electoral_class_aut, aus_state_electoral, aus_state_electoral_polygon
    - Geometries: tiny rectangular buffers (ST_Expand 0.00005°) per address point, snapped to 0.000001° grid
  - Created `fixtures/prep-admin-bdys.sql` adapted from gnaf-loader's 02-02a-prep-admin-bdys-tables.sql
    - Transforms raw → admin_bdys boundary tables (5 tables: CE, LGA, wards, SE lower, SE upper)
  - Enhanced `sql/address_full_prep.sql` spatial join fallback to support state upper house electorates
  - Removed 451-row pre-baked `address_principal_admin_boundaries` \copy block from seed-postgres.sql
  - Updated `scripts/build-fixture-only.sh` with steps 3b-3d (seed raw bdys → prep → spatial join)
  - Created shapefiles under `fixtures/admin-bdys/` (4 sets × 5 files = 20 files)
  - Build produces byte-identical output to expected-output.ndjson
  - Build completes in ~25s (well under 90s target)

### Ticket Status Changes

- E1.10: planned → done

### In Progress (from prior sessions)

- P4.07 — NSW Memory Optimisation: 2/3 DoD items checked. Needs 4 more consecutive NSW runs (1/5 done)
- P4.03 — Build-Over-Build Comparison: code complete, needs second release for verification (v2026.05)
- P4.06 — Runbook: 1/2 DoD items checked. BLOCKED (requires human tester)
- E1.06 — Build Cache: code complete, needs production build to verify ~30 min savings
- E1.13 — Patch release tooling: 5/6 DoD items checked, 1 remaining (manual: update existing v2026.04 release notes)
- E1.17 — De-hardcode G-NAF Feb 2026: 8/9 DoD items checked, 1 BLOCKED (needs May 2026 data)

### Deferred

- P3.07 data.gov.au listing: requires manual submission
- P0.07 extract-fixtures.sh: requires full VIC-loaded database
- E1.06 build time verification: needs production build (v2026.05)

### Key Decisions

- Used SQL fixtures (`seed-admin-bdys.sql`) instead of shp2pgsql for raw boundary loading — simpler pipeline, same result
- Geometries synthesized as individual rectangular buffers per address point (not convex hulls per boundary) to eliminate cross-boundary overlap that caused spatial join mismatches
- Spatial join step extracted to run BEFORE either flatten path (legacy and materialize both need boundary data)

### Blockers

- E1.17: End-to-end test needs May 2026 G-NAF data (available ~2026-05-01)
- P4.07: 5 consecutive NSW runs needed (1/5 done)
- P4.03: needs second release (v2026.05)
- P4.06: needs human tester for runbook validation
- E1.06: needs production build to verify time savings
- E1.02: blocked on P4.03
- E1.08: GitHub Pages must be manually enabled in repo settings
- E1.14: blocked on gnaf-loader upstream fix for shapefile loading

### Next Session Should Start With

- **E1.13 manual step:** Update existing v2026.04 release notes to point at patch (one-time manual edit)
- **Consider next E1 items:** E1.14 (restore boundaries — needs gnaf-loader fix), E1.15 (multi-polygon safety — now unblocked by E1.10)
- **Before v2026.05 build (2026-05-15):**
  - Set `DOWNLOAD_URL_GNAF` and `DOWNLOAD_URL_ADMIN_BDYS` env vars for May 2026 release
  - E1.17 final DoD item will be verified by the v2026.05 build itself
- **Enable GitHub Pages** in repo settings (source: GitHub Actions) to activate E1.08 catalogue

### Roadmap Progress

- P0: 12/14 tickets done (P0.07 has 1 unchecked DoD item — BLOCKED)
- P1: all tickets done
- P2: 8/8 tickets done (PHASE COMPLETE)
- P3: 7/7 tickets done (P3.07 has 1 DEFERRED item)
- P4: 3/6 tickets done, 3 in-progress (all BLOCKED)
- E1: 11/18 tickets done, 3 in-progress (E1.06, E1.13, E1.17), remaining planned
  - E1.10 completed this session
