const SUIT_SYMBOL: Record<string, string> = {
  Spar: "♠",
  Klør: "♣",
  Hjerter: "♥",
  Ruder: "♦",
};

export function suitSymbol(name?: string | null): string {
  if (!name) return "—";
  return SUIT_SYMBOL[name] ?? "—";
}

export function suitColorVar(name?: string | null): string {
  if (name === "Hjerter" || name === "Ruder") return "var(--score-neg)";
  return "var(--text)";
}

export function isRedTrump(name?: string | null): boolean {
  return name === "Hjerter" || name === "Ruder";
}

/** Termometerfarve: trumf-kulør, neutral ved sans. */
export function thermometerColor(trumpSuit?: string | null, gameType?: string | null): string {
  if (!trumpSuit) {
    const gt = (gameType ?? "").toLowerCase();
    if (gt.includes("sans") || gt.includes("gode")) {
      return "var(--thermo-neutral)";
    }
    return "var(--thermo-neutral)";
  }
  return suitColorVar(trumpSuit);
}

/** Rød overlay ved underbud med rød trumf — mørk tekst i appen. */
export function thermometerUnderColor(trumpSuit?: string | null): string {
  return isRedTrump(trumpSuit) ? "var(--text)" : "var(--score-neg)";
}

export function scoreLabel(n: number): string {
  return n > 0 ? `+${n}` : String(n);
}

/** Udvider gamle forkortelser (Alm, VIP 1) til fulde spiltype-navne. */
export function formatGameTypeLabel(raw?: string | null): string {
  if (!raw?.trim()) return "Spil";
  const key = raw.trim().toLowerCase();
  const aliases: Record<string, string> = {
    alm: "Almindelige",
    "vip 1": "VIP i første",
    "vip 2": "VIP i anden",
    "vip 3": "VIP i tredje",
  };
  return aliases[key] ?? raw.trim();
}

export function scoreToneClass(tone?: string): string {
  if (tone === "positive") return " poster-top--pos";
  if (tone === "negative") return " poster-top--neg";
  return "";
}

export function actionClass(actionText: string, borderTone?: string, live?: boolean): string {
  if (live || actionText === "MELDER") {
    return " poster-action--outline";
  }
  if (borderTone === "positive") return " poster-action--pos";
  if (borderTone === "negative") return " poster-action--neg";
  return "";
}

export type ThermoLayers = {
  bidPct: number;
  overPct: number;
  underPct: number;
  underBottomPct: number;
};

/** Beregner termometer-lag som i ActiveGameTrumpPoster. */
export function thermoLayers(
  bidTricks: number,
  actualTricks?: number | null
): ThermoLayers {
  const bid = Math.max(0, Math.min(13, bidTricks));
  const bidPct = (bid / 13) * 100;

  if (actualTricks == null) {
    return { bidPct, overPct: 0, underPct: 0, underBottomPct: 0 };
  }

  const actual = Math.max(0, Math.min(13, actualTricks));
  if (actual > bid) {
    return {
      bidPct,
      overPct: ((actual - bid) / 13) * 100,
      underPct: 0,
      underBottomPct: bidPct,
    };
  }
  if (actual < bid) {
    return {
      bidPct,
      overPct: 0,
      underPct: ((bid - actual) / 13) * 100,
      underBottomPct: (actual / 13) * 100,
    };
  }
  return { bidPct, overPct: 0, underPct: 0, underBottomPct: bidPct };
}
