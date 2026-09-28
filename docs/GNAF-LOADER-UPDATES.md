# gnaf-loader update checks

The `gnaf-loader Update Check` workflow checks `minus34/gnaf-loader` every Monday at 09:00 UTC. It reads the committed submodule pin, discovers the latest upstream release (or a tag when no release exists), and fetches that exact tag from upstream. The configured submodule `origin` may be a fork whose tags have not been synchronized.

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
