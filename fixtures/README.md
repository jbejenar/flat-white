# Work with the fixtures

The fixture gives contributors a small, repeatable build without downloading the
national dataset. It contains **451 principal VIC addresses** from the February
2026 G-NAF snapshot, plus the related data needed by the flatten query.

> **Schema 1.0.0 change:** the address snapshot stays at `2026.02`. A separate
> synthetic census overlay exercises ASGS 2026. Its codes and names are test data,
> not real 2026 assignments for these addresses. Read the
> [migration guide](../docs/MIGRATING-TO-ASGS-2026.md#if-you-contribute-code).

## Run the fixture build

With Node.js 22.22.1 or newer, Docker and Compose available:

```bash
npm ci
./scripts/build-fixture-only.sh
```

Leave `GNAF_VERSION` unset. The committed schemas use the suffix `202602`; setting
a production quarter does not rename the seed. The script writes
`output/fixture.ndjson` and checks it against the committed baseline.

Loading `seed-postgres.sql` alone is incomplete. The fixture script also prepares
administrative boundaries, executes the census overlay/preparation, derives spatial
assignments, runs both flatten paths and verifies the output.

## Files and their roles

| File                                                       | Purpose                                                                                    |
| ---------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| [seed-postgres.sql](seed-postgres.sql)                     | Frozen February address snapshot, related raw/processed tables and historical census data. |
| [seed-admin-bdys.sql](seed-admin-bdys.sql)                 | Small synthetic administrative polygons around fixture points.                             |
| [prep-admin-bdys.sql](prep-admin-bdys.sql)                 | Administrative raw-to-prepared transformation for the fixture.                             |
| [seed-census-2026.sql](seed-census-2026.sql)               | Synthetic raw 2026 mesh blocks and address mesh-block assignments.                         |
| [expected-output.ndjson](expected-output.ndjson)           | Complete schema 1.0.0 regression baseline: 451 documents.                                  |
| [expected-output-sample.json](expected-output-sample.json) | Readable sample document with synthetic census values.                                     |
| [schema-baseline.json](schema-baseline.json)               | Machine-readable schema compatibility baseline.                                            |
| [SCHEMA-REFERENCE.md](SCHEMA-REFERENCE.md)                 | Table and column reference. Read this before opening the large seed.                       |
| [edge-cases.md](edge-cases.md)                             | Measured output coverage, example PIDs and known gaps.                                     |

## What changed in the census fixture?

`seed-census-2026.sql` adds `mb_2026_code` to principal and alias address tables and
creates 430 synthetic rows in `raw_admin_bdys_202602.aus_mb_2026`. The raw column
names match the August 2026 source layout.

[`extract-census-prep.mjs`](../scripts/extract-census-prep.mjs) extracts the mesh-block
section of the pinned upstream `202608` census preparation SQL. Executing that SQL
creates `admin_bdys_202602.abs_2026_mb`, including its hierarchy columns and geometry.
The fixture therefore tests the upstream preparation contract rather than merely
seeding the final lookup table.

The 2021 tables remain in the base seed as historical data and regression decoys.
The 2026 codes and names intentionally differ. Rejoining a 2021 table must change
the output and fail regression. The baseline migration changes only the six
census fields; the frozen address data and other output fields are preserved.

## What stays frozen?

| Property                                     | Value                       |
| -------------------------------------------- | --------------------------- |
| Address source quarter / document `_version` | `2026.02`                   |
| Address state                                | VIC                         |
| Principal addresses                          | 451                         |
| Source datum                                 | GDA2020, SRID 7844          |
| Current output contract                      | Schema 1.0.0                |
| Census assignments used by tests             | Synthetic ASGS 2026 overlay |

Processed, raw G-NAF, prepared boundary and raw boundary schemas all use `202602`
in their names. That suffix identifies the **address fixture snapshot**, not the
census edition.

Related data includes 75 alias records, 267 localities, 405 streets and 828 raw
site-geocode rows. A source row count is not the same as the number of output
addresses exercising a case: some relationships point outside the selected
principal-address subset. The [edge-case catalogue](edge-cases.md) reports actual
output coverage instead of the original extraction targets.

Two foreign-key constraints are excluded from the base subset because their
referenced rows lie outside it: `address_aliases_fk2` and
`locality_neighbour_lookup_fk2`. Do not interpret this as a production schema change.

## What the checks prove

- Raw administrative data can be prepared and spatially joined to the fixture.
- The pinned upstream census mesh-block preparation accepts the fixture layout.
- The canonical and materialized SQL paths produce byte-identical output.
- Output matches the committed regression baseline and passes schema, authority
  value and administrative coverage checks.

The fixture does not execute the full loader or measure national-scale capacity.
It also does not establish that synthetic boundary codes are real geographic facts.
See [known coverage gaps](edge-cases.md#known-gaps).

## Make a deliberate fixture change

Keep the base address snapshot stable during ordinary development. Add a focused
fixture or unit case for the behaviour being changed, run the fixture build and
inspect the complete diff. Do not accept a regenerated baseline merely because a
test failed. Output changes require the document contract, `src/schema.ts` and
`expected-output.ndjson` to be reviewed together; breaking changes require a major
schema version.

The old `scripts/extract-fixtures.sh` is restricted to the original February 2026
schema and loader. It is historical capture tooling, not a command to run against
the current August loader. Replacing the address snapshot needs a separate,
reviewed fixture migration. Never require a full G-NAF download for development tests.

**Street-type trap:** `street_type_aut` reverses the usual authority convention:
`code` is the long form and `name` the abbreviation. The processed
`address_principals.street_type` already contains the long form. The flatten query
must not join that authority table to expand it again.
