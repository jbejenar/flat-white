import { spawnSync } from "node:child_process";
import {
  chmodSync,
  copyFileSync,
  existsSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { afterEach, beforeEach, describe, expect, it } from "vitest";

describe("production version guards", () => {
  let root: string;

  beforeEach(() => {
    root = mkdtempSync(join(tmpdir(), "flat-white-version-"));
    mkdirSync(join(root, "bin"));
    // Stop at the first build side effect. Never start Postgres or download data,
    // even when testing a version that the real entrypoint accepts.
    const mkdir = join(root, "bin", "mkdir");
    writeFileSync(
      mkdir,
      '#!/usr/bin/env bash\necho "REACHED_OUTPUT_SETUP version=${GNAF_VERSION:-unset}"\nexit 97\n',
    );
    chmodSync(mkdir, 0o755);
    // Source-lock validation is separately tested with real archives. Here the
    // inspector is isolated so this test still observes version-guard ordering.
    const node = join(root, "bin", "node");
    writeFileSync(
      node,
      '#!/usr/bin/env bash\nif [[ "$1" == /app/dist/source-lock.js && "$2" == inspect ]]; then echo 2026-08-31; exit 0; fi\nexit 98\n',
    );
    chmodSync(node, 0o755);
  });

  afterEach(() => rmSync(root, { recursive: true, force: true }));

  function run(script: string, version: string, args: string[] = [], adminVersion = "") {
    const result = spawnSync("bash", [resolve(script), ...args], {
      encoding: "utf8",
      env: {
        ...process.env,
        GNAF_VERSION: version,
        ADMIN_BDYS_VERSION: adminVersion,
        PATH: `${join(root, "bin")}:${process.env.PATH}`,
      },
    });
    if (result.error) throw result.error;
    return { status: result.status, output: result.stdout + result.stderr };
  }

  function runMini(input: string, discovered = "2026.08", discoveredAdmin = "2026.08") {
    // Execute the actual workflow step, with only remote discovery replaced.
    const workflow = readFileSync(resolve(".github/workflows/mini-quarterly.yml"), "utf8");
    const match = workflow.match(
      /- name: Determine version[\s\S]*?run: \|\n((?: {10}[^\n]*\n|\n)+)/,
    );
    if (!match) throw new Error("Missing mini-workflow version step");
    const script = match[1].replace(/^ {10}/gm, "");
    mkdirSync(join(root, "scripts"));
    copyFileSync(
      resolve("scripts/source_version_policy.py"),
      join(root, "scripts/source_version_policy.py"),
    );
    writeFileSync(
      join(root, "scripts/discover_latest_release.py"),
      `
import os, json
from pathlib import Path
Path("discovery-called").touch()
version = os.environ["DISCOVERED_VERSION"]
if version == "FAIL":
    raise RuntimeError("simulated discovery failure")
print(json.dumps({"gnaf_version": version, "admin_bdys_version": os.environ["DISCOVERED_ADMIN"]}))
`,
    );
    const output = join(root, "outputs");
    const result = spawnSync("bash", ["-e", "-o", "pipefail", "-c", script], {
      cwd: root,
      encoding: "utf8",
      env: {
        ...process.env,
        GNAF_INPUT: input,
        DISCOVERED_VERSION: discovered,
        DISCOVERED_ADMIN: discoveredAdmin,
        GITHUB_OUTPUT: output,
      },
    });
    if (result.error) throw result.error;
    return {
      status: result.status,
      published: existsSync(output) ? readFileSync(output, "utf8") : "",
      discovered: existsSync(join(root, "discovery-called")),
    };
  }

  describe("mini quarterly preflight", () => {
    it.each(["2026.13", "2027.01", "2026.05", "--help", "2026.08.1"])(
      "does not publish an invalid explicit quarter: %s",
      (version) => {
        const result = runMini(version);
        expect(result.status).toBe(1);
        expect(result.published).toBe("");
        expect(result.discovered).toBe(false);
      },
    );
    it.each(["2026.08", "2026.11"])("publishes a valid explicit quarter: %s", (version) => {
      const result = runMini(version);
      expect(result.status).toBe(0);
      expect(result.published).toBe(
        `version=${version}\nadmin_bdys_version=${version}\ndata_source_key=gnaf-${version}-admin-${version}\n`,
      );
      expect(result.discovered).toBe(false);
    });
    it.each(["2026.13", "2027.01", "2026.05", "", "FAIL"])(
      "does not publish an unusable discovered quarter: %s",
      (version) => {
        const result = runMini("", version);
        expect(result.status).toBe(1);
        expect(result.published).toBe("");
        expect(result.discovered).toBe(true);
      },
    );
    it("publishes a valid discovered quarter", () => {
      const result = runMini("");
      expect(result.status).toBe(0);
      expect(result.published).toBe(
        "version=2026.08\nadmin_bdys_version=2026.08\ndata_source_key=gnaf-2026.08-admin-2026.08\n",
      );
      expect(result.discovered).toBe(true);
    });
    it("freezes independently discovered source versions in the cache identity", () => {
      const result = runMini("", "2026.11", "2026.08");
      expect(result.status).toBe(0);
      expect(result.published).toBe(
        "version=2026.11\nadmin_bdys_version=2026.08\ndata_source_key=gnaf-2026.11-admin-2026.08\n",
      );
    });
    it.each(["2026.05", "2026.13", "", "--help"])(
      "rejects incompatible discovered boundaries: %s",
      (admin) => {
        const result = runMini("", "2026.08", admin);
        expect(result.status).toBe(1);
        expect(result.published).toBe("");
      },
    );
  });

  for (const script of ["docker-entrypoint.sh", "scripts/build-local.sh"]) {
    describe(script, () => {
      it.each([
        "",
        "2026.05",
        "2025.11",
        "2026.8",
        "2026.08.1",
        "2026.09",
        "2026.00",
        "2026.13",
        "2026.08\n",
        "--help",
        "-h",
        "--version",
      ])("rejects %j before output setup or infrastructure", (version) => {
        const result = run(script, version);
        expect(result.status).toBe(1);
        expect(result.output).toContain("ERROR:");
        expect(result.output).not.toContain("REACHED_OUTPUT_SETUP");
      });

      it.each(["2026.08", "2026.11", "2027.02"])("accepts %s", (version) => {
        const result = run(script, version);
        expect(result.status).toBe(97);
        expect(result.output).toContain("REACHED_OUTPUT_SETUP");
      });

      it.each([
        "2026.05",
        "2025.11",
        "2026.8",
        "2026.08.1",
        "2026.09",
        "2026.00",
        "2026.13",
        "--help",
        "-h",
        "--version",
        "manual",
      ])(
        "rejects administrative-boundary override %j before any build side effect",
        (adminVersion) => {
          const result = run(script, "2026.08", [], adminVersion);
          expect(result.status).toBe(1);
          expect(result.output).toContain("ADMIN_BDYS_VERSION");
          expect(result.output).not.toContain("REACHED_OUTPUT_SETUP");
        },
      );

      it.each(["", "   ", "2026.08", "2026.11", "2027.02", " 2026.08 "])(
        "accepts optional or compatible administrative-boundary override %j",
        (adminVersion) => {
          const result = run(script, "2026.08", [], adminVersion);
          expect(result.status).toBe(97);
          expect(result.output).toContain("REACHED_OUTPUT_SETUP");
        },
      );
    });
  }

  it.each([
    ["--skip-download", "--gnaf-path", "/unused/gnaf", "--admin-path", "/unused/admin"],
    ["--restore-db", "/unused/cache.dump"],
  ])("cached inputs do not bypass the production guard: %j", (...args) => {
    const result = run("docker-entrypoint.sh", "2026.05", args);
    expect(result.status).toBe(1);
    expect(result.output).toContain("2026.08 or newer");
    expect(result.output).not.toContain("REACHED_OUTPUT_SETUP");
  });

  it("validates the effective local --version override", () => {
    const rejected = run("scripts/build-local.sh", "2026.08", [
      "--version",
      "2026.05",
      "--skip-load",
    ]);
    expect(rejected.status).toBe(1);
    expect(rejected.output).not.toContain("REACHED_OUTPUT_SETUP");
    expect(run("scripts/build-local.sh", "2026.05", ["--version", "2026.08"]).status).toBe(97);
  });

  it("keeps the frozen February fixture exemption", () => {
    const result = run("docker-entrypoint.sh", "", ["--fixture-only"], "2026.02");
    expect(result.status).toBe(97);
    expect(result.output).toContain("REACHED_OUTPUT_SETUP version=2026.02");
  });

  it.each([
    [
      "docker-entrypoint.sh",
      "--skip-download",
      "--gnaf-path",
      "/unused/gnaf",
      "--admin-path",
      "/unused/admin",
    ],
    ["docker-entrypoint.sh", "--restore-db", "/unused/cache.dump"],
    ["scripts/build-local.sh", "--skip-load"],
  ])("cached inputs cannot bypass the boundary-version guard: %s %s", (script, ...args) => {
    const result = run(script, "2026.08", args, "2026.05");
    expect(result.status).toBe(1);
    expect(result.output).toContain("ADMIN_BDYS_VERSION 2026.08 or newer");
    expect(result.output).not.toContain("REACHED_OUTPUT_SETUP");
  });

  it("help works without a production version", () => {
    const result = run("docker-entrypoint.sh", "", ["--help"]);
    expect(result.status).toBe(0);
    expect(result.output).toContain("2026.08 or newer");
    expect(result.output).not.toContain("REACHED_OUTPUT_SETUP");
  });
});
