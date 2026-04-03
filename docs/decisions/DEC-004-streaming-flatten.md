# DEC-004 — Streaming Flatten

## Status

Accepted

## Context

The flatten pipeline must transform 15.9M addresses (largest state: NSW ~4.5M) from Postgres into NDJSON. GitHub Actions free runners have 7GB RAM. The pipeline must fit within this constraint with headroom.

## Decision

Use cursor-based streaming: read one row (or small batch) from Postgres, compose the document, write one NDJSON line, repeat. Memory target: under 500MB peak RSS regardless of dataset size.

## Alternatives Considered

- **Bulk SELECT into memory:** Simple to implement but NSW would require 5-6GB of RAM for rows alone, leaving no headroom for document composition and JSON serialisation. Would fail on free runners.
- **Postgres COPY to JSON:** Postgres can export JSON directly, but it lacks the document composition logic (nested objects, array aggregations, label generation) that flat-white needs. Would require post-processing that negates the memory savings.
- **Batch processing (e.g. 10K rows at a time):** Better than bulk but still requires careful memory management. Cursor-based streaming is simpler and has a tighter memory bound.

## Consequences

- Memory usage is O(1) relative to dataset size — bounded by the size of one document plus cursor overhead.
- Throughput depends on Postgres cursor fetch size and JSON serialisation speed. Target: VIC (~3.8M) in under 45 minutes.
- Error handling is per-document — a single bad row does not abort the entire build.
- The flatten module (`src/flatten.ts`) must never accumulate documents in memory.
