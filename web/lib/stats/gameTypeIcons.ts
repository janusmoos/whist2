import type { HistoricalGame } from "@/lib/stats/historicalTypes";
import { canonicalGameType, gameTypeLabel } from "@/lib/stats/gameTypeClassifier";

export type GameTypeIconKind =
  | { type: "almindelige" }
  | { type: "halve" }
  | { type: "gode" }
  | { type: "sans" }
  | { type: "vip"; level: number }
  | { type: "sol"; solKind: "normal" | "pure" | "halfDealer" | "dealer" }
  | { type: "duty" }
  | { type: "unknown" };

/** Spejler StatistikGameTypeIconKind(title:) i appen. */
export function gameTypeIconKindFromLabel(
  title: string | null | undefined,
  rawHint?: string | null
): GameTypeIconKind {
  const label = (title ?? "").trim();
  const raw = (rawHint ?? label).toLowerCase();
  const lower = label.toLowerCase();

  if (!label) return { type: "unknown" };
  if (lower === "duestraf") return { type: "duty" };
  if (lower === "almindelige") return { type: "almindelige" };
  if (lower === "halve") return { type: "halve" };
  if (lower === "gode") return { type: "gode" };
  if (lower === "sans") return { type: "sans" };
  if (lower === "ren sol") return { type: "sol", solKind: "pure" };
  if (lower === "halv bordlægger") return { type: "sol", solKind: "halfDealer" };
  if (lower === "bordlægger") return { type: "sol", solKind: "dealer" };
  if (lower === "sol") return { type: "sol", solKind: "normal" };
  if (lower === "vip" || lower.startsWith("vip")) {
    if (raw.includes("vip i 3") || raw.includes("vip 3") || lower === "vip 3") {
      return { type: "vip", level: 3 };
    }
    if (raw.includes("vip i 2") || raw.includes("vip 2") || lower === "vip 2") {
      return { type: "vip", level: 2 };
    }
    return { type: "vip", level: 1 };
  }

  return { type: "unknown" };
}

export function gameTypeIconKindFromHistorical(game: HistoricalGame): GameTypeIconKind {
  const label = canonicalGameType(game) ?? gameTypeLabel(game);
  const raw = `${game.gameTypeRaw ?? ""} ${game.gameTypeNormalized ?? ""}`;
  return gameTypeIconKindFromLabel(label === "—" ? null : label, raw);
}
