/** Audited August 2026 OT source exceptions, not tolerances for later editions. */
export const AUGUST_2026_OT = {
  count: 3805,
  missingFederalPids: ["GAOT_720637896", "GAOT_720637906"],
  federalCounts: { BEAN: 2166, FENNER: 182, LINGIARI: 1455 },
} as const;

export function checkAugustOtFederal(
  count: number,
  missingPids: string[],
  federalCounts: Record<string, number>,
): boolean {
  return (
    count === AUGUST_2026_OT.count &&
    JSON.stringify([...missingPids].sort()) === JSON.stringify(AUGUST_2026_OT.missingFederalPids) &&
    Object.keys(federalCounts).length === 3 &&
    Object.entries(AUGUST_2026_OT.federalCounts).every(
      ([name, expected]) => federalCounts[name] === expected,
    )
  );
}
