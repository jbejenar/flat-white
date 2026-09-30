#!/usr/bin/env python3
"""Read-only S3 gates: distinguish absence from failure and verify exact object bytes."""

import argparse
import base64
import json
from pathlib import Path
import re
import subprocess
import sys

from mirror_utils import file_sha256


def head(bucket, key, allow_missing=False):
    command = [
        "aws",
        "s3api",
        "head-object",
        "--bucket",
        bucket,
        "--key",
        key,
        "--output",
        "json",
    ]
    if not allow_missing:
        command += ["--checksum-mode", "ENABLED"]
    result = subprocess.run(command, capture_output=True, text=True, timeout=60)
    if result.returncode:
        if allow_missing and re.search(
            r"An error occurred \((?:404|NoSuchKey|NotFound)\) when calling the HeadObject operation:",
            result.stderr,
        ):
            return None
        raise ValueError(f"Cannot inspect s3://{bucket}/{key}: {result.stderr.strip()}")
    response = json.loads(result.stdout)
    if not isinstance(response, dict):
        raise ValueError(f"Invalid HeadObject response for {key}")
    return response


def verify(bucket, prefix, manifest, mappings):
    entries = [
        (Path(item["key"]).name, item["bytes"], item["sha256"])
        for item in manifest["files"] + manifest.get("artifacts", [])
    ]
    entries.append(("mappings.json", mappings.stat().st_size, file_sha256(mappings)))
    for name, size, checksum in entries:
        key = f"{prefix}/{name}"
        remote = head(bucket, key)
        expected = base64.b64encode(bytes.fromhex(checksum)).decode()
        if (
            remote.get("ContentLength") != size
            or remote.get("ChecksumSHA256") != expected
            or remote.get("ChecksumType") not in (None, "FULL_OBJECT")
        ):
            raise ValueError(
                f"Size or full-object SHA-256 mismatch: s3://{bucket}/{key}"
            )
        print(f"Verified {key}: {size} bytes and matching SHA-256")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=("exists", "verify"))
    parser.add_argument("--bucket", required=True)
    parser.add_argument("--key")
    parser.add_argument("--prefix")
    parser.add_argument("--manifest", type=Path)
    parser.add_argument("--mappings", type=Path)
    args = parser.parse_args()
    if args.mode == "exists":
        if not args.key:
            parser.error("exists requires --key")
        print(
            "skip="
            + (
                "true"
                if head(args.bucket, args.key, allow_missing=True) is not None
                else "false"
            )
        )
    else:
        if not all((args.prefix, args.manifest, args.mappings)):
            parser.error("verify requires --prefix, --manifest and --mappings")
        verify(
            args.bucket,
            args.prefix,
            json.loads(args.manifest.read_text()),
            args.mappings,
        )


if __name__ == "__main__":
    try:
        main()
    except (
        ValueError,
        KeyError,
        TypeError,
        OSError,
        subprocess.SubprocessError,
    ) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        sys.exit(1)
