# Review the schema 1.0.0 fixture migration

This records the change from the ASGS 2021 baseline at commit
`59756008148f89b2ee1c54ed7bbf9bb77abc036d` to the synthetic ASGS 2026 baseline
introduced by this migration. It is a review aid, not a replacement for the
[complete committed fixture](expected-output.ndjson).

The fixture has **451 documents with the same address IDs** before and after.
Every change is inside the six census boundary fields. All other field values,
including mesh-block category, are unchanged. The 2026 codes and names are
**synthetic test values**, not actual ABS assignments for these addresses.

## Complete change inventory

Each of these ten leaf paths changes in all 451 documents. No other paths change.

| Path inside `boundaries` | Change                                            |
| ------------------------ | ------------------------------------------------- |
| `meshBlock.code`         | Historical mesh-block code → synthetic 2026 code. |
| `sa1`                    | Historical SA1 code → synthetic 2026 code.        |
| `sa2.code`               | Historical code → `299010001`.                    |
| `sa2.name`               | Historical name → `Fixture 2026 SA2`.             |
| `sa3.code`               | Historical code → `29901`.                        |
| `sa3.name`               | Historical name → `Fixture 2026 SA3`.             |
| `sa4.code`               | Historical code → `299`.                          |
| `sa4.name`               | Historical name → `Fixture 2026 SA4`.             |
| `gccsa.code`             | Historical code → `2TEST`.                        |
| `gccsa.name`             | Historical name → `Fixture 2026 GCCSA`.           |

There are 430 distinct mesh-block code transitions and 430 distinct SA1 code
transitions. The 451 addresses share some mesh blocks. The assignments come from
[seed-census-2026.sql](seed-census-2026.sql) and the pinned upstream preparation SQL;
the [readable sample](expected-output-sample.json) shows one complete result.

The exact snapshots have these SHA-256 hashes:

| Snapshot         | SHA-256                                                            |
| ---------------- | ------------------------------------------------------------------ |
| Before migration | `69a31fdc0b4a10a3fef660ed696a6045e4a9a002a50a7edd9f9df90e9d18b4b7` |
| After migration  | `95506512752505de3b6fe92cfc09157be4b819352ea71639cc9f67035f6472a2` |

## See every changed value

Git's normal line diff repeats each complete address twice, including unchanged
labels, aliases and geocodes. That alone made the PR about 1.45 MB larger.
[.gitattributes](../.gitattributes) marks only this generated baseline as generated
and disables its default text diff. The file remains complete NDJSON; schema and
byte-for-byte regression checks still read all 451 documents.

To inspect the complete, unabridged diff, explicitly opt into text output:

```bash
git diff --text 59756008148f89b2ee1c54ed7bbf9bb77abc036d...HEAD \
  -- fixtures/expected-output.ndjson
```

For a smaller diff of every before/after census value, run this in Bash or Zsh
from the repository root. Each row contains the PID followed by mesh block, SA1,
SA2, SA3, SA4 and GCCSA. This command is for the small committed fixture:

```bash
BASE=59756008148f89b2ee1c54ed7bbf9bb77abc036d
CENSUS='[._id, .boundaries.meshBlock, .boundaries.sa1, .boundaries.sa2, .boundaries.sa3, .boundaries.sa4, .boundaries.gccsa]'
diff -u \
  <(git show "${BASE}:fixtures/expected-output.ndjson" | jq -c "$CENSUS") \
  <(jq -c "$CENSUS" fixtures/expected-output.ndjson)
```

`diff` returning 1 is expected here: the census values intentionally differ.
The production regression check still uses the whole NDJSON file, not this
projection. For future baseline changes, inspect the full or semantic diff again;
this inventory describes only the schema 1.0.0 migration.

See the [fixture guide](README.md) for development and the
[consumer migration guide](../docs/MIGRATING-TO-ASGS-2026.md) for upgrade implications.
