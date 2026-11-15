import type { HandSummary } from "@/components/HandsTable";
import { gameTypeIconKindFromHand } from "@/components/GameTypeIcon";
import type { GameTypeIconKind } from "@/lib/stats/gameTypeIcons";

export type GameTypeCounts = {
  normal: number;
  sol: number;
  duty: number;
  other: number;
};

export type HandHighlight = {
  handNumber: number;
  score: number;
};

export type PlayerDayStats = {
  seat: number;
  name: string;
  total: number;
  rank: number;
  handCount: number;
  averagePerHand: number;
  bestHand: HandHighlight | null;
  worstHand: HandHighlight | null;
  /** Kumulativ stilling efter hver kamp (samme rækkefølge som orderedHands). */
  cumulative: number[];
};

export type SessionSwing = {
  handNumber: number;
  playerName: string;
  score: number;
};

export type DayOutcome = {
  seat: number;
  name: string;
  wins: number;
  losses: number;
  zeros: number;
};

export type ScoreStreak = {
  playerName: string;
  seat: number;
  kind: "win" | "loss";
  games: number;
  totalScore: number;
};

export type StreakSummary = {
  longestWin: ScoreStreak | null;
  longestLoss: ScoreStreak | null;
};

export type GameTypeSlice = {
  title: string;
  count: number;
  iconKind: GameTypeIconKind;
};

export type HandRow = {
  handNumber: number;
  typeLabel: string;
  iconKind: GameTypeIconKind;
  scoresBySeat: number[];
  caption: string;
};

export type SessionDayStats = {
  handCount: number;
  gameTypes: GameTypeCounts;
  players: PlayerDayStats[];
  /** Spillere i sæde-rækkefølge (til stillingspanel). */
  playersBySeat: PlayerDayStats[];
  biggestSwing: SessionSwing | null;
  bestHand: SessionSwing | null;
  worstHand: SessionSwing | null;
  dayOutcomes: DayOutcome[];
  streaks: StreakSummary;
  gameTypeSlices: GameTypeSlice[];
  handRows: HandRow[];
  orderedHands: HandSummary[];
};

function orderedHands(hands: HandSummary[]): HandSummary[] {
  return [...hands].sort((a, b) => {
    if (a.handNumber >= 1 && b.handNumber >= 1 && a.handNumber !== b.handNumber) {
      return a.handNumber - b.handNumber;
    }
    return 0;
  });
}

function normalizeKind(kind: string): keyof GameTypeCounts {
  const k = kind.trim().toLowerCase();
  if (k === "normal") return "normal";
  if (k === "sol") return "sol";
  if (k === "duty") return "duty";
  return "other";
}

function rankPlayers(totals: number[]): number[] {
  const indexed = totals.map((total, seat) => ({ total, seat }));
  indexed.sort((a, b) => b.total - a.total);
  const ranks = new Array<number>(totals.length).fill(1);
  let rank = 1;
  for (let i = 0; i < indexed.length; i++) {
    if (i > 0 && indexed[i].total < indexed[i - 1].total) rank = i + 1;
    ranks[indexed[i].seat] = rank;
  }
  return ranks;
}

/** Kanonisk visningsnavn for live-kamp — spejler appens gameTypeText/classifier. */
export function liveGameTypeLabel(hand: HandSummary): string {
  const iconKind = gameTypeIconKindFromHand(hand.kind, hand.caption);
  switch (iconKind.type) {
    case "almindelige":
      return "Almindelige";
    case "halve":
      return "Halve";
    case "gode":
      return "Gode";
    case "sans":
      return "Sans";
    case "vip":
      return "VIP";
    case "sol":
      return iconKind.solKind === "pure" ? "Ren sol" : "Sol";
    case "duty":
      return "Duestraf";
    default:
      return hand.kind?.trim() || "—";
  }
}

function computeStreaks(names: string[], sorted: HandSummary[]): StreakSummary {
  const allStreaks: ScoreStreak[] = [];

  for (let seat = 0; seat < names.length; seat++) {
    let activeKind: "win" | "loss" | null = null;
    let activeGames = 0;
    let activeTotal = 0;

    const finish = () => {
      if (activeKind && activeGames > 0) {
        allStreaks.push({
          playerName: names[seat] ?? `#${seat + 1}`,
          seat,
          kind: activeKind,
          games: activeGames,
          totalScore: activeTotal,
        });
      }
      activeKind = null;
      activeGames = 0;
      activeTotal = 0;
    };

    for (const h of sorted) {
      const score = h.scoresBySeat[seat] ?? 0;
      const kind: "win" | "loss" | null = score > 0 ? "win" : score < 0 ? "loss" : null;
      if (!kind) {
        finish();
        continue;
      }
      if (activeKind !== kind) {
        finish();
        activeKind = kind;
      }
      activeGames += 1;
      activeTotal += score;
    }
    finish();
  }

  const pickBest = (streaks: ScoreStreak[], preferHigher: boolean): ScoreStreak | null => {
    if (streaks.length === 0) return null;
    return streaks.reduce((best, cur) => {
      if (cur.games !== best.games) return cur.games > best.games ? cur : best;
      if (cur.totalScore !== best.totalScore) {
        return preferHigher
          ? cur.totalScore > best.totalScore
            ? cur
            : best
          : cur.totalScore < best.totalScore
            ? cur
            : best;
      }
      return cur.seat < best.seat ? cur : best;
    });
  };

  return {
    longestWin: pickBest(
      allStreaks.filter((s) => s.kind === "win"),
      true
    ),
    longestLoss: pickBest(
      allStreaks.filter((s) => s.kind === "loss"),
      false
    ),
  };
}

