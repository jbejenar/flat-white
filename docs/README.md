# Documentation

Start with the guide for the job you need to do. Current guides describe
**schema 1.0.0 and ASGS 2026**. Release-specific metadata remains the authority
for a downloaded file; older published releases keep their original contract.

> **Schema 1.0.0 change:** six census fields have new geographic meanings even
> though the JSON structure is unchanged. The
> [migration guide](MIGRATING-TO-ASGS-2026.md) explains the impact and upgrade steps.

## Use the data

| I want to…                            | Read                                                   |
| ------------------------------------- | ------------------------------------------------------ |
| Download a state and check it         | [README quick start](../README.md#quick-start)         |
| Upgrade an existing consumer          | [ASGS 2026 migration guide](MIGRATING-TO-ASGS-2026.md) |
| Understand fields, nulls and versions | [Document schema](DOCUMENT-SCHEMA.md)                  |
| Trace a value to its source           | [Field provenance](FIELD-PROVENANCE.md)                |
| Understand geographic assignments     | [Boundary processing](BOUNDARIES.md)                   |
| Review changes to published files     | [Changelog](../CHANGELOG.md)                           |

## Build and maintain it

| I want to…                            | Read                                                                                          |
| ------------------------------------- | --------------------------------------------------------------------------------------------- |
| Make and test a change                | [Contributor instructions](../AGENTS.md) and [fixture guide](../fixtures/README.md)           |
| Look up fixture columns or edge cases | [Fixture schema](../fixtures/SCHEMA-REFERENCE.md) and [edge cases](../fixtures/edge-cases.md) |
| Publish a quarter or patch            | [Release procedure](RELEASING.md)                                                             |
| Diagnose a failed build               | [Runbook](RUNBOOK.md)                                                                         |
| Review an upstream loader update      | [Loader update checks](GNAF-LOADER-UPDATES.md)                                                |
| Use a dedicated build runner          | [Self-hosted runners](SELF-HOSTED-RUNNER.md)                                                  |
| Understand the ASGS decision          | [ASGS 2026 decision record](decisions/DEC-008-asgs-2026.md)                                   |
| Understand other design choices       | [Architectural decisions](decisions/)                                                         |
| Find current follow-up work           | [Next work](../NEXT-WORK.md)                                                                  |
| Report a security issue               | [Security policy](../SECURITY.md)                                                             |

## Read historical evidence

These records are useful context, not current build instructions:

- [Earlier boundary incidents](history/BOUNDARIES-PRE-1.0.md): the old dual-path implementation and its removal.
- [April 2026 performance baseline](PERFORMANCE.md) and [NSW memory analysis](NSW-MEMORY-ANALYSIS.md): measurements and estimates from before this migration.
- [Roadmap](../ROADMAP.md) and [earlier session notes](../NEXT-SESSION.md): dated plans and implementation history. Their old examples do not define schema 1.0.0.

Changed current guidance is marked **Schema 1.0.0 change**. Historical sections
keep their original versions and dates so that old decisions and incidents remain
traceable. The [community announcement](COMMUNITY-ANNOUNCEMENT.md) is a draft and
must be checked against an actual published release before use.
