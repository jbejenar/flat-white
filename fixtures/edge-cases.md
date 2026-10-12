# Fixture edge cases

> **Schema 1.0.0 change:** the fixture includes a synthetic ASGS 2026 census
> hierarchy and retains 2021 tables as regression decoys. See the
> [fixture guide](README.md) for the distinction between real address data and
> synthetic geographic assignments.

The table below counts the **committed output**, not extraction goals. It was
checked against all 451 documents in `expected-output.ndjson` for schema 1.1.0.
Categories overlap, so counts must not be added together. Each PID is a concrete
example that can be found in the baseline.

## Covered cases

| Case                              | Documents | Example PID      | What is exercised                                                          |
| --------------------------------- | --------- | ---------------- | -------------------------------------------------------------------------- |
| Simple addresses                  | 197       | `GAVIC411670057` | No flat, level or primary/secondary classification.                        |
| Units or flats                    | 185       | `GAVIC411087566` | Flat number present; tests type and number composition.                    |
| Levels                            | 52        | `GAVIC423623835` | Level number present.                                                      |
| Melbourne 3000                    | 28        | `GAVIC412717346` | One side of the dual-postcode locality case.                               |
| Melbourne 3004                    | 25        | `GAVIC411803305` | The same locality name with a different postcode.                          |
| Address aliases                   | 74        | `GAVIC411809712` | Non-empty aliases array.                                                   |
| Secondary addresses               | 193       | `GAVIC411087566` | Child-address classification.                                              |
| Parent with exported children     | 1         | `GAVIC423911067` | Primary classification and a non-empty secondaries array.                  |
| Multiple geocodes                 | 405       | `GAVIC411087566` | At least two exported geocodes; tests aggregation and best-code selection. |
| Ward assignment                   | 449       | `GAVIC411087566` | Non-null ward after administrative spatial processing.                     |
| Lot without street number         | 30        | `GAVIC411935231` | Lot present and numberFirst null.                                          |
| Building name                     | 33        | `GAVIC411670057` | Named building.                                                            |
| 2026 census hierarchy             | 451       | `GAVIC411087566` | All six census fields populated by the synthetic 2026 lookup.              |
| Changed census code and hierarchy | 1         | `GAVIC411087566` | A new mesh-block code and hierarchy must come from the 2026 source.        |
| Reassigned census hierarchy       | 1         | `GAVIC411441273` | The mesh-block code is retained, but SA1–SA4 and GCCSA change.             |

The two migration cases deliberately differ from the old 2021 lookup. This catches
an accidental return to the old join even though both tables exist in the fixture.
The other census values are reused as synthetic test data, not real 2026 assignments.
Administrative fields are derived from small synthetic polygons, rather than
accepted as precomputed tags.

## Known gaps

- **Non-gazetted localities:** no committed address document has a locality class
  other than `GAZETTED LOCALITY`. Authority-table rows alone do not exercise this path.
- **Broad parent/child coverage:** only one exported parent has exported children.
  There are more lookup rows, but many reference addresses outside the principal subset.
- **Retired addresses:** the frozen exported fixture does not exercise retired
  address exclusion. It cannot establish what every later source release contains.
- **Other states and national scale:** the base addresses are VIC only. Separate
  integration tests exercise state-dependent boundary validation, but the fixture
  is not a full load of every state's addresses.

These are gaps in the committed end-to-end output fixture, not a claim that no
unit test covers related behaviour. When changing one of these paths, add a small,
focused case and verify its result. Do not download the full dataset merely to
satisfy an old selection target.

## Reproduce a count

For example, count addresses with at least two exported geocodes:

```bash
jq -s '[.[] | select(.allGeocodes | length >= 2)] | length' fixtures/expected-output.ndjson
```

This command is for the small committed fixture. Use streaming checks for
production files. The [schema reference](SCHEMA-REFERENCE.md) describes source
rows and columns; the [fixture guide](README.md#make-a-deliberate-fixture-change)
explains how to change or replace the snapshot safely.

## New schema 1.1 geocode cases

`seed-geocode-cases.sql` changes four fixture addresses with clearly synthetic
source rows. The base extract is unchanged. `GAVIC411087566` has three valid
points and an equal-rank tie inserted in reverse PID order. `GAVIC411441273`
has retired site points and identical street defaults. `GAVIC411670057` has an
invalid active site point and a locality default. `GAVIC411685451` has invalid
site and default coordinates, so both exported coordinates remain null.

The committed output has 417 primary site points, 32 street fallbacks, one
locality fallback and one address without either. The integration test also
checks source reliability before type preference, unknown precision, retired
default exclusion and a conflicting-default export failure. CTE and materialized
output remain byte-identical. The 18 untouched documents in `schema-1.0-samples.json`
come from the published v2026.08 sample audit, two from each state/territory;
they test reader compatibility independently of the synthetic fixture.
