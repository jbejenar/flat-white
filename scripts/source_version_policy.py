#!/usr/bin/env python3
"""Reject incompatible production quarters before any build side effects."""

import argparse
import re
import sys


def validate_production_version(value: str, field_name: str = "GNAF_VERSION") -> None:
    if not re.fullmatch(r"[0-9]{4}\.(02|05|08|11)", value):
        raise ValueError(
            f"Invalid {field_name}: '{value}' (expected YYYY.MM with a quarterly "
            "release month: 02, 05, 08 or 11)"
        )
    if value < "2026.08":
        raise ValueError(
            f"Schema 1.x requires {field_name} 2026.08 or newer (ASGS 2026). "
            "Use the original release's code/schema to rebuild older data."
        )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("version")
    parser.add_argument("--admin-version", default="",
                        help="Optional independent Admin Boundaries quarter")
    args = parser.parse_args()
    try:
        validate_production_version(args.version)
        # Match the downloader's readEnvOverride: blank means no explicit
        # override and surrounding whitespace is removed before selection.
        admin_version = args.admin_version.strip()
        if admin_version:
            validate_production_version(admin_version, "ADMIN_BDYS_VERSION")
    except ValueError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)
