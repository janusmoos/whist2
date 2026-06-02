"use client";

import Link from "next/link";
import {
  PlayerBidTrickHeatmap,
  PlayerSolHeatmap,
} from "@/components/stats/charts/PlayerGameTypeHeatmap";
import { PlayerLinesChart } from "@/components/stats/PlayerLinesChart";
import { StatsPageShell } from "@/components/stats/StatsPageShell";
import { useClubStats } from "@/hooks/useClubStats";
import { formatAverage, scoreClass, scoreLabel } from "@/lib/stats/format";
import { shouldShowPerPlayerGameCounts } from "@/lib/stats/displayHelpers";
import { gamePath, sessionPath } from "@/lib/stats/paths";

export function PlayerDetailView({ playerId }: { playerId: string }) {
  const { model, error, loading } = useClubStats();
  const profile = model?.playerProfiles.find((p) => p.summary.player.id === playerId);
  const name = profile?.summary.player.name ?? playerId;

  const cumulativeSeries = profile
    ? [
        {
          id: playerId,
          name,
          colorIndex: profile.summary.player.displayOrder - 1,
          points: (() => {
            let run = 0;
            return [...profile.sessionScores]
              .sort((a, b) => a.sessionIndex - b.sessionIndex)
              .map((s) => {
                run += s.score;
                return { x: s.sessionIndex, y: run };
              });
          })(),
        },
      ]
    : [];

  const gameCountsUniform = model
    ? shouldShowPerPlayerGameCounts(
        model.hub.playerSummaries.map((s) => s.gamesPlayed)
      ) === false
    : true;

  const profileSubline = profile
    ? gameCountsUniform
      ? `${profile.sessionScores.length} spilledage · snit ${formatAverage(profile.summary.averageScore)}`
      : `${profile.summary.gamesPlayed} spil · snit ${formatAverage(profile.summary.averageScore)}`
    : "";

  const playerHeatmaps = model?.playerHeatmaps[playerId];

  return (
    <StatsPageShell title={name} backHref="/statistik/spillere" backLabel="Spillere">
      {error ? (
        <div className="banner" role="alert">
          Kan ikke hente data — {error}
        </div>
      ) : null}
      {loading && !profile ? <p className="stats-loading">Indlæser…</p> : null}
      {!loading && !profile ? <p className="stats-empty">Spiller ikke fundet.</p> : null}
      {profile ? (
        <div className="stats-detail">
          <p className={`stats-player-hero-total${scoreClass(profile.summary.totalScore)}`}>
            {scoreLabel(profile.summary.totalScore)}
          </p>
          <p className="stats-detail-sub">{profileSubline}</p>

          <div className="stats-outcome-cards">
            {profile.summary.bestSessionIndex ? (
              <Link
                href={sessionPath(profile.summary.bestSessionIndex)}
                className="stats-outcome-card stats-outcome-card--pos"
              >
                <span className="stats-outcome-label">Bedste dag</span>
                <span className="stats-outcome-value">
                  #{profile.summary.bestSessionIndex} ·{" "}
                  {scoreLabel(profile.summary.bestSessionScore ?? 0)}
                </span>
              </Link>
            ) : null}
            {profile.summary.worstSessionIndex ? (
              <Link
                href={sessionPath(profile.summary.worstSessionIndex)}
                className="stats-outcome-card stats-outcome-card--neg"
              >
                <span className="stats-outcome-label">Værste dag</span>
                <span className="stats-outcome-value">
                  #{profile.summary.worstSessionIndex} ·{" "}
                  {scoreLabel(profile.summary.worstSessionScore ?? 0)}
                </span>
              </Link>
            ) : null}
            {profile.bestGameId ? (
              <Link href={gamePath(profile.bestGameId)} className="stats-outcome-card stats-outcome-card--pos">
                <span className="stats-outcome-label">Bedste spil</span>
                <span className="stats-outcome-value">{scoreLabel(profile.bestGameScore ?? 0)}</span>
              </Link>
            ) : null}
            {profile.worstGameId ? (
              <Link href={gamePath(profile.worstGameId)} className="stats-outcome-card stats-outcome-card--neg">
                <span className="stats-outcome-label">Værste spil</span>
                <span className="stats-outcome-value">{scoreLabel(profile.worstGameScore ?? 0)}</span>
              </Link>
            ) : null}
          </div>

          {playerHeatmaps?.bidTrick ? (
            <section className="stats-panel">
              <PlayerBidTrickHeatmap data={playerHeatmaps.bidTrick} />
            </section>
          ) : null}

          {playerHeatmaps?.sol ? (
            <section className="stats-panel">
              <PlayerSolHeatmap data={playerHeatmaps.sol} />
            </section>
          ) : null}

          <section className="stats-panel">
            <h3 className="stats-section-title">Gevinst/tab pr. spilledag</h3>
            <PlayerLinesChart
              series={cumulativeSeries}
              ariaLabel={`${name}s kumulative score pr. spilledag`}
              height={150}
              xLabel="Spilledag"
            />
          </section>

          <section className="stats-panel">
            <h3 className="stats-section-title">Alle spilledage</h3>
            <ul className="stats-session-link-list">
              {[...profile.sessionScores]
                .sort((a, b) => b.sessionIndex - a.sessionIndex)
                .map((s) => (
                  <li key={s.sessionId}>
                    <Link href={sessionPath(s.sessionIndex)} className="stats-session-link-item">
                      <span>Spilledag {s.sessionIndex}</span>
                      <span className={scoreClass(s.score)}>{scoreLabel(s.score)}</span>
                      <span className="stats-session-link-meta">{s.gamesInSession} spil</span>
                    </Link>
                  </li>
                ))}
            </ul>
          </section>
        </div>
      ) : null}
    </StatsPageShell>
  );
}
