# DEC-003 — Submodule, Not Fork

## Status

Accepted

## Context

flat-white depends on `minus34/gnaf-loader` to load G-NAF data into Postgres and perform spatial boundary joins. gnaf-loader has 922 commits and 10 years of maintenance covering every G-NAF edge case. We need to integrate it without taking on maintenance burden.

## Decision

Pin gnaf-loader as a Git submodule at a specific release tag. Never modify it in-repo. If a change is needed, contribute it upstream via PR to `minus34/gnaf-loader`.

## Alternatives Considered

- **Fork:** Full control over the code, but creates a maintenance burden. Every upstream update requires manual merging. Risk of divergence from upstream G-NAF schema handling.
- **Vendoring (copy into repo):** Same maintenance burden as a fork, plus loses Git history and makes upstream contributions harder.
- **npm/pip package:** gnaf-loader is not published to any package registry. It's invoked as a Python script, not imported as a library.
- **Rewrite in TypeScript:** Would take months to replicate 10 years of edge-case handling. Not worth it when the Python tool works.

## Consequences

- Submodule pin is updated via `git submodule update` when upstream releases a new version.
- Automated tracking (P4.05) detects new releases and opens a PR to update the pin.
- flat-white's `src/load.ts` wraps gnaf-loader invocation — it does not import or modify gnaf-loader code.
- Contributors must use `git clone --recurse-submodules` to get gnaf-loader.
