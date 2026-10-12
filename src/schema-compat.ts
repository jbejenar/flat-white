/**
 * Schema compatibility checking for flat-white.
 *
 * Compares JSON Schema snapshots to detect breaking vs non-breaking changes.
 * Used by CI to gate PRs that alter the NDJSON output contract.
 */

/** A single schema change detected during comparison. */
export interface SchemaChange {
  path: string;
  description: string;
}

/** Result of comparing two schema snapshots. */
export interface CompareResult {
  breaking: SchemaChange[];
  nonBreaking: SchemaChange[];
}

/** JSON Schema property definition (simplified). */
interface JsonSchemaProperty {
  type?: string | string[];
  anyOf?: JsonSchemaProperty[];
  oneOf?: JsonSchemaProperty[];
  enum?: unknown[];
  const?: unknown;
  properties?: Record<string, JsonSchemaProperty>;
  required?: string[];
  items?: JsonSchemaProperty;
  [key: string]: unknown;
}

type JsonSchemaObject = JsonSchemaProperty;

/** Baseline snapshot format: named schemas keyed by identifier. */
export interface SchemaSnapshot {
  generatedAt: string;
  schemas: Record<string, JsonSchemaObject>;
}

/** Resolve the disjoint nullable unions emitted by Zod, preserving their children. */
function variants(property: JsonSchemaProperty): JsonSchemaProperty[] {
  return property.anyOf ?? property.oneOf ?? [property];
}
function types(property: JsonSchemaProperty): string[] {
  return [
    ...new Set(
      variants(property).flatMap((value) =>
        Array.isArray(value.type)
          ? value.type
          : [value.type ?? (value.properties ? "object" : value.items ? "array" : "unknown")],
      ),
    ),
  ].sort();
}
function body(property: JsonSchemaProperty, type: string): JsonSchemaProperty | undefined {
  const matches = variants(property).filter((value) =>
    types({ ...value, anyOf: undefined, oneOf: undefined }).includes(type),
  );
  return matches.length === 1 ? matches[0] : undefined;
}

