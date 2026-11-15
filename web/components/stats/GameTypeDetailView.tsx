"use client";

import Link from "next/link";
import { DonutChart, HorizontalBarChart } from "@/components/stats/charts/StatsCharts";
import { GameTypeCell } from "@/components/stats/GameTypeCell";
import { GameTypePlayerTable } from "@/components/stats/PlayerBreakdownTable";
import { StatsPageShell } from "@/components/stats/StatsPageShell";
import { shouldShowPerPlayerGameCounts } from "@/lib/stats/displayHelpers";
import { gameTypeIconKindFromLabel } from "@/lib/stats/gameTypeIcons";
import { useClubStats } from "@/hooks/useClubStats";
import { decodeGameTypeSlug, gamePath } from "@/lib/stats/paths";

export function GameTypeDetailView({ slug }: { slug: string }) {
  const gameType = decodeGameTypeSlug(slug);
  const { model, error, loading } = useClubStats();
  const overview = model?.gameTypes.find((g) => g.gameType === gameType);

  const playerGameCounts = overview?.playerTotals.map((p) => p.games) ?? [];
  const showGameCountDonut = shouldShowPerPlayerGameCounts(playerGameCounts);

  const topGames =
    model && overview
      ? Object.entries(model.games)
          .filter(([, g]) => g.gameType === gameType)
          .flatMap(([id, g]) => {
            const max = Math.max(...Object.values(g.scores));
            return [{ id, gameNumber: g.gameNumber, sessionIndex: g.sessionIndex, score: max }];
          })
          .sort((a, b) => b.score - a.score)
          .slice(0, 8)
      : [];

  return (
    <StatsPageShell
      title={gameType}
      titleAdornment={
        <GameTypeCell
          label={gameType}
          iconKind={gameTypeIconKindFromLabel(gameType)}
        />
      }
      backHref="/statistik/spiltyper"
      backLabel="Spiltyper"
    >
      {error ? (
        <div className="banner" role="alert">
          Kan ikke hente data — {error}
        </div>
      ) : null}
      {loading && !overview ? <p className="stats-loading">Indlæser…</p> : null}
      {!loading && !overview ? <p className="stats-empty">Spiltype ikke fundet.</p> : null}
      {overview ? (
        <div className="stats-detail">
          <p className="stats-detail-sub">{overview.games} spil i historikken</p>

          {showGameCountDonut ? (
            <section className="stats-panel">
              <DonutChart
                title="Spil pr. spiller"
                slices={overview.playerTotals.map((p) => ({
                  label: p.player.name,
                  value: p.games,
                }))}
              />
            </section>
          ) : null}

          <section className="stats-panel">
            <HorizontalBarChart
              title="Total point pr. spiller"
              rows={overview.playerTotals.map((p, i) => ({
                label: p.player.name,
                value: Math.abs(p.totalScore),
                colorIndex: i,
              }))}
            />
          </section>

          <section className="stats-panel">
            <h3 className="stats-section-title">Spillere</h3>
            <GameTypePlayerTable
              rows={overview.playerTotals.map((p) => ({
                playerId: p.player.id,
                name: p.player.name,
                games: p.games,
                averageScore: p.averageScore,
                totalScore: p.totalScore,
              }))}
            />
          </section>

          {topGames.length > 0 ? (
            <section className="stats-panel">
              <h3 className="stats-section-title">Dyreste spil</h3>
              <ul className="stats-session-link-list">
                {topGames.map((g) => (
                  <li key={g.id}>
                    <Link href={gamePath(g.id)} className="stats-session-link-item">
                      <span>
                        Spil #{g.gameNumber} (dag {g.sessionIndex})
                      </span>
                      <span className="score--pos">+{g.score}</span>
                    </Link>
                  </li>
                ))}
              </ul>
            </section>
          ) : null}
        </div>
      ) : null}
    </StatsPageShell>
  );
}
