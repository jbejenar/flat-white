import { describe, expect, it } from "vitest";
import { PidLedger, comparePidLedgers, DIAGNOSTIC_LIMIT } from "../../src/pid-ledger.js";

describe("disk-backed PID reconciliation", () => {
  it("detects equal-count substitution, missing records and duplicates exactly", async () => {
    const expected = await PidLedger.create();
    const actual = await PidLedger.create();
    try {
      for (const pid of ["c", "b", "a"]) await expected.add(pid);
      for (const pid of ["b", "x", "b"]) await actual.add(pid);
      expect((await expected.finish()).duplicateCount).toBe(0);
      expect(await actual.finish()).toMatchObject({
        count: 3,
        duplicateCount: 1,
        duplicatePids: ["b"],
      });
      expect(await comparePidLedgers(expected, actual)).toEqual({
        missing: 2,
        unexpected: 2,
        missingSamples: ["a", "c"],
        unexpectedSamples: ["b", "x"],
      });
    } finally {
      await expected.close();
      await actual.close();
    }
  });

  it("sorts independently of source order and escapes separators losslessly", async () => {
    const expected = await PidLedger.create();
    const actual = await PidLedger.create();
    try {
      const values = ["ä", "a\nb", "a", "b", "a\t"];
      for (const pid of values) await expected.add(pid);
      for (const pid of [...values].reverse()) await actual.add(pid);
      expect(await actual.finish()).toEqual(await expected.finish());
      expect(await comparePidLedgers(expected, actual)).toMatchObject({
        missing: 0,
        unexpected: 0,
      });
    } finally {
      await expected.close();
      await actual.close();
    }
  });

  it("bounds diagnostic samples while preserving exact totals", async () => {
    const ledger = await PidLedger.create();
    try {
      for (let i = 0; i < 1000; i++) await ledger.add("repeated");
      const result = await ledger.finish();
      expect(result.count).toBe(1000);
      expect(result.duplicateCount).toBe(999);
      expect(result.duplicatePids).toHaveLength(DIAGNOSTIC_LIMIT);
    } finally {
      await ledger.close();
    }
  });
});
