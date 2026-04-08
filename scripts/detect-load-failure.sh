#!/usr/bin/env bash
#
# detect-load-failure.sh
#
# Determines whether a gnaf-loader failure happened during boundary tagging
# (Part 5 of 6) and is therefore eligible for retry with --no-boundary-tag,
# letting flat-white's spatial-join fallback in address_full_prep.sql
# populate the boundary tables instead.
#
# Usage:
#   detect-load-failure.sh <load-log-path> <load-exit-code>
#
# Exit codes:
#   0 — Part-5 failure detected, retry with --no-boundary-tag is appropriate
#   1 — Not a Part-5 failure (real error, do not retry — fail loudly)
#
# Detection logic:
#   The condition is intentionally BROAD: any non-zero exit code from
#   gnaf-loader where the log shows we reached "Part 5 of 6 : Start
#   boundary tagging" is treated as Part-5-eligible. This catches:
#     - Today's column-mismatch bugs (lga_pid, ward_pid, ce_pid, se_lower_pid)
#     - Any future error gnaf-loader introduces in Part 5
#     - Schema-mismatch errors caused by per-state filter bugs
#   It does NOT catch:
#     - Failures before Part 5 (download, raw GNAF load, prep SQL) — those
#       are real errors and should fail loudly
#
# When upstream gnaf-loader is fixed (E1.20), the first attempt succeeds
# and this detection never fires. When upstream has a bug (today's
# situation), the retry takes over automatically.
#
# Tested by test/integration/load-detection/test.sh against 7 sample
# log fixtures covering all known failure modes plus negative cases.

set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "usage: $0 <load-log-path> <load-exit-code>" >&2
  exit 2
fi

LOG_PATH="$1"
EXIT_CODE="$2"

# Validate exit code is a non-negative integer
if [[ ! "$EXIT_CODE" =~ ^[0-9]+$ ]]; then
  echo "error: exit code must be a non-negative integer, got '$EXIT_CODE'" >&2
  exit 2
fi

# Successful run — no retry needed
if [[ "$EXIT_CODE" -eq 0 ]]; then
  exit 1
fi

# Log file missing — can't classify, treat as real error
if [[ ! -f "$LOG_PATH" ]]; then
  echo "error: log file not found: $LOG_PATH" >&2
  exit 1
fi

# Failed AND log shows we reached Part 5 → Part-5-eligible failure
if grep -q "Part 5 of 6 : Start boundary tagging" "$LOG_PATH"; then
  exit 0
fi

# Failed before Part 5 → real error
exit 1
