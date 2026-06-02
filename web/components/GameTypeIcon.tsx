import type { ReactNode } from "react";
import { NoTrumpIcon } from "@/components/NoTrumpIcon";
import { SolGameIcon, solKindFromLabel } from "@/components/SolGameIcon";

export type GameTypeIconKind =
  | { type: "almindelige" }
  | { type: "halve" }
  | { type: "gode" }
  | { type: "sans" }
  | { type: "vip"; level: number }
  | { type: "sol"; solKind: "normal" | "pure" | "halfDealer" | "dealer" }
  | { type: "duty" }
  | { type: "unknown" };

export function gameTypeIconKindFromHand(
  kind: string,
  caption: string
): GameTypeIconKind {
  const narrative = caption.toLowerCase();
  if (kind === "sol") {
    return { type: "sol", solKind: solKindFromLabel(caption) };
  }
  if (kind === "duty" || narrative.includes("duestraf")) {
    return { type: "duty" };
  }
  if (narrative.includes("vip i tredje") || narrative.includes("vip 3")) {
    return { type: "vip", level: 3 };
  }
  if (narrative.includes("vip i anden") || narrative.includes("vip 2")) {
    return { type: "vip", level: 2 };
  }
  if (narrative.includes("vip i første") || narrative.includes("vip 1") || narrative.includes("vip")) {
    return { type: "vip", level: 1 };
  }
  if (narrative.includes("gode")) return { type: "gode" };
  if (narrative.includes("halve")) return { type: "halve" };
  if (narrative.includes("sans")) return { type: "sans" };
  if (narrative.includes("almindelige") || narrative.includes("alm.")) {
    return { type: "almindelige" };
  }
  return { type: "unknown" };
}

function GameCard({
  children,
  label,
}: {
  children?: ReactNode;
  label: string;
}) {
  return (
    <span className="game-type-card" role="img" aria-label={label}>
      {children}
    </span>
  );
}

/** Spiltype-ikon som SenesteSpilGameTypeIcon i appen. */
export function GameTypeIcon({ kind }: { kind: GameTypeIconKind }) {
  switch (kind.type) {
    case "sol":
      return (
        <span className="game-type-icon game-type-icon--sol" role="img" aria-label="Sol">
          <SolGameIcon solKind={kind.solKind} size={22} />
        </span>
      );
    case "duty":
      return (
        <GameCard label="Duestraf">
          <span className="game-type-duty">!</span>
        </GameCard>
      );
    case "unknown":
      return (
        <GameCard label="Spiltype ukendt">
          <span className="game-type-unknown">?</span>
        </GameCard>
      );
    case "almindelige":
      return <GameCard label="Almindelige" />;
    case "halve":
      return (
        <GameCard label="Halve">
          <span className="game-type-halve" aria-hidden="true" />
        </GameCard>
      );
    case "gode":
      return (
        <GameCard label="Gode">
          <span className="game-type-gode">♣</span>
        </GameCard>
      );
    case "sans":
      return (
        <GameCard label="Sans">
          <NoTrumpIcon size={16} />
        </GameCard>
      );
    case "vip":
      return (
        <GameCard label={`VIP ${kind.level}`}>
          <span className="game-type-vip">V{kind.level}</span>
        </GameCard>
      );
  }
}
