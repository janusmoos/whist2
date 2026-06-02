"use client";

import type { LiveSession } from "@/lib/liveSessionTypes";

function scoreLabel(n: number): string {
  return n > 0 ? `+${n}` : String(n);
}

function scoreClass(n: number): string {
  if (n > 0) return " score--pos";
  if (n < 0) return " score--neg";
  return " score--zero";
}

export function StatsHubOverview({ session }: { session: LiveSession | null }) {
  const names = session?.playerNamesBySeat ?? [];
  const totals = session?.totalsBySeat ?? [];
  const handCount = session?.handCount ?? 0;
  const sessionNumber = session?.sessionNumber;
  const hasStandings = names.length === 4 && totals.length === 4;

  if (!session) {
    return (
      <section className="stats-hub-overview stats-hub-overview--empty">
        <p className="stats-hub-empty">Ingen aktiv spilledag lige nu.</p>
      </section>
    );
  }

  return (
    <section className="stats-hub-overview" aria-label="Overblik">
      <div className="stats-hub-metrics">
        <article className="stats-hub-metric">
          <span className="stats-hub-metric-label">Spilledage</span>
          <span className="stats-hub-metric-value">
            {sessionNumber != null ? `#${sessionNumber}` : "—"}
          </span>
        </article>
        <article className="stats-hub-metric">
          <span className="stats-hub-metric-label">Spil</span>
          <span className="stats-hub-metric-value">{handCount}</span>
        </article>
      </div>

      {hasStandings ? (
        <div className="stats-hub-standing">
          <h3 className="stats-hub-standing-label">Stilling</h3>
          <div className="stats-hub-standing-strip">
            {names.map((name, i) => (
              <article
                key={name}
                className="stats-hub-standing-chip"
                style={{ borderColor: `var(--stats-line-${i + 1})` }}
              >
                <span className="stats-hub-standing-name">{name.toUpperCase()}</span>
                <span className={`stats-hub-standing-score${scoreClass(totals[i] ?? 0)}`}>
                  {scoreLabel(totals[i] ?? 0)}
                </span>
              </article>
            ))}
          </div>
        </div>
      ) : null}

      {session.title ? (
        <p className="stats-hub-session-title">{session.title}</p>
      ) : null}
    </section>
  );
}
