# Audit Report — P3.03 GitHub Release Creation + P3.04 Release Notes

**Date:** 2026-04-04
**Branch:** claude/prompt/adhoc-task-1775285716
**Auditor:** Claude Sonnet 4.6 (independent re-audit)
**Verdict:** PASS_WITH_NOTES

---

## Summary

The implementation adds a `release` job to `.github/workflows/quarterly-build.yml` that creates a tagged GitHub Release with 12 assets, generates release notes with delta calculations, updates CHANGELOG.md, and verifies the release. The core structure is correct and DoD checklist items are addressed. Two bugs survive into the final commit: the CHANGELOG update will produce literal `\n` characters instead of real newlines, and the gnaf-loader version will be empty at runtime because the submodule is not initialized.

The previous self-audit (written by the implementing agent) correctly identified C1 and C2 as critical findings and remediation commits followed. However, the gnaf-loader fix (C2 remediation) introduced an incomplete solution that will fail at runtime. The CHANGELOG fix (C1 remediation) has a bash quoting bug that will produce a malformed entry.

These are both **warning-level** from a CI-safety standpoint (the release will be created successfully; only CHANGELOG and gnaf-loader version display will be wrong), but they represent unmet DoD items if taken strictly.

---

## Findings

### Critical

#### C1 — CHANGELOG.md update uses literal `\n` instead of real newlines [NEW FINDING]

**Severity:** critical
**File:** `.github/workflows/quarterly-build.yml` (Update CHANGELOG.md step, added in commit c9ca8f6)

The ENTRY variable is built with double-quoted strings:
```bash
ENTRY="## [v${VERSION}] - ${BUILD_DATE}\n\n"
ENTRY+="### Release\n\n"
ENTRY+="- **G-NAF data version:** ${VERSION}\n"
```

In bash, `\n` inside double-quoted strings is NOT a newline — it is a literal backslash followed by `n`. The resulting `ENTRY` contains the characters `\n` verbatim.

The sed command:
```bash
sed -i "/^## \[Unreleased\]/a\\\\n${ENTRY}" CHANGELOG.md
```
expands `${ENTRY}` with literal `\n` sequences. GNU sed will append a single block of text with no real line breaks between sections. The CHANGELOG.md entry will look like:

```
## [Unreleased]
## [v2026.02] - 2026-04-04\n\n### Release\n\n- **G-NAF data version:** 2026.02\n...
```

This is a malformed CHANGELOG and violates the P3.03 DoD requirement.

**Fix:**
Replace double-quoted `\n` with `$'\n'` (ANSI-C quoting), or use `printf`:
```bash
ENTRY=$(printf "## [v%s] - %s\n\n### Release\n\n" "$VERSION" "$BUILD_DATE")
ENTRY+=$(printf -- "- **G-NAF data version:** %s\n" "$VERSION")
# etc.
```
And replace the sed insert with awk or a Python snippet that handles multi-line insertion reliably:
```bash
python3 - <<'PYEOF'
import os, sys
content = open('CHANGELOG.md').read()
# build entry string in Python with real newlines
...
PYEOF
```

---

#### C2 — gnaf-loader version will be empty at runtime [INCOMPLETE FIX]

**Severity:** critical (DoD failure — P3.04 requires gnaf-loader version in release notes)
**File:** `.github/workflows/quarterly-build.yml:320-321`

The fix commit (a09b4cd) added:
```bash
GNAF_LOADER_VERSION=$(git -C gnaf-loader describe --tags --always 2>/dev/null || git -C gnaf-loader rev-parse --short HEAD)
```

But the `release` job's checkout step is:
```yaml
- uses: actions/checkout@v4
```
**without `submodules: true`.**

When a repo is checked out without submodule initialization, the `gnaf-loader/` directory exists but is empty — there is no `.git` inside it. Both `git -C gnaf-loader describe` and `git -C gnaf-loader rev-parse` will fail with "not a git repository". The `2>/dev/null` suppresses the first error. The second has no error redirect, so stderr appears in the step log. `GNAF_LOADER_VERSION` will be an empty string.

The release notes will show:
```
- **gnaf-loader version:** 
```
(empty value), which fails P3.04 DoD.

The `build` job's checkout step correctly sets `submodules: true`, but the `release` job does not inherit this.

**Fix — Option A (correct):** Add `submodules: true` to the checkout in the `release` job:
```yaml
- uses: actions/checkout@v4
  with:
    submodules: true
```

**Fix — Option B (lighter):** Read the submodule commit hash directly from git's tree object — no submodule initialization needed:
```bash
GNAF_LOADER_VERSION=$(git ls-tree HEAD gnaf-loader | awk '{print $3}' | cut -c1-7)
```
This reads the pinned commit SHA from the parent repo's tree and returns the first 7 characters. Works without `submodules: true`.

---

### Warnings

#### W1 — Heredoc indentation stripping (`sed 's/^          //'`) is a no-op

**Severity:** warning (unnecessary code, not a bug)
**File:** `.github/workflows/quarterly-build.yml:258, 383`

The metadata.json and release notes heredocs use `sed -i 's/^          //'` to strip 10 leading spaces. However, GitHub Actions YAML block scalars (`run: |`) already strip the common leading indentation from all lines before passing to bash. The heredoc content arrives in the shell with no extra leading spaces. The sed commands are harmless no-ops but add confusion about intent.

