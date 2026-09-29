#!/usr/bin/env python3
"""Recover a mirror from checksum-verified public release files, without rebuilding."""

import argparse
import base64
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys

from source_version_policy import validate_production_version
from mirror_utils import file_sha256

STATES = ("ACT", "NSW", "NT", "OT", "QLD", "SA", "TAS", "VIC", "WA")


def require(condition, message):
    if not condition:
        raise ValueError(message)


def github(path, raw=False):
    command = ["gh", "api", "--method", "GET", path]
    if raw:
        command += ["-H", "Accept: application/octet-stream"]
    result = subprocess.run(command, capture_output=True, timeout=60)
    require(result.returncode == 0,
            f"GitHub read failed for {path}: {result.stderr.decode(errors='replace').strip()}")
    if raw:
        return result.stdout
    data = json.loads(result.stdout)
    require(isinstance(data, dict), "Unexpected GitHub API response")
    return data


def digest(data):
    return "sha256:" + hashlib.sha256(data).hexdigest()


def resolve(repository, tag):
    require(re.fullmatch(r"[\w.-]+/[\w.-]+", repository), "Invalid repository")
    require(re.fullmatch(r"v[0-9]{4}\.(02|05|08|11)(?:\.[1-9][0-9]*)?", tag),
            "Recovery needs an explicit quarterly release tag, optionally with a patch")
    release_version = tag[1:]
    version = ".".join(release_version.split(".")[:2])
    validate_production_version(version)
    prefix = f"repos/{repository}"
    release = github(f"{prefix}/releases/tags/{tag}")
    require(release.get("tag_name") == tag and release.get("draft") is False
            and release.get("prerelease") is False,
            "Only a published, non-prerelease release may be mirrored; review drafts first")
    target = github(f"{prefix}/git/ref/tags/{tag}")["object"]
    for _ in range(5):
        if target.get("type") != "tag":
            break
        target = github(f"{prefix}/git/tags/{target['sha']}")["object"]
    commit = target.get("sha", "")
    require(target.get("type") == "commit" and re.fullmatch(r"[0-9a-f]{40}", commit),
            "Release tag must resolve to a commit")

    def asset(name):
        matches = [item for item in release.get("assets", []) if item.get("name") == name]
        require(len(matches) == 1, f"Expected exactly one published asset: {name}")
        item = matches[0]
        require(item.get("state") == "uploaded" and type(item.get("size")) is int
                and item["size"] > 0
                and re.fullmatch(r"sha256:[0-9a-f]{64}", item.get("digest") or ""),
                f"Asset is incomplete or lacks a SHA-256 digest: {name}")
        return item

    metadata_asset = asset("metadata.json")
    require(metadata_asset["size"] < 1024 * 1024, "Unexpectedly large release metadata")
    metadata_bytes = github(f"{prefix}/releases/assets/{metadata_asset['id']}", raw=True)
    require(len(metadata_bytes) == metadata_asset["size"]
            and digest(metadata_bytes) == metadata_asset["digest"], "Metadata digest mismatch")
    metadata = json.loads(metadata_bytes)
    require(isinstance(metadata, dict), "Invalid release metadata")
    require(metadata.get("version") == release_version and metadata.get("gnafVersion") == version,
            "Release metadata does not match the selected version")
    validate_production_version(metadata.get("adminBoundariesVersion", ""), "Admin Boundaries")
    schema = metadata.get("schemaVersion", "")
    require(re.fullmatch(r"1\.[0-9]+\.[0-9]+", schema) and metadata.get("asgsYear") == 2026,
            "Recovery requires the schema 1.x / ASGS 2026 contract")
    counts = metadata.get("states", {})
    require(isinstance(counts, dict) and set(counts) == set(STATES)
            and all(type(n) is int and n > 0 for n in counts.values())
            and type(metadata.get("totalCount")) is int
            and sum(counts.values()) == metadata["totalCount"], "Invalid release state counts")
    asset("verification-report.md")
    files = {}
    for state in STATES:
        item = asset(f"flat-white-{release_version}-{state.lower()}.ndjson.gz")
        files[state] = {"bytes": item["size"], "sha256": item["digest"][7:], "records": counts[state]}

    def source_json(path):
        content = github(f"{prefix}/contents/{path}?ref={commit}")
        require(content.get("encoding") == "base64", f"Cannot read source file: {path}")
        return json.loads(base64.b64decode(content["content"]))

    package = source_json("package.json")
    mappings = source_json("opensearch/address-mappings.json")
    require(package.get("version") == schema and mappings.get("_meta") == {
        "schemaVersion": schema, "asgsYear": 2026,
    }, "Source schema/mappings do not match the published release")
    return {"repository": repository, "tag": tag,
            "source_commit": commit, "release_id": release["id"], "version": version,
            "release_version": release_version, "schema_version": schema,
            "admin_bdys_version": metadata["adminBoundariesVersion"],
            "files": files, "mappings": mappings}


