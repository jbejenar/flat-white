#!/usr/bin/env python3

import json
import re
import sys
import urllib.request
from argparse import ArgumentParser

GNAF_PACKAGE_ID = "19432f89-dc3a-4ef3-b943-5326ef1dbecc"
ADMIN_PACKAGE_ID = "bdcf5b09-89bc-47ec-9281-6b8e9ee147aa"
MONTHS = {
    "JAN": "01",
    "FEB": "02",
    "MAR": "03",
    "APR": "04",
    "MAY": "05",
    "JUN": "06",
    "JUL": "07",
    "AUG": "08",
    "SEP": "09",
    "OCT": "10",
    "NOV": "11",
    "DEC": "12",
}


def fetch_resources(package_id: str) -> list[dict]:
    url = f"https://data.gov.au/data/api/3/action/package_show?id={package_id}"
    with urllib.request.urlopen(url, timeout=30) as response:
        payload = json.load(response)
    if (
        not payload.get("success")
        or "result" not in payload
        or "resources" not in payload["result"]
    ):
        raise RuntimeError(f"Unexpected CKAN payload for {package_id}")
    return payload["result"]["resources"]


def extract_versions(resources: list[dict], *, admin: bool) -> set[str]:
    versions: set[str] = set()
    for resource in resources:
        if resource.get("state", "active") != "active":
            continue
        if str(resource.get("format", "")).upper() != "ZIP":
            continue

        text = f"{resource.get('name', '')} {resource.get('url', '')}".upper()
        if "GDA2020" not in text or "GDA94" in text:
            continue
        if admin and not any(token in text for token in ("SHAPEFILE", "_SHP", " SHP")):
            continue

        for match in re.finditer(
            r"\b(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)[\s_-]?(\d{2}|\d{4})\b",
            text,
        ):
            month = MONTHS[match.group(1)]
            year = match.group(2)
            if len(year) == 2:
                year = f"20{year}"
            versions.add(f"{year}.{month}")
    return versions


def resolve_latest_release_versions(
    gnaf_versions: set[str], admin_versions: set[str]
) -> dict[str, str]:
    if not gnaf_versions:
        raise RuntimeError("No active G-NAF GDA2020 ZIP releases found on data.gov.au")
    if not admin_versions:
        raise RuntimeError(
            "No active Admin Boundaries GDA2020 shapefile ZIP releases found on data.gov.au"
        )

    return {
        "gnaf_version": sorted(gnaf_versions)[-1],
        "admin_bdys_version": sorted(admin_versions)[-1],
    }


def main() -> int:
    parser = ArgumentParser(
        description="Discover the freshest available G-NAF and Admin Boundaries releases."
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Print both discovered versions as JSON instead of only the G-NAF version.",
    )
    args = parser.parse_args()

    gnaf_versions = extract_versions(fetch_resources(GNAF_PACKAGE_ID), admin=False)
    admin_versions = extract_versions(fetch_resources(ADMIN_PACKAGE_ID), admin=True)
    versions = resolve_latest_release_versions(gnaf_versions, admin_versions)
    if args.json:
        print(json.dumps(versions, sort_keys=True))
    else:
        print(versions["gnaf_version"])
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)
