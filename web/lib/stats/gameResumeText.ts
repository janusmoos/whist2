import type { HistoricalGame, HistoricalPlayer } from "@/lib/stats/historicalTypes";
import { canonicalGameType } from "@/lib/stats/gameTypeClassifier";

function playerName(id: string | null | undefined, players: HistoricalPlayer[]): string {
  if (!id?.trim()) return "—";
  return players.find((p) => p.id === id)?.name ?? id;
}

export function gameTypeLabelFromHistorical(game: HistoricalGame): string {
  const canonical = canonicalGameType(game);
  if (canonical) return canonical;
  if (game.gameTypeRaw?.trim()) return game.gameTypeRaw.trim();
  if (game.gameTypeNormalized?.trim()) {
    return game.gameTypeNormalized.replace(/_/g, " ");
  }
  return "—";
}

function historicalBidPhrase(gameType: string, bid: number, game: HistoricalGame): string {
  const raw = `${game.gameTypeRaw ?? ""} ${game.gameTypeNormalized ?? ""}`.toLowerCase();
  switch (gameType) {
    case "Almindelige":
      return `${bid} almindelige`;
    case "Sans":
      return `${bid} sans uden trumf`;
    case "Gode":
      return `${bid} gode`;
    case "Halve":
      return `${bid} halve`;
    case "VIP": {
      if (raw.includes("vip i 3") || raw.includes("vip 3")) return `${bid} VIP i 3.`;
      if (raw.includes("vip i 2") || raw.includes("vip 2")) return `${bid} VIP i 2.`;
      if (raw.includes("vip i 1") || raw.includes("vip 1")) return `${bid} VIP i 1.`;
      return `${bid} VIP`;
    }
    case "Ren sol":
      return "ren sol";
    case "Sol":
      return "sol";
    default:
      return `${bid} ${gameType.toLowerCase()}`;
  }
}

function isSolType(gameType: string): boolean {
  return gameType === "Sol" || gameType === "Ren sol";
}

/** Forenklet port af appens gameResumeText til historiske spil. */
export function historicalGameResume(
  game: HistoricalGame,
  players: HistoricalPlayer[],
  scores: Record<string, number>
): string | null {
  const n = game.gameNumberInSession;
  const gameType = gameTypeLabelFromHistorical(game);
  const bidder = playerName(game.bidderId, players);
  const bid = game.bidTricks;

  if (gameType === "Duestraf") {
    const holder = bidder !== "—" ? bidder : playerName(game.winnerId, players);
    return `Spil #${n}: Duestraf til ${holder}`;
  }

  if (isSolType(gameType)) {
    if (bidder !== "—") {
      return `Spil #${n}: ${bidder} meldte ${gameType.toLowerCase()}`;
    }
    return `Spil #${n}: Der blev meldt ${gameType.toLowerCase()}`;
  }

  if (bidder !== "—" && bid != null) {
    return `Spil #${n}: ${bidder} meldte ${historicalBidPhrase(gameType, bid, game)}`;
  }

  if (bidder !== "—") {
    return `Spil #${n}: ${bidder} meldte ${gameType !== "—" ? gameType.toLowerCase() : "spil"}`;
  }

  if (gameType !== "—") {
    return `Spil #${n}: ${gameType}`;
  }

  if ((game.qualityFlags ?? []).length > 0) {
    return `Spil #${n}: Resumé ikke tilgængelig i historikken`;
  }

  return null;
}

/** Visbar resume-linje fra live-kamp (som HandsTable.captionText). */
export function liveHandResume(caption: string): string {
  return caption.replace(/\|\|[^|]*/g, "").trim();
}
