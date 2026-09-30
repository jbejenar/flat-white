import { afterEach, beforeEach, describe, expect, it } from "vitest";
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from "node:fs";
import { execFileSync } from "node:child_process";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { sourceIdentity, type SourceLock } from "../../src/source-lock.js";
import { parseReleaseMetadata, verifyBuildProvenance } from "../../src/verification-report.js";
import { VERSION } from "../../src/index.js";

let directory: string;
beforeEach(() => {
  directory = mkdtempSync(join(tmpdir(), "provenance-test-"));
});
afterEach(() => rmSync(directory, { recursive: true, force: true }));
const states = ["ACT", "NSW", "NT", "OT", "QLD", "SA", "TAS", "VIC", "WA"];
const lock: SourceLock = {
  formatVersion: 1,
  gnafVersion: "2026.08",
  adminVersion: "2026.08",
  boundaryReferenceDate: "2026-08-31",
  acquiredAt: "2026-09-30T00:00:00.000Z",
  acquiredWith: {
    loaderCommit: "a".repeat(40),
    preparationFingerprint: "b".repeat(64),
    node: "v22",
  },
  sources: (["gnaf", "admin"] as const).map((kind) => ({
    kind,
    name: kind,
    url: `https://fixture.invalid/${kind}.zip`,
    resourceId: null,
    edition: "2026.08",
    archive: `${kind}.zip`,
    bytes: 1,
    sha256: "c".repeat(64),
    extractedDir: kind,
    sentinelPaths: ["fixture"],
    inventory: [{ path: "fixture", bytes: 1, crc32: 1 }],
  })),
};
const metadata = () =>
  parseReleaseMetadata({
    version: "2026.08.1",
    gnafVersion: "2026.08",
    adminBoundariesVersion: "2026.08",
    schemaVersion: VERSION,
    asgsYear: 2026,
    totalCount: 9,
    states: Object.fromEntries(states.map((state) => [state, 1])),
    sourceLock: "source-lock.json",
    boundaryReferenceDate: "2026-08-31",
  });
function proof(state: string) {
  return {
    context: {
      formatVersion: 1,
      sourceIdentity: sourceIdentity(lock),
      gnafVersion: "2026.08",
      boundaryReferenceDate: "2026-08-31",
      states: [state],
      runtimeFingerprint: "d".repeat(64),
      scope: "base-gnaf-geoscape",
    },
    dumpSha256: "e".repeat(64),
  };
}
function bundle() {
  writeFileSync(join(directory, "source-lock.json"), JSON.stringify(lock));
  for (const state of states)
    writeFileSync(join(directory, `build-provenance-${state}.json`), JSON.stringify(proof(state)));
}

describe("release source provenance", () => {
  it("requires every state to use the selected sources and the same runtime", async () => {
    bundle();
    await verifyBuildProvenance(directory, metadata());
    const changed = proof("OT");
    changed.context.runtimeFingerprint = "f".repeat(64);
    writeFileSync(join(directory, "build-provenance-OT.json"), JSON.stringify(changed));
    await expect(verifyBuildProvenance(directory, metadata())).rejects.toThrow(
      "different code or runtimes",
    );
  });
  it.each(["sourceIdentity", "gnafVersion", "boundaryReferenceDate", "states", "scope"])(
    "rejects mismatched state provenance: %s",
    async (field) => {
      bundle();
      const changed = proof("OT");
      writeFileSync(
        join(directory, "build-provenance-OT.json"),
        JSON.stringify({
          ...changed,
          context: { ...changed.context, [field]: field === "states" ? ["ACT"] : "incorrect" },
        }),
      );
      await expect(verifyBuildProvenance(directory, metadata())).rejects.toThrow();
    },
  );
  it("rejects missing locks, inconsistent release metadata and partial national releases", async () => {
    bundle();
    const missing = metadata();
    delete missing.sourceLock;
    await expect(verifyBuildProvenance(directory, missing)).rejects.toThrow(
      "source lock and all nine states",
    );
    await expect(
      verifyBuildProvenance(directory, { ...metadata(), boundaryReferenceDate: "2026-09-30" }),
    ).rejects.toThrow("disagrees");
    await expect(
      verifyBuildProvenance(directory, { ...metadata(), states: { OT: 9 } }),
    ).rejects.toThrow("all nine states");
  });
});

it("fingerprints tracked build inputs and the loader pin, excluding generated files", () => {
  const git = (...args: string[]) =>
    execFileSync("git", ["-C", directory, ...args], { stdio: "pipe" });
  git("init", "-q");
  mkdirSync(join(directory, "src"));
  mkdirSync(join(directory, "scripts"));
  mkdirSync(join(directory, "gnaf-loader"));
  writeFileSync(join(directory, "src/schema.ts"), "export const version = 1;");
  git("add", "src");
  execFileSync("git", ["-C", join(directory, "gnaf-loader"), "init", "-q"]);
  const loaderCommit = () =>
    execFileSync("git", [
      "-C",
      join(directory, "gnaf-loader"),
      "-c",
      "user.name=Test",
      "-c",
      "user.email=test@example.invalid",
      "commit",
      "-q",
      "--allow-empty",
      "-m",
      "fixture",
    ]);
  loaderCommit();
  const code =
    "import importlib.util,sys; spec=importlib.util.spec_from_file_location('fingerprint',sys.argv[1]); m=importlib.util.module_from_spec(spec); spec.loader.exec_module(m); print(m.fingerprint(sys.argv[2]))";
  const hash = () =>
    execFileSync("python3", ["-c", code, resolve("scripts/cache_fingerprint.py"), directory], {
      encoding: "utf8",
    }).trim();
  const original = hash();
  mkdirSync(join(directory, "scripts/__pycache__"));
  writeFileSync(join(directory, "scripts/__pycache__/generated.pyc"), "generated");
  expect(hash()).toBe(original);
  writeFileSync(join(directory, "src/schema.ts"), "export const version = 2;");
  expect(hash()).not.toBe(original);
  const changed = hash();
  loaderCommit();
  expect(hash()).not.toBe(changed);
});