def prepare(plan, artifacts, mappings_output):
    require(resolve(plan["repository"], plan["tag"]) == plan,
            "Release changed during recovery; resolve it again")
    artifacts.mkdir(parents=True, exist_ok=True)
    paths = []
    for state in STATES:
        folder = artifacts / f"flat-white-{state}"
        folder.mkdir(exist_ok=True)
        require(not folder.is_symlink() and not any(folder.iterdir()),
                f"Recovery requires an empty artifact directory: {state}")
        published_name = f"flat-white-{plan['release_version']}-{state.lower()}.ndjson.gz"
        subprocess.run(["gh", "release", "download", plan["tag"], "--repo", plan["repository"],
                        "--pattern", published_name, "--dir", str(folder)], check=True, timeout=900)
        path = folder / f"flat-white-{plan['version']}-{state.lower()}.ndjson.gz"
        downloaded = folder / published_name
        require(not downloaded.is_symlink(), f"Invalid downloaded file: {state}")
        if downloaded != path:
            downloaded.rename(path)
        require(not folder.is_symlink() and not path.is_symlink()
                and list(folder.glob("*.ndjson.gz")) == [path], f"Missing or ambiguous artifact for {state}")
        expected = plan["files"][state]
        sha = file_sha256(path)
        require(path.stat().st_size == expected["bytes"] and sha == expected["sha256"],
                f"Artifact does not match the published release: {state}")
        (folder / f"{state}.count").write_text(str(expected["records"]) + "\n")
        paths.append(path)

    # The download can take minutes: reject a release made private or changed
    # during transfer before any AWS credentials are configured.
    require(resolve(plan["repository"], plan["tag"]) == plan,
            "Release changed during the download; resolve it again")

    # Rebuild the national gzip from the exact published state bytes. No data
    # load or address transformation is needed, and memory stays bounded.
    all_dir = artifacts / "flat-white-all"
    require(not all_dir.is_symlink(), "Invalid national artifact directory")
    all_dir.mkdir(exist_ok=True)
    output = all_dir / f"flat-white-{plan['release_version']}-all.ndjson.gz"
    require(not output.is_symlink() and all(p == output for p in all_dir.glob("*.ndjson.gz")),
            "Unexpected national artifact files")
    temporary = output.with_suffix(".partial")
    with temporary.open("xb") as combined:
        for path in paths:
            with path.open("rb") as stream:
                shutil.copyfileobj(stream, combined, length=1024 * 1024)
    temporary.replace(output)
    mappings_output.parent.mkdir(parents=True, exist_ok=True)
    mappings_output.write_text(json.dumps(plan["mappings"]) + "\n")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    resolver = commands.add_parser("resolve")
    resolver.add_argument("--repository", required=True)
    resolver.add_argument("--tag", required=True)
    resolver.add_argument("--plan", required=True, type=Path)
    verifier = commands.add_parser("prepare")
    verifier.add_argument("--plan", required=True, type=Path)
    verifier.add_argument("--artifacts", required=True, type=Path)
    verifier.add_argument("--mappings-output", required=True, type=Path)
    args = parser.parse_args()
    if args.command == "resolve":
        plan = resolve(args.repository, args.tag)
        args.plan.write_text(json.dumps(plan) + "\n")
        for key in ("version", "admin_bdys_version", "release_version", "schema_version",
                    "source_commit"):
            print(f"{key}={plan[key]}")
        print("mirror_only=true")
    else:
        prepare(json.loads(args.plan.read_text()), args.artifacts, args.mappings_output)
        print("All nine artifacts match the public release; national gzip reconstructed")


if __name__ == "__main__":
    try:
        main()
    except (ValueError, KeyError, TypeError, OSError, subprocess.SubprocessError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        sys.exit(1)
