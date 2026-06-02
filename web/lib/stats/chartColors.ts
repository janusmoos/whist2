/** Diagram-serier — CSS-variabler defineret i globals.css (Summer Reader / Tropica Summer-inspireret). */
export const CHART_SERIES_COLORS = [
  "var(--chart-1)",
  "var(--chart-2)",
  "var(--chart-3)",
  "var(--chart-4)",
  "var(--chart-5)",
  "var(--chart-6)",
] as const;

export function chartSeriesColor(index: number): string {
  return CHART_SERIES_COLORS[((index % CHART_SERIES_COLORS.length) + CHART_SERIES_COLORS.length) % CHART_SERIES_COLORS.length];
}

/** Spillercanvas — alias til de første fire serier (displayOrder). */
export const PLAYER_LINE_COLORS = CHART_SERIES_COLORS.slice(0, 4);
