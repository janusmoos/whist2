import type { HistoricalGame, HistoricalWhistData } from "@/lib/stats/historicalTypes";
import { canonicalGameType } from "@/lib/stats/gameTypeClassifier";
import { gameTypeIconKindFromHistorical, gameTypeIconKindFromLabel, type GameTypeIconKind } from "@/lib/stats/gameTypeIcons";

export const SOL_GAME_TYPES = ["Sol", "Ren sol", "Halv bordlægger", "Bordlægger"] as const;

export const BID_TRICK_GAME_TYPES = ["Almindelige", "Sans", "Halve", "Gode", "VIP"] as const;

export const BID_TRICK_COLUMNS = [8, 9, 10, 11, 12, 13] as const;

export type PlayerHeatmapCellData = {
  gameType: string;
  iconKind: GameTypeIconKind;
  bidTricks: number | null;
  averageScore: number;
  games: number;
};

export type PlayerBidTrickHeatmapData = {
  rows: { gameType: string; iconKind: GameTypeIconKind }[];
  columns: number[];
  cells: PlayerHeatmapCellData[];
  maxAbs: number;
};

export type PlayerSolHeatmapData = {
  cells: PlayerHeatmapCellData[];
  maxAbs: number;
};

export type PlayerHeatmapBundle = {
  bidTrick: PlayerBidTrickHeatmapData | null;
  sol: PlayerSolHeatmapData | null;
};

function isSolType(type: string): boolean {
  return (SOL_GAME_TYPES as readonly string[]).includes(type);
}

function resolveBidTricks(game: HistoricalGame): number | null {
  const bid = game.bidTricks;
  if (bid == null) return null;
  if (bid >= 8 && bid <= 13) return bid;
  return null;
}

type Bucket = { totalScore: number; games: number; iconKind: GameTypeIconKind };

function bucketKey(gameType: string, bidTricks: number | null): string {
  return bidTricks == null ? gameType : `${gameType}:${bidTricks}`;
}

export function buildPlayerHeatmaps(
  data: HistoricalWhistData,
  playerId: string
): PlayerHeatmapBundle {
  const gameById = new Map(data.games.map((g) => [g.id, g]));
  const bidBuckets = new Map<string, Bucket>();
  const solBuckets = new Map<string, Bucket>();

  for (const result of data.playerResults) {
    if (result.playerId !== playerId) continue;
    const game = gameById.get(result.gameId);
    if (!game) continue;

    const gameType = canonicalGameType(game);
    if (!gameType) continue;

    const iconKind = gameTypeIconKindFromHistorical(game);

    if (isSolType(gameType)) {
      const cur = solBuckets.get(gameType) ?? { totalScore: 0, games: 0, iconKind };
      cur.totalScore += result.score;
      cur.games += 1;
      solBuckets.set(gameType, cur);
      continue;
    }

    const bidTricks = resolveBidTricks(game);
    if (bidTricks == null) continue;
    if (!(BID_TRICK_GAME_TYPES as readonly string[]).includes(gameType)) continue;

    const key = bucketKey(gameType, bidTricks);
    const cur = bidBuckets.get(key) ?? { totalScore: 0, games: 0, iconKind };
    cur.totalScore += result.score;
    cur.games += 1;
    bidBuckets.set(key, cur);
  }

  const bidCells: PlayerHeatmapCellData[] = [];
  for (const [key, bucket] of bidBuckets) {
    const [gameType, bidStr] = key.includes(":") ? key.split(":") : [key, null];
    bidCells.push({
      gameType,
      iconKind: bucket.iconKind,
      bidTricks: bidStr != null ? Number(bidStr) : null,
      averageScore: bucket.totalScore / bucket.games,
      games: bucket.games,
    });
  }

  const bidRows = BID_TRICK_GAME_TYPES.filter((type) =>
    bidCells.some((c) => c.gameType === type)
  ).map((gameType) => ({
    gameType,
    iconKind: gameTypeIconKindFromLabel(gameType),
  }));

  const bidMaxAbs =
    bidCells.length > 0 ? Math.max(1, ...bidCells.map((c) => Math.abs(c.averageScore))) : 1;

  const solCells: PlayerHeatmapCellData[] = SOL_GAME_TYPES.filter((t) => solBuckets.has(t)).map(
    (gameType) => {
      const bucket = solBuckets.get(gameType)!;
      return {
        gameType,
        iconKind: bucket.iconKind,
        bidTricks: null,
        averageScore: bucket.totalScore / bucket.games,
        games: bucket.games,
      };
    }
  );

  const solMaxAbs =
    solCells.length > 0 ? Math.max(1, ...solCells.map((c) => Math.abs(c.averageScore))) : 1;

  return {
    bidTrick:
      bidCells.length > 0
        ? {
            rows: bidRows,
            columns: [...BID_TRICK_COLUMNS],
            cells: bidCells,
            maxAbs: bidMaxAbs,
          }
        : null,
    sol:
      solCells.length > 0
        ? {
            cells: solCells,
            maxAbs: solMaxAbs,
          }
        : null,
  };
}

export function buildAllPlayerHeatmaps(
  data: HistoricalWhistData
): Record<string, PlayerHeatmapBundle> {
  const out: Record<string, PlayerHeatmapBundle> = {};
  for (const player of data.players) {
    out[player.id] = buildPlayerHeatmaps(data, player.id);
  }
  return out;
}

export function findHeatmapCell(
  cells: PlayerHeatmapCellData[],
  gameType: string,
  bidTricks: number | null
): PlayerHeatmapCellData | undefined {
  return cells.find((c) => c.gameType === gameType && c.bidTricks === bidTricks);
}
