import type { HandSummary } from "@/components/HandsTable";

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

export type SessionDayStats = {
  handCount: number;
  gameTypes: GameTypeCounts;
  players: PlayerDayStats[];
  /** Største enkeltstående point (positiv eller negativ) på dagen. */
  biggestSwing: SessionSwing | null;
  /** Kampe i kronologisk rækkefølge. */
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
  let biggestSwing: SessionSwing | null = null;

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

      if (
        !biggestSwing ||
        Math.abs(score) > Math.abs(biggestSwing.score)
      ) {
        biggestSwing = {
          handNumber: h.handNumber,
          playerName: names[seat] ?? `#${seat + 1}`,
          score,
        };
      }
    }
  }

  const ranks = rankPlayers(cumulativeBySeat);
  const handCount = sorted.length;

  const players: PlayerDayStats[] = names.map((name, seat) => ({
    seat,
    name,
    total: cumulativeBySeat[seat],
    rank: ranks[seat],
    handCount,
    averagePerHand:
      handCount > 0
        ? Math.round((cumulativeBySeat[seat] / handCount) * 10) / 10
        : 0,
    bestHand: bestBySeat[seat],
    worstHand: worstBySeat[seat],
    cumulative: cumulativeSeries[seat],
  }));

  players.sort((a, b) => a.rank - b.rank || b.total - a.total);

  return {
    handCount,
    gameTypes,
    players,
    biggestSwing,
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
