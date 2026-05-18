import { execFileSync } from "node:child_process";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const scriptPath = resolve("scripts/discover_latest_release.py");

function resolveLatest(gnafVersions: string[], adminVersions: string[]): string {
  const code = `
import importlib.util
spec = importlib.util.spec_from_file_location("discover_latest_release", ${JSON.stringify(scriptPath)})
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
print(module.resolve_latest_common_version(set(${JSON.stringify(gnafVersions)}), set(${JSON.stringify(adminVersions)})))
`;

  return execFileSync("python3", ["-c", code], { encoding: "utf8" }).trim();
}

function resolveLatestFailure(gnafVersions: string[], adminVersions: string[]): string {
  const code = `
import importlib.util
spec = importlib.util.spec_from_file_location("discover_latest_release", ${JSON.stringify(scriptPath)})
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
module.resolve_latest_common_version(set(${JSON.stringify(gnafVersions)}), set(${JSON.stringify(adminVersions)}))
`;

  try {
    execFileSync("python3", ["-c", code], {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "pipe"],
    });
    throw new Error("Expected resolver to fail");
  } catch (error) {
    const stderr = error instanceof Error && "stderr" in error ? String(error.stderr) : "";
    return stderr;
  }
}

describe("discover_latest_release.py", () => {
  it("keeps the known fallback buildable during partial data.gov.au rollout", () => {
    expect(resolveLatest(["2026.05"], ["2026.02"])).toBe("2026.02");
  });

  it("does not mask a parser regression where no versions are discovered", () => {
    expect(resolveLatestFailure([], [])).toContain(
      "No overlapping quarterly G-NAF/Admin Boundaries releases found",
    );
  });

  it("does not invent the fallback when neither package advertises it", () => {
    expect(resolveLatestFailure(["2026.05"], ["2026.04"])).toContain(
      "No overlapping quarterly G-NAF/Admin Boundaries releases found",
    );
  });

  it("selects a normal future overlap ahead of the fallback", () => {
    expect(resolveLatest(["2026.05"], ["2026.05", "2026.02"])).toBe("2026.05");
  });
});
