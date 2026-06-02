/** Diagram-serier — CSS-variabler defineret i globals.css (Summer Reader / Tropica Summer-inspireret). */
export const CHART_SERIES_COLORS = [
  "var(--chart-1)",
  "var(--chart-2)",
  "var(--chart-3)",
  "var(--chart-4)",
  "var(--chart-5)",
  "var(--chart-6)",
  "var(--chart-7)",
  "var(--chart-8)",
  "var(--chart-9)",
  "var(--chart-10)",
  "var(--chart-11)",
  "var(--chart-12)",
] as const;

export function chartSeriesColor(index: number): string {
  return CHART_SERIES_COLORS[((index % CHART_SERIES_COLORS.length) + CHART_SERIES_COLORS.length) % CHART_SERIES_COLORS.length];
}

/** Spillercanvas — alias til de første fire serier (displayOrder). */
export const PLAYER_LINE_COLORS = CHART_SERIES_COLORS.slice(0, 4);

/** Fast farve pr. kanonisk spiltype — uafhængig af sortering i diagrammer. */
const GAME_TYPE_COLOR_INDEX: Record<string, number> = {
  VIP: 0,
  Halve: 1,
  "Ren sol": 2,
  Sol: 3,
  Gode: 4,
  Almindelige: 5,
  Sans: 6,
  "Halv bordlægger": 7,
  Bordlægger: 8,
  Duestraf: 9,
};

export function gameTypeChartColor(gameTypeLabel: string): string {
  const idx = GAME_TYPE_COLOR_INDEX[gameTypeLabel.trim()];
  return chartSeriesColor(idx ?? 11);
}
