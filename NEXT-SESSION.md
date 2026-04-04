# Next Session — flat-white

## Session: 2026-04-05

Phase: P3 (Distribution)
Checkboxes checked this session: 14 (P3.03 ×5, P3.04 ×2, P3.05 ×2, P3.06 ×3, P3.07 ×2)

### Completed

- P3.03 — GitHub Release Creation: verified existing implementation in quarterly-build.yml, marked done
- P3.04 — Release Notes: verified auto-generated notes implementation, marked done
- P3.05 — Downstream Dispatch: added `repository_dispatch` step to quarterly-build.yml for geocode-au notification, marked done
- P3.06 — Download Docs: added programmatic download examples + verification one-liner to README, marked done

### Ticket Status Changes

- P3.03: planned → done
- P3.04: planned → done
- P3.05: planned → done
- P3.06: planned → done
- P3.07: planned → in-progress

### In Progress

- P3.07 — Adoption & Discovery: 2/3 DoD items checked (Quick Start + community announcement plan). data.gov.au listing DEFERRED until first verified release.

### Deferred

- P3.07 data.gov.au listing: requires manual submission after first production release. Instructions in `docs/COMMUNITY-ANNOUNCEMENT.md`.
- P3.01 wall-clock time verification: cannot verify until first real production run.

### Key Decisions

- P3.05 uses `DISPATCH_TOKEN` secret (not `github.token`) because `repository_dispatch` to external repos requires a PAT with repo scope. Non-fatal warning if secret is not configured.
- P3.07 data.gov.au listing deferred as it requires manual external submission — cannot be automated.

### Blockers

- None

### Next Session Should Start With

- **P3.07** — data.gov.au listing is DEFERRED; once first release ships, submit manually
- **P4 tickets** — P3 is nearly complete (6/7 done, 1 in-progress with DEFERRED item). P4 starts with P4.01 (All-States Production Release) which requires triggering the actual matrix build.
- P0.07 still has 1 unchecked DoD item (extract-fixtures.sh automation — requires VIC-loaded DB)

### Roadmap Progress

- P0: 12/14 tickets done (P0.07 has 1 unchecked DoD item)
- P1: 14/16 tickets done
- P2: 8/8 tickets done (PHASE COMPLETE)
- P3: 6/7 tickets done, 1 in-progress (P3.07 — 1 item DEFERRED)
