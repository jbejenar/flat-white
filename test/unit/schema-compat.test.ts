import { describe, it, expect } from "vitest";
import { compareSchemas, compareSnapshots, type SchemaSnapshot } from "../../src/schema-compat.js";

describe("compareSchemas", () => {
  it("returns no changes for identical schemas", () => {
    const schema = {
      type: "object",
      properties: {
        name: { type: "string" },
        age: { type: "number" },
      },
      required: ["name", "age"],
    };
    const result = compareSchemas(schema, schema);
    expect(result.breaking).toHaveLength(0);
    expect(result.nonBreaking).toHaveLength(0);
  });

  it("detects removed field as breaking", () => {
    const baseline = {
      type: "object",
      properties: {
        name: { type: "string" },
        age: { type: "number" },
      },
    };
    const current = {
      type: "object",
      properties: {
        name: { type: "string" },
      },
    };
    const result = compareSchemas(baseline, current);
    expect(result.breaking).toHaveLength(1);
    expect(result.breaking[0].path).toBe("age");
    expect(result.breaking[0].description).toBe("field removed");
  });

  it("detects added field as non-breaking", () => {
    const baseline = {
      type: "object",
      properties: {
        name: { type: "string" },
      },
    };
    const current = {
      type: "object",
      properties: {
        name: { type: "string" },
        email: { type: "string" },
      },
    };
    const result = compareSchemas(baseline, current);
    expect(result.nonBreaking).toHaveLength(1);
    expect(result.nonBreaking[0].path).toBe("email");
    expect(result.nonBreaking[0].description).toBe("field added");
  });

  it("detects type change as breaking", () => {
    const baseline = {
      type: "object",
      properties: {
        age: { type: "number" },
      },
    };
    const current = {
      type: "object",
      properties: {
        age: { type: "string" },
      },
    };
    const result = compareSchemas(baseline, current);
    expect(result.breaking).toHaveLength(1);
    expect(result.breaking[0].path).toBe("age");
    expect(result.breaking[0].description).toContain("type changed");
  });

  it("detects nullable→non-nullable as breaking", () => {
    const baseline = {
      type: "object",
      properties: {
        name: { anyOf: [{ type: "string" }, { type: "null" }] },
      },
    };
    const current = {
      type: "object",
      properties: {
        name: { type: "string" },
      },
    };
    const result = compareSchemas(baseline, current);
    expect(result.breaking).toHaveLength(1);
    expect(result.breaking[0].description).toContain("nullable to non-nullable");
  });

  it("detects non-nullable→nullable as non-breaking", () => {
    const baseline = {
      type: "object",
      properties: {
        name: { type: "string" },
      },
    };
    const current = {
      type: "object",
      properties: {
        name: { anyOf: [{ type: "string" }, { type: "null" }] },
      },
    };
    const result = compareSchemas(baseline, current);
    expect(result.nonBreaking).toHaveLength(1);
    expect(result.nonBreaking[0].description).toContain("non-nullable to nullable");
  });

  it("detects changes in nested objects", () => {
    const baseline = {
      type: "object",
      properties: {
        address: {
          type: "object",
          properties: {
            street: { type: "string" },
            city: { type: "string" },
          },
        },
      },
    };
    const current = {
      type: "object",
      properties: {
        address: {
          type: "object",
          properties: {
            street: { type: "string" },
          },
        },
      },
    };
    const result = compareSchemas(baseline, current);
    expect(result.breaking).toHaveLength(1);
    expect(result.breaking[0].path).toBe("address.city");
  });

  it("detects changes in array items", () => {
    const baseline = {
      type: "object",
      properties: {
        tags: {
          type: "array",
          items: {
            type: "object",
            properties: {
              label: { type: "string" },
              value: { type: "number" },
            },
          },
        },
      },
    };
    const current = {
      type: "object",
      properties: {
        tags: {
          type: "array",
          items: {
            type: "object",
            properties: {
              label: { type: "string" },
            },
          },
        },
      },
    };
    const result = compareSchemas(baseline, current);
    expect(result.breaking).toHaveLength(1);
    expect(result.breaking[0].path).toBe("tags[].value");
  });

  it("handles multiple changes simultaneously", () => {
    const baseline = {
      type: "object",
      properties: {
        a: { type: "string" },
        b: { type: "number" },
        c: { type: "string" },
      },
    };
    const current = {
      type: "object",
      properties: {
        a: { type: "string" },
        d: { type: "boolean" },
      },
    };
    const result = compareSchemas(baseline, current);
    // b removed, c removed = 2 breaking
    expect(result.breaking).toHaveLength(2);
    // d added = 1 non-breaking
    expect(result.nonBreaking).toHaveLength(1);
  });
});

