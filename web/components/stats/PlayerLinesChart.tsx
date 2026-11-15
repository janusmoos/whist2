"use client";

import { ChartReveal, chartStagger } from "@/components/stats/charts/ChartReveal";
import { PLAYER_LINE_COLORS } from "@/lib/stats/chartColors";

export type ChartLineSeries = {
  id: string;
  name: string;
  colorIndex: number;
  points: { x: number; y: number }[];
};

export function playerColorIndex(playerId: string, orderedIds: string[]): number {
  const idx = orderedIds.indexOf(playerId);
  return idx >= 0 ? idx : 0;
}

export function PlayerLinesChart({
  series,
  xLabel,
  ariaLabel,
  height = 136,
  showLegend = true,
  labelColumn,
}: {
  series: ChartLineSeries[];
  xLabel?: string;
  ariaLabel: string;
  height?: number;
  showLegend?: boolean;
  labelColumn?: { name: string; score: number; colorIndex: number }[];
}) {
  if (series.every((s) => s.points.length === 0)) return null;

  const allValues = series.flatMap((s) => s.points.map((p) => p.y));
  const allX = series.flatMap((s) => s.points.map((p) => p.x));
  const minY = Math.min(0, ...allValues);
  const maxY = Math.max(0, ...allValues);
  const rangeY = maxY - minY || 1;
  const minX = Math.min(...allX);
  const maxX = Math.max(...allX);
  const rangeX = maxX - minX || 1;

  const width = 360;
  const labelW = labelColumn ? 96 : 0;
  const totalW = width + labelW + (labelColumn ? 12 : 0);
  const padX = 10;
  const padY = 12;
  const chartW = width - padX * 2;
  const chartH = height - padY * 2;

  const xAt = (x: number) =>
    rangeX === 0 ? padX + chartW / 2 : padX + ((x - minX) / rangeX) * chartW;

  const yAt = (y: number) => padY + chartH - ((y - minY) / rangeY) * chartH;
  const zeroY = yAt(0);

  return (
    <ChartReveal className="player-lines-chart">
      {xLabel ? <p className="player-lines-chart-xlabel">{xLabel}</p> : null}
      <div className="player-lines-chart-row">
        <svg
          className="player-lines-chart-svg"
          viewBox={`0 0 ${width} ${height}`}
          role="img"
          aria-label={ariaLabel}
        >
          <line
            x1={padX}
            y1={zeroY}
            x2={width - padX}
            y2={zeroY}
            className="session-stats-chart-zero"
          />
          {series.map((line) => {
            if (line.points.length === 0) return null;
            const points = line.points.map((p) => `${xAt(p.x)},${yAt(p.y)}`).join(" ");
            return (
              <polyline
                key={line.id}
                points={points}
                pathLength={100}
                className="session-stats-chart-line"
                style={{
                  stroke: PLAYER_LINE_COLORS[line.colorIndex % 4],
                  ...chartStagger(line.colorIndex),
                }}
              />
            );
          })}
        </svg>
        {labelColumn ? (
          <div className="player-lines-chart-labels" aria-hidden="true">
            {labelColumn.map((row) => (
              <div
                key={row.name}
                className="player-lines-chart-label"
                style={{
                  color: PLAYER_LINE_COLORS[row.colorIndex % 4],
                  ...chartStagger(row.colorIndex),
                }}
              >
                {row.name} {row.score > 0 ? `+${row.score}` : row.score}
              </div>
            ))}
          </div>
        ) : null}
      </div>
      {showLegend ? (
        <ul className="session-stats-chart-legend">
          {series.map((line) => (
            <li key={line.id} style={chartStagger(line.colorIndex)}>
              <span
                className="session-stats-chart-swatch"
                style={{ background: PLAYER_LINE_COLORS[line.colorIndex % 4] }}
                aria-hidden="true"
              />
              {line.name}
            </li>
          ))}
        </ul>
      ) : null}
    </ChartReveal>
  );
}

export function timelineToSeries(
  timelinePoints: {
    playerId: string;
    playerName: string;
    sessionIndex: number;
    cumulativeScore: number;
  }[],
  playerOrder: string[]
): ChartLineSeries[] {
  const byPlayer = new Map<string, { x: number; y: number }[]>();
  for (const p of timelinePoints) {
    (byPlayer.get(p.playerId) ?? byPlayer.set(p.playerId, []).get(p.playerId))!.push({
      x: p.sessionIndex,
      y: p.cumulativeScore,
    });
  }

  return playerOrder.map((playerId) => {
    const first = timelinePoints.find((p) => p.playerId === playerId);
    return {
      id: playerId,
      name: first?.playerName ?? playerId,
      colorIndex: playerColorIndex(playerId, playerOrder),
      points: byPlayer.get(playerId) ?? [],
    };
  });
}
