import { mkdtempSync, rmSync, writeFileSync, readFileSync } from "node:fs";
import { spawnSync } from "node:child_process";
import { join, resolve } from "node:path";
import { tmpdir } from "node:os";
import { gzipSync, gunzipSync } from "node:zlib";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
let root: string;
beforeEach(() => {
  root = mkdtempSync(join(tmpdir(), "release-diff-"));
});
afterEach(() => rmSync(root, { recursive: true, force: true }));
const doc = (id: string) => ({
  _id: id,
  _version: "2026.08",
  state: "OT",
  postcode: "6798",
  boundaries: { commonwealthElectorate: null },
  allGeocodes: [],
});
function compare(before: unknown[], after: unknown[]) {
  for (const [name, docs] of [
    ["prior", before],
    ["current", after],
  ] as const)
    writeFileSync(
      join(root, name + ".gz"),
      gzipSync(docs.map((doc) => JSON.stringify(doc)).join("\n") + "\n"),
    );
  return spawnSync(
    "python3",
    [
      "-c",
      `import sys,json\nfrom pathlib import Path\nsys.path.insert(0,sys.argv[1])\nfrom compare_release_files import compare_state\nr=Path(sys.argv[2])\nprint(json.dumps(compare_state(r/'prior.gz',r/'current.gz',r/'changes.gz',state='OT',prior_quarter='2026.08',quarter='2026.08',prior_schema='1.0.0',schema='1.0.0')))`,
      resolve("scripts"),
      root,
    ],
    { encoding: "utf8" },
  );
}
describe("full release comparison", () => {
  it("records every expected OT repair and rejects an unrelated field change", () => {
    const first = doc("GAOT_1"),
      second = doc("GAOT_2");
    const result = compare(
      [first, second],
      [
        { ...first, boundaries: { commonwealthElectorate: { name: "BEAN" } } },
        { ...second, postcode: "9999" },
      ],
    );
    expect(result.status, result.stderr).toBe(0);
    const report = JSON.parse(result.stdout);
    expect(report).toMatchObject({
      priorCount: 2,
      currentCount: 2,
      changed: 2,
      unexpectedChanges: 1,
      added: 0,
      removed: 0,
    });
    expect(report.fields).toEqual({
      "boundaries.commonwealthElectorate": { changed: 1, unexpected: 0 },
      postcode: { changed: 1, unexpected: 1 },
    });
    const changes = gunzipSync(readFileSync(join(root, "changes.gz")))
      .toString()
      .trim()
      .split("\n")
      .map((line) => JSON.parse(line));
    expect(changes).toHaveLength(2);
    expect(changes[1].changes[0]).toMatchObject({
      path: "postcode",
      before: "6798",
      after: "9999",
      expected: false,
    });
  });
  it("finds same-count PID substitution, missing versus null and array-order differences", () => {
    const one = doc("GAOT_1"),
      two = doc("GAOT_2");
    const report = JSON.parse(compare([one, two], [two, doc("GAOT_3")]).stdout);
    expect(report).toMatchObject({ added: 1, removed: 1, unchanged: 1, unexpectedChanges: 2 });
    const changed = JSON.parse(
      compare(
        [one],
        [
          {
            ...one,
            fallbackGeocode: null,
            allGeocodes: [
              { lat: 1, lng: 2 },
              { lat: 3, lng: 4 },
            ],
          },
        ],
      ).stdout,
    );
    expect(changed.fields).toHaveProperty("fallbackGeocode");
    const array = JSON.parse(
      compare([{ ...one, allGeocodes: [1, 2] }], [{ ...one, allGeocodes: [2, 1] }]).stdout,
    );
    expect(array.unexpectedChanges).toBe(1);
  });
  it.each([
    [doc("GAOT_2"), doc("GAOT_1")],
    [doc("GAOT_1"), doc("GAOT_1")],
  ])("rejects an unordered or duplicate baseline", (...rows) => {
    const result = compare(rows, [doc("GAOT_1")]);
    expect(result.status).not.toBe(0);
    expect(result.stderr).toContain("Duplicate or unordered PID");
  });
  it("keeps diagnostics bounded while preserving all 100 changes in compressed evidence", () => {
    const before = Array.from({ length: 100 }, (_, i) => doc("GAOT_" + String(i).padStart(4, "0")));
    const result = JSON.parse(
      compare(
        before,
        before.map((d) => ({ ...d, postcode: "9999" })),
      ).stdout,
    );
    expect(result.unexpectedChanges).toBe(100);
    expect(result.samples).toHaveLength(20);
    expect(
      gunzipSync(readFileSync(join(root, "changes.gz")))
        .toString()
        .trim()
        .split("\n"),
    ).toHaveLength(100);
  });
  it("selects the nearest earlier release from the same quarter and refuses a patch without a baseline", () => {
    const result = spawnSync(
      "python3",
      [
        "-c",
        `import sys,json\nsys.path.insert(0,sys.argv[1])\nfrom compare_release_files import choose_prior\nreleases=[{'tagName':t} for t in ['v2026.08','v2026.11','v2026.08.2','v2026.08.1']]\nassert choose_prior(releases,'2026.08.3')=='v2026.08.2'\ntry: choose_prior([], '2026.08.1')\nexcept ValueError: pass\nelse: raise AssertionError('missing baseline accepted')`,
        resolve("scripts"),
      ],
      { encoding: "utf8" },
    );
    expect(result.status, result.stderr).toBe(0);
  });
});
