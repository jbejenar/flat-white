# Next Session — flat-white

## Session: 2026-04-06 (session 3)

Phase: E1 (Ongoing) — P4 items all blocked, advanced to E1
Checkboxes checked this session: 4 (E1.09 ×2, E1.07 ×2)

### Completed

- E1.09 — Self-Hosted Runner Fallback: docs/SELF-HOSTED-RUNNER.md + `runner` input in quarterly-build.yml
- E1.07 — Multi-Arch Image: ARM64 + AMD64 in docker-publish.yml with QEMU + cross-arch verification jobs

### Ticket Status Changes

- E1.09: planned → done (2026-04-06)
- E1.07: planned → done (2026-04-06)

### In Progress (from prior sessions)

- P4.07 — NSW Memory Optimisation: 2/3 DoD items checked. Needs 5 consecutive successful NSW runs (1/5 done). Next data point: v2026.05 (May 2026).
- P4.03 — Build-Over-Build Comparison: code complete, needs second release for verification (v2026.05)
- P4.06 — Runbook: 1/2 DoD items checked. "Tested by uninvolved person" BLOCKED (requires human tester)

### Deferred

- P3.07 data.gov.au listing: requires manual submission — instructions in docs/COMMUNITY-ANNOUNCEMENT.md
- P0.07 extract-fixtures.sh: requires full VIC-loaded database

### Key Decisions

- E1.09: Self-hosted runner support via `inputs.runner` with `ubuntu-latest` default. Scheduled runs always use free runners. Only manual `workflow_dispatch` can target self-hosted.
- E1.07: Multi-arch via QEMU (not native ARM runners) to avoid cost. Fixture-only verification for output parity — full production builds not tested cross-arch (impractical given QEMU speed).

### Blockers

- P4.07: 5 consecutive NSW runs needed — accumulates across quarterly builds
- P4.03: needs second release for real comparison (v2026.05)
- P4.06: needs human tester for runbook validation

### Next Session Should Start With

- **E1.01 — Parquet Output** (p1-high, planned): add `--format parquet` option. Needs Parquet library evaluation (parquet-wasm, apache-arrow).
- **E1.06 — Build Cache** (p1-high, planned): cache Postgres dump after gnaf-loader to skip load step on cache hit.
- **P4.07** — After v2026.05 build, track consecutive run count (currently 1/5).
- **P4.03** — Verify comparison report after v2026.05.
- **Boundary coverage** — check gnaf-loader upstream for wards table fix.

### Roadmap Progress

- P0: 12/14 tickets done (P0.07 has 1 unchecked DoD item — BLOCKED)
- P1: all tickets done
- P2: 8/8 tickets done (PHASE COMPLETE)
- P3: 7/7 tickets done (P3.07 has 1 DEFERRED item)
- P4: 3/6 tickets done (P4.01, P4.02, P4.04), 3 in-progress (P4.03, P4.06, P4.07 — all BLOCKED)
- E1: 4/9 tickets done (E1.03, E1.04, E1.07, E1.09), 5 planned
