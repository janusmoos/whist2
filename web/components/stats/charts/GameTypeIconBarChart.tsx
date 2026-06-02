"use client";

import { GameTypeIcon } from "@/components/GameTypeIcon";
import { ChartReveal, chartStagger } from "@/components/stats/charts/ChartReveal";
import type { GameTypeIconKind } from "@/lib/stats/gameTypeIcons";

export function GameTypeIconBarChart({
  slices,
  title = "Spiltyper efter antal",
}: {
  slices: { title: string; count: number; iconKind: GameTypeIconKind }[];
  title?: string;
}) {
  if (slices.length === 0) {
    return <p className="stats-chart-empty">Ingen registrerede spiltyper på dagen.</p>;
  }

  const maxCount = Math.max(...slices.map((s) => s.count), 1);

  return (
    <ChartReveal className="stats-gametype-icon-bar">
      <h4 className="stats-chart-subtitle">{title}</h4>
      <ul className="stats-gametype-icon-bar-list">
        {slices.map((slice, i) => (
          <li key={slice.title} className="stats-gametype-icon-bar-row" style={chartStagger(i)}>
            <span className="stats-gametype-icon-bar-icon" aria-hidden>
              <GameTypeIcon kind={slice.iconKind} />
            </span>
            <div className="stats-gametype-icon-bar-track">
              <div
                className="stats-gametype-icon-bar-fill"
                style={{ width: `${(slice.count / maxCount) * 100}%` }}
              />
            </div>
            <span className="stats-gametype-icon-bar-count">{slice.count}</span>
          </li>
        ))}
      </ul>
    </ChartReveal>
  );
}
