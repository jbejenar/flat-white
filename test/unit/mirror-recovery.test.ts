import { spawnSync } from "node:child_process";
import { createHash } from "node:crypto";
import {
  copyFileSync,
  existsSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { gunzipSync, gzipSync } from "node:zlib";
import { afterEach, beforeEach, describe, expect, it } from "vitest";

const states = ["ACT", "NSW", "NT", "OT", "QLD", "SA", "TAS", "VIC", "WA"];
const commit = "a".repeat(40);
const prefix = "repos/owner/repo";
const sha = (data: string | Buffer) => createHash("sha256").update(data).digest("hex");

describe("published-release mirror recovery", () => {
  let root: string;
  let responses: Record<string, unknown>;
  let metadata: Record<string, unknown>;
  let release: {
    id: number;
    tag_name: string;
    draft: boolean;
    prerelease: boolean;
    assets: Array<{ id: number; name: string; size: number; digest: string; state: string }>;
  };

  beforeEach(() => {
    root = mkdtempSync(join(tmpdir(), "flat-white-mirror-"));
    mkdirSync(join(root, "bin"));
    mkdirSync(join(root, "public"));
    writeFileSync(
      join(root, "bin/gh"),
      `#!/usr/bin/env python3
import json, os, shutil, sys
from pathlib import Path
root = Path(os.environ['MIRROR_TEST_ROOT'])
args = sys.argv[1:]
with (root / 'calls').open('a') as log: log.write(json.dumps(args) + '\\n')
if args[:3] == ['api', '--method', 'GET']:
    value = json.loads((root / 'responses.json').read_text())[args[3]]
    if (root / 'make-draft-after-download').exists() and (root / 'downloaded').exists() and '/releases/tags/' in args[3]:
        value['draft'] = True
    if isinstance(value, dict) and 'raw' in value: sys.stdout.write(value['raw'])
    else: print(json.dumps(value))
elif args[:2] == ['release', 'download']:
    name = args[args.index('--pattern') + 1]
    target = Path(args[args.index('--dir') + 1]) / name
    shutil.copyfile(root / 'public' / name, target)
    if (root / 'corrupt-download').exists():
        with target.open('ab') as output: output.write(b'corruption')
    (root / 'downloaded').touch()
else:
    raise SystemExit('Unexpected command: ' + repr(args))
`,
      { mode: 0o755 },
    );
    fixture("v2026.08.1");
  });
  afterEach(() => rmSync(root, { recursive: true, force: true }));

  function fixture(tag: string) {
    metadata = {
      version: tag.slice(1),
      gnafVersion: "2026.08",
      adminBoundariesVersion: "2026.08",
      schemaVersion: "1.0.0",
      asgsYear: 2026,
      states: Object.fromEntries(states.map((state) => [state, 1])),
      totalCount: 9,
    };
    release = { id: 123, tag_name: tag, draft: false, prerelease: false, assets: [] };
    function add(name: string, data: string | Buffer) {
      release.assets.push({
        id: release.assets.length + 1,
        name,
        size: Buffer.byteLength(data),
        digest: `sha256:${sha(data)}`,
        state: "uploaded",
      });
      writeFileSync(join(root, "public", name), data);
    }
    add("metadata.json", JSON.stringify(metadata));
    add("verification-report.md", "All states passed");
    for (const state of states)
      add(
        `flat-white-${tag.slice(1)}-${state.toLowerCase()}.ndjson.gz`,
        gzipSync(JSON.stringify({ state }) + "\n"),
      );
    const content = (value: unknown) => ({
      encoding: "base64",
      content: Buffer.from(JSON.stringify(value)).toString("base64"),
    });
    responses = {
      [`${prefix}/releases/tags/${tag}`]: release,
      [`${prefix}/git/ref/tags/${tag}`]: { object: { type: "commit", sha: commit } },
      [`${prefix}/releases/assets/1`]: { raw: JSON.stringify(metadata) },
      [`${prefix}/contents/package.json?ref=${commit}`]: content({ version: "1.0.0" }),
      [`${prefix}/contents/opensearch/address-mappings.json?ref=${commit}`]: content({
        _meta: { schemaVersion: "1.0.0", asgsYear: 2026 },
        properties: {},
      }),
    };
  }

  function save() {
    writeFileSync(join(root, "responses.json"), JSON.stringify(responses));
  }
  function updateMetadata() {
    const text = JSON.stringify(metadata);
    responses[`${prefix}/releases/assets/1`] = { raw: text };
    release.assets[0].digest = `sha256:${sha(text)}`;
    release.assets[0].size = Buffer.byteLength(text);
  }
  function run(args: string[]) {
    save();
    return spawnSync("python3", [resolve("scripts/prepare-mirror-recovery.py"), ...args], {
      cwd: root,
      encoding: "utf8",
      env: {
        ...process.env,
        PATH: `${join(root, "bin")}:${process.env.PATH}`,
        MIRROR_TEST_ROOT: root,
      },
    });
  }
  function plan(tag = release.tag_name) {
    return run([
      "resolve",
      "--repository=owner/repo",
      `--tag=${tag}`,
      `--plan=${join(root, "plan.json")}`,
    ]);
  }
  function prepare() {
    return run([
      "prepare",
      `--plan=${join(root, "plan.json")}`,
      `--artifacts=${join(root, "artifacts")}`,
      `--mappings-output=${join(root, "source/mappings.json")}`,
    ]);
  }

  it.each(["v2026.08", "v2026.08.1"])(
    "recovers %s from public files without retained run artifacts",
    (tag) => {
      fixture(tag);
      expect(plan().status).toBe(0);
      const result = prepare();
      expect(result.status, result.stderr).toBe(0);
      const all = readFileSync(
        join(root, `artifacts/flat-white-all/flat-white-${tag.slice(1)}-all.ndjson.gz`),
      );
      expect(gunzipSync(all).toString()).toBe(
        states.map((state) => JSON.stringify({ state }) + "\n").join(""),
      );
      for (const state of states)
        expect(
          readFileSync(join(root, `artifacts/flat-white-${state}/${state}.count`), "utf8"),
        ).toBe("1\n");
      const calls = readFileSync(join(root, "calls"), "utf8");
      expect(calls).not.toContain("actions/runs");
      expect(calls).not.toMatch(/"(?:create|edit|delete|POST|PATCH)"/);
      expect(JSON.parse(readFileSync(join(root, "source/mappings.json"), "utf8"))).toMatchObject({
        _meta: { schemaVersion: "1.0.0", asgsYear: 2026 },
      });
    },
  );

  // Execute the actual publisher shell steps on Linux (GNU stat/date and bash).
  // The fake AWS CLI stores objects locally and rejects unsupported commands.
  it.skipIf(process.platform !== "linux").each(["publish", "existing", "denied"])(
    "runs the shared mirror publisher safely: %s",
    (mode) => {
      expect(plan().status).toBe(0);
      const prepared = prepare();
      expect(prepared.status, prepared.stderr).toBe(0);
      mkdirSync(join(root, "scripts"));
      for (const name of ["check-s3-mirror.py", "mirror_utils.py"])
        copyFileSync(resolve("scripts", name), join(root, "scripts", name));
      writeFileSync(
        join(root, "bin/aws"),
        `#!/usr/bin/env python3
import base64, hashlib, json, os, shutil, sys
from pathlib import Path
root = Path(os.environ['MIRROR_TEST_ROOT'])
store = root / 's3'
args = sys.argv[1:]
with (root / 'aws-calls').open('a') as log: log.write(json.dumps(args) + '\\n')
def value(flag): return args[args.index(flag) + 1]
def error(code):
    print('An error occurred (' + code + ') when calling the HeadObject operation: blocked', file=sys.stderr)
    raise SystemExit(255)
if args[:2] == ['s3api', 'head-object']:
    if os.environ['MIRROR_AWS_TEST'] == 'denied': error('403')
    path = store / value('--key')
    if not path.exists(): error('404')
    data = path.read_bytes()
    print(json.dumps({'ContentLength': len(data), 'ChecksumSHA256': base64.b64encode(hashlib.sha256(data).digest()).decode(), 'ChecksumType': 'FULL_OBJECT'}))
elif args[:2] == ['s3api', 'put-object']:
    target = store / value('--key')
    if '--if-none-match' in args and target.exists(): error('412')
    data = Path(value('--body')).read_bytes()
    if '--checksum-sha256' in args:
        assert base64.b64encode(hashlib.sha256(data).digest()).decode() == value('--checksum-sha256')
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(data)
elif args[:2] == ['s3api', 'copy-object']:
    target = store / value('--key')
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(store / value('--copy-source').split('/', 1)[1], target)
elif args[:2] == ['s3', 'rm']:
    shutil.rmtree(store / args[2].split('s3://bucket/', 1)[1])
elif args[:2] != ['s3', 'ls']:
    raise SystemExit('Unexpected AWS command: ' + repr(args))
`,
        { mode: 0o755 },
      );
      const manifestPath = join(root, "s3/manifests/address-2026-08-1.json");
      if (mode === "existing") {
        mkdirSync(join(root, "s3/manifests"), { recursive: true });
        writeFileSync(manifestPath, "existing immutable manifest");
      }
      const workflow = readFileSync(".github/workflows/quarterly-build.yml", "utf8").split(
        "  s3-upload:\n",
      )[1];
      const names = [
        "Check for existing manifest (reject same-version republish)",
        "Upload data files + collect manifest metadata",
        "Generate manifest (local only — not uploaded yet)",
        "Validate manifest contract",
        "Verify staged data files (pre-promote gate)",
        "Promote staging to published prefix",
        "Verify published data files (pre-manifest gate)",
        "Upload manifest (final publish step)",
      ];
      const outputs: Record<string, string> = {};
      let status = 0;
      for (const [index, name] of names.entries()) {
        const block = workflow.split(`      - name: ${name}\n`)[1]?.split("\n      - name:")[0];
        if (!block) throw new Error(`Missing publisher step: ${name}`);
        if (index > 0) expect(block).toContain("if: steps.check_existing.outputs.skip != 'true'");
        if (outputs.skip === "true") break;
        const lines = block.split("        run: |\n")[1].split("\n");
        const body = [];
        for (const line of lines) {
          if (line && !line.startsWith("          ")) break;
          body.push(line.slice(10));
        }
        const values: Record<string, string> = {
          "needs.setup.outputs.release_version": "2026.08.1",
          "needs.setup.outputs.version": "2026.08",
          "github.repository": "owner/repo",
          "github.sha": "publisher-commit",
          "github.run_id": "42",
        };
        for (const [key, value] of Object.entries(outputs))
          values[`steps.upload_data.outputs.${key}`] = value;
        const script = body
          .join("\n")
          .replace(/\$\{\{\s*([^}]+?)\s*\}\}/g, (_, key: string) => {
            if (!(key in values)) throw new Error(`Unhandled workflow input: ${key}`);
            return values[key];
          })
          .replaceAll("/tmp/manifest", join(root, "manifest"));
        const result = spawnSync("bash", ["-e", "-o", "pipefail", "-c", script], {
          cwd: root,
          encoding: "utf8",
          env: {
            ...process.env,
            PATH: `${join(root, "bin")}:${process.env.PATH}`,
            MIRROR_TEST_ROOT: root,
            MIRROR_AWS_TEST: mode,
            S3_BUCKET: "bucket",
            MIRROR_SCHEMA_VERSION: "1.0.0",
            MAPPINGS_SOURCE: join(root, "source/mappings.json"),
            VERSION_DASH: outputs.version_dash ?? "",
            GITHUB_OUTPUT: join(root, "outputs"),
            LC_ALL: "C",
          },
        });
        status = result.status ?? 1;
        if (mode !== "denied") expect(status, `${name}: ${result.stderr}`).toBe(0);
        if (status !== 0) break;
        for (const line of readFileSync(join(root, "outputs"), "utf8").trim().split("\n")) {
          const [key, value] = line.split("=");
          outputs[key] = value;
        }
      }
      const calls: string[][] = readFileSync(join(root, "aws-calls"), "utf8")
        .trim()
        .split("\n")
        .map((line) => JSON.parse(line));
      const writes = calls.filter((args) => ["put-object", "copy-object", "rm"].includes(args[1]));
      if (mode === "publish") {
        expect(status).toBe(0);
        const manifest = JSON.parse(readFileSync(manifestPath, "utf8"));
        expect(manifest).toMatchObject({
          version: "2026-08-1",
          schema_version: "1.0.0",
          asgs_year: 2026,
          total_records: 9,
        });
        expect(manifest.files).toHaveLength(10);
        expect(writes.at(-1)).toContain("--if-none-match");
        expect(writes.at(-1)).toContain("manifests/address-2026-08-1.json");
        const national = readFileSync(join(root, "s3/data/address/2026-08-1/all.ndjson.gz"));
        expect(gunzipSync(national).toString().trim().split("\n")).toHaveLength(9);
      } else {
        expect(writes).toHaveLength(0);
        if (mode === "existing")
          expect(readFileSync(manifestPath, "utf8")).toBe("existing immutable manifest");
        if (mode === "denied") expect(status).toBe(1);
      }
    },
    20_000,
  );

  it("resolves an annotated tag to the original mapping commit", () => {
    const tagObject = "b".repeat(40);
    responses[`${prefix}/git/ref/tags/${release.tag_name}`] = {
      object: { type: "tag", sha: tagObject },
    };
    responses[`${prefix}/git/tags/${tagObject}`] = { object: { type: "commit", sha: commit } };
    expect(plan().stdout).toContain(`source_commit=${commit}`);
  });

  it.each(["draft", "prerelease"] as const)(
    "rejects a %s before downloading address data",
    (field) => {
      release[field] = true;
      expect(plan().status).toBe(1);
      expect(existsSync(join(root, "downloaded"))).toBe(false);
    },
  );

  it.each(["--help", "v2026.05", "v2026.13", "v2026.08.0", "v2026.08/../main"])(
    "rejects incompatible tag %s",
    (tag) => {
      expect(plan(tag).status).toBe(1);
      expect(existsSync(join(root, "calls"))).toBe(false);
    },
  );

  it.each([
    ["version", "2026.08.2"],
    ["gnafVersion", "2026.11"],
    ["asgsYear", 2021],
    ["totalCount", 10],
    ["schemaVersion", "1.1.0"],
  ])("rejects inconsistent metadata %s", (field, value) => {
    metadata[field as string] = value;
    updateMetadata();
    expect(plan().status).toBe(1);
  });

  it("rejects metadata whose published digest does not match", () => {
    responses[`${prefix}/releases/assets/1`] = { raw: "{}" };
    expect(plan().stderr).toContain("Metadata digest mismatch");
  });

  it.each(["missing", "duplicate", "no-digest"])("rejects %s state assets", (kind) => {
    if (kind === "missing") release.assets.pop();
    if (kind === "duplicate") release.assets.push(release.assets[2]);
    if (kind === "no-digest") release.assets[2].digest = "";
    expect(plan().status).toBe(1);
  });

  it("rejects corrupted downloads before preparing a mirror", () => {
    expect(plan().status).toBe(0);
    writeFileSync(join(root, "corrupt-download"), "yes");
    expect(prepare().stderr).toContain("does not match the published release");
    expect(existsSync(join(root, "source/mappings.json"))).toBe(false);
  });

  it("rejects a release made private while its files are transferring", () => {
    expect(plan().status).toBe(0);
    writeFileSync(join(root, "make-draft-after-download"), "yes");
    expect(prepare().status).toBe(1);
    expect(existsSync(join(root, "source/mappings.json"))).toBe(false);
  });
});

