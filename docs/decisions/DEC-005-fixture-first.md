# DEC-005 — Fixture-First Development

## Status

Accepted

## Context

The full G-NAF dataset is ~6.5GB and takes 30-60 minutes to load per state via gnaf-loader. Iterating on flatten logic, SQL, and schema validation against the full dataset would make development painfully slow and require significant disk space and network bandwidth.

## Decision

Commit a fixture subset (~451 carefully selected VIC addresses) in `fixtures/seed-postgres.sql`. All development and CI testing uses this fixture data exclusively. The fixture loads via `psql` in under 30 seconds. The full dataset is only used for quarterly production builds and initial fixture extraction.

## Alternatives Considered

- **Develop against the full dataset:** Accurate but impractical — 30-60 minute feedback loops kill productivity. Also requires 6.5GB download, which is hostile to new contributors and CI.
- **Mock data (synthetic):** Fast but unreliable — synthetic data cannot reproduce real G-NAF edge cases (dual-postcode localities, primary-secondary relationships, boundary edge cases). Mocked tests that pass but fail on real data are worse than no tests.
- **Small random sample:** Would miss edge cases. The fixture must be curated, not random.

## Consequences

- `scripts/build-fixture-only.sh` provides a sub-30-second dev loop: seed Postgres, flatten, validate output.
- `fixtures/expected-output.ndjson` serves as the regression baseline — any change to flatten logic that alters output is caught immediately.
- CI runs fixture-based tests on every PR in under 60 seconds.
- Edge cases must be explicitly represented in the fixture. If a code path has no fixture coverage, it is untested.
- `fixtures/edge-cases.md` catalogues what the fixture covers and what it does not.
