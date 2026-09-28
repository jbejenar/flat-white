# Review the schema 1.0.0 fixture migration

The complete [NDJSON baseline](expected-output.ndjson) still contains **451
addresses**, with the same IDs and full byte-for-byte regression checks. Compared
with the pre-migration commit `59756008148f89b2ee1c54ed7bbf9bb77abc036d`,
**449 records are byte-identical**. Only the two migration cases below change.
Every changed value is listed here; all other fields, including mesh-block
category, are unchanged.

## Why only two records change

The fixture loads all 430 mesh-block rows through the real ASGS 2026 column layout
and the pinned upstream preparation SQL. It reuses historical values as synthetic
inputs for most rows, retaining varied boundaries instead of replacing every
hierarchy with the same test values. These are **not real 2026 assignments** and
this technique must not be used to migrate production data.

One case has a new mesh-block code and hierarchy. The other keeps its code but
changes its hierarchy. The retained 2021 lookup gives different results for both,
so an accidental legacy join still fails the complete regression comparison.
The [seed](seed-census-2026.sql) makes both cases explicit; the
[readable sample](expected-output-sample.json) contains the first case.

## New mesh-block code and hierarchy

Address: `GAVIC411087566`.

| Path inside `boundaries` | Before                    | After                |
| ------------------------ | ------------------------- | -------------------- |
| `meshBlock.code`         | `20192490000`             | `29900000083`        |
| `sa1`                    | `20802117831`             | `29901000103`        |
| `sa2.code`               | `208021178`               | `299010001`          |
| `sa2.name`               | `Caulfield - South`       | `Fixture 2026 SA2`   |
| `sa3.code`               | `20802`                   | `29901`              |
| `sa3.name`               | `Glen Eira`               | `Fixture 2026 SA3`   |
| `sa4.code`               | `208`                     | `299`                |
| `sa4.name`               | `Melbourne - Inner South` | `Fixture 2026 SA4`   |
| `gccsa.code`             | `2GMEL`                   | `2TEST`              |
| `gccsa.name`             | `Greater Melbourne`       | `Fixture 2026 GCCSA` |

## Same mesh-block code, reassigned hierarchy

Address: `GAVIC411441273`.

| Path inside `boundaries` | Before                    | After                       |
| ------------------------ | ------------------------- | --------------------------- |
| `sa1`                    | `20804119443`             | `29901000201`               |
| `sa2.code`               | `208041194`               | `299010002`                 |
| `sa2.name`               | `Malvern - Glen Iris`     | `Fixture 2026 reassignment` |
| `sa3.code`               | `20804`                   | `29901`                     |
| `sa3.name`               | `Stonnington - East`      | `Fixture 2026 SA3`          |
| `sa4.code`               | `208`                     | `299`                       |
| `sa4.name`               | `Melbourne - Inner South` | `Fixture 2026 SA4`          |
| `gccsa.code`             | `2GMEL`                   | `2TEST`                     |
| `gccsa.name`             | `Greater Melbourne`       | `Fixture 2026 GCCSA`        |

Its mesh-block code remains `20555940000`. An unchanged code does not prove
that the hierarchy is unchanged.

## Reproduce the review

The ordinary GitHub and local text diffs now show just these two changed records.
No binary flags or hidden replacement baseline are needed. To inspect the full
changes locally:

```bash
git diff 59756008148f89b2ee1c54ed7bbf9bb77abc036d...HEAD \
  -- fixtures/expected-output.ndjson
```

The exact snapshots have these SHA-256 hashes:

| Snapshot         | SHA-256                                                            |
| ---------------- | ------------------------------------------------------------------ |
| Before migration | `69a31fdc0b4a10a3fef660ed696a6045e4a9a002a50a7edd9f9df90e9d18b4b7` |
| After migration  | `e19b5fcfa3be74d4e41521d06fc532dc536edcb29760e3e8eae180f15a8ebfba` |

Run `./scripts/build-fixture-only.sh` to regenerate all 451 documents, compare both
SQL paths and check the complete baseline byte for byte. This inventory explains
the change; it does not replace that check.

See the [fixture guide](README.md) for development and the
[consumer migration guide](../docs/MIGRATING-TO-ASGS-2026.md) for upgrade implications.
