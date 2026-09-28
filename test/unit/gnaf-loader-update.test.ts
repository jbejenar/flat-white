import { execFileSync } from "node:child_process";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import { checkUpdate, discoverLatestTag } from "../../scripts/check-gnaf-loader-update.mjs";

function response(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status });
}

describe("gnaf-loader release discovery", () => {
  it("uses the latest published release", async () => {
    const fetchImpl = vi.fn().mockResolvedValue(response({ tag_name: "202608" }));
    expect(await discoverLatestTag({ fetchImpl })).toBe("202608");
    expect(fetchImpl).toHaveBeenCalledTimes(1);
    expect(fetchImpl.mock.calls[0][0]).toBe(
      "https://api.github.com/repos/minus34/gnaf-loader/releases/latest",
    );
  });

  it("falls back to a tag only when the latest release returns 404", async () => {
    const fetchImpl = vi
      .fn()
      .mockResolvedValueOnce(response({ message: "Not Found" }, 404))
      .mockResolvedValueOnce(response([{ name: "202608" }]));
    expect(await discoverLatestTag({ fetchImpl })).toBe("202608");
    expect(fetchImpl.mock.calls[1][0]).toBe(
      "https://api.github.com/repos/minus34/gnaf-loader/tags?per_page=1",
    );
  });

  it("reports no release when the repository has neither releases nor tags", async () => {
    const fetchImpl = vi
      .fn()
      .mockResolvedValueOnce(response({}, 404))
      .mockResolvedValueOnce(response([]));
    expect(await discoverLatestTag({ fetchImpl })).toBeNull();
  });

  it.each([401, 403, 429, 500])("does not hide HTTP %s as no update", async (status) => {
    const fetchImpl = vi.fn().mockResolvedValue(response({}, status));
    await expect(discoverLatestTag({ fetchImpl })).rejects.toThrow(`HTTP ${status}`);
    expect(fetchImpl).toHaveBeenCalledTimes(1);
  });

  it("does not hide a failure from the fallback tags endpoint", async () => {
    const fetchImpl = vi
      .fn()
      .mockResolvedValueOnce(response({}, 404))
      .mockResolvedValueOnce(response({}, 403));
    await expect(discoverLatestTag({ fetchImpl })).rejects.toThrow("GitHub tags failed: HTTP 403");
  });

  it("propagates network failures", async () => {
    const fetchImpl = vi.fn().mockRejectedValue(new Error("connection reset"));
    await expect(discoverLatestTag({ fetchImpl })).rejects.toThrow("connection reset");
  });

  it.each([
    null,
    {},
    { tag_name: "" },
    { tag_name: "202608\nneeds_update=true" },
    { tag_name: "$(id)" },
  ])("rejects a malformed or unsafe release response: %j", async (body) => {
    const fetchImpl = vi.fn().mockResolvedValue(response(body));
    await expect(discoverLatestTag({ fetchImpl })).rejects.toThrow("invalid release tag");
  });

  it("rejects a malformed tag-list response", async () => {
    const fetchImpl = vi
      .fn()
      .mockResolvedValueOnce(response({}, 404))
      .mockResolvedValueOnce(response({ message: "unexpected shape" }));
    await expect(discoverLatestTag({ fetchImpl })).rejects.toThrow("not an array");
  });
});