describe("read-only S3 mirror gates", () => {
  let root: string;
  let responses: Record<string, unknown>;
  beforeEach(() => {
    root = mkdtempSync(join(tmpdir(), "flat-white-s3-gates-"));
    mkdirSync(join(root, "bin"));
    writeFileSync(
      join(root, "bin/aws"),
      `#!/usr/bin/env python3
import json, os, sys
from pathlib import Path
root = Path(os.environ['MIRROR_TEST_ROOT'])
args = sys.argv[1:]
if args[:2] != ['s3api', 'head-object']: raise SystemExit('Unexpected write')
key = args[args.index('--key') + 1]
value = json.loads((root / 'responses.json').read_text())[key]
if isinstance(value, str):
    print(value, file=sys.stderr)
    raise SystemExit(255)
print(json.dumps(value))
`,
      { mode: 0o755 },
    );
    const manifest = {
      files: [{ key: "data/address/2026-08/vic.ndjson.gz", bytes: 5, sha256: sha("state") }],
    };
    writeFileSync(join(root, "manifest.json"), JSON.stringify(manifest));
    writeFileSync(join(root, "mappings.json"), "{}");
    responses = {
      "manifest.json": { ContentLength: 1 },
      "test/vic.ndjson.gz": {
        ContentLength: 5,
        ChecksumSHA256: Buffer.from(sha("state"), "hex").toString("base64"),
        ChecksumType: "FULL_OBJECT",
      },
      "test/mappings.json": {
        ContentLength: 2,
        ChecksumSHA256: Buffer.from(sha("{}"), "hex").toString("base64"),
      },
    };
  });
  afterEach(() => rmSync(root, { recursive: true, force: true }));
  function run(mode: string) {
    writeFileSync(join(root, "responses.json"), JSON.stringify(responses));
    return spawnSync(
      "python3",
      [
        resolve("scripts/check-s3-mirror.py"),
        mode,
        "--bucket=test",
        "--key=manifest.json",
        "--prefix=test",
        `--manifest=${join(root, "manifest.json")}`,
        `--mappings=${join(root, "mappings.json")}`,
      ],
      {
        encoding: "utf8",
        env: {
          ...process.env,
          PATH: `${join(root, "bin")}:${process.env.PATH}`,
          MIRROR_TEST_ROOT: root,
        },
      },
    );
  }
  it("skips an already-published manifest", () => expect(run("exists").stdout).toBe("skip=true\n"));
  it("permits first publication only after a confirmed missing object", () => {
    responses["manifest.json"] =
      "An error occurred (404) when calling the HeadObject operation: Not Found";
    expect(run("exists").stdout).toBe("skip=false\n");
  });
  it.each(["403", "301", "500", "Unable to locate credentials", "Could not connect to endpoint"])(
    "fails closed on %s",
    (error) => {
      responses["manifest.json"] =
        `An error occurred (${error}) when calling the HeadObject operation: failure`;
      const result = run("exists");
      expect(result.status).toBe(1);
      expect(result.stdout).not.toContain("skip=false");
    },
  );
  it("requires matching sizes and full-object checksums for data and mappings", () =>
    expect(run("verify").status).toBe(0));
  it.each([
    ["ContentLength", 6],
    ["ChecksumSHA256", "wrong"],
    ["ChecksumSHA256", null],
    ["ChecksumType", "COMPOSITE"],
  ])("rejects incorrect %s", (field, value) => {
    responses["test/vic.ndjson.gz"] = {
      ...(responses["test/vic.ndjson.gz"] as object),
      [field as string]: value,
    };
    expect(run("verify").status).toBe(1);
  });
  it("checks mappings content, not merely its presence", () => {
    responses["test/mappings.json"] = { ContentLength: 2, ChecksumSHA256: "wrong" };
    expect(run("verify").stderr).toContain("mappings.json");
  });
});
