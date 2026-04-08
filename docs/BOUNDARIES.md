# Boundaries — How They're Calculated, Where They Come From, What Goes Wrong

> **Audience:** anyone reading the quarterly build logs and trying to figure out why "LGA" appears in scary red text. Also: future contributors who need to change anything in the boundary path.
>
> **TL;DR:** boundary enrichment is layered. There's an upstream gnaf-loader path that's currently broken for 7 of 9 states, and our own spatial-join fallback that picks up the slack. The scary `lga_pid SQL FAILED` lines you see in the logs are the **upstream bug being caught and rerouted**, not a flat-white failure.

---

## What "boundaries" are

Every address in the output gets enriched with the administrative and statistical areas it sits inside. Five sources, seven fields:

| Field                    | What it is                                      | Source polygon table                               | Example              |
| ------------------------ | ----------------------------------------------- | -------------------------------------------------- | -------------------- |
| `lga`                    | Local Government Area (council)                 | `admin_bdys.local_government_areas`                | "MARIBYRNONG"        |
| `ward`                   | Sub-council voting area                         | `admin_bdys.local_government_wards`                | "RIVER WARD"         |
| `stateElectorate`        | State lower-house electorate                    | `admin_bdys.state_lower_house_electorates`         | "FOOTSCRAY"          |
| `commonwealthElectorate` | Federal electorate                              | `admin_bdys.commonwealth_electorates`              | "GELLIBRAND"         |
| `meshBlock`              | ABS Mesh Block (smallest stat geography)        | `admin_bdys.abs_2021_mb_lookup` via `mb_2021_code` | `{ code, category }` |
| `sa1`                    | ABS Statistical Area 1 (~200-800 people)        | derived from mesh-block lookup                     | `{ code }`           |
| `sa2`                    | ABS Statistical Area 2 (~3k-25k people, suburb) | derived from mesh-block lookup                     | `{ code, name }`     |

The `lga`/`ward`/`stateElectorate`/`commonwealthElectorate` fields come from a **point-in-polygon spatial join** — for each address point, find which polygon it sits inside. The mesh block / SA1 / SA2 fields come from a much simpler **non-spatial code lookup**: `address_principals.mb_2021_code` is already populated by gnaf-loader during the load stage; flatten just joins it against `abs_2021_mb_lookup` to expand the code into mesh-block category, SA1, SA2, SA3, SA4, GCC, etc.

So when this doc talks about "the boundary problem", it almost always means **the spatial join for the four polygon-derived fields**. Mesh block / SA1 / SA2 are mechanical and have never been a source of trouble.

---

## The two paths boundaries can be populated

There are **two completely independent code paths** that can populate `address_principal_admin_boundaries` (the table that flatten reads from). They're alternatives — only one needs to run.

```
                        ┌──────────────────────────────────┐
download admin bdys ──→ │ gnaf-loader Part 5               │
                        │   "boundary tagging"             │ ◄── Path 1
                        │   ST_Subdivide + bulk hash join  │     (upstream)
                        │   ~2 min for VIC                 │
                        └────────────────┬─────────────────┘
                                         │
                                         ▼
              gnaf_*.address_principal_admin_boundaries
                                         │
                                         ▼
                        ┌──────────────────────────────────┐
                        │ flat-white flatten               │
                        │ address_full_prep.sql            │ ◄── Path 2
                        │   IF table empty: spatial join   │     (our fallback)
                        │   LEFT JOIN LATERAL ... LIMIT 1  │
                        │   ~30 min - 3 hr for NSW         │
                        └────────────────┬─────────────────┘
                                         │
                                         ▼
                                   NDJSON output
```

### Path 1 — gnaf-loader's Part 5 (upstream, fast)

Upstream gnaf-loader's `load-gnaf.py` runs a stage called `Part 5 of 6 : Start boundary tagging addresses`. It does the spatial join in two stacked optimisations:

**(a) `ST_Subdivide` pre-processing.** Before tagging, gnaf-loader runs `02-03-create-admin-bdy-analysis-tables_template.sql` to build "analysis" copies of every boundary table:

```sql
INSERT INTO admin_bdys.local_government_areas_analysis (lga_pid, name, state, geom)
SELECT lga_pid, name, state,
       ST_Subdivide((ST_Dump(ST_Buffer(geom, 0.0))).geom, 512)
  FROM admin_bdys.local_government_areas;
```

This is the single biggest speedup. LGA polygons can be enormous — Western Australia's Outer Ngaanyatjarraku LGA is the size of Greece. PostGIS spatial indexes work on bounding boxes, so a giant LGA polygon's bbox covers most of WA, and the GiST index is useless: every address in WA becomes a candidate for that LGA, forcing PostGIS to do an expensive `ST_Within` check on the actual polygon for each one.

`ST_Subdivide` chops each polygon into pieces of at most 512 vertices. A giant LGA becomes hundreds of small tiles, each with a tight bounding box. Now the GiST index is razor-sharp: a point in Perth only matches the ~5 tiles around Perth, not all of WA. **Spatial index hit rate goes from ~1% to ~99%** — typically a 10–50× speedup.

