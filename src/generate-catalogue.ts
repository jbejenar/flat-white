/**
 * flat-white — GitHub Pages catalogue generator.
 *
 * Fetches release data from the GitHub API and generates a self-contained
 * static HTML page with release history, per-state stats, schema docs,
 * and download links.
 *
 * Usage:
 *   node dist/generate-catalogue.js --repo owner/repo --out dist/catalogue/index.html
 *
 * Environment:
 *   GITHUB_TOKEN — optional, increases API rate limit
 */

import { writeFileSync, mkdirSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

// --- Types ---

interface ReleaseAsset {
  name: string;
  browser_download_url: string;
  size: number;
}

export interface GitHubRelease {
  tag_name: string;
  name: string;
  published_at: string;
  html_url: string;
  body: string;
  assets: ReleaseAsset[];
}

interface StateCount {
  state: string;
  count: number;
}

interface ReleaseData {
  version: string;
  date: string;
  url: string;
  totalCount: number;
  states: StateCount[];
  schemaVersion: string;
  assets: { name: string; url: string; sizeMB: string }[];
}

// --- CLI ---

interface CatalogueOptions {
  repo: string;
  outPath: string;
}

export function parseArgs(argv: string[]): CatalogueOptions {
  let repo = "";
  let outPath = "dist/catalogue/index.html";

  for (let i = 2; i < argv.length; i++) {
    if (argv[i] === "--repo" && argv[i + 1]) {
      repo = argv[++i];
    } else if (argv[i] === "--out" && argv[i + 1]) {
      outPath = argv[++i];
    }
  }

  if (!repo) {
    throw new Error("--repo owner/repo is required");
  }

  return { repo, outPath };
}

// --- GitHub API ---

async function fetchReleases(repo: string): Promise<GitHubRelease[]> {
  const token = process.env.GITHUB_TOKEN ?? "";
  const headers: Record<string, string> = {
    Accept: "application/vnd.github+json",
    "User-Agent": "flat-white-catalogue",
  };
  if (token) {
    headers.Authorization = `Bearer ${token}`;
  }

  const url = `https://api.github.com/repos/${repo}/releases?per_page=20`;
  const res = await fetch(url, { headers });
  if (!res.ok) {
    throw new Error(`GitHub API error: ${res.status} ${res.statusText}`);
  }
  return (await res.json()) as GitHubRelease[];
}

function parseMetadataFromAssets(
  release: GitHubRelease,
): { totalCount: number; states: StateCount[]; schemaVersion: string } | null {
  // Try to find metadata.json in release assets — we can't download it via
  // browser_download_url without auth, so we parse from release body instead.
  const body = release.body ?? "";

  // Extract total count from release notes (format: "**15,015,573** addresses")
  const totalMatch = body.match(/\*\*([0-9,]+)\*\*\s+addresses/);
  const totalCount = totalMatch ? Number(totalMatch[1].replace(/,/g, "")) : 0;

  // Extract per-state counts from table (format: "| VIC | 3,456,789 |")
  const states: StateCount[] = [];
  const statePattern = /\|\s*(VIC|NSW|QLD|SA|WA|TAS|NT|ACT|OT)\s*\|\s*([0-9,]+)\s*\|/g;
  let match;
  while ((match = statePattern.exec(body)) !== null) {
    states.push({ state: match[1], count: Number(match[2].replace(/,/g, "")) });
  }

  // Extract schema version
  const schemaMatch = body.match(/Schema:\s*v?([0-9.]+)/i);
  const schemaVersion = schemaMatch ? schemaMatch[1] : "unknown";

  return { totalCount, states, schemaVersion };
}

export function processReleases(releases: GitHubRelease[]): ReleaseData[] {
  return releases
    .filter((r) => r.tag_name.startsWith("v"))
    .map((r) => {
      const metadata = parseMetadataFromAssets(r);
      const dataAssets = r.assets
        .filter((a) => a.name.endsWith(".ndjson.gz") || a.name === "metadata.json")
        .map((a) => ({
          name: a.name,
          url: a.browser_download_url,
          sizeMB: (a.size / 1_048_576).toFixed(1),
        }));

      return {
        version: r.tag_name,
        date: r.published_at.split("T")[0],
        url: r.html_url,
        totalCount: metadata?.totalCount ?? 0,
        states: metadata?.states ?? [],
        schemaVersion: metadata?.schemaVersion ?? "unknown",
        assets: dataAssets,
      };
    });
}

// --- HTML Generation ---

export function esc(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function formatNumber(n: number): string {
  return n.toLocaleString("en-AU");
}

export function generateHTML(repo: string, releases: ReleaseData[]): string {
  const [owner, repoName] = repo.split("/");
  const repoUrl = `https://github.com/${repo}`;
  const now = new Date().toISOString().split("T")[0];

  const releasesHTML = releases
    .map(
      (r) => `
      <section class="release">
        <h2><a href="${esc(r.url)}">${esc(r.version)}</a></h2>
        <p class="meta">Released ${esc(r.date)} &middot; ${esc(formatNumber(r.totalCount))} addresses &middot; Schema ${esc(r.schemaVersion)}</p>
        ${
          r.states.length > 0
            ? `<table class="states">
          <thead><tr><th>State</th><th>Addresses</th></tr></thead>
          <tbody>${r.states.map((s) => `<tr><td>${esc(s.state)}</td><td>${esc(formatNumber(s.count))}</td></tr>`).join("")}</tbody>
        </table>`
            : ""
        }
        ${
          r.assets.length > 0
            ? `<details>
          <summary>Downloads (${r.assets.length} files)</summary>
          <ul class="downloads">${r.assets.map((a) => `<li><a href="${esc(a.url)}">${esc(a.name)}</a> <span class="size">(${esc(a.sizeMB)} MB)</span></li>`).join("")}</ul>
        </details>`
            : ""
        }
      </section>`,
    )
    .join("\n");

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>flat-white — Australian Address Data</title>
  <style>
    :root {
      --bg: #fafaf9;
      --fg: #1c1917;
      --muted: #78716c;
      --border: #d6d3d1;
      --accent: #b45309;
      --card-bg: #ffffff;
    }
    @media (prefers-color-scheme: dark) {
      :root {
        --bg: #1c1917;
        --fg: #fafaf9;
        --muted: #a8a29e;
        --border: #44403c;
        --accent: #f59e0b;
        --card-bg: #292524;
      }
    }
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      background: var(--bg);
      color: var(--fg);
      line-height: 1.6;
      max-width: 800px;
      margin: 0 auto;
      padding: 2rem 1rem;
    }
    header { margin-bottom: 2rem; border-bottom: 1px solid var(--border); padding-bottom: 1rem; }
    header h1 { font-size: 1.75rem; font-weight: 700; }
    header p { color: var(--muted); margin-top: 0.25rem; }
    nav { margin-top: 0.75rem; display: flex; gap: 1rem; flex-wrap: wrap; }
    nav a { color: var(--accent); text-decoration: none; font-size: 0.9rem; }
    nav a:hover { text-decoration: underline; }
    .release {
      background: var(--card-bg);
      border: 1px solid var(--border);
      border-radius: 0.5rem;
      padding: 1.25rem;
      margin-bottom: 1rem;
    }
    .release h2 { font-size: 1.25rem; }
    .release h2 a { color: var(--accent); text-decoration: none; }
    .release h2 a:hover { text-decoration: underline; }
    .meta { color: var(--muted); font-size: 0.875rem; margin-top: 0.25rem; }
    .states { width: 100%; border-collapse: collapse; margin: 0.75rem 0; font-size: 0.875rem; }
    .states th, .states td { text-align: left; padding: 0.375rem 0.75rem; border-bottom: 1px solid var(--border); }
    .states th { font-weight: 600; color: var(--muted); }
    .states td:last-child { text-align: right; font-variant-numeric: tabular-nums; }
    details { margin-top: 0.75rem; }
    summary { cursor: pointer; color: var(--accent); font-size: 0.875rem; }
    .downloads { list-style: none; margin-top: 0.5rem; }
    .downloads li { padding: 0.25rem 0; font-size: 0.875rem; }
    .downloads a { color: var(--accent); text-decoration: none; }
    .downloads a:hover { text-decoration: underline; }
    .size { color: var(--muted); font-size: 0.8rem; }
    .schema { margin-top: 2rem; border-top: 1px solid var(--border); padding-top: 1rem; }
    .schema h2 { font-size: 1.25rem; margin-bottom: 0.5rem; }
    .schema-link { color: var(--accent); text-decoration: none; }
    .schema-link:hover { text-decoration: underline; }
    footer { margin-top: 2rem; padding-top: 1rem; border-top: 1px solid var(--border); color: var(--muted); font-size: 0.8rem; }
    .empty { text-align: center; padding: 3rem 1rem; color: var(--muted); }
  </style>
</head>
<body>
  <header>
    <h1>flat-white</h1>
    <p>Australian addresses. Flattened and served.</p>
    <nav>
      <a href="${esc(repoUrl)}">GitHub</a>
      <a href="${esc(repoUrl)}/blob/main/docs/DOCUMENT-SCHEMA.md">Schema Reference</a>
      <a href="${esc(repoUrl)}/blob/main/CHANGELOG.md">Changelog</a>
      <a href="${esc(repoUrl)}/releases">All Releases</a>
    </nav>
  </header>

  <main>
    <h2 style="margin-bottom: 1rem;">Releases</h2>
    ${releases.length > 0 ? releasesHTML : '<p class="empty">No releases yet.</p>'}
  </main>

  <section class="schema">
    <h2>Document Schema</h2>
    <p>Each NDJSON line is one address document. See the full <a class="schema-link" href="${esc(repoUrl)}/blob/main/docs/DOCUMENT-SCHEMA.md">schema reference</a>.</p>
    <p style="margin-top: 0.5rem; font-size: 0.875rem; color: var(--muted);">
      Output formats: NDJSON (.ndjson.gz), Parquet (--format parquet), Geoparquet (--format geoparquet)
    </p>
  </section>

  <footer>
    <p>Generated ${esc(now)} from <a href="${esc(repoUrl)}" style="color: var(--accent);">${esc(owner)}/${esc(repoName)}</a>. Data sourced from the <a href="https://data.gov.au/dataset/geocoded-national-address-file-g-naf" style="color: var(--accent);">G-NAF</a> under Creative Commons Attribution 4.0.</p>
  </footer>
</body>
</html>`;
}

// --- Main ---

async function main(): Promise<void> {
  const opts = parseArgs(process.argv);

  console.log(`Fetching releases for ${opts.repo}...`);
  const ghReleases = await fetchReleases(opts.repo);
  console.log(`Found ${ghReleases.length} releases`);

  const releases = processReleases(ghReleases);

  const html = generateHTML(opts.repo, releases);

  mkdirSync(dirname(opts.outPath), { recursive: true });
  writeFileSync(opts.outPath, html, "utf-8");
  console.log(`Catalogue written to ${opts.outPath}`);
}

// Only run when invoked directly (not when imported by tests)
if (process.argv[1] && resolve(fileURLToPath(import.meta.url)) === resolve(process.argv[1])) {
  main().catch((err: unknown) => {
    console.error("Failed to generate catalogue:", err);
    process.exit(1);
  });
}
