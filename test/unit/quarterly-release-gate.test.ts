import { execFileSync, spawnSync } from "node:child_process";
import { mkdtempSync, writeFileSync, rmSync, existsSync, readFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { afterEach, describe, expect, it } from "vitest";

const gate = resolve("scripts/check-quarterly-release.sh");
const dirs: string[] = [];

function environment(response: unknown, exitCode = 0): NodeJS.ProcessEnv {
  const dir = mkdtempSync(join(tmpdir(), "quarterly-gate-"));
  dirs.push(dir);
  writeFileSync(join(dir, "response.json"), JSON.stringify(response));
  writeFileSync(join(dir, "gh"), '#!/usr/bin/env bash\ncat "$GATE_RESPONSE"\nexit "$GATE_EXIT"\n', {
    mode: 0o755,
  });
  return {
    ...process.env,
    PATH: `${dir}:${process.env.PATH}`,
    GATE_RESPONSE: join(dir, "response.json"),
    GATE_EXIT: String(exitCode),
  };
}

afterEach(() => {
  for (const dir of dirs.splice(0)) rmSync(dir, { recursive: true, force: true });
});

describe("quarterly release gate", () => {
  function reservation(ref: unknown = null, creation = "success", mode = "reserve") {
    const response = { data: { repository: { release: null, ref } } };
    const env = environment(response);
    const root = dirname(String(env.GATE_RESPONSE));
    writeFileSync(
      join(root, "after.json"),
      JSON.stringify({
        data: {
          repository: {
            release: null,
            ref:
              creation === "denied"
                ? null
                : {
                    target: {
                      __typename: "Commit",
                      oid: creation === "race-other" ? "other-commit" : "built-commit",
                    },
                  },
          },
        },
      }),
    );
    writeFileSync(
      join(root, "gh"),
      `#!/usr/bin/env bash
if [[ "$*" == *"--method POST"* ]]; then
  printf '%s\\n' "$@" > "$GATE_ROOT/writes"
  if [[ "$GATE_CREATION" == success ]]; then
    echo built-commit
  elif [[ "$GATE_CREATION" == wrong-response ]]; then
    echo other-commit
  else
    cp "$GATE_ROOT/after.json" "$GATE_RESPONSE"
    exit 1
  fi
else
  cat "$GATE_RESPONSE"
fi
`,
      { mode: 0o755 },
    );
    const result = spawnSync(
      "bash",
      [gate, "workflow_dispatch", "owner/repo", "v2026.08", "built-commit", mode],
      {
        env: { ...env, GATE_ROOT: root, GATE_CREATION: creation },
        encoding: "utf8",
      },
    );
    return {
      ...result,
      writes: existsSync(join(root, "writes")) ? readFileSync(join(root, "writes"), "utf8") : "",
    };
  }

  it.each([
    ["success", true],
    ["race-same", true],
    ["race-other", false],
    ["denied", false],
    ["wrong-response", false],
  ] as const)("reserves the exact tag and handles %s", (creation, accepted) => {
    const result = reservation(null, creation);
    expect(result.status === 0).toBe(accepted);
    expect(result.stdout.includes("build_required=true")).toBe(accepted);
    expect(result.writes).toContain("ref=refs/tags/v2026.08");
    expect(result.writes).toContain("sha=built-commit");
    expect(result.writes).not.toContain("PATCH");
    expect(result.writes).not.toContain("DELETE");
  });

  it("reuses a matching reservation without a write", () => {
    const result = reservation({ target: { __typename: "Commit", oid: "built-commit" } });
    expect(result.status).toBe(0);
    expect(result.writes).toBe("");
  });

  it("refuses to move an existing tag", () => {
    const result = reservation({ target: { __typename: "Commit", oid: "other-commit" } });
    expect(result.status).toBe(1);
    expect(result.writes).toBe("");
  });

  it.each(["check", "require", "verify"])("mode %s never creates a missing tag", (mode) => {
    const result = reservation(null, "success", mode);
    expect(result.status).toBe(mode === "check" ? 0 : 1);
    expect(result.writes).toBe("");
  });

  it.each([null, { target: { __typename: "Commit", oid: "built-commit" } }])(
    "skips held drafts on schedule and refuses manual replacement, with ref %j",
    (ref) => {
      const env = environment({
        data: {
          repository: {
            release: {
              url: "https://example.com/draft",
              isDraft: true,
            },
            ref,
          },
        },
      });
      for (const event of ["schedule", "workflow_dispatch"]) {
        const result = spawnSync("bash", [gate, event, "owner/repo", "v2026.08", "built-commit"], {
          env,
          encoding: "utf8",
        });
        expect(result.status).toBe(event === "schedule" ? 0 : 1);
        expect(result.stdout).not.toContain("build_required=true");
      }
    },
  );

  it.each([false, true])("skips an existing release (draft=%s)", (isDraft) => {
    const env = environment({
      data: {
        repository: {
          release: { url: "https://example.com/release", isDraft },
        },
      },
    });
    expect(
      execFileSync("bash", [gate, "schedule", "owner/repo", "v2026.08"], {
        env,
        encoding: "utf8",
      }).trim(),
    ).toBe("build_required=false");
  });

  it("builds a new quarter only after a successful lookup", () => {
    const env = environment({ data: { repository: { release: null } } });
    expect(
      execFileSync("bash", [gate, "schedule", "owner/repo", "v2026.08"], {
        env,
        encoding: "utf8",
      }).trim(),
    ).toBe("build_required=true");
  });

  it.each([
    { data: { repository: null } },
    { data: { repository: {} } },
    { errors: [{ message: "Access denied" }] },
  ])("fails closed on an unusable API response: %j", (response) => {
    const result = spawnSync("bash", [gate, "schedule", "owner/repo", "v2026.08"], {
      env: environment(response),
      encoding: "utf8",
    });
    expect(result.status).not.toBe(0);
    expect(result.stdout).not.toContain("build_required=true");
  });

  it("does not interpret a failed request as a missing release", () => {
    const result = spawnSync("bash", [gate, "schedule", "owner/repo", "v2026.08"], {
      env: environment({}, 1),
      encoding: "utf8",
    });
    expect(result.status).not.toBe(0);
    expect(result.stdout).not.toContain("build_required=true");
  });

  it("allows a manual build after confirming that the release is absent", () => {
    expect(
      execFileSync("bash", [gate, "workflow_dispatch", "owner/repo", "v2026.08"], {
        env: environment({ data: { repository: { release: null } } }),
        encoding: "utf8",
      }).trim(),
    ).toBe("build_required=true");
  });

  it.each([true, false])(
    "refuses to overwrite an existing release on a manual run (draft=%s)",
    (isDraft) => {
      const result = spawnSync("bash", [gate, "workflow_dispatch", "owner/repo", "v2026.08"], {
        env: environment({
          data: {
            repository: {
              release: { url: "https://example.com/release", isDraft },
            },
          },
        }),
        encoding: "utf8",
      });
      expect(result.status).toBe(1);
      expect(result.stderr).toContain("will not be overwritten");
      expect(result.stdout).not.toContain("build_required=true");
    },
  );

  it.each([
    { ref: null, accepted: true },
    { ref: { target: { __typename: "Commit", oid: "built-commit" } }, accepted: true },
    {
      ref: { target: { __typename: "Tag", target: { __typename: "Commit", oid: "built-commit" } } },
      accepted: true,
    },
    { ref: { target: { __typename: "Commit", oid: "another-commit" } }, accepted: false },
    {
      ref: {
        target: { __typename: "Tag", target: { __typename: "Commit", oid: "another-commit" } },
      },
      accepted: false,
    },
    { ref: { target: { __typename: "Blob", oid: "built-commit" } }, accepted: false },
  ])("checks the tag against the built commit: %j", ({ ref, accepted }) => {
    const result = spawnSync(
      "bash",
      [gate, "workflow_dispatch", "owner/repo", "v2026.08", "built-commit"],
      {
        env: environment({
          data: { repository: { release: null, ref } },
        }),
        encoding: "utf8",
      },
    );
    expect(result.status === 0).toBe(accepted);
    expect(result.stdout.includes("build_required=true")).toBe(accepted);
  });

  it("fails closed on a manual lookup error", () => {
    const result = spawnSync("bash", [gate, "workflow_dispatch", "owner/repo", "v2026.08"], {
      env: environment({}, 1),
      encoding: "utf8",
    });
    expect(result.status).not.toBe(0);
    expect(result.stdout).not.toContain("build_required=true");
  });
});