**(b) Bulk hash join (one big SQL).** Then it does one `INSERT ... SELECT` per boundary table:

```sql
-- gnaf-loader/postgres-scripts/04-01b-bdy-tag-template.sql
INSERT INTO gnaf.temp_local_government_areas_tags (gnaf_pid, lga_pid, ...)
SELECT pnts.gnaf_pid, bdys.lga_pid, ...
  FROM gnaf.address_principals AS pnts
  INNER JOIN admin_bdys.local_government_areas_analysis AS bdys
    ON ST_Within(pnts.geom, bdys.geom);
```

One INSERT, one query plan, the planner picks a hash join with the GiST index, processes all 4.6M NSW addresses in one shot. PostgreSQL is excellent at this kind of single big set-oriented operation.

**(c) Multiprocessing across boundary types.** The 5 boundary type tags (LGA, ward, ce, se_lower, se_upper) run **in parallel** on separate CPUs via Python `multiprocessing`. Time per boundary type stays roughly constant; total time = max(per-type time), not sum.

**Result:** NSW boundary tagging in ~2 minutes when it works. The result is a row per address in `address_principal_admin_boundaries`, populated with `lga_pid`, `lga_name`, `ward_pid`, `ward_name`, `ce_pid`, `ce_name`, `se_lower_pid`, `se_lower_name`, `se_upper_pid`, `se_upper_name`.

### Path 2 — flat-white's spatial-join fallback (`address_full_prep.sql`, slow)

Our fallback lives in `sql/address_full_prep.sql` and runs as a flatten-time prelude. It only fires when `address_principal_admin_boundaries` is empty (i.e. Path 1 was skipped or failed):

```sql
DO $$
BEGIN
  SELECT COUNT(*) INTO bdy_count FROM gnaf_*.address_principal_admin_boundaries;
  IF bdy_count > 0 THEN
    RAISE NOTICE 'admin_boundaries already populated — skipping spatial join fallback';
    RETURN;
  END IF;
  -- ... otherwise, build it ourselves ...
END $$;
```

If the table is empty, the fallback inserts via:

```sql
INSERT INTO gnaf_*.address_principal_admin_boundaries (...)
SELECT
  ap.gnaf_pid, ap.locality_pid, ...,
  lga.lga_pid, lga.full_name, ...
FROM gnaf_*.address_principals ap
LEFT JOIN LATERAL (
  SELECT lga_pid, full_name
    FROM admin_bdys_*.local_government_areas
    WHERE ST_Intersects(ap.geom, geom)
    ORDER BY lga_pid LIMIT 1
) lga ON true
LEFT JOIN LATERAL (... ward) ward ON true
LEFT JOIN LATERAL (... ce) ce ON true
LEFT JOIN LATERAL (... se_lower) se ON true
LEFT JOIN LATERAL (... se_upper) se_up ON true;
```

