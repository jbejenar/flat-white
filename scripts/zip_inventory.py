#!/usr/bin/env python3
"""Describe a source ZIP and reject unsafe or ambiguous extraction paths."""
import json
from pathlib import PurePosixPath
import stat
import sys
import zipfile


def inventory(path):
    with zipfile.ZipFile(path) as archive:
        entries = archive.infolist()
        if len(entries) > 100_000:
            raise ValueError("Source archive has too many entries")
        seen = set()
        result = []
        for entry in entries:
            name = entry.filename
            parts = PurePosixPath(name).parts
            if (
                name.startswith("/")
                or "\\" in name
                or ":" in name
                or ".." in parts
                or stat.S_ISLNK(entry.external_attr >> 16)
            ):
                raise ValueError(f"Unsafe source archive member: {name}")
            canonical = str(PurePosixPath(name)).casefold()
            if canonical in seen:
                raise ValueError(f"Duplicate source archive member: {name}")
            seen.add(canonical)
            if not entry.is_dir():
                result.append(
                    {"path": name, "bytes": entry.file_size, "crc32": entry.CRC}
                )
        if not result:
            raise ValueError("Empty source archive")
        return sorted(result, key=lambda item: item["path"])


if __name__ == "__main__":
    print(json.dumps(inventory(sys.argv[1]), separators=(",", ":")))
