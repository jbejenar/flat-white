# gnaf-loader update checks

> **Schema 1.0.0 change:** the current pin builds on upstream release `202608`,
> with the authority-cleanup repair described below. A newer tag alone is not evidence
> that its output remains compatible. See the [migration guide](MIGRATING-TO-ASGS-2026.md).

The `gnaf-loader Update Check` workflow checks `minus34/gnaf-loader` every Monday at 09:00 UTC. It reads the committed submodule pin, discovers the latest upstream release (or a tag when no release exists), and fetches that exact tag from upstream. The configured submodule `origin` may be a fork whose tags have not been synchronized.

## Current pin and upstream repair

The pin is [`c2f6de7`](https://github.com/jbejenar/gnaf-loader/commit/c2f6de7cc9b511cfc850ace2d06345de5169895b),
the `202608` release plus the fix submitted in
[upstream PR #103](https://github.com/minus34/gnaf-loader/pull/103). The release's
authority-table query contains a literal `%` before the schema name and selects
no tables. That skips field-name normalization, deduplication and authority keys;
electoral preparation then fails or multiplies polygon rows.

The contribution uses a parameterized exact schema comparison and a literal
`_aut` suffix. The existing configured fork hosts this immutable commit while
upstream review is pending. The submodule working tree stays clean; no build-time
patch is applied. This is a temporary pin exception, not a new source contract.
The census preparation SQL and NDJSON baseline are unchanged by this repair.

CI now runs seven small database tests from the pinned loader inside the built
production image, with networking disabled. They exercise the actual cleanup
function for both raw schemas, legacy DBF columns, duplicate/conflicting codes,
schema isolation and repeated cleanup. They also execute the real electoral
preparation SQL and require populated tables with unique polygon IDs.

```bash
docker build -t flat-white:ci .
bash test/integration/loader-authority/test.sh flat-white:ci
```

The test container creates and removes its own Postgres database. It needs no
national data. Keep this check alongside the normal fixture regression: the
fixture starts with normalized authority tables and cannot catch this failure.

The updater should report `ahead` against the unpatched `202608` tag. Once
upstream includes the repair, review a new pin and rerun these checks. A squash
or rebase upstream can make histories diverge; investigate that result and move
the pin deliberately rather than dropping the fix to satisfy ancestry checks.

## Safe checks and update PRs

Manual runs default to a dry run. To test a workflow change from its branch:

```bash
gh workflow run gnaf-loader-update.yml --ref <branch> -f dry_run=true
gh run list --workflow gnaf-loader-update.yml --branch <branch> --limit 5
gh run view <run-id> --log
```

Detection fetches Git history but leaves the submodule working tree, pin, and remote URL unchanged. The job summary reports the current commit, upstream tag, resolved commit, and result:

| Result       | Behavior                                                                                                                                       |
| ------------ | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| `no-release` | No releases or tags exist; no PR.                                                                                                              |
| `current`    | Already pinned to the release commit; no PR.                                                                                                   |
| `ahead`      | The current pin contains the release plus additional commits; no downgrade.                                                                    |
| `update`     | Upstream contains the current pin; a forward update is available.                                                                              |
| Failure      | API/Git errors, incomplete history, malformed metadata, or divergent fork history require investigation. They are not reported as "no update." |

Scheduled runs can create a draft update PR. To explicitly request the same behavior manually, run from the default branch:

```bash
gh workflow run gnaf-loader-update.yml --ref main -f dry_run=false
```

An existing PR for the same tag, including a closed PR, is preserved. Reopen an intentionally closed update if it should be reconsidered. An orphaned automation branch from a failed PR creation can be recovered on the next run. Concurrent checks are serialized.

Update PRs start as drafts because fixture CI does not execute a complete upstream loader run. Review changes to the loader, settings, and raw/reference table definitions against flat-white's SQL and boundary preparation. Add targeted committed fixtures when needed; do not download the full G-NAF dataset for development tests. If GitHub displays **Approve workflows to run** on the generated PR, a maintainer must approve its CI before proceeding. This is the supported behavior for [PRs created using `GITHUB_TOKEN`](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/trigger-a-workflow#triggering-a-workflow-from-a-workflow).

## Recovering a stopped schedule

GitHub can disable scheduled workflows after repository inactivity. A code fix does not itself establish that the schedule is enabled. Inspect the workflow state and re-enable it when necessary:

```bash
gh api repos/jbejenar/flat-white/actions/workflows/gnaf-loader-update.yml --jq .state
gh workflow enable gnaf-loader-update.yml
gh workflow run gnaf-loader-update.yml --ref main -f dry_run=true
```

Expected workflow state: `active`. The manual dry run verifies discovery and ancestry without opening a loader update PR.

## Regression tests

```bash
npm test -- test/unit/gnaf-loader-update.test.ts
actionlint .github/workflows/gnaf-loader-update.yml
```

The tests use temporary Git repositories and mocked GitHub responses. They cover missing fork tags, annotated/lightweight tags, conflicting local tags, retaining fork fixes, upstream merges, divergence, shallow history, and API failures. They never modify the committed `gnaf-loader/` checkout.

## Review census compatibility before accepting a pin

Check the raw mesh-block layout, `mb_2026_code` assignment and prepared
`abs_2026_mb` hierarchy against flat-white's SQL. The fixture executes the pinned
upstream mesh-block preparation section; keep that coverage when the upstream
file changes. Retained 2021 fixture tables must not become runtime fallbacks.

Run the fixture and relevant unit/integration checks, and review the document
contract, schema version, ASGS metadata, OpenSearch mapping and fixture baseline
if output meanings change. Use small committed test inputs for new compatibility
cases. Fixture CI does not prove a complete national load; record that limit in
the update PR and assess production evidence separately.