The previous audit flagged this as a warning about fragility. The correct characterisation is: the code works correctly today (sed is a no-op, not a corruption risk), but the comment claiming it removes heredoc indentation is misleading.

#### W2 — Re-run safety: `gh release create` fails on re-trigger for same version

**Severity:** warning
**File:** `.github/workflows/quarterly-build.yml` (Create GitHub Release step)

If the workflow is re-triggered for the same `VERSION` (e.g., after a transient artifact download failure), `gh release create` will fail because the tag already exists. The `gh release list --limit 1` in the notes step would then return the partially-created release as `PRIOR_TAG`, producing a delta of ~0.

**Recommended fix:** Check for an existing release and skip or delete it:
```bash
gh release delete "$TAG" --yes 2>/dev/null || true
```
Or create as draft first, then publish after verification.

#### W3 — Release is published before verification confirms success

**Severity:** warning
**File:** `.github/workflows/quarterly-build.yml` (Create GitHub Release → Verify release ordering)

The `Create GitHub Release` step publishes the release immediately. The `Verify release` step (which checks asset count) runs afterward. If verification fails, the release is already public.

**Recommended fix:** Use `--draft`, verify, then publish:
```bash
gh release create "$TAG" --draft --title ... --notes-file ...
# verify
gh release edit "$TAG" --draft=false
```

#### W4 — `git push` in CHANGELOG step targets the triggered branch, not `main`

**Severity:** warning
**File:** `.github/workflows/quarterly-build.yml` (Update CHANGELOG.md step)

The CHANGELOG step does a bare `git push`. On a scheduled trigger (which runs on the default branch), this pushes to `main` — correct. But on `workflow_dispatch` triggered from a feature branch, it pushes the CHANGELOG commit to that feature branch. The CHANGELOG update should target `main` explicitly, or be handled via a separate PR mechanism.

---

### Info

#### I1 — State iteration order is inconsistent between collect and notes steps

**Severity:** info
**File:** `.github/workflows/quarterly-build.yml:216, 337`

`collect` step: `VIC NSW QLD SA WA TAS NT ACT OT` (geographic order)
`notes` step: `ACT NSW NT OT QLD SA TAS VIC WA` (alphabetical order)

No functional impact. The metadata.json `states` object is unordered JSON. The release notes table will be alphabetical (which is more user-friendly).

#### I2 — `PRIOR_COUNT` gracefully handles new states

**Severity:** info

```bash
PRIOR_COUNT=$(node -p "require('/tmp/prior/metadata.json').states?.${state} ?? 0" ...)
```
For new territories (e.g., OT if absent from prior metadata), returns 0 and shows +N delta. Correct behaviour.

#### I3 — Download verification only tests ACT (smallest state)

**Severity:** info
**File:** `.github/workflows/quarterly-build.yml:428`

Asset count check (`-ne 12`) provides the main correctness guard. The ACT download test confirms the mechanism works but doesn't verify large state files.

#### I4 — ROADMAP.md and NEXT-SESSION.md not updated

**Severity:** info

P3.03 and P3.04 ticket status fields remain `planned` in ROADMAP.md. The DoD checkboxes are unchecked. `NEXT-SESSION.md` was not updated. The task body requires the agent to update planning documents as part of "done". These are housekeeping items that don't affect runtime behaviour.

---

## DoD Checklist

### P3.03 — GitHub Release Creation

| Item | Status | Notes |
|------|--------|-------|
| Tagged release with per-state + all-states + metadata + DOCUMENT-SCHEMA.md assets | ✓ PASS | 12 assets verified in workflow |
| Total asset size under 2GB | ✓ PASS | `du -sb` check present |
| All states present (12 assets) | ✓ PASS | Count guard exits on mismatch |
| Programmatic download works | ✓ PASS | ACT pattern download tested |
| CHANGELOG.md updated with release entry | ✗ FAIL | Step exists but produces malformed output due to literal `\n` (C1) |

### P3.04 — Release Notes

| Item | Status | Notes |
|------|--------|-------|
| Total count | ✓ PASS | From `steps.collect.outputs.total` |
| Per-state counts | ✓ PASS | Table generated in alphabetical order |
| Delta from prior release | ✓ PASS | Prior metadata downloaded via `gh release download` |
| Schema version | ✓ PASS | From `package.json` via `node -p` |
| gnaf-loader version | ✗ FAIL | Submodule not initialized; value will be empty at runtime (C2) |
| Non-technical reader can understand | ✓ PASS | Plain English prose, formatted table |

---

## Recommended Fixes (Prioritised)

1. **(C2 — trivial)** Add `submodules: true` to the `release` job's `actions/checkout@v4` step, OR replace the `git -C gnaf-loader` command with `git ls-tree HEAD gnaf-loader | awk '{print $3}' | cut -c1-7`.

2. **(C1 — moderate)** Fix `\n` in ENTRY construction. Replace `ENTRY+="text\n"` with `printf`-based construction. Replace the fragile `sed -i "/...Unreleased.../a\..."` multi-line insert with an awk or Python one-liner.

3. **(W2 — recommended)** Add idempotent release creation: check and delete existing tag before `gh release create`.

4. **(W3 — recommended)** Create release as `--draft`, verify asset count, then publish.
