import type {
  ClubHubSnapshot,
  ClubStatsModel,
  GameTypeOverview,
  HistoricalGame,
  HistoricalPlayer,
  HistoricalSession,
  HistoricalWhistData,
  PlayerScoreSummary,
  PlayerSessionScore,
  ScoreTimelinePoint,
  ScopedTimeline,
  SessionOverview,
} from "@/lib/stats/historicalTypes";
import {
  buildGameIndex,
  buildHeatmap,
  buildPlayerProfiles,
  buildRankDistribution,
  buildSessionDayOutcomes,
  buildSessionDetails,
  enrichPlayerSummaries,
} from "@/lib/stats/historicalDetails";
import { canonicalGameType } from "@/lib/stats/gameTypeClassifier";
import { buildAllPlayerHeatmaps } from "@/lib/stats/playerGameTypeStats";

function sortedPlayers(players: HistoricalPlayer[]): HistoricalPlayer[] {
  return [...players].sort((a, b) => {
    if (a.displayOrder !== b.displayOrder) return a.displayOrder - b.displayOrder;
    return a.name.localeCompare(b.name, "da");
  });
}

function sessionDisplayTitle(session: HistoricalSession): string {
  const parts = [`#${session.sessionNumber}`];
  if (session.date) parts.push(session.date);
  if (session.location) parts.push(session.location);
  return parts.join(" · ");
}

function gamesWithIssues(games: HistoricalGame[]): number {
  return games.filter((g) => (g.qualityFlags?.length ?? 0) > 0).length;
}

function gameDetailsIssueCount(data: HistoricalWhistData): number {
  return data.games.filter((g) => (g.qualityFlags?.length ?? 0) > 0).length;
}

export function playerSessionScores(
  data: HistoricalWhistData
): Record<string, PlayerSessionScore[]> {
  const players = sortedPlayers(data.players);
  const gameById = new Map(data.games.map((g) => [g.id, g]));
  const gamesBySession = groupBy(data.games, (g) => g.sessionId);
  const sessionOrder = new Map(
    data.sessions.map((s, i) => [s.id, i + 1] as const)
  );

  const totalsBySessionAndPlayer = new Map<string, Map<string, number>>();
  for (const result of data.playerResults) {
    const game = gameById.get(result.gameId);
    if (!game) continue;
    if (!totalsBySessionAndPlayer.has(game.sessionId)) {
      totalsBySessionAndPlayer.set(game.sessionId, new Map());
    }
    const map = totalsBySessionAndPlayer.get(game.sessionId)!;
    map.set(result.playerId, (map.get(result.playerId) ?? 0) + result.score);
  }

  const output: Record<string, PlayerSessionScore[]> = {};
  for (const session of data.sessions) {
    const index = sessionOrder.get(session.id) ?? 0;
    const gamesInSession =
      gamesBySession.get(session.id)?.length ?? session.importedGameCount;
    const sessionTotals = totalsBySessionAndPlayer.get(session.id) ?? new Map();
    for (const player of players) {
      (output[player.id] ??= []).push({
        playerId: player.id,
        sessionId: session.id,
        sessionTitle: sessionDisplayTitle(session),
        sessionIndex: index,
        score: sessionTotals.get(player.id) ?? 0,
        gamesInSession,
      });
    }
  }
  return output;
}

