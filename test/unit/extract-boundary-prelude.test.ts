import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

import { extractBoundaryPrelude } from "../../scripts/extract-boundary-prelude.mjs";

const prepSqlPath = resolve(process.cwd(), "sql", "address_full_prep.sql");

describe("extractBoundaryPrelude", () => {
  it("returns the reusable boundary prelude without relying on line numbers", () => {
    const sqlText = readFileSync(prepSqlPath, "utf8");
    const prelude = extractBoundaryPrelude(sqlText);

    expect(prelude).toContain("CREATE SCHEMA IF NOT EXISTS admin_bdys___SCHEMA_VERSION__;");
    expect(prelude).toContain(
      "DROP TABLE gnaf___SCHEMA_VERSION__.address_principal_admin_boundaries CASCADE;",
    );
    expect(prelude).toContain(
      "CREATE UNIQUE INDEX IF NOT EXISTS address_principal_admin_boundaries_gnaf_pid_uniq",
    );
    expect(prelude).not.toContain("FIXTURE_BOUNDARY_PRELUDE_START");
    expect(prelude).not.toContain("FIXTURE_BOUNDARY_PRELUDE_END");
    expect(prelude).not.toContain("tmp_best_geocode");
  });

  it("fails fast when the SQL markers are missing", () => {
    expect(() => extractBoundaryPrelude("SELECT 1;\n")).toThrow(/Missing start marker/);
  });
});
