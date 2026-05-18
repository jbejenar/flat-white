#!/usr/bin/env python3

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from collections.abc import Callable

from discover_latest_release import (
    ADMIN_PACKAGE_ID,
    GNAF_PACKAGE_ID,
    extract_versions,
    fetch_resources,
    resolve_latest_release_versions,
)


VERSION_RE = re.compile(r"^\d{4}\.\d{2}$")
PATCH_RE = re.compile(r"^[1-9][0-9]*$")


def validate_version(value: str, field_name: str) -> None:
    if not VERSION_RE.match(value):
        raise ValueError(f"Invalid {field_name} format: '{value}' (expected YYYY.MM)")


def validate_patch(value: str) -> None:
    if not PATCH_RE.match(value):
        raise ValueError(
            f"Invalid patch_version format: '{value}' (expected positive integer >= 1)"
        )


def default_discover() -> dict[str, str]:
    gnaf_versions = extract_versions(fetch_resources(GNAF_PACKAGE_ID), admin=False)
    admin_versions = extract_versions(fetch_resources(ADMIN_PACKAGE_ID), admin=True)
    return resolve_latest_release_versions(gnaf_versions, admin_versions)


def manual_source_hash(
    version: str, download_url_gnaf: str, download_url_admin_bdys: str, admin_bdys_extracted_dir: str
) -> str:
    payload = f"{version}\n{download_url_gnaf}\n{download_url_admin_bdys}\n{admin_bdys_extracted_dir}\n"
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()


def resolve_quarterly_inputs(
    *,
    gnaf_version: str = "",
    patch_version: str = "",
    download_url_gnaf: str = "",
    download_url_admin_bdys: str = "",
    admin_bdys_extracted_dir: str = "",
    discover: Callable[[], dict[str, str]] = default_discover,
) -> dict[str, str | bool]:
    manual_values = {
        "download_url_gnaf": download_url_gnaf,
        "download_url_admin_bdys": download_url_admin_bdys,
        "admin_bdys_extracted_dir": admin_bdys_extracted_dir,
    }
    manual_source = any(manual_values.values())

    if manual_source:
        missing = [name for name, value in manual_values.items() if not value]
        if missing:
            raise ValueError(
                "Manual data-source overrides must be provided together. Missing: "
                + ", ".join(missing)
            )
        if not gnaf_version:
            raise ValueError("Manual data-source overrides require gnaf_version to be set")

    if gnaf_version:
        validate_version(gnaf_version, "gnaf_version")
    if patch_version:
        validate_patch(patch_version)

    if manual_source:
        version = gnaf_version
        admin_bdys_version = "manual"
        data_source_key = f"manual-{manual_source_hash(version, download_url_gnaf, download_url_admin_bdys, admin_bdys_extracted_dir)}"
    else:
        discovered = discover()
        discovered_gnaf = discovered.get("gnaf_version", "")
        discovered_admin = discovered.get("admin_bdys_version", "")
        if not discovered_gnaf or not discovered_admin:
            raise ValueError("Failed to determine latest G-NAF/Admin Boundaries releases")

        version = gnaf_version or discovered_gnaf
        # Explicit gnaf_version means "build that quarter"; do not silently
        # pair it with a newer boundary release. Manual URL overrides are the
        # intentional escape hatch for historical or mixed-source rebuilds.
        admin_bdys_version = version if gnaf_version else discovered_admin
        data_source_key = f"gnaf-{version}-admin-{admin_bdys_version}"

    release_version = f"{version}.{patch_version}" if patch_version else version

    return {
        "version": version,
        "admin_bdys_version": admin_bdys_version,
        "release_version": release_version,
        "data_source_key": data_source_key,
        "manual_source": manual_source,
        "auto_discovered_gnaf": not gnaf_version,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Resolve Quarterly Build setup inputs.")
    parser.add_argument("--gnaf-version", default="")
    parser.add_argument("--patch-version", default="")
    parser.add_argument("--download-url-gnaf", default="")
    parser.add_argument("--download-url-admin-bdys", default="")
    parser.add_argument("--admin-bdys-extracted-dir", default="")
    args = parser.parse_args()

    result = resolve_quarterly_inputs(
        gnaf_version=args.gnaf_version.strip(),
        patch_version=args.patch_version.strip(),
        download_url_gnaf=args.download_url_gnaf.strip(),
        download_url_admin_bdys=args.download_url_admin_bdys.strip(),
        admin_bdys_extracted_dir=args.admin_bdys_extracted_dir.strip(),
    )
    print(json.dumps(result, sort_keys=True))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)
