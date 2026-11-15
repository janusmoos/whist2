"use client";

import Link from "next/link";
import { GameTypeCell } from "@/components/stats/GameTypeCell";
import { StatsPageShell } from "@/components/stats/StatsPageShell";
import { useClubStats } from "@/hooks/useClubStats";
import { scoreClass, scoreLabel } from "@/lib/stats/format";
import { sessionPath } from "@/lib/stats/paths";

export function GameDetailView({ gameId }: { gameId: string }) {
  const { model, error, loading } = useClubStats();
  const game = model?.games[gameId];
  const players = model?.hub.playerSummaries.map((s) => s.player) ?? [];

  return (
    <StatsPageShell
      title={game ? `Spil #${game.gameNumber}` : "Spil"}
      backHref={game ? sessionPath(game.sessionIndex) : "/statistik/alle-spilledage"}
      backLabel={game ? `Spilledag ${game.sessionIndex}` : "Alle spilledage"}
    >
      {error ? (
        <div className="banner" role="alert">
          Kan ikke hente data — {error}
        </div>
      ) : null}
      {loading && !game ? <p className="stats-loading">Indlæser…</p> : null}
      {!loading && !game ? <p className="stats-empty">Spil ikke fundet.</p> : null}
      {game ? (
        <div className="stats-detail">
          <p className="stats-detail-sub stats-detail-sub--inline">
            Spilledag {game.sessionIndex}
            {game.gameType ? (
              <>
                {" · "}
                <GameTypeCell label={game.gameType} iconKind={game.iconKind} />
              </>
            ) : null}
          </p>

          <section className="stats-panel">
            <h3 className="stats-section-title">Point</h3>
            <div className="stats-hub-standing-strip">
              {players.map((player, i) => {
                const score = game.scores[player.id] ?? 0;
                return (
                  <article
                    key={player.id}
                    className="stats-hub-standing-chip"
                    style={{ borderColor: `var(--stats-line-${i + 1})` }}
                  >
                    <span className="stats-hub-standing-name">{player.name.toUpperCase()}</span>
                    <span className={`stats-hub-standing-score${scoreClass(score)}`}>
                      {scoreLabel(score)}
                    </span>
                  </article>
                );
              })}
            </div>
          </section>

          {game.qualityFlags.length > 0 ? (
            <section className="stats-panel">
              <h3 className="stats-section-title">Dataadvarsler</h3>
              <ul className="stats-flag-list">
                {game.qualityFlags.map((flag) => (
                  <li key={flag}>
                    <code>{flag}</code>
                  </li>
                ))}
              </ul>
            </section>
          ) : null}

          <p className="stats-live-link">
            <Link href={sessionPath(game.sessionIndex)}>Se hele spilledagen →</Link>
          </p>
        </div>
      ) : null}
    </StatsPageShell>
  );
}
