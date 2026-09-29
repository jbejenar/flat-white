import { describe, it, expect } from "vitest";
import { VERSION } from "../../src/index.js";

describe("flat-white", () => {
  it("exports a version string", () => {
    expect(VERSION).toBe("1.0.0");
  });
});