describe("compareSnapshots", () => {
  it("detects removed schema as breaking", () => {
    const baseline: SchemaSnapshot = {
      generatedAt: "2026-01-01",
      schemas: {
        Address: { type: "object", properties: { a: { type: "string" } } },
        Locality: { type: "object", properties: { b: { type: "string" } } },
      },
    };
    const current: SchemaSnapshot = {
      generatedAt: "2026-01-02",
      schemas: {
        Address: { type: "object", properties: { a: { type: "string" } } },
      },
    };
    const result = compareSnapshots(baseline, current);
    expect(result.breaking).toHaveLength(1);
    expect(result.breaking[0].path).toBe("Locality");
    expect(result.breaking[0].description).toBe("schema removed");
  });

  it("detects added schema as non-breaking", () => {
    const baseline: SchemaSnapshot = {
      generatedAt: "2026-01-01",
      schemas: {
        Address: { type: "object", properties: { a: { type: "string" } } },
      },
    };
    const current: SchemaSnapshot = {
      generatedAt: "2026-01-02",
      schemas: {
        Address: { type: "object", properties: { a: { type: "string" } } },
        Street: { type: "object", properties: { name: { type: "string" } } },
      },
    };
    const result = compareSnapshots(baseline, current);
    expect(result.nonBreaking).toHaveLength(1);
    expect(result.nonBreaking[0].path).toBe("Street");
  });

  it("compares fields within shared schemas", () => {
    const baseline: SchemaSnapshot = {
      generatedAt: "2026-01-01",
      schemas: {
        Address: {
          type: "object",
          properties: { name: { type: "string" }, old: { type: "number" } },
        },
      },
    };
    const current: SchemaSnapshot = {
      generatedAt: "2026-01-02",
      schemas: {
        Address: {
          type: "object",
          properties: { name: { type: "string" }, added: { type: "boolean" } },
        },
      },
    };
    const result = compareSnapshots(baseline, current);
    expect(result.breaking).toHaveLength(1); // old removed
    expect(result.nonBreaking).toHaveLength(1); // added
  });
});

describe("reader compatibility across schema 1.x", () => {
  it("treats required additions and optional-to-required changes as breaking", () => {
    const before = { type: "object", properties: { name: { type: "string" } } };
    expect(compareSchemas(before, { ...before, required: ["name"] }).breaking[0]).toMatchObject({
      path: "name",
      description: "field became required",
    });
    expect(
      compareSchemas(before, {
        ...before,
        properties: { ...before.properties, extra: { type: "string" } },
        required: ["extra"],
      }).breaking[0],
    ).toMatchObject({ path: "extra", description: "required field added" });
  });
  it("finds required, nullable and enum changes inside nullable objects and arrays", () => {
    const before = {
      type: "object",
      properties: {
        point: {
          anyOf: [
            {
              type: "object",
              properties: {
                precision: { type: "string", enum: ["street", "locality", "unknown"] },
                latitude: { anyOf: [{ type: "number" }, { type: "null" }] },
              },
            },
            { type: "null" },
          ],
        },
      },
    };
    const after = structuredClone(before);
    const branch = after.properties.point.anyOf[0];
    branch.properties!.precision.enum = ["street"];
    branch.properties!.latitude.anyOf = [{ type: "number" }];
    const changes = compareSchemas(before, after).breaking;
    expect(changes.map((c) => c.path)).toEqual(["point.precision", "point.latitude"]);
    const arrayBefore = {
      type: "object",
      properties: { points: { type: "array", items: before } },
    };
    const arrayAfter = { type: "object", properties: { points: { type: "array", items: after } } };
    expect(compareSchemas(arrayBefore, arrayAfter).breaking.map((c) => c.path)).toEqual([
      "points[].point.precision",
      "points[].point.latitude",
    ]);
  });
  it("allows the optional fallback field and enum widening, but rejects numeric narrowing", () => {
    const before = {
      type: "object",
      properties: {
        latitude: { type: "number", minimum: -90 },
        precision: { type: "string", enum: ["street"] },
      },
    };
    const after = {
      type: "object",
      properties: {
        ...before.properties,
        precision: { type: "string", enum: ["street", "locality"] },
        fallback: {
          anyOf: [
            { type: "object", properties: { source: { type: "string", const: "GNAF_DEFAULT" } } },
            { type: "null" },
          ],
        },
      },
    };
    expect(compareSchemas(before, after).breaking).toHaveLength(0);
    expect(
      compareSchemas(before, {
        ...before,
        properties: { ...before.properties, latitude: { type: "number", minimum: -44 } },
      }).breaking[0].path,
    ).toBe("latitude");
  });
});
