# Next Session — flat-white

## Session: 2026-04-06 (session 2)

Phase: P4 (Production Operations)
Checkboxes checked this session: 2 (P4.07 ×2: margin analysis, build time)

### Completed

- P4.07 (partial) — NSW Memory Optimisation: PostgreSQL tuning applied, margin analysis documented, build time verified (19m 23s)

### Ticket Status Changes

- P4.07: planned → in-progress (2/3 DoD items checked)

### In Progress

- P4.07 — NSW Memory Optimisation: 1 DoD item remaining (5 consecutive successful runs). 1/5 achieved from v2026.04. PostgreSQL tuning applied but not yet validated in production — first tuned build will be v2026.05 (May 2026).
- P4.03 — Build-Over-Build Comparison: code complete, needs second release for verification (v2026.05)
- P4.06 — Runbook: 1/2 DoD items checked. "Tested by uninvolved person" BLOCKED (requires human tester)

### Deferred

- P3.07 data.gov.au listing: requires manual submission — instructions in docs/COMMUNITY-ANNOUNCEMENT.md
- P0.07 extract-fixtures.sh: requires full VIC-loaded database

### Key Decisions

- PostgreSQL memory tuning applied conservatively: shared_buffers=256MB (2x Docker default), work_mem=64MB, maintenance_work_mem=256MB. Targets ~500-700MB PostgreSQL footprint on 7GB runners. No risk to smaller states; NSW gets ~2-4GB margin.
- Margin analysis based on indirect measurement (success/failure, stage timing) since no direct memory profiling tool is available in CI. Documented as sufficient for current purposes.

### Blockers

- P4.07: 5 consecutive NSW runs needed — can only accumulate across future quarterly builds (v2026.05, v2026.07, etc.)
- P4.03: needs second release for real comparison
- P4.06: needs human tester for runbook validation

### Next Session Should Start With

- **P4.07** — After v2026.05 build, verify PostgreSQL tuning didn't regress build time or cause issues. Track consecutive run count (currently 1/5).
- **P4.03** — Verifiable after v2026.05 (May 2026 quarterly release). Check comparison report output.
- **Boundary coverage investigation** — check if gnaf-loader upstream has fixed the wards table naming issue; if so, update submodule and rebuild without `--no-boundary-tag`
- **P3.07** — Submit data.gov.au listing (manual step)

### Roadmap Progress

- P0: 12/14 tickets done (P0.07 has 1 unchecked DoD item — BLOCKED)
- P1: all tickets done
- P2: 8/8 tickets done (PHASE COMPLETE)
- P3: 7/7 tickets done (P3.07 has 1 DEFERRED item; P3.01 wall-clock verified)
- P4: 3/6 tickets done (P4.01, P4.02, P4.04), 2 in-progress (P4.03 — BLOCKED, P4.07 — 2/3 DoD), 1 in-progress (P4.06 — BLOCKED)
