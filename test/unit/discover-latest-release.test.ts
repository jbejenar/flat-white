import { execFileSync } from "node:child_process";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const scriptPath = resolve("scripts/discover_latest_release.py");

function resolveLatest(
  gnafVersions: string[],
  adminVersions: string[],
): {
  gnaf_version: string;
  admin_bdys_version: string;
} {
  const code = `
import importlib.util
import json
spec = importlib.util.spec_from_file_location("discover_latest_release", ${JSON.stringify(scriptPath)})
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
print(json.dumps(module.resolve_latest_release_versions(set(${JSON.stringify(gnafVersions)}), set(${JSON.stringify(adminVersions)}))))
`;

  return JSON.parse(execFileSync("python3", ["-c", code], { encoding: "utf8" }).trim()) as {
    gnaf_version: string;
    admin_bdys_version: string;
  };
}

function resolveLatestFailure(gnafVersions: string[], adminVersions: string[]): string {
  const code = `
import importlib.util
spec = importlib.util.spec_from_file_location("discover_latest_release", ${JSON.stringify(scriptPath)})
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
module.resolve_latest_release_versions(set(${JSON.stringify(gnafVersions)}), set(${JSON.stringify(adminVersions)}))
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
  it("selects the freshest G-NAF and freshest Admin Boundaries independently", () => {
    expect(resolveLatest(["2026.05"], ["2026.02"])).toEqual({
      gnaf_version: "2026.05",
      admin_bdys_version: "2026.02",
    });
  });

  it("does not mask a parser regression where no versions are discovered", () => {
    expect(resolveLatestFailure([], [])).toContain("No active G-NAF GDA2020 ZIP releases found");
  });

  it("does not mask a missing Admin Boundaries package", () => {
    expect(resolveLatestFailure(["2026.05"], [])).toContain(
      "No active Admin Boundaries GDA2020 shapefile ZIP releases found",
    );
  });

  it("selects the newest versions from each package", () => {
    expect(resolveLatest(["2026.05", "2026.08"], ["2026.05", "2026.02"])).toEqual({
      gnaf_version: "2026.08",
      admin_bdys_version: "2026.05",
    });
  });
});
