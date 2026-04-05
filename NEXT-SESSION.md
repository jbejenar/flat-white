# Next Session — flat-white

## Session: 2026-04-05

Phase: P4 (Production Operations)
Checkboxes checked this session: 4 (P4.04 ×3, P4.06 ×1)

### Completed

- P4.04 — Retry Logic: added retry wrapper to quarterly-build.yml pipeline step with transient/persistent failure classification, up to 2 retries with 30s backoff, distinct GitHub Actions annotations
- P4.06 — Runbook (partial): wrote docs/RUNBOOK.md covering all 6 failure scenarios with symptoms/diagnosis/resolution/manual commands

### Ticket Status Changes

- P4.04: planned → done
- P4.06: planned → in-progress (1/2 DoD items checked; human testing BLOCKED)

### In Progress

- P4.06 — Runbook: 1/2 DoD items checked. "Tested by uninvolved person" is BLOCKED — requires human tester.

### Deferred

- P3.07 data.gov.au listing: requires manual submission after first production release
- P3.01 wall-clock time verification: cannot verify until first real production run
- P0.07 extract-fixtures.sh: requires full VIC-loaded database

### Key Decisions

- Retry logic uses shell-level retry wrapper within the workflow step (not job-level retry) to avoid re-running Docker build on each retry
- Failure classification: exit 137/143 + network/resource error patterns → transient (retried); everything else → persistent (immediate fail)
- Runbook written proactively before P4.01 (first production run) to have operational docs ready

### Blockers

- P4.01 (All-States Production Release) — requires manually triggering the quarterly build workflow. All other P4 tickets except P4.04 depend on this.
- P4.06 second DoD item — requires human tester

### Next Session Should Start With

- **P4.01** — trigger the first production release via `gh workflow run quarterly-build.yml -f gnaf_version=2026.02` and validate results
- **P4.02** — verification report (depends on P4.01 completing successfully)
- **P4.03** — build-over-build comparison (depends on P4.01; needs a prior release to compare against)
- **P4.06** — find a human tester for the runbook

### Roadmap Progress

- P0: 12/14 tickets done (P0.07 has 1 unchecked DoD item — BLOCKED)
- P1: all tickets done
- P2: 8/8 tickets done (PHASE COMPLETE)
- P3: 6/7 tickets done, 1 in-progress (P3.07 — 1 item DEFERRED)
- P4: 1/6 tickets done (P4.04), 1 in-progress (P4.06 — 1 item BLOCKED)
