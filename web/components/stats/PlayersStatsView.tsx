"use client";

import { StatsPageShell } from "@/components/stats/StatsPageShell";
import { formatAverage, scoreClass, scoreLabel } from "@/lib/stats/format";
import { useClubStats } from "@/hooks/useClubStats";

export function PlayersStatsView() {
  const { model, error, loading } = useClubStats();

  return (
    <StatsPageShell
      title="Spillere"
      lead="Samlet point, snit og enkeltspil for hver spiller."
    >
      {error ? (
        <div className="banner" role="alert">
          Kan ikke hente data — {error}
        </div>
      ) : null}
      {loading && !model ? <p className="stats-loading">Indlæser…</p> : null}
      {model ? (
        <div className="stats-players-grid">
          {model.hub.playerSummaries.map((summary, i) => (
            <article key={summary.player.id} className="stats-player-profile">
              <div
                className="stats-player-profile-accent"
                style={{ background: `var(--stats-line-${i + 1})` }}
              />
              <h3 className="stats-player-profile-name">{summary.player.name}</h3>
              <p className={`stats-player-profile-total${scoreClass(summary.totalScore)}`}>
                {scoreLabel(summary.totalScore)}
              </p>
              <dl className="stats-player-profile-meta">
                <div>
                  <dt>Spil</dt>
                  <dd>{summary.gamesPlayed}</dd>
                </div>
                <div>
                  <dt>Snit/spil</dt>
                  <dd className={scoreClass(Math.round(summary.averageScore))}>
                    {formatAverage(summary.averageScore)}
                  </dd>
                </div>
                <div>
                  <dt>Bedste spil</dt>
                  <dd className={scoreClass(summary.bestSingleGame ?? 0)}>
                    {summary.bestSingleGame != null
                      ? scoreLabel(summary.bestSingleGame)
                      : "—"}
                  </dd>
                </div>
                <div>
                  <dt>Værste spil</dt>
                  <dd className={scoreClass(summary.worstSingleGame ?? 0)}>
                    {summary.worstSingleGame != null
                      ? scoreLabel(summary.worstSingleGame)
                      : "—"}
                  </dd>
                </div>
              </dl>
            </article>
          ))}
        </div>
      ) : null}
    </StatsPageShell>
  );
}
