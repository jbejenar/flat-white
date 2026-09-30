#!/usr/bin/env python3
"""Attest and validate base database dumps; old or mismatched dumps fail closed."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess


def sha256(path):
    result = hashlib.sha256()
    with Path(path).open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            result.update(block)
    return result.hexdigest()


def source_identity(lock):
    # Acquisition time and the acquisition job's code do not change data bytes.
    fields = (
        "formatVersion",
        "gnafVersion",
        "adminVersion",
        "boundaryReferenceDate",
        "sources",
    )
    content = json.dumps(
        {key: lock[key] for key in fields},
        sort_keys=True,
        separators=(",", ":"),
        ensure_ascii=False,
    )
    return hashlib.sha256(content.encode()).hexdigest()


def runtime_fingerprint(root):
    root = Path(root)
    digest = hashlib.sha256()
    files = [root / "package.json"]
    for directory in ("dist", "sql", "scripts", "gnaf-loader"):
        files.extend(
            path
            for path in (root / directory).rglob("*")
            if path.is_file()
            and "__pycache__" not in path.parts
            and path.suffix in (".js", ".mjs", ".json", ".sql", ".py", ".sh")
        )
    entrypoint = (
        Path("/docker-entrypoint.sh")
        if root == Path("/app")
        else root / "docker-entrypoint.sh"
    )
    if entrypoint.exists():
        digest.update(entrypoint.read_bytes())
    for path in sorted(files):
        digest.update(
            str(path.relative_to(root)).encode() + b"\0" + sha256(path).encode() + b"\0"
        )
    # Installed runtime versions matter even if an upstream image tag moves.
    for command in (
        ["node", "--version"],
        ["psql", "--version"],
        [
            "python3",
            "-c",
            "import sys, psycopg; print(sys.version); print(psycopg.__version__)",
        ],
    ):
        digest.update(subprocess.check_output(command).strip() + b"\0")
    # Geometry behavior depends on the installed PostGIS library as well.
    library = Path(
        subprocess.check_output(["pg_config", "--pkglibdir"], text=True).strip()
    )
    libraries = sorted(library.glob("postgis-*.so"))
    if not libraries:
        raise ValueError("Cannot fingerprint the PostGIS runtime")
    for path in libraries:
        digest.update(path.name.encode() + b"\0" + sha256(path).encode())
    return digest.hexdigest()


def expected_context(lock_path, states, root):
    lock = json.loads(Path(lock_path).read_text())
    return {
        "formatVersion": 1,
        "sourceIdentity": source_identity(lock),
        "gnafVersion": lock["gnafVersion"],
        "boundaryReferenceDate": lock["boundaryReferenceDate"],
        "states": sorted(
            set(
                states.split()
                or ["ACT", "NSW", "NT", "OT", "QLD", "SA", "TAS", "VIC", "WA"]
            )
        ),
        "runtimeFingerprint": runtime_fingerprint(root),
        "scope": "base-gnaf-geoscape",
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["create", "verify", "source-identity"])
    parser.add_argument("--lock", required=True)
    parser.add_argument("--dump")
    parser.add_argument("--states", default="")
    parser.add_argument("--root", default="/app")
    args = parser.parse_args()
    if args.command == "source-identity":
        print(source_identity(json.loads(Path(args.lock).read_text())))
        return
    if not args.dump:
        parser.error("--dump is required")
    context = expected_context(args.lock, args.states, args.root)
    sidecar = Path(args.dump + ".provenance.json")
    if args.command == "verify":
        report = json.loads(sidecar.read_text())
        if report.get("context") != context:
            raise ValueError(
                "Database dump provenance does not match sources, states or preparation/runtime code"
            )
        if report.get("dumpSha256") != sha256(args.dump):
            raise ValueError("Database dump checksum mismatch")
    else:
        report = {
            "context": context,
            "dumpSha256": sha256(args.dump),
            "sourceLock": json.loads(Path(args.lock).read_text()),
        }
        temporary = sidecar.with_suffix(sidecar.suffix + ".partial")
        temporary.write_text(json.dumps(report, indent=2) + "\n")
        temporary.replace(sidecar)


if __name__ == "__main__":
    main()
