# DEC-002 — Ephemeral Postgres

> **Schema 1.0.0 change — current clarification.**
> Postgres still runs as temporary build infrastructure. Validated database dump
> artifacts can be cached to avoid repeating a load; this does not make the database
> a persistent service. The ASGS migration uses cache namespace `v4-locked-sources` and
> rejects incompatible restored dumps. See [cache recovery](../RUNBOOK.md#load-or-cache-validation-failed).

## Status

Accepted

## Context

gnaf-loader requires PostgreSQL + PostGIS to load G-NAF data and perform spatial boundary joins. The question is whether Postgres should persist between builds or be treated as a disposable build tool.

## Decision

Postgres is ephemeral. It starts inside the container, loads data, performs joins, exports NDJSON, and is destroyed. The running database does not persist between production containers. Exported data, metadata and explicitly validated cache dumps can persist as build artifacts.

## Alternatives Considered

- **Persistent Postgres:** Keep a running database with loaded data, update incrementally each quarter. Pros: faster subsequent builds. Cons: requires infrastructure management, state synchronisation, backup strategy, and contradicts the "one container, one file" principle.
- **SQLite + SpatiaLite:** Lighter than Postgres but gnaf-loader is built for Postgres and its spatial join pipeline depends on PostGIS. Porting would require forking gnaf-loader.

## Consequences

- Every build is reproducible from scratch — no hidden state.
- No persistent production database service to administer or migrate in place. Data consumers still need schema migration and rollback plans.
- A cold build includes a full source load; a compatible validated dump can avoid repeating that stage.
- The Dockerfile must bundle Postgres + PostGIS + Python + Node — larger image (~2-3GB), but self-contained.
- Development uses docker-compose with a named volume for convenience; production builds are fully ephemeral.
