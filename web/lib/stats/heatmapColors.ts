/** Heatmap-cellefarve — grøn/rød intensitet efter score relativt til maxAbs. */
export function heatmapCellBackground(score: number, maxAbs: number): string {
  if (score === 0 || maxAbs <= 0) {
    return "color-mix(in srgb, var(--border) 35%, transparent)";
  }
  const intensity = Math.min(1, Math.abs(score) / maxAbs);
  const mix = Math.round(intensity * 70 + 10);
  if (score > 0) {
    return `color-mix(in srgb, var(--score-pos) ${mix}%, transparent)`;
  }
  return `color-mix(in srgb, var(--score-neg) ${mix}%, transparent)`;
}
