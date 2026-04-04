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

Other states will be added as they are built (P3.01).

## Free Runner Projections

GitHub Actions free runners provide 7 GB RAM and 2-core x86_64 CPUs. Based on VIC baseline:

- **Memory**: ~65 MB Node.js + ~128 MB Postgres = well within 7 GB limit. Even NSW (~4.5M addresses) should fit comfortably.
- **Time**: gnaf-loader and flatten are CPU-bound. Expect ~2-4x slower on free runners vs M2 Max. VIC should complete well under the 45-minute target.
- **Disk**: 5 GB NDJSON output + ~2 GB loaded Postgres. Free runners typically have 14 GB disk, sufficient for single-state builds.

## Updating This Baseline

When new measurements are taken (especially on free runners or for other states), update the tables above. Keep the Apple Silicon M2 Max baseline as a reference point.
