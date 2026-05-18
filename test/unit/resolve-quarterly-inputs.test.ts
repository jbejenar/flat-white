import { execFileSync } from "node:child_process";
import { dirname, resolve } from "node:path";
import { describe, expect, it } from "vitest";

const scriptPath = resolve("scripts/resolve_quarterly_inputs.py");
const scriptDir = dirname(scriptPath);

interface QuarterlyInputs {
  version: string;
  admin_bdys_version: string;
  release_version: string;
  data_source_key: string;
  manual_source: boolean;
  auto_discovered_gnaf: boolean;
}

function resolveInputs(
  args: Record<string, string>,
  discovered: { gnaf_version: string; admin_bdys_version: string } | "raise" = {
    gnaf_version: "2026.05",
    admin_bdys_version: "2026.02",
  },
): QuarterlyInputs {
  const code = `
import importlib.util
import json
import sys
sys.path.insert(0, ${JSON.stringify(scriptDir)})
spec = importlib.util.spec_from_file_location("resolve_quarterly_inputs", ${JSON.stringify(scriptPath)})
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

def discover():
    ${
      discovered === "raise"
        ? 'raise RuntimeError("discovery should not be called")'
        : `return ${JSON.stringify(discovered)}`
    }

print(json.dumps(module.resolve_quarterly_inputs(
    gnaf_version=${JSON.stringify(args.gnaf_version ?? "")},
    patch_version=${JSON.stringify(args.patch_version ?? "")},
    download_url_gnaf=${JSON.stringify(args.download_url_gnaf ?? "")},
    download_url_admin_bdys=${JSON.stringify(args.download_url_admin_bdys ?? "")},
    admin_bdys_extracted_dir=${JSON.stringify(args.admin_bdys_extracted_dir ?? "")},
    discover=discover,
)))
`;

  return JSON.parse(execFileSync("python3", ["-c", code], { encoding: "utf8" })) as QuarterlyInputs;
}

function resolveInputsFailure(args: Record<string, string>): string {
  const code = `
import importlib.util
import json
import sys
sys.path.insert(0, ${JSON.stringify(scriptDir)})
spec = importlib.util.spec_from_file_location("resolve_quarterly_inputs", ${JSON.stringify(scriptPath)})
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

def discover():
    return {"gnaf_version":"2026.05","admin_bdys_version":"2026.02"}

try:
    module.resolve_quarterly_inputs(
        gnaf_version=${JSON.stringify(args.gnaf_version ?? "")},
        patch_version=${JSON.stringify(args.patch_version ?? "")},
        download_url_gnaf=${JSON.stringify(args.download_url_gnaf ?? "")},
        download_url_admin_bdys=${JSON.stringify(args.download_url_admin_bdys ?? "")},
        admin_bdys_extracted_dir=${JSON.stringify(args.admin_bdys_extracted_dir ?? "")},
        discover=discover,
    )
except Exception as exc:
    print(str(exc))
else:
    raise AssertionError("Expected resolver to fail")
`;

  return execFileSync("python3", ["-c", code], { encoding: "utf8" }).trim();
}

describe("resolve_quarterly_inputs.py", () => {
  it("auto-discovers freshest G-NAF and freshest Admin Boundaries", () => {
    expect(resolveInputs({})).toMatchObject({
      version: "2026.05",
      admin_bdys_version: "2026.02",
      release_version: "2026.05",
      data_source_key: "gnaf-2026.05-admin-2026.02",
      manual_source: false,
      auto_discovered_gnaf: true,
    });
  });

  it("skips discovery entirely when complete manual overrides are supplied", () => {
    const result = resolveInputs(
      {
        gnaf_version: "2026.05",
        download_url_gnaf: "https://example.com/gnaf.zip",
        download_url_admin_bdys: "https://example.com/admin.zip",
        admin_bdys_extracted_dir: "CUSTOM_AdminBounds_GDA_2020_SHP",
      },
      "raise",
    );

    expect(result.version).toBe("2026.05");
    expect(result.admin_bdys_version).toBe("manual");
    expect(result.data_source_key).toMatch(/^manual-[a-f0-9]{64}$/);
    expect(result.manual_source).toBe(true);
    expect(result.auto_discovered_gnaf).toBe(false);
  });

  it("requires gnaf_version for manual source overrides", () => {
    expect(
      resolveInputsFailure({
        download_url_gnaf: "https://example.com/gnaf.zip",
        download_url_admin_bdys: "https://example.com/admin.zip",
        admin_bdys_extracted_dir: "CUSTOM_AdminBounds_GDA_2020_SHP",
      }),
    ).toContain("Manual data-source overrides require gnaf_version");
  });

  it("rejects incomplete manual source overrides", () => {
    expect(
      resolveInputsFailure({
        gnaf_version: "2026.05",
        download_url_gnaf: "https://example.com/gnaf.zip",
      }),
    ).toContain("Manual data-source overrides must be provided together");
  });

  it("keeps Admin Boundaries aligned when gnaf_version is pinned", () => {
    expect(resolveInputs({ gnaf_version: "2026.02" })).toMatchObject({
      version: "2026.02",
      admin_bdys_version: "2026.02",
      data_source_key: "gnaf-2026.02-admin-2026.02",
      manual_source: false,
      auto_discovered_gnaf: false,
    });
  });

  it("applies patch_version only to release_version", () => {
    expect(resolveInputs({ gnaf_version: "2026.02", patch_version: "1" })).toMatchObject({
      version: "2026.02",
      admin_bdys_version: "2026.02",
      release_version: "2026.02.1",
    });
  });
});
