/** Exact PID checks with a bounded sort buffer and disk spill, even for NSW. */
import { createReadStream, createWriteStream } from "node:fs";
import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { once } from "node:events";
import { finished } from "node:stream/promises";
import { createInterface } from "node:readline";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { createHash } from "node:crypto";

const run = promisify(execFile);
export const DIAGNOSTIC_LIMIT = 20;

export interface PidSummary {
  count: number;
  duplicateCount: number;
  duplicatePids: string[];
  /** SHA-256 of sorted, newline-delimited UTF-8 hex PIDs, including duplicates. */
  sha256: string;
}

export async function* pidLines(path: string): AsyncGenerator<string> {
  const input = createReadStream(path);
  const reader = createInterface({ input, crlfDelay: Infinity });
  let failure: Error | undefined;
  input.on("error", (error) => {
    failure = error;
    reader.close();
  });
  try {
    for await (const line of reader) yield line;
    if (failure) throw failure;
  } finally {
    reader.close();
    input.destroy();
  }
}

export class PidLedger {
  private readonly writer;
  private failure?: Error;
  readonly sortedPath: string;

  private constructor(private readonly directory: string) {
    this.writer = createWriteStream(join(directory, "pids"));
    this.writer.on("error", (error) => {
      this.failure = error;
    });
    this.sortedPath = join(directory, "sorted");
  }

  static async create(): Promise<PidLedger> {
    return new PidLedger(await mkdtemp(join(tmpdir(), "flat-white-pids-")));
  }

  async add(pid: string): Promise<void> {
    if (!pid) throw new Error("Missing PID");
    if (this.failure) throw this.failure;
    // Encoding makes separators and locale irrelevant; distinct UTF-8 PIDs
    // remain distinct, including strings containing literal newlines.
    if (!this.writer.write(Buffer.from(pid, "utf8").toString("hex") + "\n")) {
      await once(this.writer, "drain");
    }
  }

  async finish(): Promise<PidSummary> {
    if (this.failure) throw this.failure;
    this.writer.end();
    await finished(this.writer);
    await run(
      "sort",
      ["-S", "32M", "-T", this.directory, "-o", this.sortedPath, join(this.directory, "pids")],
      { env: { ...process.env, LC_ALL: "C" }, maxBuffer: 65536 },
    );
    const hash = createHash("sha256");
    const result: PidSummary = { count: 0, duplicateCount: 0, duplicatePids: [], sha256: "" };
    let previous: string | undefined;
    for await (const pid of pidLines(this.sortedPath)) {
      result.count++;
      hash.update(pid + "\n");
      if (pid === previous) {
        result.duplicateCount++;
        if (result.duplicatePids.length < DIAGNOSTIC_LIMIT) {
          result.duplicatePids.push(Buffer.from(pid, "hex").toString("utf8"));
        }
      }
      previous = pid;
    }
    result.sha256 = hash.digest("hex");
    return result;
  }

  async close(): Promise<void> {
    this.writer.destroy();
    await finished(this.writer).catch(() => undefined);
    await rm(this.directory, { recursive: true, force: true });
  }
}

/** Compare every PID, rather than assuming equal counts or hashes prove equality. */
export async function comparePidLedgers(
  expected: PidLedger,
  actual: PidLedger,
): Promise<{
  missing: number;
  unexpected: number;
  missingSamples: string[];
  unexpectedSamples: string[];
}> {
  const result = {
    missing: 0,
    unexpected: 0,
    missingSamples: [] as string[],
    unexpectedSamples: [] as string[],
  };
  const left = pidLines(expected.sortedPath);
  const right = pidLines(actual.sortedPath);
  try {
    let a = await left.next();
    let b = await right.next();
    while (!a.done || !b.done) {
      if (!a.done && !b.done && a.value === b.value) {
        a = await left.next();
        b = await right.next();
      } else if (!a.done && (b.done || a.value < b.value)) {
        result.missing++;
        if (result.missingSamples.length < DIAGNOSTIC_LIMIT)
          result.missingSamples.push(Buffer.from(a.value, "hex").toString("utf8"));
        a = await left.next();
      } else if (!b.done) {
        result.unexpected++;
        if (result.unexpectedSamples.length < DIAGNOSTIC_LIMIT)
          result.unexpectedSamples.push(Buffer.from(b.value, "hex").toString("utf8"));
        b = await right.next();
      }
    }
    return result;
  } finally {
    await left.return(undefined);
    await right.return(undefined);
  }
}