**Why `LATERAL ... LIMIT 1`?** This is the [PR #66 / E1.15](../ROADMAP.md) fix for **multi-polygon row multiplication**. `ST_Intersects` returns true for points on a polygon edge, so a single point on the shared boundary between two adjacent LGAs would match BOTH polygons. With four `LEFT JOIN ... ON ST_Intersects(...)` joins cartesian-multiplied, that produced up to 16 duplicate rows per address (one per combination of matching CE × LGA × ward × SE polygons). The `LATERAL` form guarantees **at most one row per (address, boundary table)**, and the `ORDER BY pid` ensures the choice is deterministic across runs (same point always picks the same polygon).

**Why it's slow.** The `LATERAL ... LIMIT 1` pattern doesn't bulk-optimise like a hash join — PostgreSQL conceptually re-runs the inner query for each outer row. 4.6M re-executions for NSW. And we're hitting the **un-subdivided** raw polygons (`admin_bdys.local_government_areas`, not `..._analysis`) so the GiST index is much less selective. Five LATERAL joins serially per row.

**Result:** NSW spatial-join fallback in **30 minutes to 3 hours**, depending on runner luck. This is the elephant in the room and the single biggest source of "the quarterly run takes forever". Tracked as ROADMAP entry **E1.21**.

### Mesh block / SA1 / SA2 — neither path

These don't use spatial joins at all. `address_principals.mb_2021_code` is populated by gnaf-loader during the **load** stage (Part 1-4, before Part 5), so it's always present. Flatten reads it and does a non-spatial join against `admin_bdys.abs_2021_mb_lookup`:

```sql
LEFT JOIN admin_bdys_*.abs_2021_mb_lookup mb
  ON mb.mb21_code = ap.mb_2021_code
```

That join expands the mesh block code into category, SA1, SA2, SA2 name, SA3, SA4, GCC. No `ST_Intersects`, no polygon math, no performance issue. **The mesh block / SA1 / SA2 fields have never been a source of trouble.** When this doc talks about "boundary problems" you can mentally exclude these.

---

## How a build chooses which path to run

The decision lives in `docker-entrypoint.sh` and `scripts/detect-load-failure.sh`:

```
1. Run gnaf-loader (Path 1).
2. If it succeeds: done. address_principal_admin_boundaries is populated.
3. If it fails AND the failure happened during/after Part 5 boundary tagging:
     - WARNING — retry gnaf-loader with --no-boundary-tag
     - The retry skips Part 5 entirely. address_principal_admin_boundaries
       gets created (by gnaf-loader's earlier steps) but stays empty.
4. At flatten time, address_full_prep.sql sees an empty table and fires
   Path 2 (the spatial-join fallback) to populate it.
5. flatten reads from the now-populated table.
```

The detection logic is in `scripts/detect-load-failure.sh`. It's intentionally **broad**: any non-zero exit from gnaf-loader where the log contains `"Part 5 of 6 : Start boundary tagging"` AND does NOT contain the success marker `"Part 5 of 6 : Addresses boundary tagged"` is treated as Part-5-eligible. Broad-by-design so any future upstream regression in Part 5 (not just the specific column-mismatch bug below) auto-recovers without code changes.

The detection has 10 test fixtures covering all known failure modes plus negative cases — see `test/integration/load-detection/`.

---

## The current upstream bug (Problem A) — why every quarterly run is loud

This is the source of the scary `lga_pid SQL FAILED` messages you keep seeing in the quarterly build logs.

### What's broken

`gnaf-loader/postgres-scripts/04-06-bdy-tags-for-alias-addresses.sql` is **hardcoded** to reference all 5 boundary `*_pid`/`*_name` columns:

```sql
INSERT INTO gnaf.address_alias_admin_boundaries (
  gnaf_pid, ...,
  ce_pid, ce_name, lga_pid, lga_name, ward_pid, ward_name,
  se_lower_pid, se_lower_name, se_upper_pid, se_upper_name
)
SELECT ...
```

But `gnaf-loader/settings.py` filters which boundaries get loaded **per state**:

```python
if states_to_load != ["OT"]:
    admin_bdy_list.append(["commonwealth_electorates", "ce_pid"])
if states_to_load != ["ACT"]:
    admin_bdy_list.append(["local_government_areas", "lga_pid"])
if "NT" in states_to_load or "SA" in states_to_load or "VIC" in states_to_load or "WA" in states_to_load:
    admin_bdy_list.append(["local_government_wards", "ward_pid"])
if states_to_load != ["OT"]:
    admin_bdy_list.append(["state_lower_house_electorates", "se_lower_pid"])
if "TAS" in states_to_load or "VIC" in states_to_load or "WA" in states_to_load:
    admin_bdy_list.append(["state_upper_house_electorates", "se_upper_pid"])
```

When a single-state build excludes any boundary type, the dynamic `CREATE TABLE address_alias_admin_boundaries` doesn't make those columns. The hardcoded `INSERT` then crashes with `psycopg.errors.UndefinedColumn`.

### Affected states

| State you're building | Boundary excluded by `settings.py` | Hardcoded SQL crashes on |
| --------------------- | ---------------------------------- | ------------------------ |
| ACT                   | LGA                                | `lga_pid`                |
| NSW                   | ward                               | `ward_pid`               |
| QLD                   | ward                               | `ward_pid`               |
| OT                    | ce, se_lower                       | `ce_pid`                 |
| TAS                   | se_upper                           | `se_upper_pid`           |
| NT                    | se_upper                           | `se_upper_pid`           |

That's **7 of 9 states fail Path 1 with a scary-looking SQL error on every quarterly run.** Only VIC and SA are spared (they have all 5 boundary types).

The detection in `detect-load-failure.sh` catches them all (broad Part-5 detection), the entrypoint retries with `--no-boundary-tag`, and Path 2 takes over at flatten time.

### What you see in the logs

What it looks like when it's working as designed:

```
root        : INFO     Part 5 of 6 : Start boundary tagging addresses
root        : INFO     SQL FAILED! : ----------------------------------
       bdy.lga_pid,
       lga.lga_name AS lga_name,
   INNER JOIN raw_admin_bdys_202602.aus_lga AS lga ON bdy.lga_pid = lga.lga_pid
psycopg.errors.UndefinedColumn: column "ward_pid" of relation
"address_alias_admin_boundaries" does not exist

[load] ERROR: gnaf-loader exited with code 1 after 5.0 minutes
[entrypoint] WARNING: gnaf-loader boundary tagging failed; retrying with --no-boundary-tag
             so flat-white fallback can populate boundaries
[load] Python: python3 /app/gnaf-loader/load-gnaf.py ... --states QLD --no-boundary-tag
root        : INFO     	- no_boundary_tag : True
...
root        : WARNING  Part 5 of 6 : Addresses NOT boundary tagged
[entrypoint] ✓ Stage: load completed
```

**That `SQL FAILED` block is the upstream bug being caught and rerouted, not a flat-white failure.** The thing to look for is the WARNING line that follows. If you see the warning after the SQL error, the system is doing the right thing.

### Why this isn't fixed upstream

It is, eventually (ROADMAP entry **E1.20** — "push gnaf-loader settings.py / 04-06 fix upstream"). It's low priority because:

1. The broad Part-5 detection in `detect-load-failure.sh` handles it transparently.
2. Path 2 produces correct output.
3. Upstream gnaf-loader is a community-maintained project; PR review cadence is unpredictable.

When E1.20 lands, the SQL error stops appearing in the logs and the runtime drops by ~5 min per state (no retry needed). It's nice-to-have, not load-bearing.

---

## The /dev/shm bug (Problem B) — fixed in #96

This was a downstream consequence of Problem A.

When Path 2 became the primary path for 7 of 9 states, it started exercising Postgres parallel hash joins much harder than Path 1 ever did. PostgreSQL parallel hash joins allocate dynamic shared memory chunks in `/dev/shm` by default. **Docker default `/dev/shm` is 64 MB** — exhausted by a single 64 MB parallel hash table. Flatten died with:

```
[flatten] Fatal: PostgresError: could not resize shared memory segment
"/PostgreSQL.4093011826" to 67244032 bytes: No space left on device
```

This was the actual killer of the quarterly runs in March/April 2026 — VIC and WA both repeated this 3 times before the retry budget was exhausted.

### The fix (#96)

Set `dynamic_shared_memory_type = sysv` in `postgresql.conf`:

```
# docker-entrypoint.sh, postgres init
shared_buffers = 256MB
work_mem = 64MB
maintenance_work_mem = 256MB
effective_cache_size = 2GB
max_connections = 20
dynamic_shared_memory_type = sysv   # ← #96
```

This switches Postgres to **System V shared memory** which doesn't use `/dev/shm` at all. SysV shmem is bounded by `SHMMAX`/`SHMALL` kernel settings, which Docker leaves at host defaults (very high — gigabytes).

Structural fix, not a tunable. No `--shm-size` insurance flag, no magic numbers. PR #96 added test coverage and the fix has been on `main` since 2026-04-08.

### Why was this latent in v2026.04?

In v2026.04, gnaf-loader was already running with `--no-boundary-tag` as a workaround for an unrelated `shp2pgsql` upstream bug. That meant **Path 2 wasn't actually doing the spatial join** — `address_principal_admin_boundaries` stayed empty all the way through. Empty table → no parallel hash joins on it → no shm pressure. The bug was lurking; it activated the moment boundary tables started getting populated again.

---

## The silent v2026.04 incident (Problem C) — fixed by layered defence

This is the **scariest class of failure** because nothing crashed. The build completed, the output shipped, and nobody noticed for a while.

### What happened

In v2026.04:

1. gnaf-loader was running with `--no-boundary-tag` (Problem B's reason — `shp2pgsql` workaround).
2. Path 2 didn't exist yet.
3. So `address_principal_admin_boundaries` was just **empty**, the flatten ran fine (no error, just LEFT JOIN producing NULL boundary columns), and the shipped NDJSON had **0% LGA coverage, 0% ward, 0% electorate**.
4. Verify didn't have boundary coverage thresholds yet.
5. Output shipped.

### The layered defence we now have

After the v2026.04 incident, the project added **three independent gates** that all need to fail for empty boundaries to ship:

| Layer | What it checks                                                  | When it runs             | Implemented in                              |
| ----- | --------------------------------------------------------------- | ------------------------ | ------------------------------------------- |
| 1     | Path 1 OR Path 2 populates the table                            | Load + flatten time      | gnaf-loader + `address_full_prep.sql`       |
| 2     | Boundary polygon tables in the cache are populated              | Post-load + post-restore | `scripts/validate-db-cache.sh` (#99)        |
| 3     | Per-state coverage ≥ thresholds (lga ≥ 99%, etc.)               | Post-flatten verify      | `src/verify.ts` `--check-boundary-coverage` |
| 4     | PR-time shape smoke catches `address_full_prep.sql` regressions | Every relevant PR        | `quarterly-shape-smoke` in `ci.yml` (#99)   |

Layers 1 and 3 existed before #99. Layers 2 and 4 are the new gates from #99 (the "harden quarterly safety net" PR). Together they make a v2026.04-class silent failure structurally impossible to ship.

---

## Per-state vs national: a subtle gnaf-loader detail

There's a subtlety worth noting because it's tripped me up reading the code.

`gnaf-loader/settings.py`'s `admin_bdy_list` is filtered per-state — see the table in Problem A above. **But the per-state filtering is only applied to two stages:**

1. The **boundary tagging** stage (`create_admin_bdys_for_analysis` and `boundary_tag_gnaf` in `load-gnaf.py`).
2. The **`04-06-bdy-tags-for-alias-addresses.sql`** hardcoded INSERT (this is the bug in Problem A).

**It is NOT applied to the polygon prep stage** (`prep_admin_bdys` in `load-gnaf.py`). The per-state filtering for prep is commented out (lines 515–535 of `load-gnaf.py`):

```python
# # Account for bdys that are not in states to load - not yet working
# for sql in sql_list:
#     if settings.states_to_load == ["OT"] and ".commonwealth_electorates " in sql:
#         sql_list.remove(sql)
#     ...
```

So `prep_admin_bdys` runs the FULL `02-02a-prep-admin-bdys-tables.sql` regardless of state. **This means `admin_bdys_*.local_government_areas`, `local_government_wards`, `commonwealth_electorates`, `state_lower_house_electorates`, and `state_upper_house_electorates` are populated with country-wide polygon data on every state build**, even single-state builds like ACT-only or QLD-only.

This is what makes `validate-db-cache.sh`'s strict polygon-table checks correct — the polygon tables ARE always present after a successful gnaf-loader load. If a future upstream change un-comments that filtering block, the validator will fail and we'll know to update both. (The validator header documents this assumption explicitly.)

The polygon **analysis** tables (with `_analysis` suffix and ST_Subdivide tiles) ARE per-state filtered — they're built from `admin_bdy_list`. We don't currently use them in flat-white's fallback path (we hit the un-subdivided raw polygons, which is part of why Path 2 is slow — see "Future work" below).

---

## Where each output field comes from

This maps cleanly to what flatten reads — `sql/address_full.sql` lines 178–197:

```sql
-- Admin boundaries (Path 1 or Path 2 populates this table)
ab.lga_pid,
ab.lga_name,
ab.ward_name,
ab.se_lower_name AS state_electorate_name,
ab.ce_name       AS commonwealth_electorate_name,

-- ABS mesh block + statistical areas (mechanical lookup)
ap.mb_2021_code,
mb.mb_cat        AS mesh_block_category,
mb.sa1_21code,
mb.sa2_21code,
mb.sa2_21name,
mb.sa3_21code,
mb.sa3_21name,
mb.sa4_21code,
mb.sa4_21name,
mb.gcc_21code,
mb.gcc_21name,
```

And the joins:

```sql
-- Spatial-join derived
LEFT JOIN gnaf_*.address_principal_admin_boundaries ab ON ab.gnaf_pid = ap.gnaf_pid

-- Mechanical code lookup
LEFT JOIN admin_bdys_*.abs_2021_mb_lookup mb ON mb.mb21_code = ap.mb_2021_code
```

The schema field names (`lga`, `ward`, `stateElectorate`, `commonwealthElectorate`, `meshBlock`, `sa1`, `sa2`) are the **camelCase output names** in the NDJSON document. The `address_full.sql` columns are the **snake_case Postgres aliases**. The TypeScript flatten code (`src/flatten.ts`) does the snake-to-camel mapping when composing the document.

---

## The fixture path

The quarterly shape smoke (#99) and `scripts/build-fixture-only.sh` use a fixture-only build that exercises the same boundary code paths against committed seed data — no 6.5 GB download required.

Files involved:

| File                                      | Role                                                                                                                                                                                                |
| ----------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `fixtures/seed-postgres.sql`              | Schema DDL for `gnaf_*` and `raw_gnaf_*` schemas + ~451 edge-case addresses                                                                                                                         |
| `fixtures/seed-admin-bdys.sql`            | Schema DDL for `raw_admin_bdys_*` schema + raw polygon tables (commonwealth electorates, LGAs, wards, state electorates, etc.)                                                                      |
| `fixtures/prep-admin-bdys.sql`            | Transforms raw polygon tables → prepped `admin_bdys_*` tables (local_government_areas, local_government_wards, commonwealth_electorates, etc.) — equivalent to gnaf-loader's `prep_admin_bdys` step |
| `scripts/extract-boundary-prelude.mjs`    | Extracts the spatial-join fallback DO block from `address_full_prep.sql` so it can run as a standalone prelude in fixture mode                                                                      |
| `docker-entrypoint.sh` (`fixture` branch) | Runs the four scripts above in order, then flattens                                                                                                                                                 |

The fixture path is **the only way** to exercise both the polygon prep AND the spatial-join fallback in CI without waiting for a real quarterly download. It catches `address_full_prep.sql` regressions at PR time via the `quarterly-shape-smoke` job.

The committed fixture sits at near-100% boundary coverage (LGA 100%, ward 99.6%, electorates 100%, mesh block / SA1 / SA2 100%). The shape smoke uses `--boundary-thresholds lga=99,ward=99,...` so any regression that drops a boundary type entirely fails the smoke at PR time.

---

## The detection logic (`scripts/detect-load-failure.sh`)

The script that decides "is this a Part-5 retry-eligible failure or a real error". Three conditions, all must hold:

```
Part-5-eligible iff:
  1. exit_code != 0
  2. AND log contains "Part 5 of 6 : Start boundary tagging"
  3. AND log does NOT contain "Part 5 of 6 : Addresses boundary tagged"
```

The third condition (success-marker absence) was added in #96 round 2 after a bot review caught a false positive: the original two-condition check would have fired for any failure AFTER Part 5 succeeded (e.g. a hypothetical Part 6 QA-table failure). With the success-marker check, a clean Part 5 followed by a Part 6 failure correctly does NOT retry — the real Part 6 error surfaces instead of being masked by an irrelevant `--no-boundary-tag` retry.

10 fixture log files in `test/integration/load-detection/fixtures/` cover:

- `success.log` — clean run, no retry
- `failure-download.log` — failed before Part 4, no retry
- `failure-prep.log` — failed in Part 4, no retry
- `failure-act-lga_pid.log` — Problem A (ACT lga column mismatch), retry
- `failure-qld-ward_pid.log` — Problem A (QLD ward column mismatch), retry
- `failure-ot-ce_pid.log` — Problem A (OT ce column mismatch), retry
- `failure-tas-se_upper_pid.log` — Problem A (TAS se_upper column mismatch), retry
- `failure-future-part5.log` — hypothetical future Part 5 regression, broad detection still retries
- `failure-part6-after-part5-success.log` — Part 5 OK, Part 6 fails, no retry (false-positive guard)
- `success.log` claimed exit 1 — log shows Part 5 completed, treat as success, no retry

`bash test/integration/load-detection/test.sh` runs all 10 in CI on every PR (`ci.yml` `quality` job).

---

## The cache validator (`scripts/validate-db-cache.sh`)

Added in #99. Runs **after a successful gnaf-loader load AND after a cache restore**. Checks that the database state is sane before we either propagate it via cache dump or burn time on flatten.

What it catches:

- **Wrong `GNAF_VERSION`** — schema name mismatch (the `gnaf_*` / `raw_gnaf_*` / `admin_bdys_*` / `raw_admin_bdys_*` schemas don't exist).
- **Truncated / corrupt restore** — core G-NAF tables missing rows.
- **Missing admin_bdys polygon tables** — the spatial-join fallback would silently produce 0% boundary coverage. **This is the v2026.04 incident class.**
- **Missing `raw_admin_bdys.aus_lga`** — used by `fixtures/prep-admin-bdys.sql` and as a debugging fallback in production.

What it does NOT catch (intentionally):

- Whether `address_principal_admin_boundaries` is populated. By design, this table can legitimately be empty after a `--no-boundary-tag` retry — the spatial-join fallback in `address_full_prep.sql` fills it at flatten time. The verify.ts boundary coverage check (`--check-boundary-coverage`) is the gate for that, after flatten.

The strict polygon-table checks rely on the "per-state filtering of polygon prep is commented out in upstream gnaf-loader" assumption documented in the validator header.

---

## The boundary coverage thresholds (`verify.ts` and `verification-report.ts`)

Two gates with **different defaults**:

### `verify.ts` — flatten-time per-state gate

Default thresholds in `src/verify.ts`:

```ts
export const DEFAULT_BOUNDARY_THRESHOLDS: Required<BoundaryCoverageThresholds> = {
  lga: 0.99, // 99%
  ward: 0.95, // 95% — wards legitimately don't cover all addresses
  stateElectorate: 0.99, // 99%
  commonwealthElectorate: 0.99, // 99%
};
```

Wards are lower (95%) because some addresses legitimately fall outside any ward polygon — not every council has wards, and even within ward councils some boundary edges have gaps.

Run via the `--check-boundary-coverage` flag in the entrypoint's verify stage. If any boundary type drops below threshold, exit code 4 (verification failure).

### `verification-report.ts` — release-asset / shape-smoke gate

The verification-report tool produces the markdown report that ships as a release asset, AND is used by the quarterly shape smoke. As of #99, it accepts a `--boundary-thresholds lga=99,ward=99,sa1=99,...` flag and fails (exit 4) if any state falls below.

The shape smoke uses **tighter** thresholds than the production verify because the fixture has predictable, near-100% coverage:

```js
// scripts/run-quarterly-fixture-smoke.mjs
const FIXTURE_BOUNDARY_THRESHOLDS =
  "lga=99,ward=99,stateElectorate=99,commonwealthElectorate=99,meshBlock=99,sa1=99,sa2=99";
```

Production runs use the `verify.ts` defaults via `--check-boundary-coverage`. Both end up running on every release — the verify.ts gate at flatten time, then the verification-report regenerated at release-asset upload time.

### Empty-file safety

The verification-report's `passed` calculation requires `rowCount > 0` AND zero threshold failures (empty files would otherwise be vacuously passing every quality check). The threshold check itself runs even when `rowCount === 0`, treating missing values as 0% so an empty NSW with `lga=99` configured fails with `{field: lga, actual: 0, threshold: 99}`. Both safety nets added in #99 round 2 (review-bot finding).

---

## What can still go wrong

A non-exhaustive list of "things that have happened or could plausibly happen", with their current detection/mitigation:

| Failure mode                                                     | Detection                                                   | Mitigation                                     |
| ---------------------------------------------------------------- | ----------------------------------------------------------- | ---------------------------------------------- |
| gnaf-loader Part 5 fails on column mismatch (Problem A)          | `detect-load-failure.sh`                                    | Retry with `--no-boundary-tag` → Path 2        |
| Future upstream Part 5 regression (different shape)              | Broad Part-5 detection (`detect-load-failure.sh`)           | Retry with `--no-boundary-tag` → Path 2        |
| Postgres `/dev/shm` exhaustion in flatten (Problem B)            | Already happened; #96 fixed structurally                    | `dynamic_shared_memory_type = sysv`            |
| OOM kill in flatten (Path 2 LATERAL eats memory on NSW)          | `run-quarterly-state.sh` classifies exit 137 as transient   | Retry; #99 retry-from-dump skips reload        |
| Path 2 takes longer than the 360-min runner timeout              | Timeout exit                                                | Self-hosted runner via `runner` workflow input |
| Polygon tables silently empty after gnaf-loader (v2026.04 class) | `validate-db-cache.sh` (#99)                                | Build aborts with `[cache-validate] FAIL` line |
| `address_full_prep.sql` regression breaks Path 2                 | `quarterly-shape-smoke` thresholds (#99)                    | PR-time fail before merge                      |
| Empty per-state output file ships                                | `verification-report.ts` `passed = rowCount > 0` (#99)      | verification-report exit 4                     |
| Boundary coverage drops below threshold in production            | `verify.ts --check-boundary-coverage`                       | Build aborts at flatten verify stage           |
| Multi-polygon row multiplication on boundary points              | E1.15 `LATERAL ... LIMIT 1` form in `address_full_prep.sql` | Already structurally prevented                 |
| Cache restore from corrupt dump                                  | `validate-db-cache.sh` runs on restore too                  | `restoreValidationFailed` retry path           |

---

## Future work

### E1.20 — push gnaf-loader column-mismatch fix upstream

**Status:** roadmap, not started.

Send a PR to `minus34/gnaf-loader` that fixes the per-state column mismatch in `04-06-bdy-tags-for-alias-addresses.sql`. Either make the SQL dynamic-column-aware or apply the same per-state filtering that `settings.py` uses to choose which columns to insert.

**Impact when landed:**

- The scary `SQL FAILED` block stops appearing in quarterly logs.
- ~5 min saved per state (no retry needed).
- Path 1 starts running for all 9 states instead of just VIC and SA.
- Path 2 stops being the primary path and becomes a true fallback again.

**Why low priority:** the broad Part-5 detection in `detect-load-failure.sh` handles the bug transparently. Path 2 produces correct output. Nice to have, not load-bearing.

### E1.21 — replace Path 2 LATERAL with bulk hash joins

**Status:** roadmap, designed, not started.

The current Path 2 fallback in `sql/address_full_prep.sql` uses `LEFT JOIN LATERAL ... ORDER BY pid LIMIT 1` per address per boundary table. For NSW with 4.6M addresses × 5 boundary tables, that's ~23M individual ST_Intersects executions. Each uses a GiST index against the un-subdivided polygons (~0.5–2 ms), totalling **30 minutes to 3 hours** depending on runner luck.

**The fix.** Replicate gnaf-loader's technique: subdivided polygons + bulk hash join + `DISTINCT ON` for the multi-polygon dedup (instead of LATERAL+LIMIT for the same purpose):

```sql
-- Build the analysis tables (one-time, fast)
CREATE TABLE admin_bdys_*.local_government_areas_analysis AS
SELECT lga_pid, full_name, state,
       ST_Subdivide((ST_Dump(ST_Buffer(geom, 0.0))).geom, 512) AS geom
  FROM admin_bdys_*.local_government_areas;
CREATE INDEX ON admin_bdys_*.local_government_areas_analysis USING gist(geom);

-- Bulk-tag every address with its LGA in one query
INSERT INTO gnaf_*.address_principal_admin_boundaries (gnaf_pid, lga_pid, lga_name, ...)
SELECT DISTINCT ON (ap.gnaf_pid)
       ap.gnaf_pid, bdys.lga_pid, bdys.full_name, ...
  FROM gnaf_*.address_principals ap
  INNER JOIN admin_bdys_*.local_government_areas_analysis bdys
    ON ST_Intersects(ap.geom, bdys.geom)
  ORDER BY ap.gnaf_pid, bdys.lga_pid;  -- deterministic tiebreaker
```

**Why `DISTINCT ON` + `ORDER BY pid` instead of `LATERAL ... LIMIT 1`:** same correctness guarantee (one row per address, deterministic polygon choice on ties), but expressible as a bulk hash join instead of per-row execution. PostgreSQL can plan it as a hash join with the GiST index doing the heavy filtering, processing all 4.6M NSW addresses in one shot.

**Expected impact:**

- NSW from 30–180 min → ~10–15 min (estimated; needs measurement).
- The whole quarterly run drops from "1–6 hours best case" to "~20–30 min reliably".
- Eliminates most of the OOM/shm risk (smaller working set, no parallel hash explosion).
- The retry-from-dump optimisation in #99 becomes belt-and-braces (rarely needed).
- Removes the need for the 360-min job timeout.
- Removes the "is this run going to finish today" anxiety.

**Trade-offs:**

- ~200–400 lines of new SQL + prelude wiring + tests. Half-day to a day of work.
- Need to validate boundary coverage matches Path 1 byte-for-byte against a Path 1 reference (probably an integration test against a tiny multi-state real data sample).
- Fixture path needs the same treatment.

This is the **actual root-cause fix** for "the quarterly takes forever". Everything in #96 + #99 is hardening / safety-net work; this is the perf fix.

### E1.22 (not yet ticketed) — collapse Path 1 and Path 2 into a single path

Once E1.21 lands, Path 1 and Path 2 are doing exactly the same thing with exactly the same technique. The split exists only because Path 1 is upstream-controlled. We could:

- Always run with `--no-boundary-tag` (skip Path 1 entirely).
- Always populate `address_principal_admin_boundaries` from our own SQL (Path 2-as-primary).
- Drop the `detect-load-failure.sh` retry path entirely.

This makes the system simpler, more predictable, and removes the dependency on upstream behaviour. It also removes the ability to opportunistically use Path 1 when it works — but if E1.21 makes Path 2 as fast as Path 1, that's no longer a meaningful loss.

Defer until E1.21 is landed and measured. May not be worth doing if E1.20 also lands and Path 1 starts working everywhere again.

---

## Appendix: code locations

| Concern                       | File                                                                                                  |
| ----------------------------- | ----------------------------------------------------------------------------------------------------- |
| Path 1 (upstream)             | `gnaf-loader/load-gnaf.py` `boundary_tag_gnaf` + `04-01b-bdy-tag-template.sql`                        |
| Path 1 polygon prep (subdiv)  | `gnaf-loader/postgres-scripts/02-03-create-admin-bdy-analysis-tables_template.sql`                    |
| Path 1 column-mismatch bug    | `gnaf-loader/postgres-scripts/04-06-bdy-tags-for-alias-addresses.sql`                                 |
| Path 2 (our fallback)         | `sql/address_full_prep.sql` (DO block, lines ~95–215)                                                 |
| Detection / retry routing     | `scripts/detect-load-failure.sh` + `docker-entrypoint.sh` Stage 3                                     |
| Cache validator               | `scripts/validate-db-cache.sh`                                                                        |
| Per-state retry orchestration | `scripts/run-quarterly-state.sh`                                                                      |
| Flatten reads boundaries      | `sql/address_full.sql` lines 178–197 + 243–248                                                        |
| Flatten code (snake → camel)  | `src/flatten.ts`                                                                                      |
| Output schema                 | `src/schema.ts` `boundaries` field                                                                    |
| Production verify gate        | `src/verify.ts` `DEFAULT_BOUNDARY_THRESHOLDS`                                                         |
| Release/PR verify gate        | `src/verification-report.ts` `parseBoundaryThresholdsArg`                                             |
| Shape smoke (PR-time)         | `scripts/run-quarterly-fixture-smoke.mjs` + `quarterly-shape-smoke` job in `.github/workflows/ci.yml` |
| Detection test fixtures       | `test/integration/load-detection/fixtures/`                                                           |
| Fixture seed data             | `fixtures/seed-postgres.sql`, `fixtures/seed-admin-bdys.sql`                                          |
| Fixture prep (boundaries)     | `fixtures/prep-admin-bdys.sql`                                                                        |
| Boundary prelude extractor    | `scripts/extract-boundary-prelude.mjs`                                                                |

## Appendix: relevant PRs and roadmap entries

- **PR #66** — initial spatial-join fallback (introduced the LATERAL + LIMIT 1 pattern) — fixes E1.10
- **PR #67** — multi-polygon row multiplication audit — found and fixed the multi-polygon dedup bug — E1.15
- **PR #96** — permanent fix for quarterly build (Bug A column-mismatch detection + Bug B `/dev/shm` → sysv)
- **PR #97** — fixture boundary prelude + db port targeting + schema-validating stub for `address_principal_admin_boundaries`
- **PR #99** — harden quarterly safety net (cache validator strict polygon checks, shape-smoke thresholds, retry-from-dump, path filter, log accumulation, exact-one-match guard)
- **E1.10** — fixture coverage for boundary fields
- **E1.14** — restore LGA / ward / state / commonwealth electorate fields after v2026.04
- **E1.15** — fix multi-polygon row multiplication in PR #66 spatial join fallback
- **E1.20** — push gnaf-loader settings.py / 04-06 fix upstream
- **E1.21** — optimise spatial-join fallback for NSW scale
