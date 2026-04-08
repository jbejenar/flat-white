#!/usr/bin/env bash
#
# test.sh — integration test for scripts/detect-load-failure.sh
#
# Runs the detection script against 8 sample log fixtures and asserts
# the expected exit code (0 = retry-eligible Part-5 failure, 1 = real
# error or success — do not retry).
#
# Run via: bash test/integration/load-detection/test.sh
# Wired into CI via .github/workflows/ci.yml.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
DETECT="$PROJECT_DIR/scripts/detect-load-failure.sh"
FIXTURES="$SCRIPT_DIR/fixtures"

PASS=0
FAIL=0

# expect: <fixture-name> <exit-code> <expected-detect-exit>
expect() {
  local fixture="$1"
  local exit_code="$2"
  local expected="$3"
  local description="$4"

  local log_path="$FIXTURES/$fixture"
  if [[ ! -f "$log_path" ]]; then
    echo "FAIL: fixture not found: $fixture"
    FAIL=$((FAIL + 1))
    return
  fi

  set +e
  "$DETECT" "$log_path" "$exit_code"
  local actual=$?
  set -e

  if [[ "$actual" -eq "$expected" ]]; then
    echo "PASS: $fixture (exit=$exit_code) → detect=$actual ($description)"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $fixture (exit=$exit_code) → expected detect=$expected, got $actual ($description)"
    FAIL=$((FAIL + 1))
  fi
}

echo "Running detect-load-failure.sh integration tests..."
echo

# Negative cases: should NOT trigger retry (exit 1 from detect)
expect "success.log"               "0" "1" "successful run, no retry needed"
expect "failure-download.log"      "1" "1" "failed before Part 4 (download), real error"
expect "failure-prep.log"          "1" "1" "failed in Part 4 (prep SQL), real error"
# Important false-positive guard: Part 5 completed THEN something later failed.
# Without the "Part 5 completed?" check, the broad detection would incorrectly
# retry this and mask the real error in Part 6+.
expect "failure-part6-after-part5-success.log" "1" "1" "Part 5 succeeded then Part 6 failed — different problem, not retry-eligible"
# Edge case: success exit code with completion marker — should never happen but verify
expect "success.log"               "1" "1" "Part 5 completed (false alarm — exit code claims failure but log shows success)"

# Positive cases: should trigger retry (exit 0 from detect)
expect "failure-act-lga_pid.log"        "1" "0" "ACT lga_pid column mismatch — Part 5"
expect "failure-qld-ward_pid.log"       "1" "0" "QLD ward_pid column mismatch — Part 5"
expect "failure-ot-ce_pid.log"          "1" "0" "OT ce_pid column mismatch — Part 5"
expect "failure-tas-se_upper_pid.log"   "1" "0" "TAS se_upper_pid column mismatch — Part 5"
expect "failure-future-part5.log"       "1" "0" "hypothetical future Part 5 error — broad detection"

echo
echo "Result: $PASS passed, $FAIL failed"

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi

exit 0
