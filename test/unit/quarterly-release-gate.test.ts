import { execFileSync, spawnSync } from "node:child_process";
import { mkdtempSync, writeFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
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
  it.each([false, true])("skips an existing release (draft=%s)", (isDraft) => {
    const env = environment({
      data: { repository: { release: { url: "https://example.com/release", isDraft } } },
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
          data: { repository: { release: { url: "https://example.com/release", isDraft } } },
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
        env: environment({ data: { repository: { release: null, ref } } }),
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
