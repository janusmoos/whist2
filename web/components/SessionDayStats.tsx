"use client";

import type { HandSummary } from "@/components/HandsTable";
import { PosterBox } from "@/components/PosterBox";
import {
  computeSessionDayStats,
  gameTypeSummaryLabel,
  type PlayerDayStats,
} from "@/lib/stats/sessionDayStats";

function scoreLabel(n: number): string {
  return n > 0 ? `+${n}` : String(n);
}

function scoreClass(n: number): string {
  if (n > 0) return " score--pos";
  if (n < 0) return " score--neg";
  return " score--zero";
}

const PLAYER_LINE_COLORS = [
  "var(--stats-line-1)",
  "var(--stats-line-2)",
  "var(--stats-line-3)",
  "var(--stats-line-4)",
];

function ScoreProgressChart({
  players,
  handCount,
}: {
  players: PlayerDayStats[];
  handCount: number;
}) {
  if (handCount === 0) return null;

  const allValues = players.flatMap((p) => p.cumulative);
  const minY = Math.min(0, ...allValues);
  const maxY = Math.max(0, ...allValues);
  const range = maxY - minY || 1;

  const width = 320;
  const height = 120;
  const padX = 8;
  const padY = 10;
  const innerW = width - padX * 2;
  const innerH = height - padY * 2;

  const xAt = (handIndex: number) =>
    handCount === 1
      ? padX + innerW / 2
      : padX + (handIndex / (handCount - 1)) * innerW;

  const yAt = (value: number) =>
    padY + innerH - ((value - minY) / range) * innerH;

  const zeroY = yAt(0);

  return (
    <div className="session-stats-chart-wrap">
      <svg
        className="session-stats-chart"
        viewBox={`0 0 ${width} ${height}`}
        role="img"
        aria-label="Kumulativ stilling pr. spiller gennem spilledagen"
      >
        <line
          x1={padX}
          y1={zeroY}
          x2={width - padX}
          y2={zeroY}
          className="session-stats-chart-zero"
        />
        {players.map((player) => {
          if (player.cumulative.length === 0) return null;
          const points = player.cumulative
            .map((value, i) => `${xAt(i)},${yAt(value)}`)
            .join(" ");
          return (
            <polyline
              key={player.seat}
              points={points}
              className="session-stats-chart-line"
              style={{ stroke: PLAYER_LINE_COLORS[player.seat] }}
            />
          );
        })}
      </svg>
      <ul className="session-stats-chart-legend">
        {players.map((player) => (
          <li key={player.seat}>
            <span
              className="session-stats-chart-swatch"
              style={{ background: PLAYER_LINE_COLORS[player.seat] }}
              aria-hidden="true"
            />
            {player.name}
          </li>
        ))}
      </ul>
    </div>
  );
}

function PlayerStatCard({ player }: { player: PlayerDayStats }) {
  return (
    <article className="session-stats-player">
      <div className="session-stats-player-head">
        <span className="session-stats-player-rank">{player.rank}</span>
        <span className="session-stats-player-name">{player.name}</span>
        <span className={`session-stats-player-total${scoreClass(player.total)}`}>
          {scoreLabel(player.total)}
        </span>
      </div>
      <dl className="session-stats-player-meta">
        <div>
          <dt>Snit/kamp</dt>
          <dd className={scoreClass(player.averagePerHand)}>{scoreLabel(player.averagePerHand)}</dd>
        </div>
        {player.bestHand ? (
          <div>
            <dt>Bedste #{player.bestHand.handNumber}</dt>
            <dd className={scoreClass(player.bestHand.score)}>
              {scoreLabel(player.bestHand.score)}
            </dd>
          </div>
        ) : null}
        {player.worstHand ? (
          <div>
            <dt>Værste #{player.worstHand.handNumber}</dt>
            <dd className={scoreClass(player.worstHand.score)}>
              {scoreLabel(player.worstHand.score)}
            </dd>
          </div>
        ) : null}
      </dl>
    </article>
  );
}

export function SessionDayStats({
  hands,
  names,
}: {
  hands: HandSummary[];
  names: string[];
}) {
  const stats = computeSessionDayStats(hands, names);
  if (!stats) return null;

  const leader = stats.players.find((p) => p.rank === 1);

  return (
    <PosterBox className="session-stats-box" title="Spilledags-statistik">
      <div className="session-stats">
        <p className="session-stats-lead">
          {stats.handCount} {stats.handCount === 1 ? "kamp" : "kampe"}
          {leader ? (
            <>
              {" "}
              · Fører: <strong>{leader.name}</strong> ({scoreLabel(leader.total)})
            </>
          ) : null}
          {" "}
          · {gameTypeSummaryLabel(stats.gameTypes)}
        </p>

        {stats.biggestSwing ? (
          <p className="session-stats-swing">
            Største enkeltscore:{" "}
            <strong>{stats.biggestSwing.playerName}</strong> i kamp #
            {stats.biggestSwing.handNumber} (
            <span className={scoreClass(stats.biggestSwing.score).trim()}>
              {scoreLabel(stats.biggestSwing.score)}
            </span>
            )
          </p>
        ) : null}

        <div className="session-stats-players">
          {stats.players.map((player) => (
            <PlayerStatCard key={player.seat} player={player} />
          ))}
        </div>

        {stats.handCount >= 2 ? (
          <ScoreProgressChart players={stats.players} handCount={stats.handCount} />
        ) : null}
      </div>
    </PosterBox>
  );
}
