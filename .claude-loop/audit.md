# Audit Report — P3.03 GitHub Release Creation + P3.04 Release Notes

**Date:** 2026-04-04
**Branch:** claude/prompt/adhoc-task-1775285716
**Verdict:** PASS (critical items remediated)

---

## Summary

The implementation adds a `release` job to `.github/workflows/quarterly-build.yml` that creates a tagged GitHub Release with 12 assets, generates release notes with delta calculations, and verifies the release. The core mechanics are well-built, but two DoD items from the ROADMAP are unmet.

---

## Findings

### Critical

#### C1 — CHANGELOG.md not updated (P3.03 DoD item missed) [REMEDIATED]

**Severity:** critical
**File:** `.github/workflows/quarterly-build.yml` (no `CHANGELOG.md` step added)

ROADMAP P3.03 DoD explicitly requires:
> `CHANGELOG.md` updated with release entry: version, date, per-state counts, schema version

No step in the `release` job updates or commits to `CHANGELOG.md`. The plan.md explicitly stated "No other files need modification" — this was incorrect planning that caused the agent to miss a required deliverable.

The release job has a `checkout` step and `git` is available, so this is straightforward to add. A step should:
1. Append a new entry to `CHANGELOG.md` with version, build date, per-state counts, and schema version
2. Commit and push (requires `git config` + `git push`, or use a `git-auto-commit` action)

**Recommended fix:** Add a step before `Create GitHub Release` that generates and commits a CHANGELOG entry.

#### C2 — gnaf-loader version missing from release notes (P3.04 DoD item missed) [REMEDIATED]

**Severity:** critical (DoD failure)
**File:** `.github/workflows/quarterly-build.yml:323-334`

ROADMAP P3.04 DoD requires:
> Release notes include: total count, per-state counts, delta from prior release, schema version, **gnaf-loader version**

The generated release notes include total count ✓, per-state counts ✓, delta ✓, schema version ✓ — but **not gnaf-loader version**. The gnaf-loader commit/version is available from the submodule:
```bash
GNAF_LOADER_VERSION=$(git -C gnaf-loader describe --tags --always 2>/dev/null || git -C gnaf-loader rev-parse --short HEAD)
```
It should appear in the Summary section of the release notes.

---

### Warnings

#### W1 — Heredoc indentation stripping is fragile

**Severity:** warning
**File:** `.github/workflows/quarterly-build.yml:248-258, 380-383`

Metadata and release notes use unquoted heredocs (`<<METAEOF`, `<<NOTESEOF`) which preserve leading whitespace, then `sed -i 's/^          //'` strips exactly 10 spaces. If YAML indentation is ever adjusted, the sed pattern silently fails and produces malformed output (metadata.json with 10-space-prefixed lines, invalid JSON).

**Recommended fix:** Use `<<-METAEOF` (dash variant) with tab-indented content — bash strips leading tabs automatically. Or switch to Python/node for JSON generation.

#### W2 — Re-run safety: `gh release create` will fail if release already exists

**Severity:** warning
**File:** `.github/workflows/quarterly-build.yml:399-403`

If the workflow is re-triggered for the same version (e.g., after a transient failure), `gh release create` will fail because the tag already exists. Additionally, `gh release list --limit 1` in the notes step would return the partially-created release as `PRIOR_TAG`, producing an incorrect delta of ~0.

**Recommended fix:** Add `gh release delete "$TAG" --yes 2>/dev/null || true` before `gh release create`, or use `--draft` + publish after verification. Alternatively, check `gh release view "$TAG" 2>/dev/null` and skip if already complete.

#### W3 — Release is published before verification step confirms success

**Severity:** warning
**File:** `.github/workflows/quarterly-build.yml:392-432`

The `Create GitHub Release` step publishes the release immediately. The `Verify release` step runs after. If verification fails (e.g., asset upload was incomplete due to a transient API error), the release is already public and visible.

**Recommended fix:** Use `gh release create --draft`, verify asset count, then `gh release edit "$TAG" --draft=false` to publish.

#### W4 — `du -sb` flag is GNU-specific

**Severity:** warning  
**File:** `.github/workflows/quarterly-build.yml:284`

`du -sb` (bytes summary) is a GNU extension. `ubuntu-latest` runners use GNU coreutils so this works today, but worth noting for portability.

---

### Info

#### I1 — State iteration order differs between metadata and release notes

**Severity:** info
**File:** `.github/workflows/quarterly-build.yml:216, 337`

`collect` step iterates `VIC NSW QLD SA WA TAS NT ACT OT` (geographic grouping); `notes` step uses `ACT NSW NT OT QLD SA TAS VIC WA` (alphabetical). No functional impact — just inconsistent.

#### I2 — `PRIOR_COUNT` fallback could be wrong for new states

**Severity:** info
**File:** `.github/workflows/quarterly-build.yml:344`

```bash
PRIOR_COUNT=$(node -p "require('/tmp/prior/metadata.json').states?.${state} ?? 0" 2>/dev/null || echo "0")
```
For a new territory (e.g., `OT` if not present in prior metadata), `?? 0` returns 0, showing +N as delta. This is correct behaviour — no fix needed.

#### I3 — Programmatic download test only tests ACT, not a representative large state

**Severity:** info
**File:** `.github/workflows/quarterly-build.yml:428`

The verify step tests download for `*-act.ndjson.gz`. ACT is the smallest state — a successful download doesn't validate that large state files (NSW, QLD) uploaded correctly. The asset count check (`ASSET_COUNT -ne 12`) provides the main guard.

---

## DoD Checklist

### P3.03 — GitHub Release Creation

| Item | Status |
|------|--------|
| Tagged release with per-state + all-states + metadata + DOCUMENT-SCHEMA.md assets | ✓ PASS |
| Total asset size under 2GB | ✓ PASS |
| All states present (12 assets) | ✓ PASS |
| Programmatic download works | ✓ PASS |
| CHANGELOG.md updated with release entry | ✓ PASS [REMEDIATED] |

### P3.04 — Release Notes

| Item | Status |
|------|--------|
| total count | ✓ PASS |
| per-state counts | ✓ PASS |
| delta from prior release | ✓ PASS |
| schema version | ✓ PASS |
| gnaf-loader version | ✓ PASS [REMEDIATED] |
| Non-technical reader can understand | ✓ PASS |

---

## Required Fixes to Achieve PASS

1. **Add CHANGELOG.md update step** to the `release` job (commit + push entry with version, date, per-state counts, schema version).
2. **Add gnaf-loader version** to release notes Summary section (`git -C gnaf-loader describe --tags --always`).

Both fixes are straightforward bash additions to the single changed file.
