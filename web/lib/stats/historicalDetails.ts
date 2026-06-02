import type {
  DivergingRow,
  GameRecord,
  HeatmapCell,
  HistoricalPlayer,
  HistoricalWhistData,
  PlayerProfile,
  PlayerScoreSummary,
  PlayerSessionScore,
  RankDistributionRow,
  SessionDetail,
  SessionGameRow,
  SessionProgressPoint,
} from "@/lib/stats/historicalTypes";
import { canonicalGameType, gameTypeLabel } from "@/lib/stats/gameTypeClassifier";
import { gameTypeIconKindFromHistorical, type GameTypeIconKind } from "@/lib/stats/gameTypeIcons";
import { historicalGameResume } from "@/lib/stats/gameResumeText";

function sortedPlayers(players: HistoricalPlayer[]): HistoricalPlayer[] {
  return [...players].sort((a, b) => {
    if (a.displayOrder !== b.displayOrder) return a.displayOrder - b.displayOrder;
    return a.name.localeCompare(b.name, "da");
  });
}

function groupBy<T, K extends string | number>(
  items: T[],
  keyFn: (item: T) => K
): Map<K, T[]> {
  const map = new Map<K, T[]>();
  for (const item of items) {
    const key = keyFn(item);
    (map.get(key) ?? map.set(key, []).get(key))!.push(item);
  }
  return map;
}

function bestGameScore(scores: Record<string, number>): number {
  return Math.max(...Object.values(scores), -Infinity);
}

function worstGameScore(scores: Record<string, number>): number {
  return Math.min(...Object.values(scores), Infinity);
}

export function enrichPlayerSummaries(
  summaries: PlayerScoreSummary[],
  sessionScoresByPlayer: Record<string, PlayerSessionScore[]>
): PlayerScoreSummary[] {
  return summaries.map((summary) => {
    const sessions = sessionScoresByPlayer[summary.player.id] ?? [];
    const best = sessions.reduce<PlayerSessionScore | null>((acc, cur) => {
      if (!acc || cur.score > acc.score) return cur;
      return acc;
    }, null);
    const worst = sessions.reduce<PlayerSessionScore | null>((acc, cur) => {
      if (!acc || cur.score < acc.score) return cur;
      return acc;
    }, null);
    return {
      ...summary,
      bestSessionIndex: best?.sessionIndex ?? null,
      bestSessionScore: best?.score ?? null,
      worstSessionIndex: worst?.sessionIndex ?? null,
      worstSessionScore: worst?.score ?? null,
    };
  });
}

export function buildSessionDetails(data: HistoricalWhistData): SessionDetail[] {
  const players = sortedPlayers(data.players);
  const gamesBySession = groupBy(data.games, (g) => g.sessionId);
  const resultsByGame = groupBy(data.playerResults, (r) => r.gameId);

  return data.sessions.map((session, offset) => {
    const sessionIndex = offset + 1;
    const games = (gamesBySession.get(session.id) ?? []).sort(
      (a, b) => a.gameNumberInSession - b.gameNumberInSession
    );
    const runningTotals = new Map(players.map((p) => [p.id, 0]));
    const progressPoints: SessionProgressPoint[] = [];
    const gameRows: SessionGameRow[] = [];
    const gameTypeCounts = new Map<string, { count: number; iconKind: GameTypeIconKind }>();
    const dayOutcomes = players.map((p) => ({
      playerId: p.id,
      wins: 0,
      losses: 0,
      zeros: 0,
    }));
    const outcomeByPlayer = new Map(dayOutcomes.map((o) => [o.playerId, o]));

    let bestGameId: string | null = null;
    let bestGameScoreVal: number | null = null;
    let worstGameId: string | null = null;
    let worstGameScoreVal: number | null = null;
    let issueCount = 0;

    for (const game of games) {
      const results = resultsByGame.get(game.id) ?? [];
      const scores: Record<string, number> = {};
      for (const r of results) scores[r.playerId] = r.score;

      const flags = game.qualityFlags ?? [];
      if (flags.length > 0) issueCount += 1;

      const type = canonicalGameType(game);
      if (type) {
        const cur = gameTypeCounts.get(type) ?? {
          count: 0,
          iconKind: gameTypeIconKindFromHistorical(game),
        };
        cur.count += 1;
        gameTypeCounts.set(type, cur);
      }

      const high = bestGameScore(scores);
      const low = worstGameScore(scores);
      if (bestGameScoreVal == null || high > bestGameScoreVal) {
        bestGameScoreVal = high;
        bestGameId = game.id;
      }
      if (worstGameScoreVal == null || low < worstGameScoreVal) {
        worstGameScoreVal = low;
        worstGameId = game.id;
      }

      for (const player of players) {
        const score = scores[player.id] ?? 0;
        runningTotals.set(player.id, (runningTotals.get(player.id) ?? 0) + score);
        progressPoints.push({
          playerId: player.id,
          gameId: game.id,
          gameNumber: game.gameNumberInSession,
          gameScore: score,
          cumulativeScore: runningTotals.get(player.id) ?? 0,
        });
        const outcome = outcomeByPlayer.get(player.id);
        if (outcome) {
          if (score > 0) outcome.wins += 1;
          else if (score < 0) outcome.losses += 1;
          else outcome.zeros += 1;
        }
      }

      gameRows.push({
        id: game.id,
        gameNumber: game.gameNumberInSession,
        gameType: gameTypeLabel(game) === "—" ? null : gameTypeLabel(game),
        iconKind: gameTypeIconKindFromHistorical(game),
        scores,
        qualityFlags: flags,
        resume: historicalGameResume(game, players, scores),
      });
    }

    const totalsByPlayer = new Map<string, number>();
    for (const row of gameRows) {
      for (const [pid, score] of Object.entries(row.scores)) {
        totalsByPlayer.set(pid, (totalsByPlayer.get(pid) ?? 0) + score);
      }
    }

    return {
      session,
      sessionIndex,
      gamesPlayed: games.length,
      playerTotals: players.map((player) => ({
        player,
        score: totalsByPlayer.get(player.id) ?? 0,
      })),
      issueCount,
      progressPoints,
      games: gameRows,
      bestGameId,
      bestGameScore: bestGameScoreVal,
      worstGameId,
      worstGameScore: worstGameScoreVal,
      gameTypeCounts: [...gameTypeCounts.entries()]
        .map(([type, { count, iconKind }]) => ({ type, count, iconKind }))
        .sort((a, b) => b.count - a.count),
      dayOutcomes: [...outcomeByPlayer.values()],
    };
  });
}