export function scoreTimeline(data: HistoricalWhistData): ScoreTimelinePoint[] {
  const players = sortedPlayers(data.players);
  const gameById = new Map(data.games.map((g) => [g.id, g]));
  const gamesBySession = groupBy(data.games, (g) => g.sessionId);
  const sessionOrder = new Map(
    data.sessions.map((s, i) => [s.id, i + 1] as const)
  );

  const sessionTotalsByPlayer = new Map<string, Map<string, number>>();
  for (const result of data.playerResults) {
    const game = gameById.get(result.gameId);
    if (!game) continue;
    if (!sessionTotalsByPlayer.has(game.sessionId)) {
      sessionTotalsByPlayer.set(game.sessionId, new Map());
    }
    const map = sessionTotalsByPlayer.get(game.sessionId)!;
    map.set(result.playerId, (map.get(result.playerId) ?? 0) + result.score);
  }

  const runningTotals = new Map(players.map((p) => [p.id, 0]));
  const points: ScoreTimelinePoint[] = [];

  for (const session of data.sessions) {
    const index = sessionOrder.get(session.id) ?? points.length + 1;
    const sessionTotals = sessionTotalsByPlayer.get(session.id) ?? new Map();
    const gamesInSession =
      gamesBySession.get(session.id)?.length ?? session.importedGameCount;

    for (const player of players) {
      const sessionScore = sessionTotals.get(player.id) ?? 0;
      runningTotals.set(player.id, (runningTotals.get(player.id) ?? 0) + sessionScore);
      points.push({
        playerId: player.id,
        playerName: player.name,
        sessionId: session.id,
        sessionTitle: sessionDisplayTitle(session),
        sessionIndex: index,
        cumulativeScore: runningTotals.get(player.id) ?? 0,
        sessionScore,
        gamesInSession,
      });
    }
  }

  return points;
}

export function playerScoreSummaries(data: HistoricalWhistData): PlayerScoreSummary[] {
  const grouped = groupBy(data.playerResults, (r) => r.playerId);

  return sortedPlayers(data.players)
    .map((player) => {
      const results = grouped.get(player.id) ?? [];
      const scores = results.map((r) => r.score);
      const total = scores.reduce((a, b) => a + b, 0);
      const count = scores.length;
      return {
        player,
        totalScore: total,
        gamesPlayed: count,
        averageScore: count > 0 ? total / count : 0,
        bestSingleGame: scores.length ? Math.max(...scores) : null,
        worstSingleGame: scores.length ? Math.min(...scores) : null,
        bestSessionIndex: null,
        bestSessionScore: null,
        worstSessionIndex: null,
        worstSessionScore: null,
      };
    })
    .sort((a, b) => {
      if (a.totalScore !== b.totalScore) return b.totalScore - a.totalScore;
      return a.player.displayOrder - b.player.displayOrder;
    });
}

export function sessionOverviews(data: HistoricalWhistData): SessionOverview[] {
  const players = sortedPlayers(data.players);
  const gameById = new Map(data.games.map((g) => [g.id, g]));
  const gamesBySession = groupBy(data.games, (g) => g.sessionId);
  const issuesBySession = new Map<string, number>();

  for (const game of data.games) {
    if ((game.qualityFlags?.length ?? 0) > 0) {
      issuesBySession.set(
        game.sessionId,
        (issuesBySession.get(game.sessionId) ?? 0) + 1
      );
    }
  }

  return data.sessions.map((session, i) => {
    const sessionGames = gamesBySession.get(session.id) ?? [];
    const totals = new Map<string, number>();
    for (const result of data.playerResults) {
      const game = gameById.get(result.gameId);
      if (!game || game.sessionId !== session.id) continue;
      totals.set(result.playerId, (totals.get(result.playerId) ?? 0) + result.score);
    }

    return {
      session,
      sessionIndex: i + 1,
      gamesPlayed: sessionGames.length || session.importedGameCount,
      playerTotals: players.map((player) => ({
        player,
        score: totals.get(player.id) ?? 0,
      })),
      issueCount: issuesBySession.get(session.id) ?? 0,
    };
  });
}

export function gameTypeOverviews(data: HistoricalWhistData): GameTypeOverview[] {
  const players = sortedPlayers(data.players);
  const gameById = new Map(data.games.map((g) => [g.id, g]));
  const buckets = new Map<
    string,
    { gameIds: Set<string>; players: Map<string, { games: number; totalScore: number }> }
  >();

  for (const game of data.games) {
    const type = canonicalGameType(game);
    if (!type) continue;
    if (!buckets.has(type)) {
      buckets.set(type, { gameIds: new Set(), players: new Map() });
    }
    buckets.get(type)!.gameIds.add(game.id);
  }

  for (const result of data.playerResults) {
    const game = gameById.get(result.gameId);
    if (!game) continue;
    const type = canonicalGameType(game);
    if (!type) continue;
    const bucket = buckets.get(type);
    if (!bucket) continue;
    const cur = bucket.players.get(result.playerId) ?? { games: 0, totalScore: 0 };
    cur.games += 1;
    cur.totalScore += result.score;
    bucket.players.set(result.playerId, cur);
  }

  return [...buckets.entries()]
    .map(([gameType, bucket]) => ({
      gameType,
      games: bucket.gameIds.size,
      playerTotals: players.map((player) => {
        const stats = bucket.players.get(player.id) ?? { games: 0, totalScore: 0 };
        return {
          player,
          games: stats.games,
          totalScore: stats.totalScore,
          averageScore: stats.games > 0 ? stats.totalScore / stats.games : 0,
        };
      }),
    }))
    .sort((a, b) => b.games - a.games);
}

