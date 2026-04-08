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

  flags=(--dump-db "/cache/${STATE}.dump")
  if [[ "$use_restore" == "true" ]]; then
    flags=(--restore-db "/cache/${STATE}.dump")
    used_restore=true
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
    python3 scripts/summarize-quarterly-run.py \
      --state "${STATE}" \
      --version "${VERSION}" \
      --cache-hit "${CACHE_HIT:-false}" \
      --attempts "${attempt}" \
      --success false \
      --final-exit-code "${final_exit_code}" \
      --used-restore "${used_restore}" \
      --restore-validation-failed "${restore_validation_failed}" \
      --log "${log_file}" \
      --output "${TELEMETRY_FILE}"
    echo "::error::${STATE}: persistent failure on attempt ${attempt} (exit code ${final_exit_code}) — not retrying"
    exit "${final_exit_code}"
  fi

  if [[ $attempt -le $MAX_RETRIES ]]; then
    echo "Transient failure — retrying in 30 seconds..."
    sleep 30
    rm -f "${OUTPUT_DIR}"/flat-white-*.ndjson.gz "${OUTPUT_DIR}/${STATE}.count"
  fi
done

latest_log="${LOG_DIR}/${STATE}-attempt-${attempt}.log"
python3 scripts/summarize-quarterly-run.py \
  --state "${STATE}" \
  --version "${VERSION}" \
  --cache-hit "${CACHE_HIT:-false}" \
  --attempts "${attempt}" \
  --success "${success}" \
  --final-exit-code "${final_exit_code}" \
  --used-restore "${used_restore}" \
  --restore-validation-failed "${restore_validation_failed}" \
  --log "${latest_log}" \
  --output "${TELEMETRY_FILE}"

if [[ "${success}" != "true" ]]; then
  echo "::error::${STATE}: failed after ${attempt} attempts (transient failures exhausted retries)"
  exit 1
fi
