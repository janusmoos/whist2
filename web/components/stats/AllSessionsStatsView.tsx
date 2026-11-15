"use client";

import Link from "next/link";
import {
  DivergingBarChart,
  HeatmapChart,
  RankDistributionChart,
} from "@/components/stats/charts/StatsCharts";
import { StatsPageShell } from "@/components/stats/StatsPageShell";
import { scoreClass, scoreLabel } from "@/lib/stats/format";
import { sessionDisplayTitle } from "@/lib/stats/historicalEngine";
import { sessionPath } from "@/lib/stats/paths";
import { useClubStats } from "@/hooks/useClubStats";

export function AllSessionsStatsView() {
  const { model, error, loading } = useClubStats();

  const players = model?.hub.playerSummaries.map((s) => s.player) ?? [];
  const playerNames = Object.fromEntries(players.map((p) => [p.id, p.name]));
  const sessionIndices = model?.sessions.map((s) => s.sessionIndex) ?? [];

  const divergingRows =
    model?.sessionDayOutcomes.map((o, i) => ({
      label: o.playerName,
      left: o.losses,
      right: o.wins,
      colorIndex: i,
    })) ?? [];

  return (
    <StatsPageShell
      title="Alle spilledage"
      lead="Heatmap, placeringer og detaljer for hver historisk spilledag."
    >
      {error ? (
        <div className="banner" role="alert">
          Kan ikke hente data — {error}
        </div>
      ) : null}
      {loading && !model ? <p className="stats-loading">Indlæser…</p> : null}
      {model ? (
        <>
          <section className="stats-panel">
            <HeatmapChart
              title="Point pr. spiller og spilledag"
              players={players}
              sessionIndices={sessionIndices}
              cells={model.heatmap}
            />
          </section>

          <section className="stats-panel">
            <RankDistributionChart
              title="Placeringer pr. spilledag"
              rows={model.rankDistribution}
              playerNames={playerNames}
              playerOrder={players.map((p) => p.id)}
            />
          </section>

          <section className="stats-panel">
            <DivergingBarChart
              title="Samlet tab / gevinst på tværs af alle dage"
              rows={divergingRows}
            />
          </section>

          <div className="stats-list">
            {[...model.sessions].reverse().map((overview) => (
              <Link
                key={overview.session.id}
                href={sessionPath(overview.sessionIndex)}
                className="stats-session-card stats-session-card--link"
              >
                <header className="stats-session-card-head">
                  <h3 className="stats-session-card-title">
                    Spilledag {overview.session.sessionNumber}
                  </h3>
                  <span className="stats-session-card-meta">
                    {overview.gamesPlayed} spil →
                  </span>
                </header>
                <p className="stats-session-card-sub">
                  {sessionDisplayTitle(overview.session)}
                </p>
                <div className="stats-session-scores">
                  {overview.playerTotals.map((row, i) => (
                    <div key={row.player.id} className="stats-session-score-row">
                      <span
                        className="stats-session-score-name"
                        style={{ borderColor: `var(--stats-line-${i + 1})` }}
                      >
                        {row.player.name}
                      </span>
                      <span className={`stats-session-score-val${scoreClass(row.score)}`}>
                        {scoreLabel(row.score)}
                      </span>
                    </div>
                  ))}
                </div>
                {overview.issueCount > 0 ? (
                  <p className="stats-session-issues">
                    {overview.issueCount} spil med datakvalitets-flag
                  </p>
                ) : null}
              </Link>
            ))}
          </div>
        </>
      ) : null}
    </StatsPageShell>
  );
}
