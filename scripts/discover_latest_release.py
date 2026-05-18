#!/usr/bin/env python3

import json
import re
import sys
import urllib.request

GNAF_PACKAGE_ID = "19432f89-dc3a-4ef3-b943-5326ef1dbecc"
ADMIN_PACKAGE_ID = "bdcf5b09-89bc-47ec-9281-6b8e9ee147aa"
FALLBACK_VERSION = "2026.02"
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


def compatible_versions(
    gnaf_versions: set[str],
    admin_versions: set[str],
    fallback_version: str = FALLBACK_VERSION,
) -> list[str]:
    gnaf_compatible = set(gnaf_versions)
    admin_compatible = set(admin_versions)

    # data.gov.au only exposes a small moving window of resources. Keep the
    # known-good Feb 2026 fallback eligible only when at least one package still
    # advertises it, so parser/API regressions still fail fast.
    if fallback_version in gnaf_versions:
        admin_compatible.add(fallback_version)
    if fallback_version in admin_versions:
        gnaf_compatible.add(fallback_version)

    return sorted(gnaf_compatible & admin_compatible)


def resolve_latest_common_version(gnaf_versions: set[str], admin_versions: set[str]) -> str:
    common_versions = compatible_versions(gnaf_versions, admin_versions)

    if not common_versions:
        raise RuntimeError(
            "No overlapping quarterly G-NAF/Admin Boundaries releases found on data.gov.au"
        )

    return common_versions[-1]


def main() -> int:
    gnaf_versions = extract_versions(fetch_resources(GNAF_PACKAGE_ID), admin=False)
    admin_versions = extract_versions(fetch_resources(ADMIN_PACKAGE_ID), admin=True)
    print(resolve_latest_common_version(gnaf_versions, admin_versions))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)