function filterRecentSessions(
  data: HistoricalWhistData,
  limit: number
): HistoricalWhistData {
  const sessions = data.sessions.slice(-limit);
  const sessionIds = new Set(sessions.map((s) => s.id));
  const games = data.games.filter((g) => sessionIds.has(g.sessionId));
  const gameIds = new Set(games.map((g) => g.id));
  const playerResults = data.playerResults.filter((r) => gameIds.has(r.gameId));
  return { ...data, sessions, games, playerResults };
}

export function buildClubStatsModel(data: HistoricalWhistData): ClubStatsModel {
  const recentLimit = 10;
  const sessionScoresByPlayer = playerSessionScores(data);
  const baseSummaries = playerScoreSummaries(data);
  const summaries = enrichPlayerSummaries(baseSummaries, sessionScoresByPlayer);
  const sessionDetails = buildSessionDetails(data);
  const issueCount = gameDetailsIssueCount(data);
  const zeroSumGameCount =
    data.auditSummary?.fieldCounts?.scoreSumZero ??
    data.games.filter((g) => (g.checksum ?? 0) === 0).length;

  const flagCounts = new Map<string, number>();
  for (const game of data.games) {
    for (const flag of game.qualityFlags ?? []) {
      flagCounts.set(flag, (flagCounts.get(flag) ?? 0) + 1);
    }
  }

  const hub: ClubHubSnapshot = {
    generatedAt: data.generatedAt,
    dataVersion: data.version,
    sessionCount: data.sessions.length,
    gameCount: data.games.length,
    issueCount,
    zeroSumGameCount,
    playerSummaries: summaries,
    timelinePoints: scoreTimeline(data),
  };

  const recentData = filterRecentSessions(data, recentLimit);
  const scopedTimelines: ScopedTimeline[] = [
    {
      scope: "all",
      recentLimit,
      timelinePoints: scoreTimeline(data),
      playerSummaries: summaries,
    },
    {
      scope: "recent",
      recentLimit,
      timelinePoints: scoreTimeline(recentData),
      playerSummaries: enrichPlayerSummaries(
        playerScoreSummaries(recentData),
        playerSessionScores(recentData)
      ),
    },
  ];

  return {
    hub,
    sessions: sessionOverviews(data),
    sessionDetails,
    playerProfiles: buildPlayerProfiles(data, summaries, sessionScoresByPlayer),
    games: buildGameIndex(data, sessionDetails),
    heatmap: buildHeatmap(sessionDetails),
    rankDistribution: buildRankDistribution(sessionDetails),
    sessionDayOutcomes: buildSessionDayOutcomes(sessionDetails, sortedPlayers(data.players)),
    gameTypes: gameTypeOverviews(data),
    playerHeatmaps: buildAllPlayerHeatmaps(data),
    trends: {
      recentSessionLimit: recentLimit,
      all: summaries,
      recent: enrichPlayerSummaries(
        playerScoreSummaries(recentData),
        playerSessionScores(recentData)
      ),
      scopedTimelines,
    },
    dataQuality: {
      generatedAt: data.generatedAt,
      dataVersion: data.version,
      sessionCount: data.sessions.length,
      gameCount: data.games.length,
      playerResultCount: data.playerResults.length,
      zeroSumGameCount,
      gamesWithQualityFlags: gamesWithIssues(data.games),
      gamesWithIssues: issueCount,
      topQualityFlags: [...flagCounts.entries()]
        .sort((a, b) => b[1] - a[1])
        .slice(0, 12)
        .map(([flag, count]) => ({ flag, count })),
    },
  };
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

export { sessionDisplayTitle };
