# Next Session — flat-white

## Session: 2026-04-07 (session 9)

Phase: E1 — ongoing enhancements
Checkboxes checked this session: 5 (3 E1.12 + 2 E1.13)

### Completed

- **E1.12** Hardened verify checks against authority tables (3/3 DoD items checked):
  - Code was already 95% complete from prior sessions (verify.ts, verification-report.ts, 7 unit tests)
  - Wired `--db-url` in `docker-entrypoint.sh` so enum checks run in production builds (was missing)
  - `build-fixture-only.sh` already passed `--db-url` (fixture builds had enum checks)
  - CLI has `--skip-enum-check` for opt-out (default-on when DB available)
- **E1.13** Patch release tooling — 2 remaining items completed (5/6 DoD items now checked):
  - PR auto-linking: `quarterly-build.yml` queries merged PRs between base tag and HEAD, injects "Fixes" section
  - Catalogue grouping: `generate-catalogue.ts` groups `v2026.04.1` under `v2026.04` with nested rendering
  - 6 new tests (parseVersion, patch grouping, HTML rendering)
  - Remaining: "Existing v2026.04 release notes updated to point at patch" (manual one-time edit, E1.13 DoD item 6)

### Ticket Status Changes

- E1.12: planned → done
- E1.13: in-progress → in-progress (5/6 DoD items, 1 remaining is manual)

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

- E1.12 was already implemented in code; the gap was only the production wiring (docker-entrypoint.sh missing --db-url)
- PR auto-linking uses `git log --grep='(#'` between base tag and HEAD to find PR numbers, then `gh pr view` for titles
- Catalogue patch grouping uses `parseVersion()` regex to detect vYYYY.MM.N format and group under vYYYY.MM parent

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
- **Consider next E1 items:** E1.10 (shapefile fixtures — complex), E1.14 (restore boundaries — needs gnaf-loader fix)
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
- E1: 10/18 tickets done, 3 in-progress (E1.06, E1.13, E1.17), remaining planned
  - E1.12 completed this session
  - E1.13 advanced (5/6 DoD items)
