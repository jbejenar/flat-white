/**
 * Unit tests for load.ts — gnaf-loader argument building and validation.
 * Does NOT run the actual gnaf-loader (that's integration testing).
 * Uses mocked filesystem so tests work without the 6.5GB data directory.
 */

import { describe, it, expect, vi, beforeEach } from "vitest";

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

import { buildArgs, resolveGnafTablesPath, resolveAdminBdysPath } from "../../src/load.js";

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
