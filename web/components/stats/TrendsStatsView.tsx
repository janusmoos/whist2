"use client";

import { useState } from "react";
import { PlayerBreakdownTable } from "@/components/stats/PlayerBreakdownTable";
import { PlayerLinesChart } from "@/components/stats/PlayerLinesChart";
import { StatsPageShell } from "@/components/stats/StatsPageShell";
import { useClubStats } from "@/hooks/useClubStats";

export function TrendsStatsView() {
  const { model, error, loading } = useClubStats();
  const limit = model?.trends.recentSessionLimit ?? 10;
  const [scope, setScope] = useState<"all" | "recent">("all");

  const scoped = model?.trends.scopedTimelines.find((t) => t.scope === scope);
  const tableRows = scope === "all" ? model?.trends.all : model?.trends.recent;

  const series =
    scoped?.playerSummaries.map((summary, i) => ({
      id: summary.player.id,
      name: summary.player.name,
      colorIndex: i,
      points: scoped.timelinePoints
        .filter((p) => p.playerId === summary.player.id)
        .map((p) => ({ x: p.sessionIndex, y: p.cumulativeScore })),
    })) ?? [];

  return (
    <StatsPageShell
      title="Tendenser"
      lead={`Sammenligning af alle spilledage og seneste ${limit}.`}
    >
      {error ? (
        <div className="banner" role="alert">
          Kan ikke hente data — {error}
        </div>
      ) : null}
      {loading && !model ? <p className="stats-loading">Indlæser…</p> : null}
      {model ? (
        <div className="stats-trends">
          <div className="stats-scope-picker" role="tablist" aria-label="Periode">
            <button
              type="button"
              role="tab"
              aria-selected={scope === "all"}
              className={scope === "all" ? "stats-scope-btn stats-scope-btn--active" : "stats-scope-btn"}
              onClick={() => setScope("all")}
            >
              Alle spilledage
            </button>
            <button
              type="button"
              role="tab"
              aria-selected={scope === "recent"}
              className={
                scope === "recent" ? "stats-scope-btn stats-scope-btn--active" : "stats-scope-btn"
              }
              onClick={() => setScope("recent")}
            >
              Seneste {limit}
            </button>
          </div>

          <section className="stats-panel">
            <h3 className="stats-section-title">Udvikling</h3>
            <PlayerLinesChart
              series={series}
              ariaLabel={`Kumulativ udvikling — ${scope === "all" ? "alle dage" : `seneste ${limit}`}`}
              height={170}
              xLabel="Spilledag"
            />
          </section>

          <section className="stats-trends-block">
            <h3 className="stats-section-title">
              {scope === "all" ? "Alle spilledage" : `Seneste ${limit} spilledage`}
            </h3>
            <PlayerBreakdownTable
              rows={(tableRows ?? []).map((row) => ({
                name: row.player.name,
                gamesPlayed: row.gamesPlayed,
                averageScore: row.averageScore,
                totalScore: row.totalScore,
              }))}
            />
          </section>
        </div>
      ) : null}
    </StatsPageShell>
  );
}
