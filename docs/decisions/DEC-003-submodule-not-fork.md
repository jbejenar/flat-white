# DEC-003 — Submodule, Not Fork

> **Schema 1.0.0 change — current clarification.**
> The migration uses the `202608` release plus the authority-cleanup contribution
> in [upstream PR #103](https://github.com/minus34/gnaf-loader/pull/103). Its exact
> commit is temporarily pinned through the existing fork while upstream reviews
> it. The updater resolves upstream release tags and checks ancestry. Review
> raw/prepared census compatibility as described in [loader updates](../GNAF-LOADER-UPDATES.md).

## Status

Accepted

## Context

flat-white depends on `minus34/gnaf-loader` to load G-NAF data into Postgres and perform spatial boundary joins. gnaf-loader contains years of G-NAF loading and compatibility work. We need to integrate it without taking on maintenance burden.

## Decision

Pin gnaf-loader as a Git submodule at a specific release or a documented commit
carrying a submitted upstream fix. Never modify it in-repo. If a change is needed,
contribute it upstream via PR to `minus34/gnaf-loader`. Replace temporary fix pins
with an upstream version containing the repair once it passes compatibility checks.

## Alternatives Considered

- **Fork:** Full control over the code, but creates a maintenance burden. Every upstream update requires manual merging. Risk of divergence from upstream G-NAF schema handling.
- **Vendoring (copy into repo):** Same maintenance burden as a fork, plus loses Git history and makes upstream contributions harder.
- **npm/pip package:** gnaf-loader is not published to any package registry. It's invoked as a Python script, not imported as a library.
- **Rewrite in TypeScript:** Would take months to replicate 10 years of edge-case handling. Not worth it when the Python tool works.

## Consequences

- A reviewed PR advances the committed submodule pin. `git submodule update --init --recursive` checks out that committed pin; it does not choose the latest upstream release.
- Automated tracking detects new upstream releases and can open a draft pin-update PR for compatibility review.
- flat-white's `src/load.ts` wraps gnaf-loader invocation — it does not import or modify gnaf-loader code.
- Contributors must use `git clone --recurse-submodules` to get gnaf-loader.
