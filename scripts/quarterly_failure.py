"""Classify the terminal stage failure, independently of historical telemetry."""

import json
import re
import sys
from pathlib import Path

NETWORK_ERROR = re.compile(
    r"ETIMEDOUT|ECONNRESET|ECONNREFUSED|ENETUNREACH|EAI_AGAIN|ENOTFOUND|"
    r"fetch failed|socket hang up|download stalled|TimeoutError|Failure kind: transient|"
    r"UND_ERR_(?:\w*TIMEOUT|SOCKET)|"
    r"HTTP (?:408|429|5[0-9][0-9])(?:[^0-9]|$)", re.IGNORECASE,
)
RESOURCE_ERROR = re.compile(
    r"could not resize shared memory|no space left on device|cannot allocate memory",
    re.IGNORECASE,
)


def classify(log_path: str) -> str:
    network = resource = False
    download_kind = None
    with Path(log_path).open(encoding="utf-8", errors="replace") as log:
        for line in log:
            try:
                event = json.loads(line)
            except json.JSONDecodeError:
                event = None
            if isinstance(event, dict) and event.get("event") == "stage_start":
                # A recovered error in a completed stage cannot explain why
                # a later stage failed. Telemetry still retains both stages.
                network = resource = False
                download_kind = None
            if line.startswith("[download] Failure kind: "):
                download_kind = line.strip().removeprefix("[download] Failure kind: ")
            network = network or bool(NETWORK_ERROR.search(line))
            resource = resource or bool(RESOURCE_ERROR.search(line))
    if download_kind is not None:
        return "network" if download_kind == "transient" else "permanent"
    return "network" if network else "resource" if resource else "permanent"


if __name__ == "__main__":
    print(classify(sys.argv[1]))
