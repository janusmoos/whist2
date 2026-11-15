"use client";

import Link from "next/link";
import { DonutChart } from "@/components/stats/charts/StatsCharts";
import { GameTypeIconBarChart } from "@/components/stats/charts/GameTypeIconBarChart";
import { GameTypeCell } from "@/components/stats/GameTypeCell";
import { GameTypePlayerTable } from "@/components/stats/PlayerBreakdownTable";
import { StatsPageShell } from "@/components/stats/StatsPageShell";
import { gameTypePath } from "@/lib/stats/paths";
import { gameTypeIconKindFromLabel } from "@/lib/stats/gameTypeIcons";
import { gameTypeChartColor } from "@/lib/stats/chartColors";
import { useClubStats } from "@/hooks/useClubStats";

export function GameTypesStatsView() {
  const { model, error, loading } = useClubStats();

  const overviewDonut =
    model?.gameTypes.map((row) => ({
      label: row.gameType,
      value: row.games,
      color: gameTypeChartColor(row.gameType),
    })) ?? [];

  return (
    <StatsPageShell
      title="Spiltyper"
      lead="Fordeling og point pr. spiltype — tryk for detaljer."
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
            <DonutChart title="Antal spil pr. type" slices={overviewDonut} />
          </section>

          <section className="stats-panel">
            <GameTypeIconBarChart
              title="Spil pr. type"
              slices={model.gameTypes.map((row) => ({
                title: row.gameType,
                count: row.games,
                iconKind: gameTypeIconKindFromLabel(row.gameType),
                color: gameTypeChartColor(row.gameType),
              }))}
            />
          </section>

          <div className="stats-list">
            {model.gameTypes.map((row) => (
              <Link
                key={row.gameType}
                href={gameTypePath(row.gameType)}
                className="stats-gametype-card stats-gametype-card--link"
              >
                <header className="stats-gametype-head">
                  <h3 className="stats-gametype-title">
                    <GameTypeCell
                      label={row.gameType}
                      iconKind={gameTypeIconKindFromLabel(row.gameType)}
                      showLabel
                    />
                  </h3>
                  <span className="stats-gametype-count">{row.games} spil →</span>
                </header>
                <GameTypePlayerTable
                  rows={row.playerTotals.map((p) => ({
                    playerId: p.player.id,
                    name: p.player.name,
                    games: p.games,
                    averageScore: p.averageScore,
                    totalScore: p.totalScore,
                  }))}
                />
              </Link>
            ))}
          </div>
        </>
      ) : null}
    </StatsPageShell>
  );
}
