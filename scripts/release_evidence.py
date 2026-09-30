#!/usr/bin/env python3
"""Index small release evidence separately from address ingestion inputs."""
import argparse
import hashlib
import json
from pathlib import Path
import re

STATES = ("ACT", "NSW", "NT", "OT", "QLD", "SA", "TAS", "VIC", "WA")
NAME = re.compile(r"^[A-Za-z0-9][A-Za-z0-9_.-]*\.(json|md|jsonl\.gz)$")


def validate_index(record, version=None, commit=None):
    if (
        record.get("formatVersion") != 1
        or not re.fullmatch(
            r"\d{4}\.(02|05|08|11)(\.[1-9]\d*)?", record.get("releaseVersion", "")
        )
        or not re.fullmatch(r"[a-f0-9]{40}", record.get("sourceCommit", ""))
        or (version is not None and record["releaseVersion"] != version)
        or (commit is not None and record["sourceCommit"] != commit)
    ):
        raise ValueError("Invalid evidence index version or source commit")
    entries = record.get("files")
    if not isinstance(entries, list) or not entries:
        raise ValueError("Empty evidence index")
    names = set()
    for entry in entries:
        name = entry.get("name", "")
        if (
            not NAME.fullmatch(name)
            or name in names
            or name in ("evidence-index.json", "mappings.json")
            or type(entry.get("bytes")) is not int
            or entry["bytes"] <= 0
            or not re.fullmatch(r"[a-f0-9]{64}", entry.get("sha256", ""))
        ):
            raise ValueError("Invalid, duplicate or recursive evidence entry")
        names.add(name)
    required = {
        "source-lock.json",
        "metadata.json",
        "verification-report.json",
        "verification-report.md",
        "DOCUMENT-SCHEMA.md",
        "comparison.json",
        "comparison.md",
    }
    required.update(
        f"{kind}-{state}.json"
        for kind in ("reconciliation", "build-provenance")
        for state in STATES
    )
    if record["releaseVersion"].count(".") == 2:
        required.update(f"comparison-{state}.jsonl.gz" for state in STATES)
    if not required <= names:
        raise ValueError("Incomplete evidence index")
    return entries


def file_entry(path):
    if (
        not NAME.fullmatch(path.name)
        or path.is_symlink()
        or path.name == "mappings.json"
    ):
        raise ValueError(f"Invalid evidence asset: {path.name}")
    checksum = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            checksum.update(block)
    return {
        "name": path.name,
        "bytes": path.stat().st_size,
        "sha256": checksum.hexdigest(),
    }


def index(directory, version, commit):
    required = {
        "source-lock.json",
        "metadata.json",
        "verification-report.json",
        "verification-report.md",
        "DOCUMENT-SCHEMA.md",
        "comparison.json",
        "comparison.md",
    }
    required.update(
        f"{kind}-{state}.json"
        for kind in ("reconciliation", "build-provenance")
        for state in STATES
    )
    paths = sorted(
        path
        for path in directory.iterdir()
        if NAME.fullmatch(path.name) and path.name != "evidence-index.json"
    )
    if not required <= {path.name for path in paths}:
        raise ValueError(
            f"Missing release evidence: {sorted(required - {p.name for p in paths})}"
        )
    metadata = json.loads((directory / "metadata.json").read_text())
    if (
        metadata.get("version") != version
        or metadata.get("sourceLock") != "source-lock.json"
    ):
        raise ValueError(
            "Evidence metadata has the wrong release version or source lock"
        )
    result = {
        "formatVersion": 1,
        "releaseVersion": version,
        "sourceCommit": commit,
        "files": [file_entry(path) for path in paths],
    }
    validate_index(result, version, commit)
    (directory / "evidence-index.json").write_text(json.dumps(result, indent=2) + "\n")


def manifest_entries(directory, prefix):
    # Historical releases have no source lock/evidence index. Recovery must not
    # invent evidence from today's checkout for those releases.
    if not directory.exists():
        return []
    record = json.loads((directory / "evidence-index.json").read_text())
    entries = validate_index(record)
    if prefix != "data/address/" + record["releaseVersion"].replace(".", "-"):
        raise ValueError("Evidence release does not match the publication prefix")
    names = [entry["name"] for entry in entries]
    if len(set(names)) != len(names) or "evidence-index.json" in names:
        raise ValueError("Duplicate or recursive evidence index")
    if {path.name for path in directory.iterdir()} != set(names) | {
        "evidence-index.json"
    }:
        raise ValueError("Missing or unexpected evidence assets")
    result = []
    for expected in entries:
        if not NAME.fullmatch(expected["name"]):
            raise ValueError("Unsafe evidence name")
        actual = file_entry(directory / expected["name"])
        if actual != expected:
            raise ValueError(f"Evidence checksum mismatch: {expected['name']}")
        result.append(
            {
                "key": f"{prefix}/{actual['name']}",
                "bytes": actual["bytes"],
                "sha256": actual["sha256"],
            }
        )
    own = file_entry(directory / "evidence-index.json")
    result.append(
        {
            "key": f"{prefix}/{own['name']}",
            "bytes": own["bytes"],
            "sha256": own["sha256"],
        }
    )
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["index", "manifest"])
    parser.add_argument("--directory", type=Path, required=True)
    parser.add_argument("--version")
    parser.add_argument("--commit")
    parser.add_argument("--prefix")
    args = parser.parse_args()
    if args.command == "index":
        if not args.version or not args.commit:
            parser.error("index requires --version and --commit")
        index(args.directory, args.version, args.commit)
    else:
        if not args.prefix:
            parser.error("manifest requires --prefix")
        print(json.dumps(manifest_entries(args.directory, args.prefix)))
