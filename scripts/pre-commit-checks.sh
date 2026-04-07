#!/bin/sh
# pre-commit-checks.sh — Catch common agent mistakes before commit.
# Validates the staged snapshot (index), not the working tree.
set -e

# 1. Reject empty (0-byte) staged files (new or modified).
#    Uses git cat-file on the staged blob, not the working tree file.
#    Skips submodule entries (mode 160000) — their gitlink objects have size 0.
for f in $(git diff --cached --name-only --diff-filter=ACMR); do
  staged_mode=$(git ls-files --stage -- "$f" | head -1 | cut -d' ' -f1)
  if [ "$staged_mode" = "160000" ]; then continue; fi
  staged_size=$(git cat-file -s ":$f" 2>/dev/null || echo "0")
  if [ "$staged_size" = "0" ]; then
    echo "ERROR: Empty (0-byte) file staged for commit: $f"
    echo "Remove it or add content before committing."
    exit 1
  fi
done

# 2. Reject sql.unsafe() without .cursor() on the same chain in staged TypeScript files.
#    Checks each occurrence using the staged blob content (not the working tree).
#    Uses a 4-line window heuristic — not AST parsing.
for f in $(git diff --cached --name-only --diff-filter=ACMR -- '*.ts'); do
  staged=$(git show ":$f" 2>/dev/null) || continue
  # Find line numbers with sql.unsafe( — skip lines with "no cursor needed" comment
  lines=$(echo "$staged" | grep -n 'sql\.unsafe(' 2>/dev/null | grep -v 'no cursor needed' | cut -d: -f1) || true
  for lineno in $lines; do
    if ! echo "$staged" | sed -n "${lineno},$((lineno + 3))p" | grep -q '\.cursor('; then
      echo "ERROR: sql.unsafe() without .cursor() at $f:$lineno (staged content)"
      echo "All Postgres reads must be cursor-based (memory <500MB rule)."
      exit 1
    fi
  done
done
