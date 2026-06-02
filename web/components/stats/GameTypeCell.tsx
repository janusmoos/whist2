"use client";

import { GameTypeIcon } from "@/components/GameTypeIcon";
import {
  gameTypeIconKindFromLabel,
  type GameTypeIconKind,
} from "@/lib/stats/gameTypeIcons";

export function GameTypeCell({
  label,
  iconKind,
  showLabel = false,
}: {
  label?: string | null;
  iconKind?: GameTypeIconKind;
  /** I tabeller: kun ikon (tekst i aria-label på ikonet). */
  showLabel?: boolean;
}) {
  const resolved =
    iconKind ?? (label && label !== "—" ? gameTypeIconKindFromLabel(label) : { type: "unknown" as const });

  if (resolved.type === "unknown" && !label) {
    return <span className="stats-game-type-cell stats-game-type-cell--empty">—</span>;
  }

  return (
    <span className="stats-game-type-cell">
      <GameTypeIcon kind={resolved} />
      {showLabel && label && label !== "—" ? (
        <span className="stats-game-type-cell-label">{label}</span>
      ) : null}
    </span>
  );
}
