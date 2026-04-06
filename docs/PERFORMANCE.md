# Performance Baseline

> Established: 2026-04-04 from first full VIC build (P1.11).

## Hardware

| Spec     | Value                                                  |
| -------- | ------------------------------------------------------ |
| CPU      | Apple Silicon M2 Max                                   |
| RAM      | 32 GB                                                  |
| Disk     | Internal SSD (APFS)                                    |
| Postgres | 16.x + PostGIS 3.5 (Docker, `imresamu/postgis:16-3.5`) |
| Node.js  | 22.x                                                   |
| Python   | 3.x (gnaf-loader)                                      |

## VIC Build (3,940,659 addresses)

### Timing

| Stage                          | Duration   | Notes                                   |
| ------------------------------ | ---------- | --------------------------------------- |
| gnaf-loader                    | 2.5 min    | VIC-only, `--max-processes 4`           |
| Flatten (with materialization) | ~2 min     | Cursor-based streaming, batch size 500  |
| **Total**                      | **~5 min** | Excludes download (~5 min on broadband) |

### Memory

| Metric                          | Value                   |
| ------------------------------- | ----------------------- |
| Peak Node.js RSS during flatten | ~65 MB                  |
| Postgres shared_buffers         | 128 MB (Docker default) |
| Total container memory          | <500 MB                 |

Cursor-based streaming (batch size 500) keeps Node.js memory constant regardless of dataset size. The 65 MB RSS is independent of whether the dataset is 451 fixtures or 3.9M production rows.

### Output

| Metric                          | Value                        |
| ------------------------------- | ---------------------------- |
| Documents                       | 3,940,659                    |
| NDJSON file size (uncompressed) | 5.0 GB                       |
| Validation errors               | 0                            |
| Schema validation               | Every document Zod-validated |

### Per-State Row Counts

| State | Addresses |
| ----- | --------- |
| VIC   | 3,940,659 |

## Production Build — v2026.04 (Free Runners)

> Measured from workflow run 24005068570, 2026-04-05. All 9 states on `ubuntu-latest` (7 GB RAM, 2-core x86_64).

### Per-State Timing

| State     | Addresses      | Download | Load | Flatten | Total Wall Clock                   |
| --------- | -------------- | -------- | ---- | ------- | ---------------------------------- |
| NSW       | 4,619,401      | 315s     | 278s | 205s    | ~19m 23s                           |
| VIC       | 3,940,659      | 228s     | 237s | 178s    | ~16m 49s                           |
| QLD       | 3,100,481      | 342s     | 173s | 129s    | ~14m 43s                           |
| WA        | 1,526,407      | 216s     | 126s | 64s     | ~9m 8s                             |
| SA        | 1,123,131      | 328s     | 92s  | 46s     | ~9m 41s                            |
| TAS       | 346,248        | 361s     | 91s  | 16s     | ~8m 51s                            |
| ACT       | 245,362        | 236s     | 28s  | 10s     | ~5m 44s                            |
| NT        | 110,079        | 277s     | 46s  | 4s      | ~6m 12s                            |
| OT        | 3,805          | 265s     | 2s   | 0s      | ~5m 18s                            |
| **Total** | **15,015,573** | —        | —    | —       | **23m 55s** (wall clock, parallel) |

### Key Observations

- **NSW is the largest state** at 4.6M addresses — ~30% of all Australian addresses.
- **Download dominates small states** — TAS/NT/OT spend more time downloading than processing.
- **Flatten scales linearly** — ~22.5K docs/s across all states.
- **No OOM kills** on any state during the v2026.04 build.
- **Total wall clock** 23m 55s (parallel) — well under the 60-minute target.

### Memory (Free Runners)

| Component                | Estimate    | Notes                                                  |
| ------------------------ | ----------- | ------------------------------------------------------ |
| Node.js flatten RSS      | ~65 MB      | Constant regardless of dataset size (cursor streaming) |
| PostgreSQL (with tuning) | ~500-700 MB | shared_buffers=256MB + work_mem + overhead             |
| gnaf-loader (Python)     | ~1-3 GB     | Varies by state; NSW is worst case                     |
| OS + system              | ~500 MB     | Baseline                                               |
| **NSW peak (estimated)** | **~3-5 GB** | Within 7 GB limit with ~2-4 GB margin                  |

See [NSW-MEMORY-ANALYSIS.md](NSW-MEMORY-ANALYSIS.md) for detailed margin analysis.

### Verification

All 9 states passed: row count, PID uniqueness, schema validation, quality checks.

## Updating This Baseline

When new measurements are taken (especially after PostgreSQL tuning changes), update the tables above. Keep the Apple Silicon M2 Max baseline as a reference point.
