import type { ReactNode } from "react";

/** ♠ ♣ = mørk tekst, ♥ ♦ = score-neg (rød) — som SuitColoredInlineText i appen. */
export function SuitColoredText({ text }: { text: string }) {
  const parts: ReactNode[] = [];
  for (let i = 0; i < text.length; i++) {
    const ch = text[i];
    if (ch === "♥" || ch === "♦") {
      parts.push(
        <span key={i} className="suit-inline suit-inline--red">
          {ch}
        </span>
      );
    } else if (ch === "♠" || ch === "♣") {
      parts.push(
        <span key={i} className="suit-inline suit-inline--black">
          {ch}
        </span>
      );
    } else {
      parts.push(<span key={i}>{ch}</span>);
    }
  }
  return <>{parts}</>;
}
