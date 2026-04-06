/**
 * Unit tests for generate-catalogue.ts — catalogue generation logic.
 */

import { describe, it, expect } from "vitest";
import {
  parseArgs,
  processReleases,
  generateHTML,
  type GitHubRelease,
} from "../../src/generate-catalogue.js";

function makeRelease(overrides: Partial<GitHubRelease> = {}): GitHubRelease {
  return {
    tag_name: "v2026.04",
    name: "v2026.04",
    published_at: "2026-04-15T02:00:00Z",
    html_url: "https://github.com/jbejenar/flat-white/releases/tag/v2026.04",
    body: "**15,015,573** addresses\n\n| State | Count |\n|---|---|\n| VIC | 3,456,789 |\n| NSW | 4,500,000 |\n\nSchema: v0.1.0",
    assets: [
      {
        name: "flat-white-2026.04-vic.ndjson.gz",
        browser_download_url: "https://example.com/vic.ndjson.gz",
        size: 104_857_600,
      },
      {
        name: "metadata.json",
        browser_download_url: "https://example.com/metadata.json",
        size: 512,
      },
    ],
    ...overrides,
  };
}

describe("parseArgs", () => {
  it("parses --repo and --out", () => {
    const opts = parseArgs(["node", "script", "--repo", "owner/repo", "--out", "out.html"]);
    expect(opts.repo).toBe("owner/repo");
    expect(opts.outPath).toBe("out.html");
  });

  it("defaults --out to dist/catalogue/index.html", () => {
    const opts = parseArgs(["node", "script", "--repo", "owner/repo"]);
    expect(opts.outPath).toBe("dist/catalogue/index.html");
  });

  it("throws when --repo is missing", () => {
    expect(() => parseArgs(["node", "script"])).toThrow("--repo");
  });
});

describe("processReleases", () => {
  it("extracts version, date, and total count from release notes", () => {
    const releases = processReleases([makeRelease()]);
    expect(releases).toHaveLength(1);
    expect(releases[0].version).toBe("v2026.04");
    expect(releases[0].date).toBe("2026-04-15");
    expect(releases[0].totalCount).toBe(15_015_573);
  });

  it("extracts per-state counts from markdown table", () => {
    const releases = processReleases([makeRelease()]);
    expect(releases[0].states).toEqual([
      { state: "VIC", count: 3_456_789 },
      { state: "NSW", count: 4_500_000 },
    ]);
  });

  it("extracts schema version", () => {
    const releases = processReleases([makeRelease()]);
    expect(releases[0].schemaVersion).toBe("0.1.0");
  });

  it("filters out non-v-prefixed tags", () => {
    const releases = processReleases([
      makeRelease({ tag_name: "v2026.04" }),
      makeRelease({ tag_name: "nightly-2026-04-01" }),
    ]);
    expect(releases).toHaveLength(1);
  });

  it("collects download assets", () => {
    const releases = processReleases([makeRelease()]);
    expect(releases[0].assets).toHaveLength(2);
    expect(releases[0].assets[0].name).toBe("flat-white-2026.04-vic.ndjson.gz");
    expect(releases[0].assets[0].sizeMB).toBe("100.0");
  });

  it("handles release with no body gracefully", () => {
    const releases = processReleases([makeRelease({ body: "" })]);
    expect(releases[0].totalCount).toBe(0);
    expect(releases[0].states).toEqual([]);
  });
});

describe("generateHTML", () => {
  it("produces valid HTML with release data", () => {
    const releases = processReleases([makeRelease()]);
    const html = generateHTML("jbejenar/flat-white", releases);

    expect(html).toContain("<!DOCTYPE html>");
    expect(html).toContain("flat-white");
    expect(html).toContain("v2026.04");
    expect(html).toContain("github.com/jbejenar/flat-white");
  });

  it("includes download links", () => {
    const releases = processReleases([makeRelease()]);
    const html = generateHTML("jbejenar/flat-white", releases);

    expect(html).toContain("flat-white-2026.04-vic.ndjson.gz");
    expect(html).toContain("100.0 MB");
  });

  it("shows empty state when no releases", () => {
    const html = generateHTML("jbejenar/flat-white", []);
    expect(html).toContain("No releases yet.");
  });

  it("includes schema reference link", () => {
    const releases = processReleases([makeRelease()]);
    const html = generateHTML("jbejenar/flat-white", releases);
    expect(html).toContain("DOCUMENT-SCHEMA.md");
  });

  it("includes dark mode CSS", () => {
    const html = generateHTML("jbejenar/flat-white", []);
    expect(html).toContain("prefers-color-scheme: dark");
  });
});