export function buildPlayerProfiles(
  data: HistoricalWhistData,
  summaries: PlayerScoreSummary[],
  sessionScoresByPlayer: Record<string, PlayerSessionScore[]>
): PlayerProfile[] {
  const resultsByPlayer = groupBy(data.playerResults, (r) => r.playerId);
  const gameById = new Map(data.games.map((g) => [g.id, g]));

  return sortedPlayers(data.players).map((player) => {
    const summary = summaries.find((s) => s.player.id === player.id)!;
    const results = resultsByPlayer.get(player.id) ?? [];
    let bestGameId: string | null = null;
    let bestGameScoreVal: number | null = null;
    let worstGameId: string | null = null;
    let worstGameScoreVal: number | null = null;

    for (const r of results) {
      if (bestGameScoreVal == null || r.score > bestGameScoreVal) {
        bestGameScoreVal = r.score;
        bestGameId = r.gameId;
      }
      if (worstGameScoreVal == null || r.score < worstGameScoreVal) {
        worstGameScoreVal = r.score;
        worstGameId = r.gameId;
      }
    }

    return {
      summary,
      sessionScores: sessionScoresByPlayer[player.id] ?? [],
      bestGameId,
      bestGameScore: bestGameScoreVal,
      worstGameId,
      worstGameScore: worstGameScoreVal,
    };
  });
}

export function buildGameIndex(
  data: HistoricalWhistData,
  sessionDetails: SessionDetail[]
): Record<string, GameRecord> {
  const sessionIndexById = new Map(
    sessionDetails.map((d) => [d.session.id, d.sessionIndex] as const)
  );
  const out: Record<string, GameRecord> = {};
  for (const game of data.games) {
    out[game.id] = {
      id: game.id,
      sessionId: game.sessionId,
      sessionIndex: sessionIndexById.get(game.sessionId) ?? 0,
      gameNumber: game.gameNumberInSession,
      gameType: gameTypeLabel(game) === "—" ? null : gameTypeLabel(game),
      iconKind: gameTypeIconKindFromHistorical(game),
      scores: {},
      qualityFlags: game.qualityFlags ?? [],
    };
  }
  for (const r of data.playerResults) {
    const rec = out[r.gameId];
    if (rec) rec.scores[r.playerId] = r.score;
  }
  return out;
}

export function buildHeatmap(sessionDetails: SessionDetail[]): HeatmapCell[] {
  const cells: HeatmapCell[] = [];
  for (const detail of sessionDetails) {
    for (const row of detail.playerTotals) {
      cells.push({
        playerId: row.player.id,
        sessionIndex: detail.sessionIndex,
        score: row.score,
      });
    }
  }
  return cells;
}

export function buildRankDistribution(
  sessionDetails: SessionDetail[]
): RankDistributionRow[] {
  const byPlayer = new Map<string, [number, number, number, number]>();

  for (const detail of sessionDetails) {
    const sorted = [...detail.playerTotals].sort((a, b) => b.score - a.score);
    let rank = 1;
    for (let i = 0; i < sorted.length; i++) {
      if (i > 0 && sorted[i].score < sorted[i - 1].score) rank = i + 1;
      const ranks = byPlayer.get(sorted[i].player.id) ?? [0, 0, 0, 0];
      ranks[Math.min(rank - 1, 3)] += 1;
      byPlayer.set(sorted[i].player.id, ranks);
    }
  }

  return [...byPlayer.entries()].map(([playerId, ranks]) => ({ playerId, ranks }));
}

export function buildSessionDayOutcomes(
  sessionDetails: SessionDetail[],
  players: HistoricalPlayer[]
): DivergingRow[] {
  const totals = new Map(players.map((p) => [p.id, { wins: 0, losses: 0 }]));

  for (const detail of sessionDetails) {
    for (const row of detail.playerTotals) {
      const t = totals.get(row.player.id)!;
      if (row.score > 0) t.wins += 1;
      else if (row.score < 0) t.losses += 1;
    }
  }

  return players.map((player) => {
    const t = totals.get(player.id)!;
    return {
      playerId: player.id,
      playerName: player.name,
      wins: t.wins,
      losses: t.losses,
    };
  });
}

export function sessionProgressToSeries(
  progressPoints: SessionProgressPoint[],
  playerOrder: string[]
) {
  const byPlayer = new Map<string, { x: number; y: number }[]>();
  for (const p of progressPoints) {
    (byPlayer.get(p.playerId) ?? byPlayer.set(p.playerId, []).get(p.playerId))!.push({
      x: p.gameNumber,
      y: p.cumulativeScore,
    });
  }
  return playerOrder.map((playerId, colorIndex) => ({
    id: playerId,
    name: playerId,
    colorIndex,
    points: byPlayer.get(playerId) ?? [],
  }));
}
