#!/usr/bin/env node

import { spawnSync } from "node:child_process";
import { appendFileSync, existsSync } from "node:fs";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";

const UPSTREAM = "minus34/gnaf-loader";

function git(cwd, args, allowedStatuses = [0]) {
  const result = spawnSync("git", args, { cwd, encoding: "utf8" });
  if (result.error) throw result.error;
  if (!allowedStatuses.includes(result.status)) {
    throw new Error(`git ${args.join(" ")} failed: ${result.stderr.trim()}`);
  }
  return { status: result.status, stdout: result.stdout.trim() };
}

export async function discoverLatestTag({ fetchImpl = fetch } = {}) {
  const headers = { Accept: "application/vnd.github+json", "X-GitHub-Api-Version": "2022-11-28" };
  if (process.env.GH_TOKEN) headers.Authorization = `Bearer ${process.env.GH_TOKEN}`;

  async function request(path) {
    return fetchImpl(`https://api.github.com/repos/${UPSTREAM}/${path}`, {
      headers,
      signal: AbortSignal.timeout(30_000),
    });
  }

  function requireSuccess(response, path) {
    if (!response.ok) throw new Error(`GitHub ${path} failed: HTTP ${response.status}`);
  }

  const release = await request("releases/latest");
  let tag;
  if (release.status === 404) {
    // Only a missing release justifies falling back. Rate limits, outages,
    // and authentication failures must fail the check rather than look current.
    await release.text();
    const response = await request("tags?per_page=1");
    requireSuccess(response, "tags");
    const tags = await response.json();
    if (!Array.isArray(tags)) throw new Error("GitHub tags response is not an array");
    if (tags.length === 0) return null;
    tag = tags[0]?.name;
  } else {
    requireSuccess(release, "releases/latest");
    tag = (await release.json())?.tag_name;
  }

  // The tag also becomes a branch name, workflow output, and PR title.
  if (typeof tag !== "string" || !/^[A-Za-z0-9][A-Za-z0-9._/-]*$/.test(tag)) {
    throw new Error("GitHub returned an invalid release tag");
  }
  return tag;
}

export async function checkUpdate({
  root = process.cwd(),
  upstreamUrl = `https://github.com/${UPSTREAM}.git`,
  fetchImpl = fetch,
} = {}) {
  const submodule = resolve(root, "gnaf-loader");
  if (!existsSync(resolve(submodule, ".git"))) throw new Error("Initialize gnaf-loader first");
  const currentSha = git(root, ["rev-parse", "HEAD:gnaf-loader"]).stdout;
  if (git(submodule, ["rev-parse", "HEAD"]).stdout !== currentSha) {
    throw new Error("gnaf-loader checkout does not match the committed submodule pin");
  }
  if (git(submodule, ["rev-parse", "--is-shallow-repository"]).stdout === "true") {
    throw new Error("Full submodule history is required to check ancestry; use fetch-depth: 0");
  }
  const currentDesc = git(submodule, ["describe", "--tags", "--always", currentSha]).stdout;
  const tag = await discoverLatestTag({ fetchImpl });
  const result = {
    current_sha: currentSha,
    current_desc: currentDesc,
    tag: tag ?? "",
    latest_sha: "",
    status: "no-release",
    needs_update: false,
  };
  if (tag === null) return result;

  git(root, ["check-ref-format", `refs/tags/${tag}`]);
  git(root, ["check-ref-format", `refs/heads/chore/gnaf-loader-${tag}`]);

  // origin can be a fork without upstream's tags. Fetch the exact upstream
  // ref without importing or trusting same-named local tags, then peel it.
  git(submodule, ["fetch", "--no-tags", upstreamUrl, `refs/tags/${tag}`]);
  const latestSha = git(submodule, ["rev-parse", "FETCH_HEAD^{commit}"]).stdout;
  result.latest_sha = latestSha;

  function isAncestor(ancestor, descendant) {
    return (
      git(submodule, ["merge-base", "--is-ancestor", ancestor, descendant], [0, 1]).status === 0
    );
  }

  if (currentSha === latestSha) {
    result.status = "current";
  } else if (isAncestor(latestSha, currentSha)) {
    result.status = "ahead";
  } else if (isAncestor(currentSha, latestSha)) {
    result.status = "update";
    result.needs_update = true;
  } else {
    throw new Error(
      `Upstream ${tag} (${latestSha}) diverges from the current pin (${currentSha}). ` +
        "Refusing to discard fork commits; reconcile them upstream before updating.",
    );
  }
  return result;
}

async function main() {
  const result = await checkUpdate();
  console.log(JSON.stringify(result, null, 2));
  if (process.env.GITHUB_OUTPUT) {
    appendFileSync(
      process.env.GITHUB_OUTPUT,
      Object.entries(result)
        .map(([key, value]) => `${key}=${value}\n`)
        .join(""),
    );
  }
  if (process.env.GITHUB_STEP_SUMMARY) {
    appendFileSync(
      process.env.GITHUB_STEP_SUMMARY,
      `### gnaf-loader update check\n\n` +
        `- Current pin: \`${result.current_desc}\` (\`${result.current_sha}\`)\n` +
        `- Upstream tag: \`${result.tag || "none"}\` (\`${result.latest_sha || "none"}\`)\n` +
        `- Result: **${result.status}**\n\n` +
        "Detection leaves the committed submodule pin and working tree unchanged. " +
        "Only a later publishing step can prepare an update PR.\n",
    );
  }
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main().catch((error) => {
    console.error(error instanceof Error ? error.message : String(error));
    process.exitCode = 1;
  });
}
