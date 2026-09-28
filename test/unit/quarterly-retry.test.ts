import { spawnSync } from "node:child_process";
import {
  chmodSync,
  copyFileSync,
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
    for (const file of ["run-quarterly-state.sh", "summarize-quarterly-run.py"]) {
      copyFileSync(resolve("scripts", file), join(root, "scripts", file));
    }
    writeFileSync(
      join(root, "bin", "docker"),
      `#!/usr/bin/env bash
set -eu
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

  function run(failure: string) {
    writeFileSync(join(root, "failure.log"), failure);
    const result = spawnSync(
      "bash",
      ["scripts/run-quarterly-state.sh", "ACT", "2026.05", "fixture-image"],
      {
        cwd: root,
        encoding: "utf8",
        env: { ...process.env, PATH: `${join(root, "bin")}:${process.env.PATH}`, MAX_RETRIES: "2" },
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

  it.each([
    "ETIMEDOUT",
    "fetch failed",
    "FETCH FAILED",
    "HTTP 429 Too Many Requests",
    "HTTP 503 Service Unavailable",
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
