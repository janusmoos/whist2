"use client";

import type { HandSummary } from "@/components/HandsTable";
import { PlayerLinesChart } from "@/components/stats/PlayerLinesChart";
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

function DayProgressChart({
  players,
  handCount,
}: {
  players: PlayerDayStats[];
  handCount: number;
}) {
  if (handCount < 2) return null;

  return (
    <div className="session-stats-chart-wrap">
      <PlayerLinesChart
        series={players.map((p) => ({
          id: String(p.seat),
          name: p.name,
          colorIndex: p.seat,
          points: p.cumulative.map((y, i) => ({ x: i, y })),
        }))}
        xLabel="Kumulativ stilling gennem spilledagen"
        ariaLabel="Kumulativ stilling pr. spiller gennem spilledagen"
        height={120}
      />
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

export function SessionDayStatsPanel({
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
        <DayProgressChart players={stats.players} handCount={stats.handCount} />
      ) : null}
    </div>
  );
}
