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
  gameTypes: GameTypeOverview[];
  trends: {
    recentSessionLimit: number;
    all: PlayerScoreSummary[];
    recent: PlayerScoreSummary[];
  };
  dataQuality: {
    generatedAt: string;
    dataVersion: string;
    sessionCount: number;
    gameCount: number;
    playerResultCount: number;
    zeroSumGameCount: number;
    gamesWithQualityFlags: number;
    topQualityFlags: { flag: string; count: number }[];
  };
};
