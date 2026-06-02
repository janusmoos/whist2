"use client";

import { StatsPageShell } from "@/components/stats/StatsPageShell";
import { formatAverage, scoreClass, scoreLabel } from "@/lib/stats/format";
import { sessionDisplayTitle } from "@/lib/stats/historicalEngine";
import { useClubStats } from "@/hooks/useClubStats";

export function AllSessionsStatsView() {
  const { model, error, loading } = useClubStats();

  return (
    <StatsPageShell
      title="Alle spilledage"
      lead="Dato, sted, resultater og antal spil for hver historisk spilledag."
    >
      {error ? (
        <div className="banner" role="alert">
          Kan ikke hente data — {error}
        </div>
      ) : null}
      {loading && !model ? <p className="stats-loading">Indlæser…</p> : null}
      {model ? (
        <div className="stats-list">
          {[...model.sessions].reverse().map((overview) => (
            <article key={overview.session.id} className="stats-session-card">
              <header className="stats-session-card-head">
                <h3 className="stats-session-card-title">
                  Spilledag {overview.session.sessionNumber}
                </h3>
                <span className="stats-session-card-meta">
                  {overview.gamesPlayed} spil
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
            </article>
          ))}
        </div>
      ) : null}
    </StatsPageShell>
  );
}
