"use client";

import { chartSeriesColor } from "@/lib/stats/chartColors";
import { ChartReveal, chartStagger } from "@/components/stats/charts/ChartReveal";
import type { CSSProperties } from "react";
import { heatmapCellBackground } from "@/lib/stats/heatmapColors";

export function DivergingBarChart({
  rows,
  title,
  emptyText = "Ingen data.",
}: {
  rows: { label: string; left: number; right: number; colorIndex?: number }[];
  title?: string;
  emptyText?: string;
}) {
  if (rows.length === 0) {
    return <p className="stats-chart-empty">{emptyText}</p>;
  }

  const maxVal = Math.max(1, ...rows.flatMap((r) => [r.left, r.right]));

  return (
    <ChartReveal className="stats-diverging">
      {title ? <h4 className="stats-chart-subtitle">{title}</h4> : null}
      <ul className="stats-diverging-list">
        {rows.map((row, i) => (
          <li key={row.label} className="stats-diverging-row" style={chartStagger(i)}>
            <span className="stats-diverging-label">{row.label}</span>
            <div className="stats-diverging-bars">
              <div className="stats-diverging-half stats-diverging-half--left">
                <div
                  className="stats-diverging-fill stats-diverging-fill--neg"
                  style={{ width: `${(row.left / maxVal) * 100}%` }}
                />
              </div>
              <div className="stats-diverging-half stats-diverging-half--right">
                <div
                  className="stats-diverging-fill stats-diverging-fill--pos"
                  style={{ width: `${(row.right / maxVal) * 100}%` }}
                />
              </div>
            </div>
            <span className="stats-diverging-nums">
              <span className="score--neg">{row.left}</span>
              {" / "}
              <span className="score--pos">{row.right}</span>
            </span>
          </li>
        ))}
      </ul>
    </ChartReveal>
  );
}

