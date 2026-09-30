# NSW Memory Analysis — P4.07

> **Historical measurements — before schema 1.0.0.** These April 2026 results
> and estimates use earlier code/data and ASGS 2021. They are not a production
> benchmark or capacity guarantee for ASGS 2026. **Schema 1.0.0 change:** old
> database caches are invalidated, so measure the first compatible cold load.
> See [current release guidance](RELEASING.md) and [migration implications](MIGRATING-TO-ASGS-2026.md).

> Established: 2026-04-06. Based on v2026.04 production build (workflow run 24005068570).

## Current verification change

The OT integrity repair replaces the in-memory PID sets in both verifiers with
disk-backed sorting (32 MiB sort buffer). The table below records the old
implementation. It is not the memory estimate for the new verifier. Measure the
complete national pipeline separately; bounded PID storage does not establish
Postgres or loader memory use.

On 30 September 2026, a local Node 22.22.1 check sorted and checked five million
synthetic NSW-shaped PIDs in reverse order. It found the expected five million
unique IDs in 4.30 seconds, with maximum resident memory of 98,205,696 bytes
(about 94 MiB). This measures the PID ledger on this Mac, not the full production
verifier, PostgreSQL or a GitHub runner. The complete release still needs its own
capacity evidence.

## Context

In the measured release, NSW had about 4.6 million addresses (30% of the total). This analysis assumed a 7 GB runner and records the estimates and tuning considered at that time. Confirm current runner resources before reusing the calculation.

## Memory Budget (7 GB Runner)

| Component                | Estimate    | Basis                                                                                   |
| ------------------------ | ----------- | --------------------------------------------------------------------------------------- |
| OS + system processes    | ~500 MB     | Baseline Linux + Docker daemon                                                          |
| PostgreSQL server        | ~500-700 MB | shared_buffers=256MB + work_mem=64MB + maintenance_work_mem=256MB + connection overhead |
| gnaf-loader (Python)     | ~1-3 GB     | Loads CSV data, creates indexes, runs spatial joins. NSW is worst case.                 |
| Node.js flatten          | ~65 MB      | Measured. Cursor-based streaming keeps this constant.                                   |
| Node.js verify           | ~300-400 MB | PID deduplication Set for 4.6M addresses (~250-360 MB)                                  |
| **Total estimated peak** | **~3-5 GB** | During gnaf-loader spatial join phase                                                   |
| **Available margin**     | **~2-4 GB** | Headroom before OOM                                                                     |

### Peak Memory Phases

Memory usage is not constant — it varies by pipeline stage:

1. **Download** (~1 GB): Node.js streaming download + extraction. Low memory.
2. **Load (gnaf-loader)** (~3-5 GB peak): This is the danger zone. gnaf-loader loads CSV files, creates spatial indexes, and runs spatial joins. PostgreSQL needs memory for shared_buffers, sort operations (work_mem), and index creation (maintenance_work_mem).
3. **Flatten** (~700-900 MB): PostgreSQL serving cursor queries + Node.js streaming. Low memory — cursor reads batch 500 rows at a time.
4. **Verify** (~800-1100 MB): PID deduplication Set (~360 MB) + PostgreSQL query for source count.
5. **Split + Compress** (~200-300 MB): Streaming file operations. Minimal memory.

## PostgreSQL Tuning (Applied)

The following settings were recorded for this analysis. Check the current `docker-entrypoint.sh` before changing runner capacity or tuning:

| Setting                | Value  | Default | Rationale                                                                                                 |
| ---------------------- | ------ | ------- | --------------------------------------------------------------------------------------------------------- |
| `shared_buffers`       | 256 MB | 128 MB  | Increased from default for better query performance; still conservative for 7 GB runner                   |
| `work_mem`             | 64 MB  | 4 MB    | Per-operation memory for sorts/hashes. gnaf-loader uses several concurrent operations.                    |
| `maintenance_work_mem` | 256 MB | 64 MB   | For CREATE INDEX and VACUUM. gnaf-loader creates many indexes during load.                                |
| `effective_cache_size` | 2 GB   | 4 GB    | Planner hint (not allocation). Tells PostgreSQL how much OS cache is available.                           |
| `max_connections`      | 20     | 100     | Reduced from default. Only gnaf-loader + flatten connect. Each connection reserves per-connection memory. |

### Total PostgreSQL Memory Envelope

```
shared_buffers:           256 MB  (fixed allocation)
work_mem × connections:   64 MB × ~5 active = ~320 MB (per-operation, peak)
maintenance_work_mem:     256 MB (during index creation only)
Connection overhead:      ~20 × 5 MB = ~100 MB
WAL buffers:              ~16 MB
────────────────────────────────────
Theoretical peak:         ~700 MB (during gnaf-loader index creation)
Typical (flatten):        ~400 MB (shared_buffers + 1 cursor connection)
```

## Measured Results (v2026.04)

| Metric                  | Value           |
| ----------------------- | --------------- |
| NSW addresses processed | 4,619,401       |
| OOM kills               | 0               |
| Build time (wall clock) | 19m 23s         |
| Download                | 315s            |
| gnaf-loader load        | 278s (~4.6 min) |
| Flatten                 | 205s (~3.4 min) |
| Flatten throughput      | ~22.5K docs/s   |
| Validation errors       | 0               |
| Quality warnings        | 2,502           |
| Result                  | PASS            |

### Comparison with Other States

| State | Addresses | OOM? | Time    |
| ----- | --------- | ---- | ------- |
| NSW   | 4,619,401 | No   | 19m 23s |
| VIC   | 3,940,659 | No   | 16m 49s |
| QLD   | 3,100,481 | No   | 14m 43s |
| WA    | 1,526,407 | No   | 9m 8s   |
| SA    | 1,123,131 | No   | 9m 41s  |

NSW takes ~15% longer than VIC (17% more addresses) — performance scales linearly.

## Risk Assessment

| Risk                                | Likelihood | Impact                              | Mitigation                                                        |
| ----------------------------------- | ---------- | ----------------------------------- | ----------------------------------------------------------------- |
| OOM during gnaf-loader spatial join | Low        | High (build fails, retry triggered) | PostgreSQL tuning reduces peak; retry logic handles transient OOM |
| OOM during flatten                  | Very Low   | High                                | Cursor streaming limits Node.js to ~65 MB                         |
| OOM during verify                   | Low        | Medium                              | `--max-old-space-size=512` already applied                        |
| Slow build due to memory pressure   | Low        | Low (still under 60 min)            | 19m 23s measured — 3x margin to 60-min target                     |

### Reliability Assessment

- **v2026.04**: 1 successful NSW build, 0 OOM kills
- **Pre-v2026.04 failures**: NSW failed once (run 23993132649) with exit code 4 (verification failure, not OOM). This was a data quality issue, not memory-related.
- **Consecutive success tracking**: 1/5 (DoD requires 5 consecutive)

## Remaining work recorded in April 2026

These unchecked items are historical, not an assertion about current release status. Use [NEXT-WORK.md](../NEXT-WORK.md) for the active plan.

- [ ] Accumulate 5 consecutive successful NSW runs (across v2026.05, v2026.07, etc.)
- [ ] Validate PostgreSQL tuning in production (first build with tuning will be v2026.05)
- [ ] Consider adding `/usr/bin/time -v` or memory reporting to pipeline stages for direct measurement

## References

- [PERFORMANCE.md](PERFORMANCE.md) — All-states baseline
- [RUNBOOK.md](RUNBOOK.md) — OOM failure handling
- P4.04 — Retry logic (handles transient OOM via exit 137 detection)
