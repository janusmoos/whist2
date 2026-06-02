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

export function DonutChart({
  slices,
  title,
}: {
  slices: { label: string; value: number; color?: string }[];
  title?: string;
}) {
  const total = slices.reduce((s, x) => s + x.value, 0) || 1;
  let offset = 0;
  const r = 42;
  const c = 2 * Math.PI * r;

  return (
    <ChartReveal className="stats-donut-wrap">
      {title ? <h4 className="stats-chart-subtitle">{title}</h4> : null}
      <div className="stats-donut-row">
        <svg viewBox="0 0 100 100" className="stats-donut" role="img" aria-label={title ?? "Fordeling"}>
          <circle cx="50" cy="50" r={r} fill="none" stroke="var(--border-hi)" strokeWidth="14" />
          {slices.map((slice, i) => {
            const len = (slice.value / total) * c;
            const dash = `${len} ${c - len}`;
            const el = (
              <circle
                key={slice.label}
                className="stats-donut-slice"
                cx="50"
                cy="50"
                r={r}
                fill="none"
                stroke={slice.color ?? chartSeriesColor(i)}
                strokeWidth="14"
                strokeDasharray={dash}
                strokeDashoffset={-offset}
                transform="rotate(-90 50 50)"
                style={
                  {
                    ...chartStagger(i),
                    "--donut-c": c,
                  } as CSSProperties
                }
              />
            );
            offset += len;
            return el;
          })}
        </svg>
        <ul className="stats-donut-legend">
          {slices.map((slice, i) => (
            <li key={slice.label} style={chartStagger(i)}>
              <span
                className="session-stats-chart-swatch"
                style={{ background: slice.color ?? chartSeriesColor(i) }}
              />
              {slice.label} ({slice.value})
            </li>
          ))}
        </ul>
      </div>
    </ChartReveal>
  );
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
