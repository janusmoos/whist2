export type PosterScoreItem = {
  name: string;
  score: number;
  role: "bidder" | "partner" | "none";
};

export type PosterSnapshot = {
  posterKind: "trump" | "sol" | "text";
  bidderName: string;
  actionText: string;
  bidTricks?: number | null;
  gameType?: string | null;
  trumpSuit?: string | null;
  partnerAceSuit?: string | null;
  isTrumpPending?: boolean;
  actualTricks?: number | null;
  resultDelta?: number | null;
  borderTone?: "positive" | "negative" | "neutral";
  solType?: string | null;
  allyNames?: string[];
  scoreItems?: PosterScoreItem[];
  resumeLine: string;
  handNumber?: number | null;
};

export type ThemeMode = "auto" | "light" | "dark";

export const THEME_STORAGE_KEY = "whist-live-theme";
