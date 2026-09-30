# How boundary enrichment works

> **Schema 1.0.0 change:** census enrichment now uses ASGS 2026 through
> `mb_2026_code` and `abs_2026_mb`. There is no 2021 fallback. See the
> [migration guide](MIGRATING-TO-ASGS-2026.md) for consumer implications.

An address has two kinds of geographic enrichment. Administrative areas are
assigned by intersecting an address point with polygons. Census areas are looked
up through the address's mesh-block code. Both appear in the same `boundaries`
object, but their derivation and expected gaps differ.

## The ten output fields

| Field                    | Method               | Prepared source                        |
| ------------------------ | -------------------- | -------------------------------------- |
| `lga`                    | Spatial join         | `local_government_areas`               |
| `ward`                   | Spatial join         | `local_government_wards`               |
| `stateElectorate`        | Spatial join         | `state_lower_house_electorates`        |
| `commonwealthElectorate` | Spatial join         | `commonwealth_electorates`             |
| `meshBlock`              | **2026 code lookup** | `abs_2026_mb.mb_code_26`, `mb_cat_26`  |
| `sa1`                    | **2026 code lookup** | `abs_2026_mb.s1_code_26`               |
| `sa2`                    | **2026 code lookup** | `abs_2026_mb.s2_code_26`, `s2_name_26` |
| `sa3`                    | **2026 code lookup** | `abs_2026_mb.s3_code_26`, `s3_name_26` |
| `sa4`                    | **2026 code lookup** | `abs_2026_mb.s4_code_26`, `s4_name_26` |
| `gccsa`                  | **2026 code lookup** | `abs_2026_mb.gc_code_26`, `gc_name_26` |

