"use client";

import Link from "next/link";
import { PlayerLinesChart } from "@/components/stats/PlayerLinesChart";
import { StatsPageShell } from "@/components/stats/StatsPageShell";
import { formatAverage, scoreClass, scoreLabel } from "@/lib/stats/format";
import { playerPath } from "@/lib/stats/paths";
import { shouldShowPerPlayerGameCounts } from "@/lib/stats/displayHelpers";
import { useClubStats } from "@/hooks/useClubStats";

function Sparkline({
  points,
  colorIndex,
}: {
  points: { x: number; y: number }[];
  colorIndex: number;
}) {
  if (points.length < 2) return null;
  const ys = points.map((p) => p.y);
  const min = Math.min(...ys);
  const max = Math.max(...ys);
  const range = max - min || 1;
  const w = 72;
  const h = 24;
  const d = points
    .map((p, i) => {
      const x = (i / (points.length - 1)) * w;
      const y = h - ((p.y - min) / range) * h;
      return `${i === 0 ? "M" : "L"}${x.toFixed(1)},${y.toFixed(1)}`;
    })
    .join(" ");

  return (
    <svg viewBox={`0 0 ${w} ${h}`} className="stats-sparkline" aria-hidden>
      <path
        d={d}
        fill="none"
        stroke={`var(--stats-line-${colorIndex + 1})`}
        strokeWidth="2"
        strokeLinecap="round"
      />
    </svg>
  );
}

export function PlayersStatsView() {
  const { model, error, loading } = useClubStats();

  const cumulativeSeries =
    model?.hub.playerSummaries.map((summary, i) => {
      let run = 0;
      const profile = model.playerProfiles.find(
        (p) => p.summary.player.id === summary.player.id
      );
      const points = [...(profile?.sessionScores ?? [])]
        .sort((a, b) => a.sessionIndex - b.sessionIndex)
        .map((s) => {
          run += s.score;
          return { x: s.sessionIndex, y: run };
        });
      return {
        id: summary.player.id,
        name: summary.player.name,
        colorIndex: i,
        points,
      };
    }) ?? [];

  const showGamesColumn = model
    ? shouldShowPerPlayerGameCounts(model.hub.playerSummaries.map((s) => s.gamesPlayed))
    : false;

  return (
    <StatsPageShell
      title="Spillere"
      lead="Samlet point, snit og udvikling — tryk for fuld profil."
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
            <h3 className="stats-section-title">Kumulativ udvikling</h3>
            <PlayerLinesChart
              series={cumulativeSeries}
              ariaLabel="Spillernes kumulative point over tid"
              height={160}
              xLabel="Spilledag"
            />
          </section>

          <div className="stats-players-grid">
            {model.hub.playerSummaries.map((summary, i) => {
              const profile = model.playerProfiles.find(
                (p) => p.summary.player.id === summary.player.id
              );
              const sparkPoints = [...(profile?.sessionScores ?? [])]
                .sort((a, b) => a.sessionIndex - b.sessionIndex)
                .reduce<{ x: number; y: number }[]>((acc, s) => {
                  const prev = acc.length ? acc[acc.length - 1].y : 0;
                  acc.push({ x: s.sessionIndex, y: prev + s.score });
                  return acc;
                }, []);

              return (
                <Link
                  key={summary.player.id}
                  href={playerPath(summary.player.id)}
                  className="stats-player-profile stats-player-profile--link"
                >
                  <div
                    className="stats-player-profile-accent"
                    style={{ background: `var(--stats-line-${i + 1})` }}
                  />
                  <div className="stats-player-profile-head">
                    <h3 className="stats-player-profile-name">{summary.player.name}</h3>
                    <Sparkline points={sparkPoints} colorIndex={i} />
                  </div>
                  <p className={`stats-player-profile-total${scoreClass(summary.totalScore)}`}>
                    {scoreLabel(summary.totalScore)}
                  </p>
                  <dl className="stats-player-profile-meta">
                    {showGamesColumn ? (
                      <div>
                        <dt>Spil</dt>
                        <dd>{summary.gamesPlayed}</dd>
                      </div>
                    ) : null}
                    <div>
                      <dt>Snit/spil</dt>
                      <dd className={scoreClass(Math.round(summary.averageScore))}>
                        {formatAverage(summary.averageScore)}
                      </dd>
                    </div>
                    <div>
                      <dt>Bedste dag</dt>
                      <dd className={scoreClass(summary.bestSessionScore ?? 0)}>
                        {summary.bestSessionIndex != null
                          ? `#${summary.bestSessionIndex} · ${scoreLabel(summary.bestSessionScore ?? 0)}`
                          : "—"}
                      </dd>
                    </div>
                    <div>
                      <dt>Værste dag</dt>
                      <dd className={scoreClass(summary.worstSessionScore ?? 0)}>
                        {summary.worstSessionIndex != null
                          ? `#${summary.worstSessionIndex} · ${scoreLabel(summary.worstSessionScore ?? 0)}`
                          : "—"}
                      </dd>
                    </div>
                  </dl>
                </Link>
              );
            })}
          </div>
        </>
      ) : null}
    </StatsPageShell>
  );
}
