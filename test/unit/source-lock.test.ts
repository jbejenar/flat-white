import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { mkdtempSync, readFileSync, writeFileSync, rmSync, existsSync } from "node:fs";
import { execFileSync } from "node:child_process";
import { tmpdir } from "node:os";
import { join } from "node:path";
import {
  acquireSources,
  extractLockedSources,
  quarterEnd,
  readSourceLock,
  sourceIdentity,
  validateBoundaryDate,
} from "../../src/source-lock.js";

let root: string;
beforeEach(() => {
  root = mkdtempSync(join(tmpdir(), "source-lock-test-"));
  vi.stubEnv("DOWNLOAD_URL_GNAF", "https://fixture.invalid/gnaf.zip");
  vi.stubEnv("DOWNLOAD_URL_ADMIN_BDYS", "https://fixture.invalid/admin.zip");
  vi.stubEnv("ADMIN_BDYS_EXTRACTED_DIR", "AUG26_AdminBounds_GDA_2020_SHP");
});
afterEach(() => {
  vi.unstubAllGlobals();
  vi.unstubAllEnvs();
  rmSync(root, { recursive: true, force: true });
});

function archive(name: string, paths: string[], contents = "fixture") {
  const file = join(root, name);
  execFileSync("python3", [
    "-c",
    "import sys,json,zipfile\nwith zipfile.ZipFile(sys.argv[1], 'w') as z:\n for p in json.loads(sys.argv[2]): z.writestr(p, sys.argv[3])",
    file,
    JSON.stringify(paths),
    contents,
  ]);
  return new Uint8Array(readFileSync(file));
}
function mockSources(gnafExtra: string[] = []) {
  const gnaf = archive("gnaf-input.zip", [
    "G-NAF/G-NAF AUGUST 2026/Standard/OT_ADDRESS_DETAIL_psv.psv",
    "G-NAF/G-NAF AUGUST 2026/Authority Code/STATE_psv.psv",
    ...gnafExtra,
  ]);
  const admin = archive("admin-input.zip", [
    "LocalGovernmentAreas_AUG26/lga.shp",
    "StateBoundaries_AUG20/state.shp",
  ]);
  const fetcher = vi.fn(
    async (url: string | URL | Request) =>
      new Response(String(url).endsWith("gnaf.zip") ? gnaf : admin),
  );
  vi.stubGlobal("fetch", fetcher);
  return fetcher;
}
function acquire(directory = join(root, "sources"), pinnedLock?: string) {
  return acquireSources({
    version: "2026.08",
    adminVersion: "manual",
    boundaryDate: "2026-08-31",
    directory,
    pinnedLock,
  });
}

describe("locked source archives", () => {
  it("acquires each archive once, locks its bytes and inventory, and verifies extraction", async () => {
    const fetcher = mockSources();
    const lock = await acquire();
    expect(fetcher).toHaveBeenCalledTimes(2);
    expect(lock.sources.map((source) => source.sha256)).toEqual([
      expect.stringMatching(/^[a-f0-9]{64}$/),
      expect.stringMatching(/^[a-f0-9]{64}$/),
    ]);
    expect(lock.sources[0].inventory).toHaveLength(2);
    const lockPath = join(root, "sources/source-lock.json");
    expect(await readSourceLock(lockPath)).toEqual(lock);
    await extractLockedSources(lockPath, join(root, "sources"), join(root, "data"));
    expect(readFileSync(join(root, "data/.flat-white-source-identity"), "utf8").trim()).toBe(
      sourceIdentity(lock),
    );
    expect(
      readFileSync(
        join(root, "data/G-NAF/G-NAF AUGUST 2026/Standard/OT_ADDRESS_DETAIL_psv.psv"),
        "utf8",
      ),
    ).toBe("fixture");
    const pythonIdentity = execFileSync(
      "python3",
      ["scripts/cache_attestation.py", "source-identity", "--lock", lockPath],
      { encoding: "utf8" },
    ).trim();
    expect(pythonIdentity).toBe(sourceIdentity(lock));
    expect(sourceIdentity({ ...lock, acquiredAt: "2027-01-01T00:00:00.000Z" })).toBe(
      sourceIdentity(lock),
    );
  });

  it("reuses a pinned lock and rejects upstream replacement bytes", async () => {
    mockSources();
    const original = await acquire();
    const lockPath = join(root, "sources/source-lock.json");
    expect(await acquire(join(root, "repeat"), lockPath)).toEqual(original);
    mockSources(["G-NAF/new.txt"]);
    await expect(acquire(join(root, "changed"), lockPath)).rejects.toThrow("Source bytes changed");
    expect(existsSync(join(root, "changed/source-lock.json"))).toBe(false);
  });

  it("verifies both archive checksums before touching extracted datasets", async () => {
    mockSources();
    await acquire();
    writeFileSync(join(root, "sources/admin.zip"), "corrupt");
    await expect(
      extractLockedSources(
        join(root, "sources/source-lock.json"),
        join(root, "sources"),
        join(root, "data"),
      ),
    ).rejects.toThrow("Source checksum mismatch");
    expect(existsSync(join(root, "data"))).toBe(false);
  });

  it("removes an old extraction stamp if replacement fails part-way through", async () => {
    mockSources();
    const lock = await acquire();
    const lockPath = join(root, "sources/source-lock.json");
    await extractLockedSources(lockPath, join(root, "sources"), join(root, "data"));
    lock.sources[1].sentinelPaths = ["missing-directory"];
    writeFileSync(lockPath, JSON.stringify(lock));
    await expect(
      extractLockedSources(lockPath, join(root, "sources"), join(root, "data")),
    ).rejects.toThrow("Incomplete locked extraction");
    expect(existsSync(join(root, "data/.flat-white-source-identity"))).toBe(false);
  });

  it("rejects a boundary date that disagrees with a pinned lock", async () => {
    mockSources();
    await acquire();
    await expect(
      acquireSources({
        version: "2026.08",
        adminVersion: "manual",
        directory: join(root, "repeat"),
        pinnedLock: join(root, "sources/source-lock.json"),
        boundaryDate: "2026-09-30",
      }),
    ).rejects.toThrow("Boundary date disagrees");
  });

  it("rejects extraction traversal before publishing a source lock", async () => {
    mockSources(["../escape.shp"]);
    await expect(acquire()).rejects.toThrow("Unsafe source archive member");
    expect(existsSync(join(root, "sources/source-lock.json"))).toBe(false);
  });

  it("requires a real administrative reference date for manual sources", async () => {
    await expect(
      acquireSources({
        version: "2026.08",
        adminVersion: "manual",
        directory: join(root, "sources"),
      }),
    ).rejects.toThrow("Invalid boundary reference date");
  });

  it("uses package month-end including leap years, never the build date", () => {
    expect(quarterEnd("2026.08")).toBe("2026-08-31");
    expect(quarterEnd("2028.02")).toBe("2028-02-29");
    for (const value of ["2026-02-29", "20260831", "2026-13-01", "2026-08-31'"])
      expect(() => validateBoundaryDate(value)).toThrow();
  });
});
