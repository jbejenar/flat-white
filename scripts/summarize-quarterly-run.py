#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
from pathlib import Path


def parse_bool(value: str) -> bool:
    return value.lower() in {"1", "true", "yes", "y"}


def main() -> int:
    parser = argparse.ArgumentParser(description="Summarize a quarterly build state run")
    parser.add_argument("--state", required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--cache-hit", required=True)
    parser.add_argument("--attempts", required=True, type=int)
    parser.add_argument("--success", required=True)
    parser.add_argument("--final-exit-code", required=True, type=int)
    parser.add_argument("--used-restore", required=True)
    parser.add_argument("--restore-validation-failed", required=True)
    parser.add_argument("--log", action="append", default=[])
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    stage_durations: dict[str, int] = {}
    fallback_retry_count = 0
    network_error_detected = False
    resource_error_detected = False

    for log_path in args.log:
        for raw_line in Path(log_path).read_text(encoding="utf-8", errors="replace").splitlines():
            line = raw_line.strip()
            if "retrying with --no-boundary-tag" in line:
                fallback_retry_count += 1
            if any(
                token in line
                for token in [
                    "ETIMEDOUT",
                    "ECONNRESET",
                    "ECONNREFUSED",
                    "ENETUNREACH",
                    "EAI_AGAIN",
                    "ENOTFOUND",
                    "download failed",
                    "fetch failed",
                    "socket hang up",
                ]
            ):
                network_error_detected = True
            if any(
                token in line
                for token in [
                    "could not resize shared memory",
                    "no space left on device",
                    "cannot allocate memory",
                ]
            ):
                resource_error_detected = True
            if not line.startswith("{"):
                continue
            try:
                payload = json.loads(line)
            except json.JSONDecodeError:
                continue
            if payload.get("event") == "stage_end" and "elapsed_s" in payload:
                stage = payload.get("stage")
                if isinstance(stage, str):
                    stage_durations[stage] = int(payload["elapsed_s"])

    summary = {
        "state": args.state,
        "version": args.version,
        "cacheHit": parse_bool(args.cache_hit),
        "attempts": args.attempts,
        "success": parse_bool(args.success),
        "finalExitCode": args.final_exit_code,
        "usedRestore": parse_bool(args.used_restore),
        "restoreValidationFailed": parse_bool(args.restore_validation_failed),
        "fallbackRetryCount": fallback_retry_count,
        "networkErrorDetected": network_error_detected,
        "resourceErrorDetected": resource_error_detected,
        "stageDurations": stage_durations,
    }

    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
