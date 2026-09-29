import { spawnSync } from "node:child_process";
import {
  copyFileSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  rmSync,
  truncateSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { afterEach, beforeEach, describe, expect, it } from "vitest";

const limit = 2 * 1024 ** 3;

describe("release publication guards", () => {
  let root: string;
  let assets: string;
  beforeEach(() => {
    root = mkdtempSync(join(tmpdir(), "flat-white-release-publication-"));
    assets = join(root, "assets");
    mkdirSync(assets);
  });
  afterEach(() => rmSync(root, { recursive: true, force: true }));

  function asset(name: string, bytes: number) {
    const path = join(assets, name);
    writeFileSync(path, "");
    // Sparse files exercise the real size boundary without writing gigabytes.
    truncateSync(path, bytes);
  }

  function sizeCheck() {
    return spawnSync("python3", [resolve("scripts/check-release-asset-sizes.py"), assets], {
      encoding: "utf8",
    });
  }

  it("accepts a release larger than 2 GiB when each asset fits", () => {
    asset("first.gz", limit - 1);
    asset("second.gz", limit - 1);
    expect(sizeCheck().status).toBe(0);
  });

  it.each([limit, limit + 1])("rejects an individual asset of %i bytes", (bytes) => {
    asset("oversized.gz", bytes);
    const result = sizeCheck();
    expect(result.status).toBe(1);
    expect(result.stderr).toContain("oversized.gz");
  });

  it("rejects an empty asset directory", () => {
    expect(sizeCheck().status).toBe(1);
  });

  function createRelease(
    existing: boolean,
    ref: "matching" | "missing" | "moved" = "matching",
    mainAdvanced = false,
  ) {
    mkdirSync(join(root, "bin"));
    mkdirSync(join(root, "scripts"));
    for (const name of ["check-quarterly-release.sh", "check-release-asset-sizes.py"]) {
      copyFileSync(resolve("scripts", name), join(root, "scripts", name));
    }
    writeFileSync(
      join(root, "response.json"),
      JSON.stringify({
        data: {
          repository: {
            release: existing ? { url: "https://example.com/release", isDraft: false } : null,
            ref:
              ref === "missing"
                ? null
                : {
                    target: {
                      __typename: "Commit",
                      oid: ref === "matching" ? "built-commit" : "other-commit",
                    },
                  },
          },
        },
      }),
    );
    writeFileSync(
      join(root, "bin/gh"),
      `#!/usr/bin/env bash
if [[ "$1" == api ]]; then
  cat "$AUDIT_ROOT/response.json"
elif [[ "$MAIN_ADVANCED" == true && " $* " == *" --target "* ]]; then
  echo 'HTTP 403: workflow-write authorization required for historical target' >&2
  exit 1
else
  printf '%s\\n' "$@" >> "$AUDIT_ROOT/mutations"
fi
`,
      { mode: 0o755 },
    );
    writeFileSync(join(root, "notes.md"), "Synthetic release notes");
    asset("fixture.gz", 1);
    const workflow = readFileSync(".github/workflows/quarterly-build.yml", "utf8");
    const match = workflow.match(
      /- name: Create GitHub Release \(draft\)\n\s+run: \|\n((?: {10}[^\n]*\n|\n)+)/,
    );
    if (!match) throw new Error("Release creation step not found");
    const script = match[1]
      .replace(/^ {10}/gm, "")
      .replaceAll("${{ needs.setup.outputs.release_version }}", "2026.08")
      .replaceAll("${{ steps.collect.outputs.asset_dir }}", assets)
      .replaceAll("${{ steps.notes.outputs.notes_file }}", join(root, "notes.md"));
    const result = spawnSync("bash", ["-e", "-o", "pipefail", "-c", script], {
      cwd: root,
      encoding: "utf8",
      env: {
        ...process.env,
        PATH: `${join(root, "bin")}:${process.env.PATH}`,
        AUDIT_ROOT: root,
        MAIN_ADVANCED: String(mainAdvanced),
        GITHUB_SHA: "built-commit",
        GITHUB_REPOSITORY: "owner/repo",
      },
    });
    let mutations = "";
    try {
      mutations = readFileSync(join(root, "mutations"), "utf8");
    } catch {
      /* no writes expected on rejection */
    }
    return { status: result.status, mutations };
  }

  it("rechecks before publication and leaves an existing release untouched", () => {
    const result = createRelease(true);
    expect(result.status).toBe(1);
    expect(result.mutations).toBe("");
  });

  it.each([false, true])("uses the verified tag when main advanced=%s", (mainAdvanced) => {
    const result = createRelease(false, "matching", mainAdvanced);
    expect(result.status).toBe(0);
    expect(result.mutations).toContain("release\ncreate\nv2026.08\n--draft\n--verify-tag\n");
    expect(result.mutations).not.toContain("--target");
    expect(result.mutations).not.toContain("delete");
  });

  it.each(["missing", "moved"] as const)(
    "refuses publication when the reserved tag is %s",
    (ref) => {
      const result = createRelease(false, ref, true);
      expect(result.status).toBe(1);
      expect(result.mutations).toBe("");
    },
  );

  it("keeps draft visibility, tag reservation and publication wired to the built-in token", () => {
    const workflow = readFileSync(".github/workflows/quarterly-build.yml", "utf8");
    const setup = workflow.split("  setup:\n")[1].split("  build:\n")[0];
    expect(setup).toContain("contents: write");
    expect(setup).toContain(
      "steps.reserve-tag.outputs.build_required || steps.release-check.outputs.build_required",
    );
    expect(setup).toContain(
      "steps.release-check.outputs.build_required == 'true' && !inputs.preflight_only",
    );
    expect(setup).toContain('"$GITHUB_SHA" reserve');
    expect(workflow).toContain('git checkout --detach "$GITHUB_SHA"');
    expect(workflow).toContain('"$GITHUB_SHA" verify');
    expect(workflow).toContain("steps.verify_release.outputs.published == 'true'");
    expect(workflow).not.toContain("create-github-app-token");
  });
});
