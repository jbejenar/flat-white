#!/usr/bin/env python3
"""Hash tracked build inputs once; generated __pycache__ files never enter the key."""
import hashlib
from pathlib import Path
import subprocess


def fingerprint(root):
    root = Path(root)
    paths = subprocess.check_output(
        [
            "git",
            "ls-files",
            "-z",
            "--",
            "Dockerfile",
            "docker-entrypoint.sh",
            "package.json",
            "package-lock.json",
            ".nvmrc",
            "tsconfig.json",
            "src/",
            "sql/",
            "scripts/",
        ],
        cwd=root,
    ).split(b"\0")
    digest = hashlib.sha256()
    for path in sorted(filter(None, paths)):
        digest.update(path + b"\0")
        with (root / path.decode()).open("rb") as source:
            for chunk in iter(lambda: source.read(1024 * 1024), b""):
                digest.update(chunk)
        digest.update(b"\0")
    loader = subprocess.check_output(
        ["git", "-C", "gnaf-loader", "rev-parse", "HEAD"], cwd=root
    )
    digest.update(b"gnaf-loader\0" + loader.strip())
    return digest.hexdigest()


if __name__ == "__main__":
    print(fingerprint(Path(__file__).resolve().parents[1]))
