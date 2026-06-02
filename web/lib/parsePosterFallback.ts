import type { PosterSnapshot } from "./posterTypes";

const SUIT_MAP: Record<string, string> = {
  "♠": "Spar",
  "♣": "Klør",
  "♥": "Hjerter",
  "♦": "Ruder",
};

function lastSuit(text: string): string | null {
  let found: string | null = null;
  for (const ch of text) {
    if (SUIT_MAP[ch]) found = SUIT_MAP[ch];
  }
  return found;
}

function parseBidTricks(text: string): number | null {
  const m = text.match(/meld(?:te|er)\s+(\d+)/i);
  return m ? Number(m[1]) : null;
}

function parseGameType(text: string): string {
  const lower = text.toLowerCase();
  if (lower.includes("vip i tredje") || lower.includes("vip 3")) return "VIP 3";
  if (lower.includes("vip i anden") || lower.includes("vip 2")) return "VIP 2";
  if (lower.includes("vip")) return "VIP 1";
  if (lower.includes("gode")) return "Gode";
  if (lower.includes("halve")) return "Halve";
  if (lower.includes("sans")) return "Sans";
  if (lower.includes("almindelige") || lower.includes("alm.")) return "Alm";
  if (lower.includes("sol")) return "Sol";
  return "Spil";
}

function parseDelta(text: string): number | null {
  const m = text.match(/\(([+-]?\d+)\)\s*$/);
  return m ? Number(m[1]) : null;
}

function parseBidder(text: string): string {
  const m = text.match(/^(.+?)\s+meld(?:te|er)\s/i);
  return m ? m[1].trim() : "Melder";
}

/** Bygger et forenklet plakat-snapshot fra schema v1-tekst. */
export function posterFromCaption(
  caption: string,
  actionText: "MELDER" | "MELDTE"
): PosterSnapshot {
  const lower = caption.toLowerCase();
  const bidTricks = parseBidTricks(caption);
  const gameType = parseGameType(caption);
  const isSol = lower.includes(" sol") || lower.startsWith("sol");

  if (isSol) {
    return {
      posterKind: "sol",
      bidderName: parseBidder(caption),
      actionText,
      solType: gameType,
      allyNames: [],
      resumeLine: caption,
    };
  }

  if (lower.includes("duestraf")) {
    return {
      posterKind: "text",
      bidderName: parseBidder(caption) || "Duestraf",
      actionText,
      resumeLine: caption,
    };
  }

  const trumpIdx = caption.toLowerCase().indexOf("som trumf");
  const trumpSuit =
    trumpIdx >= 0 ? lastSuit(caption.slice(0, trumpIdx)) : lower.includes("sans") ? null : null;

  let partnerAceSuit: string | null = null;
  const partnerIdx = caption.toLowerCase().indexOf("som makker-es");
  if (partnerIdx >= 0) {
    partnerAceSuit = lastSuit(caption.slice(0, partnerIdx));
  }

  return {
    posterKind: bidTricks != null ? "trump" : "text",
    bidderName: parseBidder(caption),
    actionText,
    bidTricks,
    gameType,
    trumpSuit,
    partnerAceSuit,
    isTrumpPending: false,
    resultDelta: parseDelta(caption),
    borderTone: "neutral",
    resumeLine: caption,
  };
}
