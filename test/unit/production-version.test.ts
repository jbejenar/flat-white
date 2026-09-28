import { spawnSync } from "node:child_process";
import { chmodSync, mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
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
  });

  afterEach(() => rmSync(root, { recursive: true, force: true }));

  function run(script: string, version: string, args: string[] = []) {
    const result = spawnSync("bash", [resolve(script), ...args], {
      encoding: "utf8",
      env: {
        ...process.env,
        GNAF_VERSION: version,
        PATH: `${join(root, "bin")}:${process.env.PATH}`,
      },
    });
    if (result.error) throw result.error;
    return { status: result.status, output: result.stdout + result.stderr };
  }

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
    const result = run("docker-entrypoint.sh", "", ["--fixture-only"]);
    expect(result.status).toBe(97);
    expect(result.output).toContain("REACHED_OUTPUT_SETUP version=2026.02");
  });

  it("help works without a production version", () => {
    const result = run("docker-entrypoint.sh", "", ["--help"]);
    expect(result.status).toBe(0);
    expect(result.output).toContain("2026.08 or newer");
    expect(result.output).not.toContain("REACHED_OUTPUT_SETUP");
  });
});
