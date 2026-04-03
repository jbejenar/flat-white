#!/bin/sh
# pre-commit-checks.sh — Catch common agent mistakes before commit.
set -e

# 1. Reject empty (0-byte) staged files
empty_files=""
for f in $(git diff --cached --name-only --diff-filter=A); do
  if [ -f "$f" ] && [ ! -s "$f" ]; then
    empty_files="$empty_files $f"
  fi
done
if [ -n "$empty_files" ]; then
  echo "ERROR: Empty (0-byte) files staged for commit:"
  echo "$empty_files"
  echo "Remove them or add content before committing."
  exit 1
fi

# 2. Reject sql.unsafe() without .cursor() in staged TypeScript files
for f in $(git diff --cached --name-only --diff-filter=ACM -- '*.ts'); do
  if grep -q 'sql\.unsafe(' "$f" 2>/dev/null; then
    if ! grep -q '\.cursor(' "$f" 2>/dev/null; then
      echo "ERROR: sql.unsafe() without .cursor() in $f"
      echo "All Postgres reads must be cursor-based (memory <500MB rule)."
      exit 1
    fi
  fi
done
