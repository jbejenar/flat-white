"""Check GitHub's 2 GiB limit per asset, not against the whole release."""

import sys
from pathlib import Path

LIMIT = 2 * 1024**3


def main(directory: str) -> int:
    assets = sorted(path for path in Path(directory).iterdir() if path.is_file())
    if not assets:
        print("ERROR: No release assets found", file=sys.stderr)
        return 1
    oversized = [path for path in assets if path.stat().st_size >= LIMIT]
    for path in oversized:
        print(f"ERROR: {path.name} must be smaller than 2 GiB", file=sys.stderr)
    if oversized:
        return 1
    print(f"All {len(assets)} release assets are individually below 2 GiB")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1]))
