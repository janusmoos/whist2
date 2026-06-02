import type { GameTypeIconKind } from "@/lib/stats/gameTypeIcons";
import type { PlayerHeatmapBundle } from "@/lib/stats/playerGameTypeStats";

export type HistoricalPlayer = {
  id: string;
  name: string;
  displayOrder: number;
  isActive?: boolean;
};

export type HistoricalSession = {
  id: string;
  sessionNumber: string;
  date?: string;
  location?: string;
  importedGameCount: number;
  expectedGameCount?: number;
  qualityStatus?: string;
};

export type HistoricalGame = {
  id: string;
  sessionId: string;
  sessionNumber?: string;
  gameNumberInSession: number;
  gameTypeRaw?: string | null;
  gameTypeNormalized?: string | null;
  bidTricks?: number | null;
  bidderId?: string | null;
  bidderIds?: string[];
  winnerId?: string | null;
  winnerIds?: string[];
  partnerId?: string | null;
  dealerId?: string | null;
  checksum?: number | null;
  qualityFlags?: string[];
};

export type HistoricalPlayerResult = {
  id: string;
  gameId: string;
  playerId: string;
  score: number;
};

export type HistoricalWhistData = {
  version: string;
  generatedAt: string;
  players: HistoricalPlayer[];
  sessions: HistoricalSession[];
  games: HistoricalGame[];
  playerResults: HistoricalPlayerResult[];
  auditSummary?: {
    fieldCounts?: {
      scoreSumZero?: number;
    };
  };
};

export type ScoreTimelinePoint = {
  playerId: string;
  playerName: string;
  sessionId: string;
  sessionTitle: string;
  sessionIndex: number;
  cumulativeScore: number;
  sessionScore: number;
  gamesInSession: number;
};

export type PlayerScoreSummary = {
  player: HistoricalPlayer;
  totalScore: number;
  gamesPlayed: number;
  averageScore: number;
  bestSingleGame: number | null;
  worstSingleGame: number | null;
  bestSessionIndex: number | null;
  bestSessionScore: number | null;
  worstSessionIndex: number | null;
  worstSessionScore: number | null;
};

export type SessionProgressPoint = {
  playerId: string;
  gameId: string;
  gameNumber: number;
  gameScore: number;
  cumulativeScore: number;
};

export type SessionGameRow = {
  id: string;
  gameNumber: number;
  gameType: string | null;
  iconKind: GameTypeIconKind;
  scores: Record<string, number>;
  qualityFlags: string[];
  resume: string | null;
};

export type SessionDetail = {
  session: HistoricalSession;
  sessionIndex: number;
  gamesPlayed: number;
  playerTotals: { player: HistoricalPlayer; score: number }[];
  issueCount: number;
  progressPoints: SessionProgressPoint[];
  games: SessionGameRow[];
  bestGameId: string | null;
  bestGameScore: number | null;
  worstGameId: string | null;
  worstGameScore: number | null;
  gameTypeCounts: { type: string; count: number; iconKind: GameTypeIconKind }[];
  dayOutcomes: { playerId: string; wins: number; losses: number; zeros: number }[];
};

export type PlayerProfile = {
  summary: PlayerScoreSummary;
  sessionScores: PlayerSessionScore[];
  bestGameId: string | null;
  bestGameScore: number | null;
  worstGameId: string | null;
  worstGameScore: number | null;
};

export type GameRecord = {
  id: string;
  sessionId: string;
  sessionIndex: number;
  gameNumber: number;
  gameType: string | null;
  iconKind: GameTypeIconKind;
  scores: Record<string, number>;
  qualityFlags: string[];
};

export type HeatmapCell = {
  playerId: string;
  sessionIndex: number;
  score: number;
};

export type RankDistributionRow = {
  playerId: string;
  ranks: [number, number, number, number];
};

export type DivergingRow = {
  playerId: string;
  playerName: string;
  wins: number;
  losses: number;
};

export type ScopedTimeline = {
  scope: "all" | "recent";
  recentLimit: number;
  timelinePoints: ScoreTimelinePoint[];
  playerSummaries: PlayerScoreSummary[];
};

export type PlayerSessionScore = {
  playerId: string;
  sessionId: string;
  sessionTitle: string;
  sessionIndex: number;
  score: number;
  gamesInSession: number;
};

export type SessionOverview = {
  session: HistoricalSession;
  sessionIndex: number;
  gamesPlayed: number;
  playerTotals: { player: HistoricalPlayer; score: number }[];
  issueCount: number;
};

export type GameTypeOverview = {
  gameType: string;
  games: number;
  playerTotals: { player: HistoricalPlayer; games: number; totalScore: number; averageScore: number }[];
};

export type ClubHubSnapshot = {
  generatedAt: string;
  dataVersion: string;
  sessionCount: number;
  gameCount: number;
  issueCount: number;
  zeroSumGameCount: number;
  playerSummaries: PlayerScoreSummary[];
  timelinePoints: ScoreTimelinePoint[];
};

export type ClubStatsModel = {
  hub: ClubHubSnapshot;
  sessions: SessionOverview[];
  sessionDetails: SessionDetail[];
  playerProfiles: PlayerProfile[];
  games: Record<string, GameRecord>;
  heatmap: HeatmapCell[];
  rankDistribution: RankDistributionRow[];
  sessionDayOutcomes: DivergingRow[];
  gameTypes: GameTypeOverview[];
  playerHeatmaps: Record<string, PlayerHeatmapBundle>;
  trends: {
    recentSessionLimit: number;
    all: PlayerScoreSummary[];
    recent: PlayerScoreSummary[];
    scopedTimelines: ScopedTimeline[];
  };
  dataQuality: {
    generatedAt: string;
    dataVersion: string;
    sessionCount: number;
    gameCount: number;
    playerResultCount: number;
    zeroSumGameCount: number;
    gamesWithQualityFlags: number;
    gamesWithIssues: number;
    topQualityFlags: { flag: string; count: number }[];
  };
};
