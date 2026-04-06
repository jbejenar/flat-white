# Next Session — flat-white

## Session: 2026-04-07 (session 6)

Phase: P4/E1 — all remaining items blocked on external factors
Checkboxes checked this session: 16 milestone checkboxes (M0–M4)

### Completed

- Milestone reconciliation: updated 16 unchecked milestone items (M0–M4) in ROADMAP.md to reflect completed ticket status. M0–M3 are now fully checked.
- Prettier hygiene: added `.prettierignore` (excludes gnaf-loader submodule, dist/, seed-postgres.sql), fixed formatting in 6 files. `npm run format:check` now passes clean.

### Ticket Status Changes

- No ticket status changes — all remaining tickets are blocked on external factors.

### In Progress (from prior sessions)

- P4.07 — NSW Memory Optimisation: 2/3 DoD items checked. Needs 4 more consecutive successful NSW runs (1/5 done).
- P4.03 — Build-Over-Build Comparison: code complete, needs second release for verification (v2026.05)
- P4.06 — Runbook: 1/2 DoD items checked. "Tested by uninvolved person" BLOCKED (requires human tester)
- E1.06 — Build Cache: code complete, needs production build to verify ~30 min savings

### Deferred

- P3.07 data.gov.au listing: requires manual submission — instructions in docs/COMMUNITY-ANNOUNCEMENT.md
- P0.07 extract-fixtures.sh: requires full VIC-loaded database
- E1.06 build time verification: needs production build (v2026.05)

### Key Decisions

- Milestone checkboxes should reference the ticket IDs that satisfy them (added as inline annotations).
- `.prettierignore` added to prevent gnaf-loader submodule from polluting format checks.

### Blockers

- P4.07: 5 consecutive NSW runs needed — accumulates across quarterly builds (1/5 done)
- P4.03: needs second release for real comparison (v2026.05)
- P4.06: needs human tester for runbook validation
- E1.06: needs production build to verify time savings
- E1.02: blocked on P4.03 (needs second release)
- E1.08: GitHub Pages must be manually enabled in repo settings (source: GitHub Actions)

### Next Session Should Start With

- **Enable GitHub Pages** in repo settings (source: GitHub Actions) to activate E1.08 catalogue
- **After v2026.05 build:**
  - E1.06: check cache hit behavior and measure time savings
  - P4.07: track consecutive run count (currently 1/5)
  - P4.03: verify comparison report
  - E1.02: can begin delta builds implementation once P4.03 is verified
- **M3.5 verification:** check GitHub Release download counts to see if external downloads have occurred

### Roadmap Progress

- P0: 12/14 tickets done (P0.07 has 1 unchecked DoD item — BLOCKED)
- P1: all tickets done
- P2: 8/8 tickets done (PHASE COMPLETE)
- P3: 7/7 tickets done (P3.07 has 1 DEFERRED item)
- P4: 3/6 tickets done (P4.01, P4.02, P4.04), 3 in-progress (P4.03, P4.06, P4.07 — all BLOCKED)
- E1: 7/9 tickets done (E1.01, E1.03, E1.04, E1.05, E1.07, E1.08, E1.09), 1 in-progress (E1.06), 1 planned (E1.02 — blocked)
- Milestones: M0 ✓, M1 ✓, M2 ✓, M3 ✓, M3.5 partial (3 unchecked), M4 partial (1/4 checked)
