import type { HistoricalGame } from "@/lib/stats/historicalTypes";

function normalizedText(value: string | null | undefined): string {
  return value?.trim().toLowerCase() ?? "";
}

/**
 * Spejler Whist20/Domain/HistoricalStatisticsPreparer.swift → HistoricalGameTypeClassifier.
 * Returnerer kanonisk dansk spiltype-navn, eller null hvis typen ikke kan klassificeres.
 */
export function canonicalGameType(game: HistoricalGame): string | null {
  const normalized = normalizedText(game.gameTypeNormalized);
  const raw = normalizedText(game.gameTypeRaw);
  const combined = `${normalized} ${raw}`;

  if (combined.includes("halv bord") || combined.includes("halv bordlaeg")) {
    return "Halv bordlægger";
  }
  if (
    combined.includes("bordlægger") ||
    combined.includes("bordlaegger") ||
    combined.includes("bordlaegning")
  ) {
    return "Bordlægger";
  }
  if (combined.includes("ren sol") || combined.includes("rent sol") || combined.includes("ren_sol")) {
    return "Ren sol";
  }
  if (combined.includes("sol")) {
    return "Sol";
  }
  if (combined.includes("vip")) {
    return "VIP";
  }
  if (combined.includes("sans") || combined.includes("sang")) {
    return "Sans";
  }
  if (combined.includes("gode")) {
    return "Gode";
  }
  if (combined.includes("halve")) {
    return "Halve";
  }
  if (
    normalized === "alm" ||
    combined.includes(" almindelige") ||
    combined.includes(" alm") ||
    combined.startsWith("alm")
  ) {
    return "Almindelige";
  }
  if (combined.includes("duestraf") || combined.includes("duefejl") || combined.includes("due fejl")) {
    return "Duestraf";
  }

  return null;
}

/**
 * Spejler StatistikTabView.gameTypeText — bruges til visning i tabeller og spildetaljer.
 */
export function gameTypeLabel(game: HistoricalGame): string {
  const canonical = canonicalGameType(game);
  if (canonical) return canonical;

  const raw = game.gameTypeRaw?.trim();
  if (raw) return raw;

  const normalized = game.gameTypeNormalized?.trim();
  if (normalized) {
    return normalized.replace(/_/g, " ").replace(/^\w/, (c) => c.toUpperCase());
  }

  return "—";
}
