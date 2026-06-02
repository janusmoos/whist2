"use client";

import { formatAverage, scoreClass, scoreLabel } from "@/lib/stats/format";
import { shouldShowPerPlayerGameCounts } from "@/lib/stats/displayHelpers";

export function PlayerBreakdownTable({
  rows,
  tableClassName = "stats-trends-table",
}: {
  rows: {
    name: string;
    gamesPlayed: number;
    averageScore: number;
    totalScore: number;
  }[];
  tableClassName?: string;
}) {
  const showGames = shouldShowPerPlayerGameCounts(rows.map((r) => r.gamesPlayed));

  return (
    <div className="stats-trends-table-wrap">
      <table className={tableClassName}>
        <thead>
          <tr>
            <th>Spiller</th>
            {showGames ? <th>Spil</th> : null}
            <th>Snit</th>
            <th>Total</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr key={row.name}>
              <td>{row.name}</td>
              {showGames ? <td>{row.gamesPlayed}</td> : null}
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

export function GameTypePlayerTable({
  rows,
}: {
  rows: {
    playerId: string;
    name: string;
    games: number;
    averageScore: number;
    totalScore: number;
  }[];
}) {
  const showGames = shouldShowPerPlayerGameCounts(rows.map((r) => r.games));

  return (
    <div className="stats-gametype-table-wrap">
      <table className="stats-gametype-table">
        <thead>
          <tr>
            <th>Spiller</th>
            {showGames ? <th>Spil</th> : null}
            <th>Snit</th>
            <th>Total</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr key={row.playerId}>
              <td>{row.name}</td>
              {showGames ? <td>{row.games}</td> : null}
              <td className={scoreClass(Math.round(row.averageScore))}>
                {row.games > 0 ? formatAverage(row.averageScore) : "—"}
              </td>
              <td className={scoreClass(row.totalScore)}>{scoreLabel(row.totalScore)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
