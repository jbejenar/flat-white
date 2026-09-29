import { mkdirSync, mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { download } from "../../src/download.js";

describe("download failure policy", () => {
  let root: string;

  beforeEach(() => {
    root = mkdtempSync(join(tmpdir(), "flat-white-download-retry-"));
    vi.stubEnv("DOWNLOAD_URL_GNAF", "https://fixture.invalid/gnaf.zip");
    vi.stubEnv("DOWNLOAD_URL_ADMIN_BDYS", "https://fixture.invalid/admin.zip");
    vi.stubEnv("ADMIN_BDYS_EXTRACTED_DIR", "admin");
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
    vi.unstubAllGlobals();
    vi.unstubAllEnvs();
    rmSync(root, { recursive: true, force: true });
  });

  async function failedDownload() {
    // Attach the handler before advancing timers, so an expected rejection
    // never becomes an unhandled promise rejection during the backoff.
    const outcome = download({ version: "2026.08", outputDir: root }).catch(
      (error: unknown) => error,
    );
    await vi.runAllTimersAsync();
    expect(await outcome).toBeInstanceOf(Error);
  }

  it.each([400, 401, 403, 404, 410])("does not retry permanent HTTP %i", async (status) => {
    const fetchMock = vi.fn(async () => new Response(null, { status }));
    vi.stubGlobal("fetch", fetchMock);
    await failedDownload();
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it.each([408, 429, 500, 503])("bounds retries for transient HTTP %i", async (status) => {
    const fetchMock = vi.fn(async () => new Response(null, { status }));
    vi.stubGlobal("fetch", fetchMock);
    await failedDownload();
    expect(fetchMock).toHaveBeenCalledTimes(4);
  });

  it("stops when a transient failure is followed by a permanent one", async () => {
    const fetchMock = vi.fn().mockResolvedValue(new Response(null, { status: 404 }));
    fetchMock.mockRejectedValueOnce(
      new TypeError("fetch failed", {
        cause: Object.assign(new Error("reset"), { code: "ECONNRESET" }),
      }),
    );
    vi.stubGlobal("fetch", fetchMock);
    await failedDownload();
    expect(fetchMock).toHaveBeenCalledTimes(2);
  });

  it("does not treat a certificate failure as a transient fetch failure", async () => {
    const fetchMock = vi.fn().mockRejectedValue(
      new TypeError("fetch failed", {
        cause: Object.assign(new Error("certificate expired"), { code: "CERT_HAS_EXPIRED" }),
      }),
    );
    vi.stubGlobal("fetch", fetchMock);
    await failedDownload();
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it("does not retry a local file-write failure", async () => {
    vi.useRealTimers();
    mkdirSync(join(root, "gnaf.zip"));
    const fetchMock = vi.fn(async () => new Response("synthetic archive data"));
    vi.stubGlobal("fetch", fetchMock);
    await expect(download({ version: "2026.08", outputDir: root })).rejects.toThrow("EISDIR");
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it("retries a stalled request within the attempt budget", async () => {
    const fetchMock = vi.fn(
      (_url: string, options: RequestInit) =>
        new Promise((_resolve, reject) => {
          const signal = options.signal!;
          signal.addEventListener("abort", () => reject(signal.reason), { once: true });
        }),
    );
    vi.stubGlobal("fetch", fetchMock);
    await failedDownload();
    expect(fetchMock).toHaveBeenCalledTimes(4);
  });
});
