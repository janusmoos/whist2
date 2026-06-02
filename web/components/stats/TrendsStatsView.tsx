"use client";

import { StatsPageShell } from "@/components/stats/StatsPageShell";
import { scoreClass, scoreLabel } from "@/lib/stats/format";
import { useClubStats } from "@/hooks/useClubStats";

export function TrendsStatsView() {
  const { model, error, loading } = useClubStats();
  const limit = model?.trends.recentSessionLimit ?? 10;

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
          <section className="stats-trends-block">
            <h3 className="stats-section-title">Alle spilledage</h3>
            <TrendsTable rows={model.trends.all} />
          </section>
          <section className="stats-trends-block">
            <h3 className="stats-section-title">Seneste {limit} spilledage</h3>
            <TrendsTable rows={model.trends.recent} />
          </section>
        </div>
      ) : null}
    </StatsPageShell>
  );
}

function TrendsTable({
  rows,
}: {
  rows: {
    player: { name: string };
    totalScore: number;
    gamesPlayed: number;
    averageScore: number;
  }[];
}) {
  return (
    <div className="stats-trends-table-wrap">
      <table className="stats-trends-table">
        <thead>
          <tr>
            <th>Spiller</th>
            <th>Spil</th>
            <th>Snit</th>
            <th>Total</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr key={row.player.name}>
              <td>{row.player.name}</td>
              <td>{row.gamesPlayed}</td>
              <td className={scoreClass(Math.round(row.averageScore))}>
                {row.gamesPlayed > 0
                  ? scoreLabel(Math.round(row.averageScore * 10) / 10)
                  : "—"}
              </td>
              <td className={scoreClass(row.totalScore)}>{scoreLabel(row.totalScore)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
