#!/usr/bin/env python3
"""Compare every published PID and field using two ordered gzip streams."""
import argparse
import gzip
import importlib.util
import json
from pathlib import Path
import re
import subprocess
import tempfile

from mirror_utils import file_sha256

STATES = ("ACT", "NSW", "NT", "OT", "QLD", "SA", "TAS", "VIC", "WA")
MISSING = object()


def json_equal(before, after):
    if type(before) in (int, float) and type(after) in (int, float):
        return before == after
    if type(before) is not type(after):
        return False
    if isinstance(before, list):
        return len(before) == len(after) and all(
            json_equal(a, b) for a, b in zip(before, after)
        )
    if isinstance(before, dict):
        return before.keys() == after.keys() and all(
            json_equal(before[key], after[key]) for key in before
        )
    return before == after


def rows(path, state, version):
    previous = None
    with gzip.open(path, "rt", encoding="utf-8") as source:
        for line in source:
            if not line.strip():
                continue
            row = json.loads(line)
            pid = row.get("_id")
            if (
                not isinstance(pid, str)
                or not pid
                or row.get("state") != state
                or row.get("_version") != version
            ):
                raise ValueError(f"Invalid identity, state or quarter in {path.name}")
            if previous is not None and pid <= previous:
                raise ValueError(f"Duplicate or unordered PID in {path.name}: {pid}")
            previous = pid
            yield row


def differences(before, after, path=""):
    if isinstance(before, dict) and isinstance(after, dict):
        for key in sorted(before.keys() | after.keys()):
            yield from differences(
                before.get(key, MISSING),
                after.get(key, MISSING),
                f"{path}.{key}" if path else key,
            )
    elif before is MISSING or after is MISSING or not json_equal(before, after):
        yield {
            "path": path,
            "beforePresent": before is not MISSING,
            "afterPresent": after is not MISSING,
            **({"before": before} if before is not MISSING else {}),
            **({"after": after} if after is not MISSING else {}),
        }


def allowed_change(change, state, quarter, prior_schema, schema):
    # This narrowly scoped correction is independently checked by the OT
    # release coverage/snapshot gate. Every other same-quarter change is held.
    return (
        quarter == "2026.08"
        and prior_schema == schema == "1.0.0"
        and state == "OT"
        and change["path"] == "boundaries.commonwealthElectorate"
        and change.get("beforePresent")
        and change.get("before") is None
        and change.get("after")
        in ({"name": "BEAN"}, {"name": "FENNER"}, {"name": "LINGIARI"})
    )


def compare_state(
    prior, current, output, *, state, prior_quarter, quarter, prior_schema, schema
):
    same_quarter = prior_quarter == quarter
    report = {
        "state": state,
        "priorCount": 0,
        "currentCount": 0,
        "added": 0,
        "removed": 0,
        "changed": 0,
        "unchanged": 0,
        "unexpectedChanges": 0,
        "fields": {},
        "samples": [],
    }
    with output.open("wb") as raw, gzip.GzipFile(
        fileobj=raw, mode="wb", filename="", mtime=0, compresslevel=1
    ) as evidence:

        def record(event):
            evidence.write(
                (
                    json.dumps(event, separators=(",", ":"), ensure_ascii=False) + "\n"
                ).encode()
            )
            if len(report["samples"]) < 20:
                # Full before/after details are streamed to the compressed evidence.
                report["samples"].append(
                    {key: event[key] for key in ("pid", "kind", "unexpected")}
                )

        old = rows(prior, state, prior_quarter)
        new = rows(current, state, quarter)
        try:
            a, b = next(old, None), next(new, None)
            while a is not None or b is not None:
                if b is None or (a is not None and a["_id"] < b["_id"]):
                    report["priorCount"] += 1
                    report["removed"] += 1
                    report["unexpectedChanges"] += int(same_quarter)
                    record(
                        {
                            "pid": a["_id"],
                            "kind": "removed",
                            "unexpected": same_quarter,
                            "before": a,
                        }
                    )
                    a = next(old, None)
                elif a is None or b["_id"] < a["_id"]:
                    report["currentCount"] += 1
                    report["added"] += 1
                    report["unexpectedChanges"] += int(same_quarter)
                    record(
                        {
                            "pid": b["_id"],
                            "kind": "added",
                            "unexpected": same_quarter,
                            "after": b,
                        }
                    )
                    b = next(new, None)
                else:
                    report["priorCount"] += 1
                    report["currentCount"] += 1
                    changes = list(differences(a, b))
                    if changes:
                        unexpected = False
                        for change in changes:
                            approved = not same_quarter or allowed_change(
                                change, state, quarter, prior_schema, schema
                            )
                            change["expected"] = approved
                            unexpected |= not approved
                            field = report["fields"].setdefault(
                                change["path"], {"changed": 0, "unexpected": 0}
                            )
                            field["changed"] += 1
                            field["unexpected"] += int(not approved)
                        if len(report["fields"]) > 256:
                            raise ValueError("Unexpectedly many document field paths")
                        report["changed"] += 1
                        report["unexpectedChanges"] += int(unexpected)
                        record(
                            {
                                "pid": a["_id"],
                                "kind": "changed",
                                "unexpected": unexpected,
                                "changes": changes,
                            }
                        )
                    else:
                        report["unchanged"] += 1
                    a, b = next(old, None), next(new, None)
        finally:
            old.close()
            new.close()
    return report


