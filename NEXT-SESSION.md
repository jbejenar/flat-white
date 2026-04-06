# Next Session — flat-white

## Session: 2026-04-06

Phase: P4 (Production Operations)
Checkboxes checked this session: 6 (P4.01 ×3, P4.02 ×2, P3.01 ×1)

### Completed

- P4.01 — All-States Production Release: verified v2026.04 release (15,015,573 addresses across 9 states), all assets valid
- P4.02 — Verification Report: generated locally against all 9 state files, uploaded as release asset (12 assets total). All states PASS schema/quality/uniqueness checks
- P3.01 — Matrix Build Workflow: last unchecked DoD item (wall-clock time under 60 minutes) verified — actual time 23m55s

### Ticket Status Changes

- P4.01: planned → done (completed 2026-04-05)
- P4.02: planned → done (completed 2026-04-06)
- P4.03: planned → in-progress (code complete, needs second release to verify comparison)
- P3.01: completed date set to 2026-04-06 (wall-clock time DoD verified)

### In Progress

- P4.03 — Build-Over-Build Comparison: code complete and integrated into workflow. Cannot verify until second release (v2026.05 expected May 2026). Unit tests cover anomaly detection, thresholds, new/retired states.
- P4.06 — Runbook: 1/2 DoD items checked. "Tested by uninvolved person" remains BLOCKED (requires human tester)
- P4.07 — NSW Memory Optimisation: not started. Requires multiple production runs to measure reliability.

### Deferred

- P3.07 data.gov.au listing: requires manual submission after first production release
- P0.07 extract-fixtures.sh: requires full VIC-loaded database

### Key Decisions

- Verification report generated locally (downloaded all 9 state files, ~1.5GB) and uploaded to v2026.04 release as additional asset
- Boundary coverage note: LGA/ward/electorate all 0% due to `--no-boundary-tag` flag in docker-entrypoint.sh (gnaf-loader crashes on Feb 2026 admin boundaries wards table naming change). ABS boundaries (meshBlock/SA1/SA2) at 100%. Tracked by P4.05 (gnaf-loader update check) — when upstream fixes, auto-PR will update submodule.

### Blockers

- P4.03: needs second release for real comparison (first release has no prior to compare against)
- P4.06: needs human tester for runbook validation
- P4.07: needs multiple NSW production runs to measure OOM reliability

### Next Session Should Start With

- **P4.07** — NSW Memory Optimisation: analyze the successful build's memory usage, document margin analysis
- **P4.03** — Will be verifiable after v2026.05 (May 2026 quarterly release)
- **Boundary coverage investigation** — check if gnaf-loader upstream has fixed the wards table naming issue; if so, update submodule and rebuild without `--no-boundary-tag`
- **P3.07** — Submit data.gov.au listing (manual step, instructions in docs/COMMUNITY-ANNOUNCEMENT.md)

### Roadmap Progress

- P0: 12/14 tickets done (P0.07 has 1 unchecked DoD item — BLOCKED)
- P1: all tickets done
- P2: 8/8 tickets done (PHASE COMPLETE)
- P3: 7/7 tickets done (P3.07 has 1 DEFERRED item; P3.01 wall-clock verified)
- P4: 3/6 tickets done (P4.01, P4.02, P4.04), 1 in-progress (P4.03), 1 in-progress (P4.06 — BLOCKED), 1 planned (P4.07)
