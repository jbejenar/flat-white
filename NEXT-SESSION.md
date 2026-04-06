# Next Session — flat-white

## Session: 2026-04-06 (session 4)

Phase: E1 (Ongoing) — P4 items all blocked, advanced to E1
Checkboxes checked this session: 4 (E1.01 ×2, E1.06 ×2)

### Completed

- E1.01 — Parquet Output: roadmap updated to `done` (code was merged in PR #57 but roadmap not updated)
- E1.06 — Build Cache: `--dump-db`/`--restore-db` flags in docker-entrypoint.sh, `actions/cache@v4` in quarterly-build.yml

### Ticket Status Changes

- E1.01: planned → done (2026-04-06)
- E1.06: planned → in-progress (2/3 DoD items checked; build time verification deferred to v2026.05)

### In Progress (from prior sessions)

- P4.07 — NSW Memory Optimisation: 2/3 DoD items checked. Needs 5 consecutive successful NSW runs (1/5 done).
- P4.03 — Build-Over-Build Comparison: code complete, needs second release for verification (v2026.05)
- P4.06 — Runbook: 1/2 DoD items checked. "Tested by uninvolved person" BLOCKED (requires human tester)
- E1.06 — Build Cache: code complete, needs production build to verify ~30 min savings

### Deferred

- P3.07 data.gov.au listing: requires manual submission — instructions in docs/COMMUNITY-ANNOUNCEMENT.md
- P0.07 extract-fixtures.sh: requires full VIC-loaded database
- E1.06 build time verification: needs production build (v2026.05)

### Key Decisions

- E1.06: pg_dump custom format (`-Fc --compress=6`) for cache dumps. Cache key includes gnaf-loader submodule hash for schema safety. `--restore-db` uses `--jobs=2` for parallel restore.

### Blockers

- P4.07: 5 consecutive NSW runs needed — accumulates across quarterly builds
- P4.03: needs second release for real comparison (v2026.05)
- P4.06: needs human tester for runbook validation
- E1.06: needs production build to verify time savings

### Next Session Should Start With

- **E1.06 verification** — After v2026.05 build, check cache hit behavior and measure time savings
- **E1.05 — Geoparquet Output** (p2-medium, planned): add `--format geoparquet` option with POINT geometry. Needs WKB encoding library.
- **E1.08 — GitHub Pages Catalogue** (p2-medium, planned): static site with release data
- **P4.07** — After v2026.05 build, track consecutive run count (currently 1/5)
- **P4.03** — Verify comparison report after v2026.05

### Roadmap Progress

- P0: 12/14 tickets done (P0.07 has 1 unchecked DoD item — BLOCKED)
- P1: all tickets done
- P2: 8/8 tickets done (PHASE COMPLETE)
- P3: 7/7 tickets done (P3.07 has 1 DEFERRED item)
- P4: 3/6 tickets done (P4.01, P4.02, P4.04), 3 in-progress (P4.03, P4.06, P4.07 — all BLOCKED)
- E1: 5/9 tickets done (E1.01, E1.03, E1.04, E1.07, E1.09), 1 in-progress (E1.06), 3 planned
