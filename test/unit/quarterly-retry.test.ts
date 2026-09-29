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

describe("quarterly pipeline retries", () => {
  let root: string;

  beforeEach(() => {
    root = mkdtempSync(join(tmpdir(), "flat-white-quarterly-retry-"));
    mkdirSync(join(root, "bin"));
    mkdirSync(join(root, "scripts"));
    for (const file of [
      "run-quarterly-state.sh",
      "summarize-quarterly-run.py",
      "quarterly_failure.py",
      "source_version_policy.py",
    ]) {
      copyFileSync(resolve("scripts", file), join(root, "scripts", file));
    }
    writeFileSync(
      join(root, "bin", "docker"),
      `#!/usr/bin/env bash
set -eu
printf '%s\\n' "$@" >> docker-args
calls=0
[[ ! -f calls ]] || calls="$(cat calls)"
calls=$((calls + 1))
echo "$calls" > calls
if [[ "$calls" == 1 ]]; then
  cat failure.log
  exit 1
fi
exit 0
`,
    );
    writeFileSync(join(root, "bin", "sleep"), "#!/usr/bin/env bash\nexit 0\n");
    chmodSync(join(root, "bin", "docker"), 0o755);
    chmodSync(join(root, "bin", "sleep"), 0o755);
  });

  afterEach(() => rmSync(root, { recursive: true, force: true }));

  function run(failure: string, overrides: NodeJS.ProcessEnv = {}) {
    writeFileSync(join(root, "failure.log"), failure);
    const result = spawnSync(
      "bash",
      ["scripts/run-quarterly-state.sh", "ACT", "2026.08", "fixture-image"],
      {
        cwd: root,
        encoding: "utf8",
        env: {
          ...process.env,
          PATH: `${join(root, "bin")}:${process.env.PATH}`,
          MAX_RETRIES: "2",
          ADMIN_BDYS_VERSION_EFFECTIVE: "",
          ...overrides,
        },
      },
    );
    if (result.error) throw result.error;
    return {
      status: result.status,
      output: result.stdout + result.stderr,
      calls: Number(readFileSync(join(root, "calls"), "utf8")),
      telemetry: JSON.parse(
        readFileSync(join(root, "output", "quarterly-telemetry-ACT.json"), "utf8"),
      ) as {
        attempts: number;
        success: boolean;
        networkErrorDetected: boolean;
      },
    };
  }

  const manualSources = {
    ADMIN_BDYS_VERSION_EFFECTIVE: "manual",
    DOWNLOAD_URL_GNAF_EFFECTIVE: "https://fixture.invalid/gnaf.zip",
    DOWNLOAD_URL_ADMIN_BDYS_EFFECTIVE: "https://fixture.invalid/admin.zip",
    ADMIN_BDYS_EXTRACTED_DIR_EFFECTIVE: "AUG26_AdminBounds_GDA_2020_SHP",
  };

  it("keeps manual provenance out of the downloader's quarter selector", () => {
    const result = run("[download] Failure kind: transient", manualSources);
    expect(result.status).toBe(0);
    const args = readFileSync(join(root, "docker-args"), "utf8");
    expect(args).toContain("ADMIN_BDYS_VERSION=\n");
    expect(args).not.toContain("ADMIN_BDYS_VERSION=manual");
    expect(args).toContain("DOWNLOAD_URL_ADMIN_BDYS=https://fixture.invalid/admin.zip");
  });

  it("passes a valid independent boundary quarter to Docker", () => {
    expect(
      run("[download] Failure kind: transient", { ADMIN_BDYS_VERSION_EFFECTIVE: "2026.11" }).status,
    ).toBe(0);
    expect(readFileSync(join(root, "docker-args"), "utf8")).toContain(
      "ADMIN_BDYS_VERSION=2026.11\n",
    );
  });

  it.each([
    { ADMIN_BDYS_VERSION_EFFECTIVE: "2026.05" },
    { ADMIN_BDYS_VERSION_EFFECTIVE: "2026.13" },
    { ADMIN_BDYS_VERSION_EFFECTIVE: "--help" },
    { ADMIN_BDYS_VERSION_EFFECTIVE: "manual" },
    { ...manualSources, DOWNLOAD_URL_GNAF_EFFECTIVE: "" },
    { ...manualSources, DOWNLOAD_URL_ADMIN_BDYS_EFFECTIVE: " " },
    { ...manualSources, ADMIN_BDYS_EXTRACTED_DIR_EFFECTIVE: "" },
  ])("rejects invalid source selection before output, cache or Docker: %j", (overrides) => {
    const result = spawnSync(
      "bash",
      ["scripts/run-quarterly-state.sh", "ACT", "2026.08", "fixture-image"],
      {
        cwd: root,
        encoding: "utf8",
        env: {
          ...process.env,
          PATH: `${join(root, "bin")}:${process.env.PATH}`,
          DOWNLOAD_URL_GNAF_EFFECTIVE: "",
          DOWNLOAD_URL_ADMIN_BDYS_EFFECTIVE: "",
          ADMIN_BDYS_EXTRACTED_DIR_EFFECTIVE: "",
          ...overrides,
        },
      },
    );
    expect(result.status).toBe(1);
    expect(result.stdout + result.stderr).toContain("ERROR:");
    for (const file of ["calls", "output", "cache"])
      expect(existsSync(join(root, file))).toBe(false);
  });

  it("does not retry the real archive-validation failure behind the generic Download failed message", () => {
    const result = run(
      "[download] Fatal: Error: Extraction of Administrative Boundaries GDA2020 failed sentinel validation\n[entrypoint] ERROR: Download failed\n",
    );
    expect(result.status).toBe(1);
    expect(result.calls).toBe(1);
    expect(result.output).toContain("persistent failure on attempt 1");
    expect(result.telemetry).toMatchObject({
      attempts: 1,
      success: false,
      networkErrorDetected: false,
    });
  });

  it("does not retry a missing resource", () => {
    const result = run(
      "Failed to download G-NAF after 4 attempts: HTTP 404 Not Found\n[entrypoint] ERROR: Download failed\n",
    );
    expect(result.status).toBe(1);
    expect(result.calls).toBe(1);
    expect(result.telemetry.networkErrorDetected).toBe(false);
  });

  it("does not retry a permanent download failure after a recovered transport error", () => {
    const result = run(
      "[download] attempt 1 failed: fetch failed\n[download] complete\n" +
        "[download] Fatal: Error: failed sentinel validation\n" +
        "[download] Failure kind: permanent\n[entrypoint] ERROR: Download failed\n",
    );
    expect(result.status).toBe(1);
    expect(result.calls).toBe(1);
    expect(result.telemetry.networkErrorDetected).toBe(true);
  });

  it("does not use recovered errors from an earlier stage to retry failed verification", () => {
    const result = run(
      '{"stage":"download","event":"stage_start"}\nfetch failed\n' +
        '{"stage":"download","event":"stage_end","elapsed_s":2}\n' +
        '{"stage":"verify","event":"stage_start"}\nERROR: schema validation failed\n',
    );
    expect(result.status).toBe(1);
    expect(result.calls).toBe(1);
    expect(result.telemetry.networkErrorDetected).toBe(true);
  });

  it.each([
    "ETIMEDOUT",
    "fetch failed",
    "FETCH FAILED",
    "HTTP 408 Request Timeout",
    "HTTP 429 Too Many Requests",
    "HTTP 503 Service Unavailable",
    "[download] Failure kind: transient",
  ])("still retries actual transient failures: %s", (message) => {
    const result = run(`${message}\n[entrypoint] ERROR: Download failed\n`);
    expect(result.status).toBe(0);
    expect(result.calls).toBe(2);
    expect(result.telemetry).toMatchObject({
      attempts: 2,
      success: true,
      networkErrorDetected: true,
    });
  });
});
