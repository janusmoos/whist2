import type { CSSProperties, ReactNode } from "react";
import { NoTrumpIcon } from "@/components/NoTrumpIcon";
import { SolGameIcon, solKindFromLabel } from "@/components/SolGameIcon";
import { SuitColoredText } from "@/components/SuitColoredText";
import type { PosterScoreItem, PosterSnapshot } from "@/lib/posterTypes";
import {
  actionClass,
  scoreLabel,
  scoreToneClass,
  suitColorVar,
  suitSymbol,
  thermoLayers,
  thermometerColor,
  thermometerUnderColor,
} from "@/lib/posterHelpers";

function ScoreStrip({ items, large }: { items: PosterScoreItem[]; large?: boolean }) {
  if (items.length === 0) return null;
  return (
    <div className={`poster-score-strip${large ? " poster-score-strip--large" : ""}`}>
      {items.map((item, i) => (
        <div
          key={i}
          className={`poster-score-chip${item.role === "bidder" ? " poster-score-chip--bidder" : item.role === "partner" ? " poster-score-chip--partner" : ""}`}
        >
          <span className="poster-score-name">{item.name}</span>
          <span
            className={`poster-score-value${item.score > 0 ? " score--pos" : item.score < 0 ? " score--neg" : ""}`}
          >
            {scoreLabel(item.score)}
          </span>
        </div>
      ))}
    </div>
  );
}

function Thermometer({
  bidTricks,
  actualTricks,
  trumpSuit,
  gameType,
}: {
  bidTricks: number;
  actualTricks?: number | null;
  trumpSuit?: string | null;
  gameType?: string | null;
}) {
  const color = thermometerColor(trumpSuit, gameType);
  const underColor = thermometerUnderColor(trumpSuit);
  const { bidPct, overPct, underPct, underBottomPct } = thermoLayers(
    bidTricks,
    actualTricks
  );

  return (
    <div
      className="poster-thermo"
      style={{ "--thermo-color": color, "--thermo-under": underColor } as CSSProperties}
      aria-hidden="true"
    >
      <div className="poster-thermo-track">
        <div className="poster-thermo-bg" />
        <div className="poster-thermo-bid" style={{ height: `${bidPct}%` }} />
        {overPct > 0 ? (
          <div
            className="poster-thermo-over"
            style={{ height: `${overPct}%`, bottom: `${bidPct}%` }}
          />
        ) : null}
        {underPct > 0 ? (
          <div
            className="poster-thermo-under"
            style={{ height: `${underPct}%`, bottom: `${underBottomPct}%` }}
          />
        ) : null}
      </div>
    </div>
  );
}

function TrumpPoster({ p, live }: { p: PosterSnapshot; live?: boolean }) {
  const delta = p.resultDelta;
  const bid = p.bidTricks ?? 0;
  const isSans = !p.trumpSuit && (p.gameType ?? "").toLowerCase().includes("sans");

  return (
    <div className="poster-illustration">
      <div className={`poster-top${scoreToneClass(p.borderTone)}`}>
        <div className="poster-top-copy">
          <span className="poster-name">{p.bidderName.toUpperCase()}</span>
          <span
            className={`poster-action${actionClass(p.actionText, p.borderTone, live)}`}
          >
            {p.actionText}
          </span>
          <span className="poster-game-type">{(p.gameType ?? "SPIL").toUpperCase()}</span>
        </div>
        {p.bidTricks != null ? (
          <div className="poster-bid-wrap">
            <span className="poster-bid">{p.bidTricks}</span>
            {delta != null ? (
              <span
                className={`poster-delta${delta >= 0 ? " poster-delta--pos" : " poster-delta--neg"}`}
              >
                {delta > 0 ? `+${delta}` : delta}
              </span>
            ) : null}
          </div>
        ) : null}
        <Thermometer
          bidTricks={bid}
          actualTricks={p.actualTricks}
          trumpSuit={p.trumpSuit}
          gameType={p.gameType}
        />
      </div>

      {p.scoreItems && p.scoreItems.length > 0 ? (
        <ScoreStrip items={p.scoreItems} large={!live} />
      ) : null}

      <div className="poster-suit-row">
        <div className="poster-suit-panel">
          <span className="poster-suit-title">TRUMF</span>
          {p.isTrumpPending ? (
            <span className="poster-suit-pending">VÆLGES</span>
          ) : p.trumpSuit ? (
            <span
              className="poster-suit-symbol"
              style={{ color: suitColorVar(p.trumpSuit) }}
            >
              {suitSymbol(p.trumpSuit)}
            </span>
          ) : isSans ? (
            <NoTrumpIcon size={80} />
          ) : (
            <NoTrumpIcon size={80} />
          )}
        </div>
        <div className="poster-suit-panel">
          <span className="poster-suit-title">MAKKER</span>
          {p.partnerAceSuit ? (
            <span
              className="poster-suit-symbol"
              style={{ color: suitColorVar(p.partnerAceSuit) }}
            >
              {suitSymbol(p.partnerAceSuit)}
            </span>
          ) : (
            <span className="poster-suit-symbol poster-suit-symbol--empty">—</span>
          )}
        </div>
      </div>
    </div>
  );
}

function SolPoster({ p, live }: { p: PosterSnapshot; live?: boolean }) {
  const solKind = solKindFromLabel(p.solType);
  return (
    <div className="poster-illustration">
      <div className={`poster-top poster-top--sol${scoreToneClass(p.borderTone)}`}>
        <div className="poster-top-copy">
          <span className="poster-name">{p.bidderName.toUpperCase()}</span>
          <span
            className={`poster-action${actionClass(p.actionText, p.borderTone, live)}`}
          >
            {p.actionText}
          </span>
          <span className="poster-game-type">{(p.solType ?? "SOL").toUpperCase()}</span>
        </div>
        <div className="poster-sol-icon-wrap">
          <SolGameIcon solKind={solKind} size={88} />
        </div>
      </div>
      {p.scoreItems && p.scoreItems.length > 0 ? (
        <ScoreStrip items={p.scoreItems} large={!live} />
      ) : null}
      {p.allyNames && p.allyNames.length > 0 ? (
        <p className="poster-allies">Går med: {p.allyNames.join(", ")}</p>
      ) : null}
    </div>
  );
}

function ResumePanel({ text }: { text: string }) {
  return (
    <div className="poster-resume">
      <p>
        <SuitColoredText text={text.replace(/\|\|[^|]*/g, "")} />
      </p>
    </div>
  );
}

function PosterIllustration({
  poster,
  live,
}: {
  poster: PosterSnapshot;
  live?: boolean;
}) {
  if (poster.posterKind === "sol") return <SolPoster p={poster} live={live} />;
  if (poster.posterKind === "trump") return <TrumpPoster p={poster} live={live} />;
  return null;
}

export function PosterBox({
  title,
  live,
  poster,
  emptyText,
  children,
}: {
  title: string;
  live?: boolean;
  poster?: PosterSnapshot | null;
  emptyText?: string;
  children?: ReactNode;
}) {
  return (
    <section className={`poster-box${live ? " poster-box--live" : ""}`}>
      <header className="poster-box-header">
        {live ? <span className="poster-live-dot" aria-hidden="true" /> : null}
        <h3 className="poster-box-title">{title}</h3>
      </header>

      {children ? (
        children
      ) : poster ? (
        <>
          {poster.posterKind !== "text" ? (
            <PosterIllustration poster={poster} live={live} />
          ) : null}
          <ResumePanel text={poster.resumeLine} />
        </>
      ) : (
        <p className="poster-empty">{emptyText}</p>
      )}
    </section>
  );
}
