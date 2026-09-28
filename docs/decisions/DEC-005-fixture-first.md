# DEC-005 — Fixture-First Development

> **Schema 1.0.0 change — current clarification.**
> The 451 February 2026 addresses remain frozen. Small synthetic administrative
> polygons and a synthetic ASGS 2026 census overlay exercise preparation and joins.
> The mesh-block preparation comes from the pinned upstream SQL; 2021 tables remain
> as regression decoys. See [fixture scope and limits](../../fixtures/README.md).

## Status

Accepted

## Context

The full G-NAF dataset is ~6.5GB and takes 30-60 minutes to load per state via gnaf-loader. Iterating on flatten logic, SQL, and schema validation against the full dataset would make development painfully slow and require significant disk space and network bandwidth.

## Decision

Commit a fixture subset (~451 carefully selected VIC addresses) in `fixtures/seed-postgres.sql`. All development and CI testing uses this fixture data exclusively. The fixture loads via `psql` in under 30 seconds. The full dataset is only used for quarterly production builds and initial fixture extraction.

## Alternatives Considered

- **Develop against the full dataset:** Accurate but impractical — 30-60 minute feedback loops kill productivity. Also requires 6.5GB download, which is hostile to new contributors and CI.
- **Entirely synthetic addresses:** Would lose real G-NAF relationships and quirks. The chosen fixture combines a real address snapshot with focused synthetic boundary inputs, so preparation and edition changes remain testable.
- **Small random sample:** Would miss edge cases. The fixture must be curated, not random.

## Consequences

- `scripts/build-fixture-only.sh` provides a sub-30-second dev loop: seed Postgres, flatten, validate output.
- `fixtures/expected-output.ndjson` serves as the regression baseline — any change to flatten logic that alters output is caught immediately.
- CI runs fixture-based checks on PRs; duration depends on the runner and build cache.
- Edge cases must be explicitly represented in the fixture. If a code path has no fixture coverage, it is untested.
- `fixtures/edge-cases.md` catalogues what the fixture covers and what it does not.
