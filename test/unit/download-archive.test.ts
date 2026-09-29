import { execFileSync } from "node:child_process";
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import {
  ADMIN_BDYS_PACKAGE_ID,
  DEFAULT_DATA_SOURCES,
  download,
  isExtractionComplete,
} from "../../src/download.js";

// These tiny ZIPs reproduce the published archive layout, with synthetic file
// contents. No G-NAF data, external HTTP request, or loader run is involved.
describe("download archive validation", () => {
  let root: string;
  const adminDirectory = "AUG26_AdminBounds_GDA_2020_SHP";
  const modernLga = "LOCAL-GOVERNMENT-AREAS_202608_ALLSTATES_GDA2020_SHP_002-002-001";
  const legacyLga = "LocalGovernmentAreas_FEB26_ALLSTATES_GDA2020_SHP_100";
  const states = "StateBoundaries_AUG20_ALLSTATES_GDA2020_SHP_100";

  beforeEach(() => {
    root = mkdtempSync(join(tmpdir(), "flat-white-archive-"));
    for (const variable of [
      "DOWNLOAD_URL_GNAF",
      "DOWNLOAD_URL_ADMIN_BDYS",
      "ADMIN_BDYS_EXTRACTED_DIR",
      "ADMIN_BDYS_VERSION",
    ]) {
      vi.stubEnv(variable, undefined);
    }
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    vi.unstubAllEnvs();
    rmSync(root, { recursive: true, force: true });
  });

  function zip(name: string, entries: string[]) {
    const path = join(root, name);
    execFileSync("python3", [
      "-c",
      `import json, sys, zipfile
with zipfile.ZipFile(sys.argv[1], 'w') as archive:
    for name in json.loads(sys.argv[2]):
        archive.writestr(name, 'synthetic fixture\\n')
`,
      path,
      JSON.stringify(entries),
    ]);
    return new Uint8Array(readFileSync(path));
  }

  function mockSources(adminEntries: string[]) {
    const gnafZip = zip("source-gnaf.zip", [
      "G-NAF/G-NAF AUGUST 2026/Standard/ACT_ADDRESS_DETAIL_psv.psv",
      "G-NAF/G-NAF AUGUST 2026/Authority Code/Authority_Code_STATE_psv.psv",
    ]);
    const adminZip = zip("source-admin.zip", adminEntries);
    const fetchMock = vi.fn(async (input: string | URL | Request) => {
      const url = String(input);
      if (url.includes("package_show")) {
        const admin = url.includes(ADMIN_BDYS_PACKAGE_ID);
        return Response.json({
          success: true,
          result: {
            resources: [
              {
                name: admin
                  ? "AUG26 - Geoscape Admin Boundaries - ESRI Shapefile - GDA2020"
                  : "AUG 2026 - Geoscape G-NAF - GDA2020",
                format: "ZIP",
                url: `https://fixture.invalid/${admin ? "admin" : "gnaf"}.zip`,
              },
            ],
          },
        });
      }
      if (url === "https://fixture.invalid/gnaf.zip") return new Response(gnafZip);
      if (url === "https://fixture.invalid/admin.zip") return new Response(adminZip);
      throw new Error(`Unexpected request: ${url}`);
    });
    vi.stubGlobal("fetch", fetchMock);
    return fetchMock;
  }

  it.each([
    { label: "legacy flat", lga: legacyLga, prefix: "" },
    { label: "modern flat", lga: modernLga, prefix: "" },
    { label: "modern wrapped", lga: modernLga, prefix: `${adminDirectory}/` },
  ])("downloads, extracts, validates, and promotes the $label archive", async ({ lga, prefix }) => {
    mockSources([
      `${prefix}${lga}/nsw_lga.shp`,
      `${prefix}${states}/State Boundaries/ACT_STATE_shp.shp`,
    ]);
    const outputDir = join(root, "data");
    const results = await download({ version: "2026.08", outputDir });
    expect(results).toHaveLength(2);
    expect(results.every((result) => !result.skipped && result.bytesDownloaded > 0)).toBe(true);
    expect(readFileSync(join(outputDir, adminDirectory, lga, "nsw_lga.shp"), "utf8")).toBe(
      "synthetic fixture\n",
    );
    expect(existsSync(join(outputDir, `${adminDirectory}.extracting`))).toBe(false);
    expect(existsSync(join(outputDir, "admin.zip"))).toBe(false);
    expect(
      (await download({ version: "2026.08", outputDir, skipIfExists: true })).every(
        (result) => result.skipped,
      ),
    ).toBe(true);
  });

  it("rejects a partial modern archive without replacing an existing extraction", async () => {
    mockSources([`${modernLga}/nsw_lga.shp`]);
    const outputDir = join(root, "data");
    const previous = join(outputDir, adminDirectory);
    mkdirSync(previous, { recursive: true });
    writeFileSync(join(previous, "previous.txt"), "preserve until replacement validates");
    await expect(download({ version: "2026.08", outputDir })).rejects.toThrow(
      "failed sentinel validation",
    );
    expect(readFileSync(join(previous, "previous.txt"), "utf8")).toBe(
      "preserve until replacement validates",
    );
    expect(existsSync(join(outputDir, `${adminDirectory}.extracting`))).toBe(false);
    expect(existsSync(join(outputDir, "admin.zip"))).toBe(false);
  });

  it("does not mistake a similarly named file for a required layer directory", () => {
    writeFileSync(join(root, modernLga), "not a directory");
    mkdirSync(join(root, states));
    expect(isExtractionComplete(root, DEFAULT_DATA_SOURCES[1].sentinelPaths)).toBe(false);
  });
});
