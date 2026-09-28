# DEC-001 — NDJSON Over Parquet

> **Schema 1.0.0 change — current clarification.**
> The primary published format remains NDJSON. Optional Parquet and GeoParquet
> conversion modules now exist; they carry the same census meanings. Read the
> [current format contract](../DOCUMENT-SCHEMA.md#output-formats), including the
> existing GeoParquet CRS limitation. Older size estimates below predate this migration.

## Status

Accepted

## Context

flat-white needs an output format for 15.9M address documents. The format must be streamable (write one doc at a time), universally readable (no specialised tooling required), and work with GitHub Releases file size limits (~2GB per asset). The two main contenders are NDJSON (Newline-Delimited JSON) and Apache Parquet.

## Decision

Use NDJSON as the primary output format. Each line is one self-contained JSON document. Per-state files are gzipped for distribution.

## Alternatives Considered

- **Parquet:** Excellent compression and columnar query performance, but requires specialised libraries to read/write. Not streamable line-by-line. Harder to inspect with basic tools. Would lock out consumers who just want `jq` or `grep`.
- **CSV:** Flat structure cannot represent nested objects (boundaries, aliases, secondaries) without awkward encoding. Loses type information.
- **SQLite:** Good for local querying but not streamable, not easily splittable per state, and adds a binary dependency.

## Consequences

- Any tool that reads JSON can consume the output — `jq`, `DuckDB`, Python `json`, Node.js `readline`, etc.
- Streaming writes keep memory bounded regardless of dataset size.
- Gzipped NDJSON achieves ~85-90% compression, fitting within GitHub Release limits.
- Columnar queries (e.g. "all postcodes in VIC") are slower than Parquet. Optional Parquet conversion is now available; see the current clarification above.
- Lines can be parsed independently. JSON parsing alone is not schema validation; use the matching Zod schema or verifier.