// Real Git repositories reproduce the fork/tag/history failures. No network,
// live gnaf-loader checkout, or G-NAF download is involved.
describe("gnaf-loader update ancestry", () => {
  let directory: string;
  let upstream: string;
  let fork: string;
  let root: string;
  let submodule: string;
  let originalSha: string;

  function git(cwd: string, ...args: string[]): string {
    return execFileSync(
      "git",
      [
        "-c",
        "user.name=Fixture",
        "-c",
        "user.email=fixture@example.test",
        "-c",
        "commit.gpgsign=false",
        "-c",
        "core.hooksPath=/dev/null",
        ...args,
      ],
      { cwd, encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] },
    ).trim();
  }

  function commit(cwd: string, message: string): string {
    git(cwd, "commit", "--allow-empty", "-m", message);
    return git(cwd, "rev-parse", "HEAD");
  }

  function check(tag = "202608") {
    return checkUpdate({
      root,
      upstreamUrl: upstream,
      fetchImpl: vi.fn().mockResolvedValue(response({ tag_name: tag })),
    });
  }

  function assertPinUnchanged() {
    expect(git(root, "status", "--porcelain")).toBe("");
    expect(git(root, "rev-parse", "HEAD:gnaf-loader")).toBe(originalSha);
    expect(git(submodule, "rev-parse", "HEAD")).toBe(originalSha);
    expect(git(submodule, "remote", "get-url", "origin")).toBe(fork);
  }

  beforeEach(() => {
    directory = mkdtempSync(join(tmpdir(), "flat-white-loader-check-"));
    upstream = join(directory, "upstream");
    fork = join(directory, "fork");
    root = join(directory, "flat-white");
    submodule = join(root, "gnaf-loader");
    git(directory, "init", "--initial-branch=main", upstream);
    originalSha = commit(upstream, "base release");
    git(upstream, "tag", "202602");
    git(directory, "clone", upstream, fork);
    git(directory, "init", "--initial-branch=main", root);
    git(root, "-c", "protocol.file.allow=always", "submodule", "add", fork, "gnaf-loader");
    commit(root, "pin loader");
  });

  afterEach(() => rmSync(directory, { recursive: true, force: true }));

  it.each(["lightweight", "annotated"])(
    "finds an upstream %s tag absent from the configured fork, without moving the pin",
    async (kind) => {
      const expected = commit(upstream, "new release");
      if (kind === "annotated") git(upstream, "tag", "-a", "202608", "-m", "release");
      else git(upstream, "tag", "202608");
      expect(git(fork, "tag", "--list", "202608")).toBe("");
      const before = readFileSync(join(root, ".gitmodules"), "utf8");

      expect(await check()).toMatchObject({
        status: "update",
        needs_update: true,
        current_sha: originalSha,
        tag: "202608",
        latest_sha: expected,
      });
      assertPinUnchanged();
      expect(readFileSync(join(root, ".gitmodules"), "utf8")).toBe(before);
    },
  );

  it("ignores a conflicting local tag and preserves it", async () => {
    git(submodule, "tag", "202608");
    const latest = commit(upstream, "new release");
    git(upstream, "tag", "202608");
    expect(await check()).toMatchObject({ needs_update: true, latest_sha: latest });
    expect(git(submodule, "rev-parse", "202608")).toBe(originalSha);
    assertPinUnchanged();
  });

  it("does not create an update when the release is already pinned", async () => {
    expect(await check("202602")).toMatchObject({ status: "current", needs_update: false });
    assertPinUnchanged();
  });

  it("does not downgrade a fork commit to an older upstream release (PR #140 regression)", async () => {
    originalSha = commit(submodule, "fork fix");
    git(root, "add", "gnaf-loader");
    commit(root, "pin fork fix");
    expect(await check("202602")).toMatchObject({ status: "ahead", needs_update: false });
    assertPinUnchanged();
  });

  it("refuses a divergent upstream release that would discard an unmerged fork fix", async () => {
    originalSha = commit(submodule, "unmerged fork fix");
    git(root, "add", "gnaf-loader");
    commit(root, "pin fork fix");
    commit(upstream, "independent upstream changes");
    git(upstream, "tag", "202608");
    await expect(check()).rejects.toThrow("Refusing to discard fork commits");
    assertPinUnchanged();
  });

  it("accepts a release after upstream merges the pinned fork fix", async () => {
    originalSha = commit(submodule, "fork fix");
    git(root, "add", "gnaf-loader");
    commit(root, "pin fork fix");
    commit(upstream, "upstream work");
    git(upstream, "fetch", submodule, "HEAD");
    git(upstream, "merge", "--no-ff", "FETCH_HEAD", "-m", "merge fork fix");
    const latest = commit(upstream, "new release");
    git(upstream, "tag", "202608");

    expect(await check()).toMatchObject({ needs_update: true, latest_sha: latest });
    assertPinUnchanged();
  });

  it("fails when release metadata names a missing Git tag", async () => {
    await expect(check()).rejects.toThrow("couldn't find remote ref refs/tags/202608");
    assertPinUnchanged();
  });

  it("rejects invalid Git references before fetching", async () => {
    await expect(check("release..202608")).rejects.toThrow("check-ref-format");
    assertPinUnchanged();
  });

  it("rejects an uncommitted submodule checkout", async () => {
    commit(submodule, "uncommitted pin change");
    await expect(check()).rejects.toThrow("does not match the committed submodule pin");
  });

  it("rejects shallow history instead of guessing ancestry", async () => {
    const shallowFile = resolve(submodule, git(submodule, "rev-parse", "--git-path", "shallow"));
    writeFileSync(shallowFile, `${originalSha}\n`);
    await expect(check()).rejects.toThrow("Full submodule history is required");
  });
});
