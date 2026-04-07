/**
 * Unit tests for load.ts — gnaf-loader argument building and validation.
 * Does NOT run the actual gnaf-loader (that's integration testing).
 * Uses mocked filesystem so tests work without the 6.5GB data directory.
 */

import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";

// Mock node:fs before importing the module under test
vi.mock("node:fs", async (importOriginal) => {
  const actual = await importOriginal<typeof import("node:fs")>();
  return {
    ...actual,
    existsSync: vi.fn((p: string) => {
      const s = String(p);
      // Only simulate paths under the project's ./data directory
      if (s.includes("nonexistent") || s.includes("empty")) return false;
      if (s.includes("G-NAF")) return true;
      if (s.includes("Standard")) return true;
      if (s.includes("gnaf-loader/load-gnaf.py")) return true;
      if (s.endsWith("/data") || s.endsWith("/data/")) return true;
      return false;
    }),
    readdirSync: vi.fn((p: string) => {
      const s = String(p);
      if (s.includes("nonexistent") || s.includes("empty")) return [];
      if (s.endsWith("G-NAF")) return ["G-NAF FEBRUARY 2026"];
      if (s.endsWith("/data") || s.endsWith("/data/"))
        return ["G-NAF", "FEB26_AdminBounds_GDA_2020_SHP", "gnaf.zip"];
      return [];
    }),
  };
});

import {
  buildArgs,
  resolveGnafTablesPath,
  resolveAdminBdysPath,
  deriveGeoscapeVersion,
} from "../../src/load.js";

beforeEach(() => {
  vi.clearAllMocks();
});

describe("buildArgs", () => {
  it("builds correct default args for VIC", () => {
    const args = buildArgs({ states: ["VIC"] });

    expect(args[0]).toMatch(/gnaf-loader\/load-gnaf\.py$/);
    expect(args).toContain("--pghost");
    expect(args).toContain("localhost");
    expect(args).toContain("--pgdb");
    expect(args).toContain("gnaf");
    expect(args).toContain("--geoscape-version");
    expect(args).toContain("202602");
    expect(args).toContain("--srid");
    expect(args).toContain("7844");
    expect(args).toContain("--states");
    expect(args).toContain("VIC");
    expect(args).toContain("--gnaf-tables-path");
    expect(args).toContain("--admin-bdys-path");
  });

  it("omits --local-server-dir when serverDataDir not set", () => {
    const args = buildArgs({ states: ["VIC"] });
    expect(args).not.toContain("--local-server-dir");
  });

  it("includes multiple states", () => {
    const args = buildArgs({ states: ["VIC", "NSW"] });
    const statesIdx = args.indexOf("--states");
    expect(args[statesIdx + 1]).toBe("VIC");
    expect(args[statesIdx + 2]).toBe("NSW");
  });

  it("omits --states when none specified", () => {
    const args = buildArgs({});
    expect(args).not.toContain("--states");
  });

  it("includes --no-boundary-tag when set", () => {
    const args = buildArgs({ noBoundaryTag: true });
    expect(args).toContain("--no-boundary-tag");
  });

  it("uses custom postgres connection", () => {
    const args = buildArgs({
      pgHost: "db.example.com",
      pgPort: 5433,
      pgDb: "mydb",
    });
    const hostIdx = args.indexOf("--pghost");
    expect(args[hostIdx + 1]).toBe("db.example.com");
    const portIdx = args.indexOf("--pgport");
    expect(args[portIdx + 1]).toBe("5433");
    const dbIdx = args.indexOf("--pgdb");
    expect(args[dbIdx + 1]).toBe("mydb");
  });

  it("uses custom max-processes", () => {
    const args = buildArgs({ maxProcesses: 8 });
    const idx = args.indexOf("--max-processes");
    expect(args[idx + 1]).toBe("8");
  });

  it("does not include password in CLI args", () => {
    const args = buildArgs({ states: ["VIC"], pgPassword: "secret123" });
    expect(args).not.toContain("--pgpassword");
    expect(args).not.toContain("secret123");
  });

  it("computes --local-server-dir when serverDataDir is set", () => {
    const args = buildArgs({ states: ["VIC"], serverDataDir: "/data" });
    const idx = args.indexOf("--local-server-dir");
    expect(idx).toBeGreaterThan(-1);
    const serverDir = args[idx + 1];
    expect(serverDir).toMatch(/^\/data\/G-NAF/);
  });
});

describe("resolveGnafTablesPath", () => {
  it("resolves the G-NAF version directory", () => {
    const path = resolveGnafTablesPath("./data");
    expect(path).toMatch(/G-NAF.*G-NAF FEBRUARY 2026$/);
  });

  it("throws if G-NAF base directory does not exist", () => {
    // The mock returns false for paths not matching known patterns
    expect(() => resolveGnafTablesPath("/nonexistent/path")).toThrow("G-NAF directory not found");
  });
});

describe("deriveGeoscapeVersion", () => {
  const originalEnv = process.env.GNAF_VERSION;

  afterEach(() => {
    if (originalEnv === undefined) {
      delete process.env.GNAF_VERSION;
    } else {
      process.env.GNAF_VERSION = originalEnv;
    }
  });

  it("derives 6-digit version from GNAF_VERSION env var", () => {
    process.env.GNAF_VERSION = "2026.05";
    expect(deriveGeoscapeVersion()).toBe("202605");
  });

  it("returns null when GNAF_VERSION is not set", () => {
    delete process.env.GNAF_VERSION;
    expect(deriveGeoscapeVersion()).toBeNull();
  });

  it("returns null for invalid GNAF_VERSION format", () => {
    process.env.GNAF_VERSION = "bad";
    expect(deriveGeoscapeVersion()).toBeNull();
  });
});

describe("buildArgs — geoscape version", () => {
  const originalEnv = process.env.GNAF_VERSION;

  afterEach(() => {
    if (originalEnv === undefined) {
      delete process.env.GNAF_VERSION;
    } else {
      process.env.GNAF_VERSION = originalEnv;
    }
  });

  it("uses explicit geoscapeVersion option when provided", () => {
    const args = buildArgs({ geoscapeVersion: "202605" });
    const idx = args.indexOf("--geoscape-version");
    expect(args[idx + 1]).toBe("202605");
  });

  it("derives from GNAF_VERSION env var when no explicit option", () => {
    process.env.GNAF_VERSION = "2026.05";
    const args = buildArgs({});
    const idx = args.indexOf("--geoscape-version");
    expect(args[idx + 1]).toBe("202605");
  });

  it("falls back to 202602 when neither option nor env var set", () => {
    delete process.env.GNAF_VERSION;
    const args = buildArgs({});
    const idx = args.indexOf("--geoscape-version");
    expect(args[idx + 1]).toBe("202602");
  });
});

describe("buildArgs — geoscape version validation", () => {
  it("rejects non-6-digit geoscapeVersion", () => {
    expect(() => buildArgs({ geoscapeVersion: "20265" })).toThrow(
      /must be a 6-digit YYYYMM string/,
    );
  });

  it("rejects alphabetic geoscapeVersion", () => {
    expect(() => buildArgs({ geoscapeVersion: "abcdef" })).toThrow(
      /must be a 6-digit YYYYMM string/,
    );
  });
});

describe("resolveAdminBdysPath", () => {
  it("resolves the Admin Boundaries directory", () => {
    const path = resolveAdminBdysPath("./data");
    expect(path).toMatch(/AdminBounds/);
  });

  it("throws if no AdminBounds directory found", () => {
    // The mock returns [] for paths not matching known patterns
    expect(() => resolveAdminBdysPath("/some/empty/dir")).toThrow();
  });
});
