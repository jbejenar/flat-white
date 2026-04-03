# DEC-002 — Ephemeral Postgres

## Status

Accepted

## Context

gnaf-loader requires PostgreSQL + PostGIS to load G-NAF data and perform spatial boundary joins. The question is whether Postgres should persist between builds or be treated as a disposable build tool.

## Decision

Postgres is ephemeral. It starts inside the container, loads data, performs joins, exports NDJSON, and is destroyed. No data persists between runs. The NDJSON file is the only artifact.

## Alternatives Considered

- **Persistent Postgres:** Keep a running database with loaded data, update incrementally each quarter. Pros: faster subsequent builds. Cons: requires infrastructure management, state synchronisation, backup strategy, and contradicts the "one container, one file" principle.
- **SQLite + SpatiaLite:** Lighter than Postgres but gnaf-loader is built for Postgres and its spatial join pipeline depends on PostGIS. Porting would require forking gnaf-loader.

## Consequences

- Every build is reproducible from scratch — no hidden state.
- No database administration, no migrations, no backups.
- Build time includes full data load (~30-40 min per state), but this happens once per quarter.
- The Dockerfile must bundle Postgres + PostGIS + Python + Node — larger image (~2-3GB), but self-contained.
- Development uses docker-compose with a named volume for convenience; production builds are fully ephemeral.
