import { readFileSync } from "node:fs";
import { describe, it, expect } from "vitest";
import {
  WardRegistrySchema,
  WardLockSchema,
  parseWardFeatures,
  loadWardLock,
  registryIdentity,
} from "../../src/ward-sources.js";

const root = "fixtures/ward-sources/";
const registry = WardRegistrySchema.parse(JSON.parse(readFileSync(root + "registry.json", "utf8")));
const bytes = readFileSync(root + "wards-fixture.json");
describe("qualified ward source integrity", () => {
  it("preserves duplicate polygon parts under one logical ward identity", () => {
    const features = parseWardFeatures(bytes, registry.councils[0]);
    expect(features).toHaveLength(4);
    expect(new Set(features.map((f) => f.id)).size).toBe(3);
  });
  it("rejects changed bytes, absent logical wards and changed feature inventories", () => {
    expect(() =>
      parseWardFeatures(Buffer.concat([bytes, Buffer.from(" ")]), registry.councils[0]),
    ).toThrow(/bytes changed/);
    const source = registry.councils[0].source!;
    expect(() =>
      parseWardFeatures(bytes, { ...registry.councils[0], source: { ...source, featureCount: 5 } }),
    ).toThrow(/feature count/);
    expect(() =>
      parseWardFeatures(bytes, {
        ...registry.councils[0],
        source: { ...source, wards: [...source.wards, { id: "missing", name: "Missing Ward" }] },
      }),
    ).toThrow(/Missing logical wards/);
  });
  it("rejects approximate/unknown precision, duplicate crosswalks, future boundaries and unsafe paths", () => {
    for (const code of ["STL", "LOC", "GG", "UNK", "FUTURE"])
      expect(
        WardRegistrySchema.safeParse({ ...registry, preciseSiteTypes: [{ code, name: code }] })
          .success,
      ).toBe(false);
    expect(
      WardRegistrySchema.safeParse({
        ...registry,
        councils: [registry.councils[0], registry.councils[0]],
      }).success,
    ).toBe(false);
    expect(WardRegistrySchema.safeParse({ ...registry, referenceDate: "2025-02-28" }).success).toBe(
      false,
    );
    expect(WardRegistrySchema.safeParse({ ...registry, referenceDate: "2026-02-30" }).success).toBe(
      false,
    );
    const council = registry.councils[0];
    expect(
      WardRegistrySchema.safeParse({
        ...registry,
        councils: [{ ...council, source: { ...council.source, file: "../wards-escape.json" } }],
      }).success,
    ).toBe(false);
    expect(
      WardRegistrySchema.safeParse({ ...registry, councils: [{ ...council, source: null }] })
        .success,
    ).toBe(false);
  });
  it("cannot reuse a fixture lock in production, change the date, or silently drop the enabled source", async () => {
    const path = root + "ward-source-lock.json";
    const lock = await loadWardLock(path, "2026-02-28", true);
    expect(lock.identity).toBe(registryIdentity(registry));
    await expect(loadWardLock(path, "2026-02-28")).rejects.toThrow(/reviewed registry/);
    await expect(loadWardLock(path, "2026-08-31", true)).rejects.toThrow(/reviewed registry/);
    await expect(loadWardLock(root + "missing.json", "2026-02-28", true)).rejects.toThrow();
    expect(
      WardLockSchema.safeParse({
        ...lock,
        registry: { ...registry, councils: [registry.councils[1]] },
      }).success,
    ).toBe(false);
    expect(WardLockSchema.safeParse({ ...lock, identity: "0".repeat(64) }).success).toBe(false);
  });
});
