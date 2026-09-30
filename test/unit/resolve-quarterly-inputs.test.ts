import { mkdtempSync, writeFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
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
    gnaf_version: "2026.11",
    admin_bdys_version: "2026.08",
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
    boundary_reference_date=${JSON.stringify(args.boundary_reference_date ?? "")},
    source_lock=${JSON.stringify(args.source_lock ?? "")},
    discover=discover,
)))
`;

  return JSON.parse(execFileSync("python3", ["-c", code], { encoding: "utf8" })) as QuarterlyInputs;
}

function resolveInputsFailure(
  args: Record<string, string>,
  discovered = { gnaf_version: "2026.11", admin_bdys_version: "2026.08" },
): string {
  const code = `
import importlib.util
import json
import sys
sys.path.insert(0, ${JSON.stringify(scriptDir)})
spec = importlib.util.spec_from_file_location("resolve_quarterly_inputs", ${JSON.stringify(scriptPath)})
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

def discover():
    return ${JSON.stringify(discovered)}

try:
    module.resolve_quarterly_inputs(
        gnaf_version=${JSON.stringify(args.gnaf_version ?? "")},
        patch_version=${JSON.stringify(args.patch_version ?? "")},
        download_url_gnaf=${JSON.stringify(args.download_url_gnaf ?? "")},
        download_url_admin_bdys=${JSON.stringify(args.download_url_admin_bdys ?? "")},
        admin_bdys_extracted_dir=${JSON.stringify(args.admin_bdys_extracted_dir ?? "")},
        boundary_reference_date=${JSON.stringify(args.boundary_reference_date ?? "")},
    source_lock=${JSON.stringify(args.source_lock ?? "")},
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
      version: "2026.11",
      admin_bdys_version: "2026.08",
      release_version: "2026.11",
      data_source_key: "gnaf-2026.11-admin-2026.08",
      manual_source: false,
      auto_discovered_gnaf: true,
    });
  });

  it("skips discovery entirely when complete manual overrides are supplied", () => {
    const result = resolveInputs(
      {
        boundary_reference_date: "2026-11-30",
        gnaf_version: "2026.11",
        download_url_gnaf: "https://example.com/gnaf.zip",
        download_url_admin_bdys: "https://example.com/admin.zip",
        admin_bdys_extracted_dir: "CUSTOM_AdminBounds_GDA_2020_SHP",
      },
      "raise",
    );

    expect(result.version).toBe("2026.11");
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
        gnaf_version: "2026.11",
        download_url_gnaf: "https://example.com/gnaf.zip",
      }),
    ).toContain("Manual data-source overrides must be provided together");
  });

  it("keeps Admin Boundaries aligned when gnaf_version is pinned", () => {
    expect(resolveInputs({ gnaf_version: "2026.08" })).toMatchObject({
      version: "2026.08",
      admin_bdys_version: "2026.08",
      data_source_key: "gnaf-2026.08-admin-2026.08",
      manual_source: false,
      auto_discovered_gnaf: false,
    });
  });

  it("does not rediscover explicit or locked source editions", () => {
    expect(resolveInputs({ gnaf_version: "2026.08" }, "raise").version).toBe("2026.08");
    const directory = mkdtempSync(join(tmpdir(), "setup-lock-"));
    try {
      const path = join(directory, "source-lock.json");
      writeFileSync(
        path,
        JSON.stringify({
          formatVersion: 1,
          gnafVersion: "2026.11",
          adminVersion: "2026.08",
          boundaryReferenceDate: "2026-08-31",
        }),
      );
      expect(resolveInputs({ source_lock: path, patch_version: "1" }, "raise")).toMatchObject({
        version: "2026.11",
        admin_bdys_version: "2026.08",
        release_version: "2026.11.1",
      });
      expect(resolveInputsFailure({ source_lock: path, gnaf_version: "2026.08" })).toContain(
        "disagrees",
      );
      expect(
        resolveInputsFailure({ source_lock: path, boundary_reference_date: "2026-09-30" }),
      ).toContain("disagrees");
      writeFileSync(path, "{}");
      expect(resolveInputsFailure({ source_lock: path })).toContain(
        "Unsupported pinned source lock",
      );
    } finally {
      rmSync(directory, { recursive: true, force: true });
    }
  });

  it("validates the manual reference date before source acquisition", () => {
    const manual = {
      gnaf_version: "2026.08",
      download_url_gnaf: "https://example.com/gnaf.zip",
      download_url_admin_bdys: "https://example.com/admin.zip",
      admin_bdys_extracted_dir: "AdminBounds",
    };
    expect(resolveInputsFailure(manual)).toContain("require boundary_reference_date");
    expect(resolveInputsFailure({ ...manual, boundary_reference_date: "2026-02-30" })).toContain(
      "day is out of range",
    );
    expect(
      resolveInputsFailure({ gnaf_version: "2026.08", boundary_reference_date: "2026-08-30" }),
    ).toContain("package month-end");
  });

  it("applies patch_version only to release_version", () => {
    expect(resolveInputs({ gnaf_version: "2026.08", patch_version: "1" })).toMatchObject({
      version: "2026.08",
      admin_bdys_version: "2026.08",
      release_version: "2026.08.1",
    });
  });
  it("rejects a pre-migration G-NAF release before download", () => {
    expect(resolveInputsFailure({ gnaf_version: "2026.05" })).toContain("2026.08 or newer");
  });

  it("rejects old Admin Boundaries even with a current G-NAF release", () => {
    expect(
      resolveInputsFailure(
        {},
        {
          gnaf_version: "2026.08",
          admin_bdys_version: "2026.05",
        },
      ),
    ).toContain("2026.08 or newer");
  });

  it("does not let manual URLs bypass the G-NAF vintage guard", () => {
    expect(
      resolveInputsFailure({
        gnaf_version: "2026.05",
        download_url_gnaf: "https://example.com/gnaf.zip",
        download_url_admin_bdys: "https://example.com/admin.zip",
        admin_bdys_extracted_dir: "admin",
      }),
    ).toContain("2026.08 or newer");
  });

  it.each(["2026.8", "2026.08.1", "2026.09", "2026.13"])(
    "rejects malformed or non-quarterly explicit versions: %s",
    (version) => {
      expect(resolveInputsFailure({ gnaf_version: version })).toContain("expected YYYY.MM");
    },
  );

  it.each(["gnaf_version", "admin_bdys_version"])("also validates auto-discovered %s", (field) => {
    expect(
      resolveInputsFailure(
        {},
        {
          gnaf_version: "2026.08",
          admin_bdys_version: "2026.08",
          [field]: "2026.13",
        },
      ),
    ).toContain(`Invalid ${field}`);
  });
});