All ten fields are nullable. Types and object shapes are defined in the
[document schema](DOCUMENT-SCHEMA.md#boundaries). `lga.code` is a Geoscape LGA
identifier; it is not one of the six ASGS census codes changed by this migration.

## The current pipeline

1. **Load and prepare.** The pinned loader imports G-NAF and raw administrative
   shapefiles and prepares boundary tables. flat-white always passes
   `--no-boundary-tag`; it owns the subsequent address-to-administrative-area join.
2. **Validate the input.** After a fresh load or cache restore,
   [`validate-db-cache.sh`](../scripts/validate-db-cache.sh) checks the expected
   schemas, populated tables and state-specific boundaries. It also requires
   2026 census columns and a complete census hierarchy for at least 99% of
   addresses in each state.
3. **Assign administrative areas.** The boundary prelude in
   [`address_full_prep.sql`](../sql/address_full_prep.sql) creates/populates
   `address_principal_admin_boundaries` when needed. It uses bulk spatial joins
   and polygon subdivision. Deterministic selection and a unique address-PID
   index prevent overlapping polygons from multiplying address rows.
4. **Flatten.** [`address_full.sql`](../sql/address_full.sql) joins each principal
   address to its administrative assignments and the 2026 mesh-block hierarchy.
   Production pre-materializes aggregations before streaming. Its generated main
   query must agree with the canonical CTE query.
5. **Verify output.** Schema, row-count, PID and data-quality checks run on the
   documents. Administrative coverage gates apply per state. Mesh-block, SA1,
   SA2, SA3, SA4 and GCCSA coverage must each reach 99% in every state.

Names such as `gnaf_202608` use the **source quarter** as the schema suffix. The
`2026` in `abs_2026_mb` identifies the **ASGS edition**. These are different
concepts; changing one does not change the other.

## Census validation is deliberately strict about the edition

Schema 1.0.0 follows this path:

```text
address_principals.mb_2026_code
  → abs_2026_mb.mb_code_26
  → mesh-block category, SA1, SA2, SA3, SA4 and GCCSA
```

A populated `abs_2021_mb` table cannot satisfy the requirement. Neither can an
empty 2026 column with no matching codes. An old restored dump fails validation
and is rebuilt from source by the state wrapper. The cache namespace is
`v3-asgs2026`.

## Coverage and verification

After loading or restoring, at least **99% of each state's addresses** must match
a mesh block with populated SA1–SA4 and GCCSA codes. The check rejects null and
blank hierarchy codes and counts each reference code once. One matching row, or
a large healthy state beside a broken small state, cannot certify the cache.

After flattening, `verify.ts` applies a 99% floor to each of the six census fields
in each state when production boundary checks are enabled. The compressed release
verifier applies the same census defaults even when no threshold flag is supplied.
Both report all six levels and compare unrounded coverage. Administrative fields
retain their separate, state-specific thresholds.

Why 99%, rather than 100%? The [published May 2026 report](https://github.com/jbejenar/flat-white/releases/download/v2026.05/verification-report.md)
reported rounded 100% mesh-block, SA1 and SA2 coverage in all nine states. The
floor leaves room for isolated missing assignments while rejecting incomplete
enrichment. SA3, SA4 and GCCSA must also form a complete hierarchy. Individual
missing assignments remain `null`; they are never filled with 2021 geography.

That report describes the older edition, not measured ASGS 2026 coverage. Treat
99% as a safety floor, not a geographic accuracy guarantee. Inspect the first
2026 release's actual rates and representative joins. If a legitimate source
exception breaches the floor, investigate and review the evidence before changing
the policy; do not lower it simply to make a failed build pass.

## Administrative gaps vary by state

The pinned loader's single-state builds prepare these polygon types:

| State | LGA | Ward | Lower house | Commonwealth | Upper house |
| ----- | --- | ---- | ----------- | ------------ | ----------- |
| ACT   | No  | No   | Yes         | Yes          | No          |
| NSW   | Yes | No   | Yes         | Yes          | No          |
| NT    | Yes | Yes  | Yes         | Yes          | No          |
| OT    | Yes | No   | No          | Yes          | No          |
| QLD   | Yes | No   | Yes         | Yes          | No          |
| SA    | Yes | Yes  | Yes         | Yes          | No          |
| TAS   | Yes | No   | Yes         | Yes          | Yes         |
| VIC   | Yes | Yes  | Yes         | Yes          | Yes         |
| WA    | Yes | Yes  | Yes         | Yes          | Yes         |

**OT repair:** Commonwealth boundaries for Other Territories are supplied by
ACT and NT. The loader now imports their electoral attributes, polygons and
state lookup rows without importing ACT/NT addresses. Both build verification
and compressed release verification require at least 99% OT federal coverage.
Every export rebuilds address assignments, including after a database restore.

The audited August 2026 snapshot has 3,803 matches among 3,805 OT addresses:
2,166 Bean, 182 Fenner and 1,455 Lingiari. Two Norfolk Island PIDs remain null:
`GAOT_720637896` and `GAOT_720637906`. Their source points fall about 4.0 m and
3.2 m outside the supplied Bean polygon. We retain those source disagreements;
we do not move the points or guess an electorate. Release verification checks
these exact exceptions when both source quarters are August 2026. Later source
editions need a fresh audit, not a copied exception list.

Upper-house tables are validated/prepared where applicable, but upper-house
membership is not an output field. A prepared polygon type also does not imply
100% coverage: some councils have no wards, and many OT addresses have no LGA
assignment. The exact administrative thresholds live in
[`PER_STATE_BOUNDARY_THRESHOLDS`](../src/verify.ts), not in this table.

Do not treat a legitimate state-specific absence as a load failure. Conversely,
an empty required raw or prepared table must not be dismissed as an expected null.
For multi-state builds, validation and coverage checks account for the states
actually selected.

## What the fixture exercises

The fixture keeps 451 VIC addresses from February 2026. Its setup:

1. Loads the frozen address seed.
2. Seeds small synthetic administrative polygons and runs their preparation SQL.
3. Adds `seed-census-2026.sql`, including 430 synthetic raw mesh-block rows and
   2026 assignments on principal and alias addresses.
4. Uses `extract-census-prep.mjs` to execute the mesh-block section of the **pinned
   upstream 202608 census preparation SQL**.
5. Runs the same administrative boundary prelude, both flatten query paths,
   output verification and byte-for-byte comparison with the committed baseline.

Old 2021 tables remain as decoys. Two explicit migration cases differ so a
regression to the old lookup changes the output and fails comparison. They test
the transformation; they do not assert real ABS assignments for those addresses.
The fixture does not run the full national loader or establish production capacity.

Use `./scripts/build-fixture-only.sh` and the [fixture guide](../fixtures/README.md)
for development. Leave `GNAF_VERSION` unset so its frozen schema names stay aligned.

## Where to make a change

- Change flatten fields and joins in `sql/address_full.sql`, then generate the main
  query with `npm run generate:sql`.
- Change shared preparation in `sql/address_full_prep.sql` and preserve both-path
  equality. Do not create a separate fixture-only repair for a production defect.
- Make loader source changes upstream. A submodule pin update still needs
  [compatibility review](GNAF-LOADER-UPDATES.md).
- Review the document schema, Zod schema and expected fixture output together for
  any output change. Breaking meanings require a major schema version.

For failures, follow the [runbook](RUNBOOK.md). For the earlier two-path design,
missing-boundary incidents and the reasons it was removed, read the
[historical boundary guide](history/BOUNDARIES-PRE-1.0.md). Those incidents explain
the safeguards; their old recovery steps are not current instructions.
