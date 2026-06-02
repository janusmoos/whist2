"use client";

import type { LiveSession } from "@/lib/liveSessionTypes";
import type { ClubHubSnapshot } from "@/lib/stats/historicalTypes";
import {
  PlayerLinesChart,
  timelineToSeries,
} from "@/components/stats/PlayerLinesChart";

function scoreLabel(n: number): string {
  return n > 0 ? `+${n}` : String(n);
}

function scoreClass(n: number): string {
  if (n > 0) return " score--pos";
  if (n < 0) return " score--neg";
  return " score--zero";
}

export function StatsHubOverview({
  hub,
  activeSession,
}: {
  hub: ClubHubSnapshot | null;
  activeSession: LiveSession | null;
}) {
  if (!hub) {
    return (
      <section className="stats-hub-overview stats-hub-overview--empty">
        <p className="stats-hub-empty">Historisk statistik indlæses…</p>
      </section>
    );
  }

  const playerOrder = hub.playerSummaries.map((s) => s.player.id);
  const series = timelineToSeries(hub.timelinePoints, playerOrder);
  const latestByPlayer = new Map<string, { name: string; score: number; colorIndex: number }>();
  for (const point of hub.timelinePoints) {
    const idx = playerOrder.indexOf(point.playerId);
    latestByPlayer.set(point.playerId, {
      name: point.playerName,
      score: point.cumulativeScore,
      colorIndex: idx >= 0 ? idx : 0,
    });
  }
  const labelColumn = playerOrder
    .map((id) => latestByPlayer.get(id))
    .filter((v): v is NonNullable<typeof v> => Boolean(v));

  return (
    <section className="stats-hub-overview" aria-label="Overblik">
      <div className="stats-hub-metrics">
        <article className="stats-hub-metric">
          <span className="stats-hub-metric-label">Spilledage</span>
          <span className="stats-hub-metric-value">{hub.sessionCount}</span>
        </article>
        <article className="stats-hub-metric">
          <span className="stats-hub-metric-label">Spil</span>
          <span className="stats-hub-metric-value">{hub.gameCount}</span>
        </article>
      </div>

      <div className="stats-hub-chart-block">
        <h3 className="stats-hub-standing-label">Status</h3>
        <PlayerLinesChart
          series={series}
          ariaLabel="Udvikling i samlet pointstilling pr. spilledag"
          labelColumn={labelColumn}
          showLegend={false}
        />
      </div>

      <div className="stats-hub-standing">
        <h3 className="stats-hub-standing-label">Stilling</h3>
        <div className="stats-hub-standing-strip">
          {hub.playerSummaries.map((summary, i) => (
            <article
              key={summary.player.id}
              className="stats-hub-standing-chip"
              style={{ borderColor: `var(--stats-line-${i + 1})` }}
            >
              <span className="stats-hub-standing-name">
                {summary.player.name.toUpperCase()}
              </span>
              <span className={`stats-hub-standing-score${scoreClass(summary.totalScore)}`}>
                {scoreLabel(summary.totalScore)}
              </span>
            </article>
          ))}
        </div>
      </div>

      {activeSession?.title ? (
        <p className="stats-hub-session-title">
          Aktiv spilledag: {activeSession.title}
          {activeSession.sessionNumber != null
            ? ` (#${activeSession.sessionNumber})`
            : ""}
        </p>
      ) : null}
    </section>
  );
}