function buildGameTypeSlices(sorted: HandSummary[]): GameTypeSlice[] {
  const buckets = new Map<string, { count: number; iconKind: GameTypeIconKind }>();
  for (const hand of sorted) {
    const title = liveGameTypeLabel(hand);
    const iconKind = gameTypeIconKindFromHand(hand.kind, hand.caption);
    const cur = buckets.get(title) ?? { count: 0, iconKind };
    cur.count += 1;
    buckets.set(title, cur);
  }
  return [...buckets.entries()]
    .map(([title, { count, iconKind }]) => ({ title, count, iconKind }))
    .sort((a, b) => {
      if (a.count !== b.count) return a.count - b.count;
      return a.title.localeCompare(b.title, "da");
    });
}

/** Beregner spilledags-statistik udelukkende fra `hands[]` og spillernavne. */
export function computeSessionDayStats(
  hands: HandSummary[],
  names: string[]
): SessionDayStats | null {
  if (names.length !== 4 || hands.length === 0) return null;

  const sorted = orderedHands(hands);
  const gameTypes: GameTypeCounts = { normal: 0, sol: 0, duty: 0, other: 0 };

  for (const h of sorted) {
    gameTypes[normalizeKind(h.kind)] += 1;
  }

  const cumulativeBySeat = names.map(() => 0);
  const cumulativeSeries = names.map(() => [] as number[]);
  const bestBySeat = names.map((): HandHighlight | null => null);
  const worstBySeat = names.map((): HandHighlight | null => null);
  const dayOutcomes: DayOutcome[] = names.map((name, seat) => ({
    seat,
    name,
    wins: 0,
    losses: 0,
    zeros: 0,
  }));

  let biggestSwing: SessionSwing | null = null;
  let bestHand: SessionSwing | null = null;
  let worstHand: SessionSwing | null = null;

  for (const h of sorted) {
    for (let seat = 0; seat < 4; seat++) {
      const score = h.scoresBySeat[seat] ?? 0;
      cumulativeBySeat[seat] += score;
      cumulativeSeries[seat].push(cumulativeBySeat[seat]);

      const highlight: HandHighlight = { handNumber: h.handNumber, score };
      const best = bestBySeat[seat];
      if (!best || score > best.score) bestBySeat[seat] = highlight;
      const worst = worstBySeat[seat];
      if (!worst || score < worst.score) worstBySeat[seat] = highlight;

      const outcome = dayOutcomes[seat];
      if (score > 0) outcome.wins += 1;
      else if (score < 0) outcome.losses += 1;
      else outcome.zeros += 1;

      const swing: SessionSwing = {
        handNumber: h.handNumber,
        playerName: names[seat] ?? `#${seat + 1}`,
        score,
      };

      if (!biggestSwing || Math.abs(score) > Math.abs(biggestSwing.score)) {
        biggestSwing = swing;
      }
      if (!bestHand || score > bestHand.score) {
        bestHand = swing;
      }
      if (!worstHand || score < worstHand.score) {
        worstHand = swing;
      }
    }
  }

  const ranks = rankPlayers(cumulativeBySeat);
  const handCount = sorted.length;

  const playersBySeat: PlayerDayStats[] = names.map((name, seat) => ({
    seat,
    name,
    total: cumulativeBySeat[seat],
    rank: ranks[seat],
    handCount,
    averagePerHand:
      handCount > 0 ? Math.round((cumulativeBySeat[seat] / handCount) * 10) / 10 : 0,
    bestHand: bestBySeat[seat],
    worstHand: worstBySeat[seat],
    cumulative: cumulativeSeries[seat],
  }));

  const players = [...playersBySeat].sort((a, b) => a.rank - b.rank || b.total - a.total);

  const handRows: HandRow[] = sorted.map((hand) => ({
    handNumber: hand.handNumber,
    typeLabel: liveGameTypeLabel(hand),
    iconKind: gameTypeIconKindFromHand(hand.kind, hand.caption),
    scoresBySeat: hand.scoresBySeat,
    caption: hand.caption,
  }));

  return {
    handCount,
    gameTypes,
    players,
    playersBySeat,
    biggestSwing,
    bestHand,
    worstHand,
    dayOutcomes,
    streaks: computeStreaks(names, sorted),
    gameTypeSlices: buildGameTypeSlices(sorted),
    handRows: [...handRows].reverse(),
    orderedHands: sorted,
  };
}

export function gameTypeSummaryLabel(counts: GameTypeCounts): string {
  const parts: string[] = [];
  if (counts.normal > 0) {
    parts.push(`${counts.normal} alm.${counts.normal === 1 ? "" : "."}`);
  }
  if (counts.sol > 0) {
    parts.push(`${counts.sol} sol`);
  }
  if (counts.duty > 0) {
    parts.push(`${counts.duty} duestraf`);
  }
  if (counts.other > 0) {
    parts.push(`${counts.other} andet`);
  }
  return parts.length > 0 ? parts.join(" · ") : "—";
}
