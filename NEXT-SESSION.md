# Next Session — flat-white

## Session: 2026-04-07 (session 7)

Phase: E1 — ongoing enhancements
Checkboxes checked this session: 10 (8 E1.17 + 2 E1.18)

### Completed

- **E1.17** De-hardcode G-NAF Feb 2026 (8/9 DoD items checked — 1 BLOCKED on May 2026 data):
  - Removed all `"2026.02"` / `"202602"` hardcoded defaults from production code paths
  - `GNAF_VERSION` env var now required for production builds (`docker-entrypoint.sh`, `build-local.sh`)
  - Fixture scripts retain `2026.02` default (frozen fixture data)
  - SQL files were already parameterized with `__SCHEMA_VERSION__` — no changes needed
  - `scripts/extract-fixtures.sh` parameterized to derive schema from `GNAF_VERSION`
  - Unit test updated: `buildArgs()` now throws when no version is provided
  - `docs/RELEASING.md` updated with version configuration + URL discovery docs
  - `AGENTS.md` updated with GNAF_VERSION note
- **E1.18** Workflow CHANGELOG `[Unreleased]` not cleared on release (2/2 DoD items):
  - Python script in quarterly-build.yml rewritten to extract `[Unreleased]` content and move into versioned entry
  - Idempotent via regex removal of existing version entry before inserting

### Ticket Status Changes

- E1.17: planned → in-progress (1 DoD item BLOCKED on May 2026 data)
- E1.18: planned → done

### In Progress (from prior sessions)

- P4.07 — NSW Memory Optimisation: 2/3 DoD items checked. Needs 4 more consecutive NSW runs (1/5 done)
- P4.03 — Build-Over-Build Comparison: code complete, needs second release for verification (v2026.05)
- P4.06 — Runbook: 1/2 DoD items checked. BLOCKED (requires human tester)
- E1.06 — Build Cache: code complete, needs production build to verify ~30 min savings
- E1.13 — Patch release tooling: 3/6 DoD items checked, remaining need manual/external work
- E1.17 — De-hardcode G-NAF Feb 2026: 8/9 DoD items checked, 1 BLOCKED (needs May 2026 data)

### Deferred

- P3.07 data.gov.au listing: requires manual submission
- P0.07 extract-fixtures.sh: requires full VIC-loaded database
- E1.06 build time verification: needs production build (v2026.05)

### Key Decisions

- Chose env-var approach for download URLs (DOWNLOAD_URL_GNAF / DOWNLOAD_URL_ADMIN_BDYS) over CKAN API discovery — simpler, no external dependency
- Fixture scripts keep 2026.02 default since fixtures are frozen snapshots, not production code
- Production builds (docker-entrypoint.sh) fail early if GNAF_VERSION is not set

### Blockers

- E1.17: End-to-end test needs May 2026 G-NAF data (available ~2026-05-01)
- P4.07: 5 consecutive NSW runs needed (1/5 done)
- P4.03: needs second release (v2026.05)
- P4.06: needs human tester for runbook validation
- E1.06: needs production build to verify time savings
- E1.02: blocked on P4.03
- E1.08: GitHub Pages must be manually enabled in repo settings

### Next Session Should Start With

- **Before v2026.05 build (2026-05-15):**
  - Set `DOWNLOAD_URL_GNAF` and `DOWNLOAD_URL_ADMIN_BDYS` env vars in the workflow inputs or secrets for the May 2026 release (find URLs on data.gov.au)
  - Set `ADMIN_BDYS_EXTRACTED_DIR` to match the May 2026 zip structure
  - E1.17 final DoD item will be verified by the v2026.05 build itself
- **Enable GitHub Pages** in repo settings (source: GitHub Actions) to activate E1.08 catalogue
- **After v2026.05 build:**
  - E1.06: check cache hit behavior and measure time savings
  - P4.07: track consecutive run count (currently 1/5)
  - P4.03: verify comparison report
  - E1.02: can begin delta builds implementation once P4.03 is verified
- **Consider next E1 items:** E1.11 (consolidate flatten SQL), E1.12 (hardened verify), E1.14 (restore boundaries — needs gnaf-loader fix)

### Roadmap Progress

- P0: 12/14 tickets done (P0.07 has 1 unchecked DoD item — BLOCKED)
- P1: all tickets done
- P2: 8/8 tickets done (PHASE COMPLETE)
- P3: 7/7 tickets done (P3.07 has 1 DEFERRED item)
- P4: 3/6 tickets done, 3 in-progress (all BLOCKED)
- E1: 7/9 tickets done, 3 in-progress (E1.06, E1.13, E1.17), 4 planned (E1.02, E1.10, E1.11, E1.12)
  - E1.18 completed this session
  - E1.16, E1.14 remain planned
- Milestones: M0 ✓, M1 ✓, M2 ✓, M3 ✓, M3.5 partial, M4 partial
