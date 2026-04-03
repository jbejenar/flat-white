#!/bin/sh
# pre-commit-checks.sh — Catch common agent mistakes before commit.
set -e

# 1. Reject empty (0-byte) staged files (new or modified)
empty_files=""
for f in $(git diff --cached --name-only --diff-filter=ACM); do
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

# 2. Reject sql.unsafe() without .cursor() on the same chain in staged TypeScript files.
#    Checks each sql.unsafe( occurrence individually — a file with one cursor-based
#    query and one non-cursor query will still be caught.
for f in $(git diff --cached --name-only --diff-filter=ACM -- '*.ts'); do
  if grep -n 'sql\.unsafe(' "$f" 2>/dev/null | while IFS=: read -r lineno _; do
    # Check if .cursor( appears on the same line or the next few lines (chained call)
    if ! sed -n "${lineno},$((lineno + 3))p" "$f" | grep -q '\.cursor('; then
      echo "$f:$lineno"
      exit 1
    fi
  done; then
    : # all occurrences had .cursor()
  else
    echo "ERROR: sql.unsafe() without .cursor() in $f"
    echo "All Postgres reads must be cursor-based (memory <500MB rule)."
    exit 1
  fi
done