def release_key(tag):
    if not re.fullmatch(r"v\d{4}\.(02|05|08|11)(\.[1-9]\d*)?", tag):
        return None
    parts = list(map(int, tag[1:].split(".")))
    return tuple(parts + [0] * (3 - len(parts)))


def choose_prior(releases, version):
    target = release_key("v" + version)
    if target is None:
        raise ValueError("Invalid current release version")
    eligible = [
        (release_key(item["tagName"]), item["tagName"])
        for item in releases
        if not item.get("isDraft") and not item.get("isPrerelease")
    ]
    eligible = [(key, tag) for key, tag in eligible if key is not None and key < target]
    same = [(key, tag) for key, tag in eligible if key[:2] == target[:2]]
    if target[2] and not same:
        raise ValueError("Patch release requires a published same-quarter baseline")
    return max(same or eligible, default=(None, None))[1]


def compare_release(directory, repository):
    spec = importlib.util.spec_from_file_location(
        "mirror_recovery", Path(__file__).with_name("prepare-mirror-recovery.py")
    )
    mirror = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mirror)
    metadata = json.loads((directory / "metadata.json").read_text())
    releases = json.loads(
        subprocess.check_output(
            [
                "gh",
                "release",
                "list",
                "--repo",
                repository,
                "--limit",
                "1000",
                "--json",
                "tagName,isDraft,isPrerelease",
            ]
        )
    )
    prior_tag = choose_prior(releases, metadata["version"])
    report = {
        "formatVersion": 1,
        "currentVersion": metadata["version"],
        "priorTag": prior_tag,
        "scope": "every PID and field; arrays compared in order",
        "states": [],
        "hasAnomalies": False,
    }
    if prior_tag is None:
        report["note"] = "First published quarter: no prior release exists to compare."
        return report
    plan = mirror.resolve(repository, prior_tag)
    report["sameSourceQuarter"] = plan["version"] == metadata["gnafVersion"]
    report["priorArchiveChecksumsAvailable"] = "evidence" in plan
    report["sourceArchiveBytesMatch"] = None
    with tempfile.TemporaryDirectory(prefix="flat-white-comparison-") as temporary:
        folder = Path(temporary)

        def download(name, expected):
            subprocess.run(
                [
                    "gh",
                    "release",
                    "download",
                    prior_tag,
                    "--repo",
                    repository,
                    "--pattern",
                    name,
                    "--dir",
                    str(folder),
                ],
                check=True,
                timeout=900,
            )
            path = folder / name
            if (
                path.is_symlink()
                or path.stat().st_size != expected["bytes"]
                or file_sha256(path) != expected["sha256"]
            ):
                raise ValueError(f"Prior release checksum mismatch: {name}")
            return path

        if plan.get("evidence"):
            prior_lock = json.loads(
                download(
                    "source-lock.json", plan["evidence"]["source-lock.json"]
                ).read_text()
            )
            current_lock = json.loads((directory / "source-lock.json").read_text())

            def archives(lock):
                return [
                    (source["kind"], source["bytes"], source["sha256"])
                    for source in lock["sources"]
                ]

            report["sourceArchiveBytesMatch"] = archives(prior_lock) == archives(
                current_lock
            )
            if report["sameSourceQuarter"] and not report["sourceArchiveBytesMatch"]:
                report["hasAnomalies"] = True
        for state in STATES:
            prior_name = (
                f"flat-white-{plan['release_version']}-{state.lower()}.ndjson.gz"
            )
            prior = download(prior_name, plan["files"][state])
            current = (
                directory
                / f"flat-white-{metadata['version']}-{state.lower()}.ndjson.gz"
            )
            output = directory / f"comparison-{state}.jsonl.gz"
            result = compare_state(
                prior,
                current,
                output,
                state=state,
                prior_quarter=plan["version"],
                quarter=metadata["gnafVersion"],
                prior_schema=plan["schema_version"],
                schema=metadata["schemaVersion"],
            )
            if (
                result["priorCount"] != plan["files"][state]["records"]
                or result["currentCount"] != metadata["states"][state]
            ):
                raise ValueError(
                    f"Comparison count disagrees with verified metadata: {state}"
                )
            result["evidence"] = output.name
            # New quarters may legitimately add/remove/change addresses, but the
            # existing 1% count anomaly gate remains in force, separately per state.
            result["countAnomaly"] = (
                abs(result["currentCount"] - result["priorCount"])
                / max(1, result["priorCount"])
                > 0.01
            )
            report["hasAnomalies"] |= bool(
                result["unexpectedChanges"] or result["countAnomaly"]
            )
            report["states"].append(result)
            print(
                f"{state}: {result['unchanged']} unchanged, {result['changed']} changed, {result['unexpectedChanges']} unexpected",
                flush=True,
            )
            prior.unlink()
        if mirror.resolve(repository, prior_tag) != plan:
            raise ValueError("Prior release changed during comparison")
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--directory", required=True, type=Path)
    parser.add_argument("--repository", required=True)
    args = parser.parse_args()
    report = compare_release(args.directory, args.repository)
    (args.directory / "comparison.json").write_text(json.dumps(report, indent=2) + "\n")
    lines = [
        "# Full release comparison",
        "",
        f"Current: {report['currentVersion']}. Prior: {report['priorTag'] or 'none'}.",
        "",
        "Every PID and every field is compared. Arrays are order-sensitive. Full changes are in the per-state `comparison-STATE.jsonl.gz` files.",
        "",
        "Same-quarter changes must match a reviewed repair rule. Any added or removed PID is unexpected. New-quarter changes are reported; count changes above 1% are held for review.",
        "",
        "| State | Unchanged | Changed | Added | Removed | Unexpected |",
        "| --- | ---: | ---: | ---: | ---: | ---: |",
    ]
    for state in report["states"]:
        lines.append(
            "| "
            + " | ".join(
                str(state[key])
                for key in (
                    "state",
                    "unchanged",
                    "changed",
                    "added",
                    "removed",
                    "unexpectedChanges",
                )
            )
            + " |"
        )
    if not report.get("priorArchiveChecksumsAvailable"):
        lines += [
            "",
            "The prior release has no source archive lock. This comparison proves document differences; it does not prove identical historical upstream archive bytes.",
        ]
    lines += [
        "",
        (
            "Publication held for review."
            if report["hasAnomalies"]
            else "No unexpected differences found."
        ),
    ]
    (args.directory / "comparison.md").write_text("\n".join(lines) + "\n")
    if report["hasAnomalies"]:
        raise SystemExit(2)


if __name__ == "__main__":
    main()
