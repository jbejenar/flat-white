/**
 * Unit tests for cli.ts — CLI argument parsing and validation.
 */

import { describe, it, expect } from "vitest";
import { parseArgs, validateArgs, CliError, HELP_TEXT } from "../../src/cli.js";

describe("parseArgs", () => {
  it("returns defaults when no arguments provided", () => {
    const opts = parseArgs([]);
    expect(opts).toEqual({
      help: false,
      fixtureOnly: false,
      states: [],
      outputDir: "/output",
      compress: false,
      splitStates: false,
      skipDownload: false,
      gnafPath: null,
      adminPath: null,
    });
  });

  it("parses --help", () => {
    expect(parseArgs(["--help"]).help).toBe(true);
  });

  it("parses -h", () => {
    expect(parseArgs(["-h"]).help).toBe(true);
  });

  it("parses --fixture-only", () => {
    expect(parseArgs(["--fixture-only"]).fixtureOnly).toBe(true);
  });

  it("parses --states with a single value", () => {
    expect(parseArgs(["--states", "VIC"]).states).toEqual(["VIC"]);
  });

  it("parses --states with multiple values", () => {
    expect(parseArgs(["--states", "VIC", "NSW", "QLD"]).states).toEqual(["VIC", "NSW", "QLD"]);
  });

  it("uppercases state values", () => {
    expect(parseArgs(["--states", "vic", "nsw"]).states).toEqual(["VIC", "NSW"]);
  });

  it("parses --states followed by another flag", () => {
    const opts = parseArgs(["--states", "VIC", "--compress"]);
    expect(opts.states).toEqual(["VIC"]);
    expect(opts.compress).toBe(true);
  });

  it("throws when --states has no value", () => {
    expect(() => parseArgs(["--states"])).toThrow(CliError);
    expect(() => parseArgs(["--states", "--compress"])).toThrow("--states requires");
  });

  it("parses --output", () => {
    expect(parseArgs(["--output", "/tmp/out"]).outputDir).toBe("/tmp/out");
  });

  it("throws when --output has no value", () => {
    expect(() => parseArgs(["--output"])).toThrow(CliError);
  });

  it("parses --compress", () => {
    expect(parseArgs(["--compress"]).compress).toBe(true);
  });

  it("parses --split-states", () => {
    expect(parseArgs(["--split-states"]).splitStates).toBe(true);
  });

  it("parses --skip-download", () => {
    expect(parseArgs(["--skip-download"]).skipDownload).toBe(true);
  });

  it("parses --gnaf-path", () => {
    expect(parseArgs(["--gnaf-path", "/data/gnaf"]).gnafPath).toBe("/data/gnaf");
  });

  it("parses --admin-path", () => {
    expect(parseArgs(["--admin-path", "/data/admin"]).adminPath).toBe("/data/admin");
  });

  it("throws on unknown flags", () => {
    expect(() => parseArgs(["--bogus"])).toThrow(CliError);
    expect(() => parseArgs(["--bogus"])).toThrow("Unknown argument");
  });

  it("parses a full production-like command", () => {
    const opts = parseArgs([
      "--states",
      "VIC",
      "NSW",
      "--output",
      "/output",
      "--compress",
      "--split-states",
    ]);
    expect(opts.states).toEqual(["VIC", "NSW"]);
    expect(opts.outputDir).toBe("/output");
    expect(opts.compress).toBe(true);
    expect(opts.splitStates).toBe(true);
  });

  it("parses --skip-download with data paths", () => {
    const opts = parseArgs([
      "--skip-download",
      "--gnaf-path",
      "/data/gnaf",
      "--admin-path",
      "/data/admin",
    ]);
    expect(opts.skipDownload).toBe(true);
    expect(opts.gnafPath).toBe("/data/gnaf");
    expect(opts.adminPath).toBe("/data/admin");
  });
});

describe("validateArgs", () => {
  it("passes with valid defaults", () => {
    expect(() => validateArgs(parseArgs([]))).not.toThrow();
  });

  it("passes when --help is set (skips validation)", () => {
    expect(() => validateArgs(parseArgs(["--help"]))).not.toThrow();
  });

  it("passes for fixture-only mode", () => {
    expect(() => validateArgs(parseArgs(["--fixture-only"]))).not.toThrow();
  });

  it("rejects --skip-download without data paths", () => {
    expect(() => validateArgs(parseArgs(["--skip-download"]))).toThrow(CliError);
    expect(() => validateArgs(parseArgs(["--skip-download"]))).toThrow("--gnaf-path");
  });

  it("rejects --skip-download with only gnaf-path", () => {
    expect(() => validateArgs(parseArgs(["--skip-download", "--gnaf-path", "/a"]))).toThrow(
      CliError,
    );
  });

  it("rejects --skip-download with only admin-path", () => {
    expect(() => validateArgs(parseArgs(["--skip-download", "--admin-path", "/b"]))).toThrow(
      CliError,
    );
  });

  it("allows --skip-download with both data paths", () => {
    expect(() =>
      validateArgs(parseArgs(["--skip-download", "--gnaf-path", "/a", "--admin-path", "/b"])),
    ).not.toThrow();
  });

  it("rejects --fixture-only with --skip-download", () => {
    expect(() => validateArgs(parseArgs(["--fixture-only", "--skip-download"]))).toThrow(
      "mutually exclusive",
    );
  });

  it("rejects --fixture-only with --split-states", () => {
    expect(() => validateArgs(parseArgs(["--fixture-only", "--split-states"]))).toThrow(
      "mutually exclusive",
    );
  });

  it("rejects --fixture-only with --states", () => {
    expect(() => validateArgs(parseArgs(["--fixture-only", "--states", "VIC"]))).toThrow(
      "mutually exclusive",
    );
  });

  it("allows --fixture-only with --compress", () => {
    expect(() => validateArgs(parseArgs(["--fixture-only", "--compress"]))).not.toThrow();
  });
});

describe("HELP_TEXT", () => {
  it("contains all flags", () => {
    for (const flag of [
      "--help",
      "--fixture-only",
      "--states",
      "--output",
      "--compress",
      "--split-states",
      "--skip-download",
      "--gnaf-path",
      "--admin-path",
    ]) {
      expect(HELP_TEXT).toContain(flag);
    }
  });

  it("contains exit codes", () => {
    expect(HELP_TEXT).toContain("Exit codes:");
  });
});
