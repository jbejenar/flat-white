#!/usr/bin/env bash
set -euo pipefail

STATE="${1:?state is required}"
VERSION="${2:?version is required}"
DOCKER_IMAGE="${3:?docker image is required}"
OUTPUT_DIR="${4:-output}"
CACHE_DIR="${5:-cache}"

MAX_RETRIES="${MAX_RETRIES:-2}"
CACHE_FILE="${CACHE_DIR}/${STATE}.dump"
LOG_DIR="${OUTPUT_DIR}/logs"
TELEMETRY_FILE="${OUTPUT_DIR}/quarterly-telemetry-${STATE}.json"

mkdir -p "$OUTPUT_DIR" "$CACHE_DIR" "$LOG_DIR"

attempt=0
success=false
final_exit_code=1
restore_validation_failed=false
used_restore=false
# `use_restore` is recomputed at the top of every loop iteration based on
# (a) whether the GH Actions cache restore landed a dump file BEFORE attempt 1
# and (b) whether a prior attempt within this loop produced a fresh dump
# (gnaf-loader succeeded but a downstream stage failed). Either way, the
# next attempt restores from $CACHE_FILE instead of re-running gnaf-loader.
# This is the load-bearing optimisation that turns a transient flatten
# failure on NSW from a 1.5-2hr re-run into a ~5min restore.
use_restore=false

if [[ -n "${CACHE_MATCHED_KEY:-}" && -f "$CACHE_FILE" ]]; then
  use_restore=true
elif [[ "${CACHE_HIT:-false}" == "true" && -f "$CACHE_FILE" ]]; then
  use_restore=true
fi

while [[ $attempt -le $MAX_RETRIES ]]; do
  attempt=$((attempt + 1))
  log_file="${LOG_DIR}/${STATE}-attempt-${attempt}.log"

  echo "--- Attempt $attempt of $((MAX_RETRIES + 1)) for ${STATE} ---"

  if [[ "$use_restore" == "true" && -f "$CACHE_FILE" ]]; then
    flags=(--restore-db "/cache/${STATE}.dump")
    used_restore=true
  else
    flags=(--dump-db "/cache/${STATE}.dump")
  fi

  set +e
  docker run --rm \
    -v "$(pwd)/${OUTPUT_DIR}:/output" \
    -v "$(pwd)/${CACHE_DIR}:/cache" \
    -e "GNAF_VERSION=${VERSION}" \
    -e "DOWNLOAD_URL_GNAF=${DOWNLOAD_URL_GNAF_EFFECTIVE:-}" \
    -e "DOWNLOAD_URL_ADMIN_BDYS=${DOWNLOAD_URL_ADMIN_BDYS_EFFECTIVE:-}" \
    -e "ADMIN_BDYS_EXTRACTED_DIR=${ADMIN_BDYS_EXTRACTED_DIR_EFFECTIVE:-}" \
    "${DOCKER_IMAGE}" \
    --states "${STATE}" \
    --split-states \
    --compress \
    --output /output \
    "${flags[@]}" 2>&1 | tee "${log_file}"
  final_exit_code=${PIPESTATUS[0]}
  set -e

  if [[ $final_exit_code -eq 0 ]]; then
    success=true
    if [[ $attempt -gt 1 ]]; then
      echo "::warning::${STATE}: succeeded on attempt ${attempt} after $((attempt - 1)) retry(ies)"
    fi
    break
  fi

  if grep -q "Restored database failed validation" "${log_file}" 2>/dev/null; then
    echo "::warning::${STATE}: cached restore failed validation on attempt ${attempt}; rebuilding from source"
    restore_validation_failed=true
    use_restore=false
    rm -f "${CACHE_FILE}"
    continue
  fi

  is_transient=false
  if [[ $final_exit_code -eq 137 ]]; then
    is_transient=true
    echo "::warning::${STATE}: OOM kill detected (exit 137) on attempt ${attempt}"
  elif [[ $final_exit_code -eq 143 ]]; then
    is_transient=true
    echo "::warning::${STATE}: container killed (exit 143) on attempt ${attempt}"
  elif grep -qiE '(ETIMEDOUT|ECONNRESET|ECONNREFUSED|ENETUNREACH|EAI_AGAIN|ENOTFOUND|download failed|fetch failed|socket hang up)' "${log_file}" 2>/dev/null; then
    is_transient=true
    echo "::warning::${STATE}: network/download error detected on attempt ${attempt}"
  elif grep -qiE '(could not resize shared memory|no space left on device|cannot allocate memory)' "${log_file}" 2>/dev/null; then
    is_transient=true
    echo "::warning::${STATE}: resource exhaustion detected on attempt ${attempt}"
  fi

  if [[ "$is_transient" == "false" ]]; then
    # Pass every attempt log so the summary captures fallback retries / network
    # / resource flags from earlier attempts (not just the one that failed).
    log_args=()
    for f in "${LOG_DIR}/${STATE}-attempt-"*.log; do
      [[ -f "$f" ]] && log_args+=(--log "$f")
    done
    python3 scripts/summarize-quarterly-run.py \
      --state "${STATE}" \
      --version "${VERSION}" \
      --cache-hit "${CACHE_HIT:-false}" \
      --attempts "${attempt}" \
      --success false \
      --final-exit-code "${final_exit_code}" \
      --used-restore "${used_restore}" \
      --restore-validation-failed "${restore_validation_failed}" \
      "${log_args[@]}" \
      --output "${TELEMETRY_FILE}"
    echo "::error::${STATE}: persistent failure on attempt ${attempt} (exit code ${final_exit_code}) — not retrying"
    exit "${final_exit_code}"
  fi

  if [[ $attempt -le $MAX_RETRIES ]]; then
    # If a dump file is present, restore from it on the next attempt instead
    # of re-running gnaf-loader. The dump came from one of:
    #   - this loop's previous attempt (gnaf-loader succeeded; flatten/etc
    #     failed transiently); the post-load validate step in
    #     docker-entrypoint.sh has already vouched for it.
    #   - the GH Actions cache restore at job start.
    # In either case, restoring is the right call: it skips the slow load
    # stage entirely. The cache-validate step inside the entrypoint will
    # re-verify on restore so a corrupt dump still gets caught.
    #
    # The "restore validation failed" branch above explicitly deletes the
    # cache file before continuing, so this condition only enables restore
    # when we have a *trusted* dump.
    if [[ -f "$CACHE_FILE" ]]; then
      if [[ "$use_restore" != "true" ]]; then
        echo "::notice::${STATE}: gnaf-loader dump present; next attempt will restore from it (skipping load)"
      fi
      use_restore=true
    fi
    echo "Transient failure — retrying in 30 seconds..."
    sleep 30
    rm -f "${OUTPUT_DIR}"/flat-white-*.ndjson.gz "${OUTPUT_DIR}/${STATE}.count"
  fi
done

log_args=()
for f in "${LOG_DIR}/${STATE}-attempt-"*.log; do
  [[ -f "$f" ]] && log_args+=(--log "$f")
done
python3 scripts/summarize-quarterly-run.py \
  --state "${STATE}" \
  --version "${VERSION}" \
  --cache-hit "${CACHE_HIT:-false}" \
  --attempts "${attempt}" \
  --success "${success}" \
  --final-exit-code "${final_exit_code}" \
  --used-restore "${used_restore}" \
  --restore-validation-failed "${restore_validation_failed}" \
  "${log_args[@]}" \
  --output "${TELEMETRY_FILE}"

if [[ "${success}" != "true" ]]; then
  echo "::error::${STATE}: failed after ${attempt} attempts (transient failures exhausted retries)"
  exit 1
fi
