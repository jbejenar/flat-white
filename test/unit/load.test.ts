/**
 * Unit tests for load.ts — gnaf-loader argument building and validation.
 * Does NOT run the actual gnaf-loader (that's integration testing).
 */

import { describe, it, expect } from "vitest";
import { buildArgs, resolveGnafTablesPath, resolveAdminBdysPath } from "../../src/load.js";

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
    expect(args).toContain("--local-server-dir");
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
});

describe("resolveGnafTablesPath", () => {
  it("resolves the G-NAF Standard directory from ./data", () => {
    const path = resolveGnafTablesPath("./data");
    expect(path).toMatch(/G-NAF.*G-NAF /);
  });

  it("throws if data directory does not exist", () => {
    expect(() => resolveGnafTablesPath("/nonexistent/path")).toThrow("G-NAF directory not found");
  });
});

describe("resolveAdminBdysPath", () => {
  it("resolves the Admin Boundaries directory from ./data", () => {
    const path = resolveAdminBdysPath("./data");
    expect(path).toMatch(/AdminBounds/);
  });

  it("throws if data directory does not exist", () => {
    expect(() => resolveAdminBdysPath("/nonexistent/path")).toThrow();
  });
});