/** Compare the current reader contract with all values accepted by the baseline. */
export function compareSchemas(
  baseline: JsonSchemaObject,
  current: JsonSchemaObject,
  path = "",
): CompareResult {
  const result: CompareResult = { breaking: [], nonBreaking: [] };
  const change = (breaking: boolean, path: string, description: string) => {
    const changes = result[breaking ? "breaking" : "nonBreaking"];
    if (!changes.some((entry) => entry.path === path && entry.description === description))
      changes.push({ path, description });
  };
  function constraints(before: JsonSchemaProperty, after: JsonSchemaProperty, path: string) {
    const values = (node: JsonSchemaProperty) =>
      node.enum ?? (Object.hasOwn(node, "const") ? [node.const] : undefined);
    const oldValues = values(before)?.map((value) => JSON.stringify(value));
    const newValues = values(after)?.map((value) => JSON.stringify(value));
    if (newValues && (!oldValues || oldValues.some((value) => !newValues.includes(value))))
      change(true, path, "allowed values narrowed or changed");
    else if (oldValues && (!newValues || newValues.some((value) => !oldValues.includes(value))))
      change(false, path, "allowed values expanded");

    const minima = ["minimum", "exclusiveMinimum", "minLength", "minItems", "minProperties"];
    const maxima = ["maximum", "exclusiveMaximum", "maxLength", "maxItems", "maxProperties"];
    for (const keyword of [...minima, ...maxima]) {
      const a = before[keyword],
        b = after[keyword];
      if (a === b) continue;
      const tighter =
        b !== undefined &&
        (a === undefined ||
          (typeof a === "number" &&
            typeof b === "number" &&
            (minima.includes(keyword) ? b > a : b < a)));
      change(tighter, path, `${keyword} constraint ${tighter ? "tightened" : "relaxed"}`);
    }
    const ignored = new Set([
      "type",
      "properties",
      "required",
      "items",
      "anyOf",
      "oneOf",
      "enum",
      "const",
      "$schema",
      "description",
      "title",
      "default",
      "examples",
      "deprecated",
      "readOnly",
      "writeOnly",
      ...minima,
      ...maxima,
    ]);
    for (const key of new Set([...Object.keys(before), ...Object.keys(after)])) {
      if (ignored.has(key) || JSON.stringify(before[key]) === JSON.stringify(after[key])) continue;
      if (key === "additionalProperties" && (after[key] === true || after[key] === undefined))
        change(false, path, "additional properties allowed");
      else if (key === "uniqueItems" && after[key] !== true)
        change(false, path, "array uniqueness relaxed");
      else change(true, path, `${key} validation changed; review compatibility`);
    }
  }
  function compare(before: JsonSchemaProperty, after: JsonSchemaProperty, path: string) {
    // Constraints outside a nullable union still constrain every branch.
    if (before.anyOf || before.oneOf || after.anyOf || after.oneOf)
      constraints(before, after, path);
    const oldTypes = types(before),
      newTypes = types(after);
    if (JSON.stringify(oldTypes) !== JSON.stringify(newTypes)) {
      const oldNonNull = oldTypes.filter((type) => type !== "null"),
        newNonNull = newTypes.filter((type) => type !== "null");
      if (JSON.stringify(oldNonNull) === JSON.stringify(newNonNull)) {
        const removesNull = oldTypes.includes("null");
        change(
          removesNull,
          path,
          removesNull
            ? "field changed from nullable to non-nullable"
            : "field changed from non-nullable to nullable",
        );
      } else
        change(true, path, `type changed: [${oldTypes.join(", ")}] → [${newTypes.join(", ")}]`);
    }
    for (const type of oldTypes.filter((type) => newTypes.includes(type))) {
      const a = body(before, type),
        b = body(after, type);
      if (!a || !b) {
        if (JSON.stringify(before) !== JSON.stringify(after))
          change(true, path, "complex union changed; review compatibility");
        continue;
      }
      constraints(a, b, path);
      const oldProps = a.properties ?? {},
        newProps = b.properties ?? {};
      const oldRequired = new Set(a.required ?? []),
        newRequired = new Set(b.required ?? []);
      for (const key of newRequired)
        if (!oldRequired.has(key) && !(key in newProps))
          change(true, path ? `${path}.${key}` : key, "field became required");
      for (const key of Object.keys(oldProps)) {
        const child = path ? `${path}.${key}` : key;
        if (!(key in newProps)) {
          change(true, child, "field removed");
          continue;
        }
        if (!oldRequired.has(key) && newRequired.has(key))
          change(true, child, "field became required");
        else if (oldRequired.has(key) && !newRequired.has(key))
          change(false, child, "field became optional");
        compare(oldProps[key], newProps[key], child);
      }
      for (const key of Object.keys(newProps))
        if (!(key in oldProps)) {
          change(
            newRequired.has(key),
            path ? `${path}.${key}` : key,
            newRequired.has(key) ? "required field added" : "field added",
          );
        }
      if (a.items && b.items) compare(a.items, b.items, `${path}[]`);
      else if (!a.items && b.items) change(true, `${path}[]`, "array item validation added");
      else if (a.items && !b.items) change(false, `${path}[]`, "array item validation removed");
    }
  }
  compare(baseline, current, path);
  return result;
}

/**
 * Compare two full snapshots (multiple named schemas).
 */
export function compareSnapshots(baseline: SchemaSnapshot, current: SchemaSnapshot): CompareResult {
  const breaking: SchemaChange[] = [];
  const nonBreaking: SchemaChange[] = [];

  const baseKeys = new Set(Object.keys(baseline.schemas));
  const currKeys = new Set(Object.keys(current.schemas));

  // Removed schemas = breaking
  for (const key of baseKeys) {
    if (!currKeys.has(key)) {
      breaking.push({ path: key, description: "schema removed" });
    }
  }

  // Added schemas = non-breaking
  for (const key of currKeys) {
    if (!baseKeys.has(key)) {
      nonBreaking.push({ path: key, description: "schema added" });
    }
  }

  // Compare shared schemas
  for (const key of baseKeys) {
    if (!currKeys.has(key)) continue;
    const result = compareSchemas(baseline.schemas[key], current.schemas[key], key);
    breaking.push(...result.breaking);
    nonBreaking.push(...result.nonBreaking);
  }

  return { breaking, nonBreaking };
}
