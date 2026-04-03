/**
 * Unit tests for download.ts pure functions.
 *
 * Tests formatting, retry delay calculation, and data source configuration.
 * Does NOT test actual HTTP downloads (requires network).
 */

import { describe, it, expect } from "vitest";
import {
  formatBytes,
  formatSpeed,
  formatProgress,
  retryDelay,
  DATA_SOURCES,
  DEFAULT_STALL_TIMEOUT_MS,
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

describe("DATA_SOURCES", () => {
  it("has two data sources", () => {
    expect(DATA_SOURCES).toHaveLength(2);
  });

  it("has G-NAF source", () => {
    const gnaf = DATA_SOURCES.find((s) => s.name.includes("G-NAF"));
    expect(gnaf).toBeDefined();
    expect(gnaf!.url).toContain("data.gov.au");
    expect(gnaf!.extractedDir).toBe("G-NAF");
  });

  it("has Admin Boundaries source with path matching .env.example", () => {
    const admin = DATA_SOURCES.find((s) => s.name.includes("Administrative"));
    expect(admin).toBeDefined();
    expect(admin!.url).toContain("data.gov.au");
    expect(admin!.extractedDir).toBe("FEB26_AdminBounds_GDA_2020_SHP");
  });
});

describe("DEFAULT_STALL_TIMEOUT_MS", () => {
  it("is a positive number suitable for multi-GB downloads", () => {
    expect(DEFAULT_STALL_TIMEOUT_MS).toBeGreaterThanOrEqual(30_000);
  });
});
