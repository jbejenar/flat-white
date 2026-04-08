/**
 * Unit tests for download.ts pure functions.
 *
 * Tests formatting, retry delay calculation, and data source configuration.
 * Does NOT test actual HTTP downloads (requires network).
 */

import { describe, it, expect, beforeEach, afterEach } from "vitest";
import { mkdirSync, rmSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";
import { tmpdir } from "node:os";
import {
  formatBytes,
  formatSpeed,
  formatProgress,
  retryDelay,
  DEFAULT_DATA_SOURCES,
  DEFAULT_FALLBACK_VERSION,
  DEFAULT_STALL_TIMEOUT_MS,
  isExtractionComplete,
  resolveOutputDir,
  resolveDataSources,
} from "../../src/download.js";

describe("formatBytes", () => {
  it("formats bytes", () => {
    expect(formatBytes(500)).toBe("500 B");
  });

  it("formats kilobytes", () => {
    expect(formatBytes(1024)).toBe("1.0 KB");
    expect(formatBytes(1536)).toBe("1.5 KB");
  });

  it("formats megabytes", () => {
    expect(formatBytes(1024 * 1024)).toBe("1.0 MB");
    expect(formatBytes(1024 * 1024 * 512)).toBe("512.0 MB");
  });

  it("formats gigabytes", () => {
    expect(formatBytes(1024 * 1024 * 1024)).toBe("1.00 GB");
    expect(formatBytes(1024 * 1024 * 1024 * 1.7)).toBe("1.70 GB");
  });
});

describe("formatSpeed", () => {
  it("formats MB/s", () => {
    expect(formatSpeed(1024 * 1024)).toBe("1.0 MB/s");
    expect(formatSpeed(1024 * 1024 * 50)).toBe("50.0 MB/s");
  });

  it("handles zero", () => {
    expect(formatSpeed(0)).toBe("0.0 MB/s");
  });
});

describe("formatProgress", () => {
  it("formats with known total", () => {
    const result = formatProgress(512 * 1024 * 1024, 1024 * 1024 * 1024, 10);
    expect(result).toContain("50.0%");
    expect(result).toContain("MB/s");
  });

  it("formats without total", () => {
    const result = formatProgress(100 * 1024 * 1024, null, 5);
    expect(result).toContain("100.0 MB");
    expect(result).toContain("MB/s");
    expect(result).not.toContain("%");
  });

  it("handles zero elapsed time", () => {
    const result = formatProgress(0, 1000, 0);
    expect(result).toContain("0.0 MB/s");
  });
});

describe("retryDelay", () => {
  it("uses exponential backoff", () => {
    expect(retryDelay(0)).toBe(1000);
    expect(retryDelay(1)).toBe(2000);
    expect(retryDelay(2)).toBe(4000);
  });
});

describe("DEFAULT_DATA_SOURCES", () => {
  it("has two data sources", () => {
    expect(DEFAULT_DATA_SOURCES).toHaveLength(2);
  });

  it("has G-NAF source with sentinel paths", () => {
    const gnaf = DEFAULT_DATA_SOURCES.find((s) => s.name.includes("G-NAF"));
    expect(gnaf).toBeDefined();
    expect(gnaf!.url).toContain("data.gov.au");
    expect(gnaf!.extractedDir).toBe("G-NAF");
    expect(gnaf!.sentinelPaths.length).toBeGreaterThan(0);
  });

  it("has Admin Boundaries source with sentinel paths", () => {
    const admin = DEFAULT_DATA_SOURCES.find((s) => s.name.includes("Administrative"));
    expect(admin).toBeDefined();
    expect(admin!.url).toContain("data.gov.au");
    expect(admin!.extractedDir).toBe("FEB26_AdminBounds_GDA_2020_SHP");
    expect(admin!.sentinelPaths.length).toBeGreaterThan(0);
  });
});

describe("DEFAULT_STALL_TIMEOUT_MS", () => {
  it("is a positive number suitable for multi-GB downloads", () => {
    expect(DEFAULT_STALL_TIMEOUT_MS).toBeGreaterThanOrEqual(30_000);
  });
});

describe("resolveOutputDir", () => {
  const originalEnv = { ...process.env };

  afterEach(() => {
    // Restore original env
    delete process.env.DATA_DIR;
    delete process.env.GNAF_DATA_PATH;
    delete process.env.ADMIN_BDYS_PATH;
    Object.assign(process.env, originalEnv);
  });

  it("defaults to ./data when no env vars are set", () => {
    delete process.env.DATA_DIR;
    delete process.env.GNAF_DATA_PATH;
    delete process.env.ADMIN_BDYS_PATH;
    expect(resolveOutputDir()).toBe(resolve("./data"));
  });

  it("uses DATA_DIR when set (takes priority over path vars)", () => {
    process.env.DATA_DIR = "/custom/root";
    process.env.GNAF_DATA_PATH = "/other/G-NAF";
    expect(resolveOutputDir()).toBe("/custom/root");
  });

  it("derives parent from consistent GNAF_DATA_PATH and ADMIN_BDYS_PATH", () => {
    process.env.GNAF_DATA_PATH = "/mydata/G-NAF";
    process.env.ADMIN_BDYS_PATH = "/mydata/FEB26_AdminBounds_GDA_2020_SHP";
    expect(resolveOutputDir()).toBe("/mydata");
  });

  it("throws when GNAF_DATA_PATH and ADMIN_BDYS_PATH have different parents", () => {
    process.env.GNAF_DATA_PATH = "/path-a/G-NAF";
    process.env.ADMIN_BDYS_PATH = "/path-b/FEB26_AdminBounds_GDA_2020_SHP";
    expect(() => resolveOutputDir()).toThrow("must share the same parent directory");
  });

  it("throws when GNAF_DATA_PATH directory name doesn't match expected extractedDir", () => {
    process.env.GNAF_DATA_PATH = "/mydata/wrong-name";
    process.env.ADMIN_BDYS_PATH = "/mydata/FEB26_AdminBounds_GDA_2020_SHP";
    expect(() => resolveOutputDir()).toThrow('does not match expected "G-NAF"');
  });

  it("throws when ADMIN_BDYS_PATH directory name doesn't match expected extractedDir", () => {
    process.env.GNAF_DATA_PATH = "/mydata/G-NAF";
    process.env.ADMIN_BDYS_PATH = "/mydata/wrong-admin-name";
    expect(() => resolveOutputDir()).toThrow(
      'does not match expected "FEB26_AdminBounds_GDA_2020_SHP"',
    );
  });

  it("derives parent from GNAF_DATA_PATH alone when ADMIN_BDYS_PATH is not set", () => {
    process.env.GNAF_DATA_PATH = "/solo/G-NAF";
    delete process.env.ADMIN_BDYS_PATH;
    expect(resolveOutputDir()).toBe("/solo");
  });

  it("derives parent from ADMIN_BDYS_PATH alone when GNAF_DATA_PATH is not set", () => {
    delete process.env.GNAF_DATA_PATH;
    process.env.ADMIN_BDYS_PATH = "/solo/FEB26_AdminBounds_GDA_2020_SHP";
    expect(resolveOutputDir()).toBe("/solo");
  });

  it("throws when only GNAF_DATA_PATH is set with wrong directory name", () => {
    process.env.GNAF_DATA_PATH = "/solo/custom-gnaf";
    delete process.env.ADMIN_BDYS_PATH;
    expect(() => resolveOutputDir()).toThrow('does not match expected "G-NAF"');
  });
});

describe("resolveDataSources", () => {
  const originalEnv = { ...process.env };

  afterEach(() => {
    delete process.env.DOWNLOAD_URL_GNAF;
    delete process.env.DOWNLOAD_URL_ADMIN_BDYS;
    delete process.env.ADMIN_BDYS_EXTRACTED_DIR;
    Object.assign(process.env, originalEnv);
  });

  it("returns default sources when no env vars are set", () => {
    delete process.env.DOWNLOAD_URL_GNAF;
    delete process.env.DOWNLOAD_URL_ADMIN_BDYS;
    const sources = resolveDataSources(DEFAULT_FALLBACK_VERSION);
    const gnaf = sources.find((s) => s.name.includes("G-NAF"));
    expect(gnaf!.url).toContain("data.gov.au");
  });

  it("overrides G-NAF URL from DOWNLOAD_URL_GNAF env var", () => {
    process.env.DOWNLOAD_URL_GNAF = "https://example.com/gnaf-may26.zip";
    process.env.DOWNLOAD_URL_ADMIN_BDYS = "https://example.com/admin-may26.zip";
    process.env.ADMIN_BDYS_EXTRACTED_DIR = "MAY26_AdminBounds_GDA_2020_SHP";
    const sources = resolveDataSources("2026.05");
    const gnaf = sources.find((s) => s.name.includes("G-NAF"));
    expect(gnaf!.url).toBe("https://example.com/gnaf-may26.zip");
    // Sentinel paths should be relaxed to wildcard
    expect(gnaf!.sentinelPaths[0]).toContain("G-NAF */");
  });

  it("overrides Admin Boundaries URL and extractedDir from env vars", () => {
    process.env.DOWNLOAD_URL_GNAF = "https://example.com/gnaf-may26.zip";
    process.env.DOWNLOAD_URL_ADMIN_BDYS = "https://example.com/admin-may26.zip";
    process.env.ADMIN_BDYS_EXTRACTED_DIR = "MAY26_AdminBounds_GDA_2020_SHP";
    const sources = resolveDataSources("2026.05");
    const admin = sources.find((s) => s.name.includes("Administrative"));
    expect(admin!.url).toBe("https://example.com/admin-may26.zip");
    expect(admin!.extractedDir).toBe("MAY26_AdminBounds_GDA_2020_SHP");
  });

  it("does not mutate DEFAULT_DATA_SOURCES", () => {
    process.env.DOWNLOAD_URL_GNAF = "https://example.com/override.zip";
    resolveDataSources(DEFAULT_FALLBACK_VERSION);
    expect(DEFAULT_DATA_SOURCES[0].url).toContain("data.gov.au");
  });

  it("fails fast for newer production versions when overrides are missing", () => {
    delete process.env.DOWNLOAD_URL_GNAF;
    delete process.env.DOWNLOAD_URL_ADMIN_BDYS;
    delete process.env.ADMIN_BDYS_EXTRACTED_DIR;

    expect(() => resolveDataSources("2026.05")).toThrow(
      "requires explicit release data configuration",
    );
  });

  it("fails when Admin Boundaries extracted dir is missing for newer versions", () => {
    process.env.DOWNLOAD_URL_GNAF = "https://example.com/gnaf-may26.zip";
    process.env.DOWNLOAD_URL_ADMIN_BDYS = "https://example.com/admin-may26.zip";
    delete process.env.ADMIN_BDYS_EXTRACTED_DIR;

    expect(() => resolveDataSources("2026.05")).toThrow("ADMIN_BDYS_EXTRACTED_DIR");
  });
});

describe("isExtractionComplete", () => {
  const testDir = resolve(tmpdir(), "flat-white-test-extraction");

  beforeEach(() => {
    mkdirSync(testDir, { recursive: true });
  });

  afterEach(() => {
    rmSync(testDir, { recursive: true, force: true });
  });

  it("returns false for non-existent directory", () => {
    expect(isExtractionComplete("/no/such/path", ["file.txt"])).toBe(false);
  });

  it("returns false for empty directory", () => {
    expect(isExtractionComplete(testDir, ["Standard"])).toBe(false);
  });

  it("returns false for empty sentinel list", () => {
    expect(isExtractionComplete(testDir, [])).toBe(false);
  });

  it("returns false when only some sentinels are present (partial extraction)", () => {
    mkdirSync(resolve(testDir, "Standard"), { recursive: true });
    expect(isExtractionComplete(testDir, ["Standard", "Authority Code"])).toBe(false);
  });

  it("returns false for directory with unrelated files but missing sentinels", () => {
    writeFileSync(resolve(testDir, "random.txt"), "junk");
    expect(isExtractionComplete(testDir, ["Standard", "Authority Code"])).toBe(false);
  });

  it("returns true when all sentinels are present", () => {
    mkdirSync(resolve(testDir, "Standard"), { recursive: true });
    mkdirSync(resolve(testDir, "Authority Code"), { recursive: true });
    expect(isExtractionComplete(testDir, ["Standard", "Authority Code"])).toBe(true);
  });

  it("supports nested sentinel paths", () => {
    mkdirSync(resolve(testDir, "G-NAF FEBRUARY 2026/Standard"), { recursive: true });
    expect(isExtractionComplete(testDir, ["G-NAF FEBRUARY 2026/Standard"])).toBe(true);
  });

  it("supports path-segment wildcards (G-NAF */Standard)", () => {
    mkdirSync(resolve(testDir, "G-NAF MAY 2026/Standard"), { recursive: true });
    mkdirSync(resolve(testDir, "G-NAF MAY 2026/Authority Code"), { recursive: true });
    expect(isExtractionComplete(testDir, ["G-NAF */Standard", "G-NAF */Authority Code"])).toBe(
      true,
    );
  });

  it("returns false for path-segment wildcard when subdirectory is missing", () => {
    mkdirSync(resolve(testDir, "G-NAF MAY 2026/Standard"), { recursive: true });
    expect(isExtractionComplete(testDir, ["G-NAF */Standard", "G-NAF */Authority Code"])).toBe(
      false,
    );
  });
});