export function HeatmapChart({
  players,
  sessionIndices,
  cells,
  title,
}: {
  players: { id: string; name: string }[];
  sessionIndices: number[];
  cells: { playerId: string; sessionIndex: number; score: number }[];
  title?: string;
}) {
  const lookup = new Map(cells.map((c) => [`${c.playerId}:${c.sessionIndex}`, c.score]));
  const maxAbs = Math.max(1, ...cells.map((c) => Math.abs(c.score)));

  return (
    <ChartReveal className="stats-heatmap-wrap">
      {title ? <h4 className="stats-chart-subtitle">{title}</h4> : null}
      <div className="stats-heatmap-scroll">
        <table className="stats-heatmap">
          <thead>
            <tr>
              <th />
              {sessionIndices.map((idx) => (
                <th key={idx}>{idx}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {players.map((player, pi) => (
              <tr key={player.id}>
                <th scope="row">{player.name}</th>
                {sessionIndices.map((idx, si) => {
                  const score = lookup.get(`${player.id}:${idx}`) ?? 0;
                  return (
                    <td
                      key={idx}
                      style={{
                        background: heatmapCellBackground(score, maxAbs),
                        ...chartStagger(pi * sessionIndices.length + si),
                      }}
                      title={`${score > 0 ? "+" : ""}${score}`}
                    >
                      {Math.abs(score) >= maxAbs * 0.55 ? (score > 0 ? `+${score}` : score) : ""}
                    </td>
                  );
                })}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </ChartReveal>
  );
}

const PIE_VIEW_BOX = "-16 -16 132 132";
const PIE_CX = 50;
const PIE_CY = 50;
const PIE_R = 24;
const PIE_LABEL_MIN_Y = 12;
const PIE_LABEL_MAX_Y = 88;
const PIE_RAIL_LEFT = 22;
const PIE_RAIL_RIGHT = 78;
const PIE_TEXT_LEFT = 9;
const PIE_TEXT_RIGHT = 91;

export function DonutChart({
  slices,
  title,
}: {
  slices: { label: string; value: number; color?: string }[];
  title?: string;
}) {
  const total = slices.reduce((s, x) => s + x.value, 0) || 1;
  const labelFontSize = Math.max(2.65, 3.25 - Math.max(0, slices.length - 5) * 0.12);

  const enriched = slices.map((slice, i) => ({
    ...slice,
    color: slice.color ?? chartSeriesColor(i),
  }));

  let angle = -Math.PI / 2;
  const pieSlices = enriched.map((slice) => {
    const sweep = (slice.value / total) * Math.PI * 2;
    const start = angle;
    const end = angle + sweep;
    angle = end;
    return { ...slice, start, end, mid: (start + end) / 2 };
  });

  const callouts = layoutPieCallouts(pieSlices);

  return (
    <ChartReveal className="stats-donut-wrap stats-pie-wrap">
      {title ? <h4 className="stats-chart-subtitle stats-pie-subtitle">{title}</h4> : null}
      <div className="stats-pie-layout">
        <svg
          viewBox={PIE_VIEW_BOX}
          className="stats-pie"
          role="img"
          aria-label={title ?? "Fordeling"}
          style={{ "--pie-label-size": `${labelFontSize}px` } as CSSProperties}
        >
          {pieSlices.map((slice, i) => (
            <path
              key={slice.label}
              className="stats-pie-slice"
              d={pieSlicePath(PIE_CX, PIE_CY, PIE_R, slice.start, slice.end)}
              fill={slice.color}
              stroke="var(--stats-surface)"
              strokeWidth={0.6}
              style={chartStagger(i)}
            >
              <title>
                {slice.label}: {slice.value}
              </title>
            </path>
          ))}
          {callouts.map((callout, i) => (
            <g
              key={`callout-${callout.label}`}
              className="stats-pie-callout"
              style={chartStagger(i)}
            >
              <polyline
                className="stats-pie-callout-line"
                points={callout.linePoints}
                stroke={callout.color}
              />
              <circle
                className="stats-pie-callout-dot"
                cx={callout.xEdge}
                cy={callout.yEdge}
                r={0.7}
                fill={callout.color}
              />
              <text
                x={callout.xText}
                y={callout.y}
                textAnchor={callout.isRight ? "start" : "end"}
                dominantBaseline="middle"
                className="stats-pie-callout-label"
              >
                {callout.label} ({callout.value})
              </text>
            </g>
          ))}
        </svg>
      </div>
    </ChartReveal>
  );
}

type PieSliceWithAngles = {
  label: string;
  value: number;
  color: string;
  start: number;
  end: number;
  mid: number;
};

type PieCallout = PieSliceWithAngles & {
  isRight: boolean;
  xEdge: number;
  yEdge: number;
  xRail: number;
  y: number;
  xLineEnd: number;
  xText: number;
  linePoints: string;
};

function layoutPieCallouts(pieSlices: PieSliceWithAngles[]): PieCallout[] {
  const callouts: PieCallout[] = pieSlices.map((slice) => {
    const cos = Math.cos(slice.mid);
    const sin = Math.sin(slice.mid);
    const isRight = cos >= 0;
    const xEdge = PIE_CX + PIE_R * cos;
    const yEdge = PIE_CY + PIE_R * sin;
    const xRail = isRight ? PIE_RAIL_RIGHT : PIE_RAIL_LEFT;
    const xText = isRight ? PIE_TEXT_RIGHT : PIE_TEXT_LEFT;
    const xLineEnd = isRight ? xText - 1.5 : xText + 1.5;

    return {
      ...slice,
      isRight,
      xEdge,
      yEdge,
      xRail,
      y: yEdge,
      xLineEnd,
      xText,
      linePoints: "",
    };
  });

  distributeCalloutYs(
    callouts.filter((c) => c.isRight),
    PIE_LABEL_MIN_Y,
    PIE_LABEL_MAX_Y
  );
  distributeCalloutYs(
    callouts.filter((c) => !c.isRight),
    PIE_LABEL_MIN_Y,
    PIE_LABEL_MAX_Y
  );

  for (const callout of callouts) {
    callout.linePoints = `${callout.xEdge},${callout.yEdge} ${callout.xRail},${callout.yEdge} ${callout.xRail},${callout.y} ${callout.xLineEnd},${callout.y}`;
  }

  return callouts;
}

function distributeCalloutYs(group: PieCallout[], minY: number, maxY: number) {
  if (group.length === 0) return;

  const sorted = [...group].sort((a, b) => a.yEdge - b.yEdge);
  const minGap = Math.min(5.75, (maxY - minY) / Math.max(sorted.length, 1));
  const ys = sorted.map((c) => clamp(c.yEdge, minY, maxY));

  for (let i = 1; i < sorted.length; i++) {
    ys[i] = Math.max(ys[i], ys[i - 1] + minGap);
  }
  for (let i = sorted.length - 2; i >= 0; i--) {
    ys[i] = Math.min(ys[i], ys[i + 1] - minGap);
  }

  if (ys[sorted.length - 1] > maxY) {
    const shift = ys[sorted.length - 1] - maxY;
    for (let i = 0; i < ys.length; i++) ys[i] -= shift;
  }
  if (ys[0] < minY) {
    const shift = minY - ys[0];
    for (let i = 0; i < ys.length; i++) ys[i] += shift;
  }

  sorted.forEach((callout, i) => {
    callout.y = ys[i];
  });
}

function clamp(value: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, value));
}

function polarToCartesian(cx: number, cy: number, r: number, angleRad: number) {
  return {
    x: cx + r * Math.cos(angleRad),
    y: cy + r * Math.sin(angleRad),
  };
}

function pieSlicePath(
  cx: number,
  cy: number,
  r: number,
  startAngle: number,
  endAngle: number
): string {
  const sweep = endAngle - startAngle;
  if (sweep >= Math.PI * 2 - 1e-6) {
    return [
      `M ${cx - r} ${cy}`,
      `A ${r} ${r} 0 1 1 ${cx + r} ${cy}`,
      `A ${r} ${r} 0 1 1 ${cx - r} ${cy}`,
      "Z",
    ].join(" ");
  }

  const start = polarToCartesian(cx, cy, r, startAngle);
  const end = polarToCartesian(cx, cy, r, endAngle);
  const largeArc = sweep > Math.PI ? 1 : 0;
  return `M ${cx} ${cy} L ${start.x} ${start.y} A ${r} ${r} 0 ${largeArc} 1 ${end.x} ${end.y} Z`;
}

export const RANK_PLACE_COLORS = [
  "var(--rank-place-1)",
  "var(--rank-place-2)",
  "var(--rank-place-3)",
  "var(--rank-place-4)",
] as const;

export const RANK_PLACE_LABELS = ["1. plads", "2. plads", "3. plads", "4. plads"] as const;
export const RANK_PLACE_SHORT = ["1.", "2.", "3.", "4."] as const;

export function RankDistributionChart({
  rows,
  playerNames,
  playerOrder,
  title,
}: {
  rows: { playerId: string; ranks: [number, number, number, number] }[];
  playerNames: Record<string, string>;
  /** Spillere i ønsket visningsrækkefølge (fx displayOrder). */
  playerOrder?: string[];
  title?: string;
}) {
  if (rows.length === 0) {
    return <p className="stats-chart-empty">Ingen placeringsdata endnu.</p>;
  }

  const orderIndex = new Map((playerOrder ?? []).map((id, i) => [id, i]));
  const chartRows = rows
    .map((row) => {
      const name = playerNames[row.playerId] ?? row.playerId;
      const total = row.ranks.reduce((sum, count) => sum + count, 0);
      return { id: row.playerId, name, ranks: row.ranks, total };
    })
    .sort((a, b) => {
      const ai = orderIndex.get(a.id);
      const bi = orderIndex.get(b.id);
      if (ai != null && bi != null && ai !== bi) return ai - bi;
      if (ai != null && bi == null) return -1;
      if (ai == null && bi != null) return 1;
      return a.name.localeCompare(b.name, "da");
    });

  return (
    <ChartReveal className="stats-rank-bars">
      {title ? <h4 className="stats-chart-subtitle">{title}</h4> : null}

      <ul className="stats-rank-bars-list">
        {chartRows.map((row, rowIndex) => {
          const ariaLabel = `${row.name}: ${RANK_PLACE_LABELS.map(
            (label, i) => `${label} ${row.ranks[i]}`
          ).join(", ")}`;

          return (
            <li key={row.id} className="stats-rank-bars-row" style={chartStagger(rowIndex)}>
              <span className="stats-rank-bars-label">{row.name}</span>
              <div className="stats-rank-bars-track" role="img" aria-label={ariaLabel}>
                {row.ranks.map((count, rankIndex) => (
                  <div
                    key={rankIndex}
                    className={`stats-rank-bars-seg${count === 0 ? " stats-rank-bars-seg--empty" : ""}`}
                    style={{
                      flex: count === 0 ? "0 0 2px" : `${count} 1 0`,
                      minWidth: count === 0 ? "2px" : "7px",
                      background: RANK_PLACE_COLORS[rankIndex],
                      opacity: count === 0 ? 0.16 : 0.82,
                      ...chartStagger(rowIndex),
                      "--seg-stagger": rankIndex,
                    } as CSSProperties}
                    title={`${RANK_PLACE_LABELS[rankIndex]}: ${count}`}
                  />
                ))}
              </div>
              <span className="stats-rank-bars-total">{row.total}</span>
            </li>
          );
        })}
      </ul>

      <ul className="stats-rank-bars-legend">
        {RANK_PLACE_SHORT.map((label, i) => (
          <li key={label} style={chartStagger(i)}>
            <span
              className="stats-rank-bars-swatch"
              style={{ background: RANK_PLACE_COLORS[i] }}
              aria-hidden
            />
            {label}
          </li>
        ))}
      </ul>
    </ChartReveal>
  );
}

export function HorizontalBarChart({
  rows,
  title,
}: {
  rows: { label: string; value: number; colorIndex?: number }[];
  title?: string;
}) {
  const max = Math.max(1, ...rows.map((r) => r.value));
  return (
    <ChartReveal className="stats-hbar">
      {title ? <h4 className="stats-chart-subtitle">{title}</h4> : null}
      <ul className="stats-hbar-list">
        {rows.map((row, i) => (
          <li key={row.label} style={chartStagger(i)}>
            <span className="stats-hbar-label">{row.label}</span>
            <div className="stats-hbar-track">
              <div
                className="stats-hbar-fill"
                style={{
                  width: `${(row.value / max) * 100}%`,
                  background: chartSeriesColor(row.colorIndex ?? i),
                }}
              />
            </div>
            <span className="stats-hbar-val">{row.value}</span>
          </li>
        ))}
      </ul>
    </ChartReveal>
  );
}

export function WinRateChart({
  rows,
  title,
}: {
  rows: { label: string; wins: number; losses: number; zeros: number }[];
  title?: string;
}) {
  return (
    <ChartReveal className="stats-winrate">
      {title ? <h4 className="stats-chart-subtitle">{title}</h4> : null}
      <ul className="stats-winrate-list">
        {rows.map((row, i) => {
          const total = row.wins + row.losses + row.zeros || 1;
          const winPct = (row.wins / total) * 100;
          const lossPct = (row.losses / total) * 100;
          return (
            <li key={row.label} style={chartStagger(i)}>
              <span className="stats-winrate-label">{row.label}</span>
              <div className="stats-winrate-track">
                <div className="stats-winrate-pos" style={{ width: `${winPct}%` }} />
                <div className="stats-winrate-neg" style={{ width: `${lossPct}%` }} />
              </div>
              <span className="stats-winrate-pct">{Math.round(winPct)}%</span>
            </li>
          );
        })}
      </ul>
    </ChartReveal>
  );
}
