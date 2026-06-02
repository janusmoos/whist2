"use client";

import { StatsPageShell } from "@/components/stats/StatsPageShell";
import { formatAverage, scoreClass, scoreLabel } from "@/lib/stats/format";
import { useClubStats } from "@/hooks/useClubStats";

export function GameTypesStatsView() {
  const { model, error, loading } = useClubStats();

  return (
    <StatsPageShell
      title="Spiltyper"
      lead="Fordeling og point pr. spiltype med tydelig sample size."
    >
      {error ? (
        <div className="banner" role="alert">
          Kan ikke hente data — {error}
        </div>
      ) : null}
      {loading && !model ? <p className="stats-loading">Indlæser…</p> : null}
      {model ? (
        <div className="stats-list">
          {model.gameTypes.map((row) => (
            <article key={row.gameType} className="stats-gametype-card">
              <header className="stats-gametype-head">
                <h3 className="stats-gametype-title">{row.gameType}</h3>
                <span className="stats-gametype-count">{row.games} spil i alt</span>
              </header>
              <div className="stats-gametype-table-wrap">
                <table className="stats-gametype-table">
                  <thead>
                    <tr>
                      <th>Spiller</th>
                      <th>Spil</th>
                      <th>Snit</th>
                      <th>Total</th>
                    </tr>
                  </thead>
                  <tbody>
                    {row.playerTotals.map((p) => (
                      <tr key={p.player.id}>
                        <td>{p.player.name}</td>
                        <td>{p.games}</td>
                        <td className={scoreClass(Math.round(p.averageScore))}>
                          {p.games > 0 ? formatAverage(p.averageScore) : "—"}
                        </td>
                        <td className={scoreClass(p.totalScore)}>
                          {scoreLabel(p.totalScore)}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </article>
          ))}
        </div>
      ) : null}
    </StatsPageShell>
  );
}
