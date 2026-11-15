/** Alle spillere har samme antal spil (typisk i Whist — alle deltager i hvert spil). */
export function perPlayerGameCountsUniform(counts: number[]): boolean {
  if (counts.length <= 1) return true;
  return counts.every((n) => n === counts[0]);
}

/** Vis «Spil»-kolonne kun når antallet faktisk varierer mellem spillere. */
export function shouldShowPerPlayerGameCounts(counts: number[]): boolean {
  return counts.length > 0 && !perPlayerGameCountsUniform(counts);
}
