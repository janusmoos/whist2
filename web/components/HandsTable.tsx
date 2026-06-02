"use client";

import { Fragment, useEffect, useRef, useState, type MouseEvent } from "react";
import { GameTypeIcon, gameTypeIconKindFromHand } from "@/components/GameTypeIcon";
import { SuitColoredText } from "@/components/SuitColoredText";

export type HandSummary = {
  handNumber: number;
  kind: string;
  caption: string;
  scoresBySeat: number[];
};

function scoreLabel(n: number): string {
  const v = Number(n);
  return v > 0 ? `+${v}` : String(v);
}

function scoreClass(n: number): string {
  const v = Number(n);
  if (v > 0) return " score--pos";
  if (v < 0) return " score--neg";
  return " score--zero";
}

function captionText(caption: string): string {
  return caption.replace(/\|\|[^|]*/g, "");
}

/** Under denne bredde skjules resumé-kolonnen til fordel for fold-ud. */
const COMPACT_BELOW_PX = 560;

function useCompactHandsTable(
  wrapRef: React.RefObject<HTMLDivElement | null>,
  layoutKey: string
) {
  const [compact, setCompact] = useState(false);

  useEffect(() => {
    const wrap = wrapRef.current;
    if (!wrap) return;

    const measure = () => {
      setCompact(wrap.clientWidth < COMPACT_BELOW_PX);
    };

    const ro = new ResizeObserver(measure);
    ro.observe(wrap);
    measure();
    return () => ro.disconnect();
  }, [layoutKey]);

  return compact;
}

function ExpandToggle({
  expanded,
  onToggle,
  label,
}: {
  expanded: boolean;
  onToggle: (e: MouseEvent<HTMLButtonElement>) => void;
  label: string;
}) {
  return (
    <button
      type="button"
      className="hands-table-expand"
      onClick={onToggle}
      aria-expanded={expanded}
      aria-label={expanded ? `Skjul resumé for ${label}` : `Vis resumé for ${label}`}
    >
      <span className="hands-table-expand-icon" aria-hidden="true">
        {expanded ? "▲" : "▼"}
      </span>
    </button>
  );
}

function ResumeCell({ caption }: { caption: string }) {
  return (
    <div className="hands-table-resume-box">
      <SuitColoredText text={captionText(caption)} />
    </div>
  );
}

function HandRow({
  hand,
  compact,
  expanded,
  onToggle,
}: {
  hand: HandSummary;
  compact: boolean;
  expanded: boolean;
  onToggle: () => void;
}) {
  const label = `kamp ${hand.handNumber}`;

  return (
    <Fragment>
      <tr
        className={compact ? "hands-table-row--compact hands-table-row--interactive" : undefined}
        onClick={compact ? onToggle : undefined}
        onKeyDown={
          compact
            ? (e) => {
                if (e.key === "Enter" || e.key === " ") {
                  e.preventDefault();
                  onToggle();
                }
              }
            : undefined
        }
        tabIndex={compact ? 0 : undefined}
        role={compact ? "button" : undefined}
        aria-expanded={compact ? expanded : undefined}
      >
        <td className="col-num">#{hand.handNumber}</td>
        <td className="col-type">
          <GameTypeIcon kind={gameTypeIconKindFromHand(hand.kind, hand.caption)} />
        </td>
        {!compact ? (
          <td className="col-caption">
            <SuitColoredText text={captionText(hand.caption)} />
          </td>
        ) : null}
        {hand.scoresBySeat.map((s, i) => (
          <td key={i} className={`col-score${scoreClass(s)}`}>
            {scoreLabel(s)}
          </td>
        ))}
        {compact ? (
          <td className="col-expand">
            <ExpandToggle
              expanded={expanded}
              onToggle={(e) => {
                e.stopPropagation();
                onToggle();
              }}
              label={label}
            />
          </td>
        ) : null}
      </tr>
      {compact && expanded ? (
        <tr className="hands-table-resume-row">
          <td colSpan={2 + hand.scoresBySeat.length + 1}>
            <ResumeCell caption={hand.caption} />
          </td>
        </tr>
      ) : null}
    </Fragment>
  );
}

export function HandsTable({
  hands,
  names,
  totals,
  handCount,
  lastCaption,
}: {
  hands: HandSummary[];
  names: string[];
  totals: number[];
  handCount?: number;
  lastCaption?: string | null;
}) {
  const wrapRef = useRef<HTMLDivElement>(null);
  const layoutKey = `${hands.length}:${names.join(",")}:${totals.join(",")}`;
  const compact = useCompactHandsTable(wrapRef, layoutKey);
  const [expandedHand, setExpandedHand] = useState<number | null>(null);

  useEffect(() => {
    setExpandedHand(null);
  }, [layoutKey, compact]);

  const metaColSpan = compact ? 2 : 3;

  if (hands.length === 0) {
    if ((handCount ?? 0) > 0 && lastCaption) {
      return (
        <div className="table-wrap" ref={wrapRef}>
          <table className={`hands-table${compact ? " hands-table--compact" : ""}`}>
            <thead>
              <tr>
                <th className="col-num">#</th>
                <th className="col-type" aria-label="Spiltype" />
                {!compact ? <th className="col-caption" /> : null}
                {names.map((n, i) => (
                  <th key={i} className="col-score">
                    {n}
                  </th>
                ))}
                {compact ? <th className="col-expand" aria-label="Resumé" /> : null}
              </tr>
            </thead>
            <tbody>
              <tr>
                <td className="col-num">{handCount}</td>
                <td className="col-type" />
                {!compact ? (
                  <td className="col-caption">
                    <SuitColoredText text={captionText(lastCaption)} />
                  </td>
                ) : null}
                {totals.map((_, i) => (
                  <td key={i} className="col-score score--zero">
                    —
                  </td>
                ))}
                {compact ? <td className="col-expand" /> : null}
              </tr>
            </tbody>
            <tfoot>
              <tr className="totals-row">
                <td colSpan={metaColSpan} className="col-totals-label">
                  Samlet stilling i dag
                </td>
                {totals.map((t, i) => (
                  <td key={i} className={`col-score${scoreClass(t)}`}>
                    {scoreLabel(t)}
                  </td>
                ))}
                {compact ? <td className="col-expand" /> : null}
              </tr>
            </tfoot>
          </table>
          <p className="table-legacy-note">
            Fuld kamptabel vises når appen sender opdateret data (genopbyg i simulator).
          </p>
        </div>
      );
    }
    return <p className="table-empty">Ingen kampe spillet endnu.</p>;
  }

  const reversed = [...hands].reverse();

  return (
    <div className="table-wrap" ref={wrapRef}>
      <table className={`hands-table${compact ? " hands-table--compact" : ""}`}>
        <thead>
          <tr>
            <th className="col-num">#</th>
            <th className="col-type" aria-label="Spiltype" />
            {!compact ? <th className="col-caption" /> : null}
            {names.map((n, i) => (
              <th key={i} className="col-score">
                {n}
              </th>
            ))}
            {compact ? <th className="col-expand" aria-label="Resumé" /> : null}
          </tr>
        </thead>
        <tbody>
          {reversed.map((h) => (
            <HandRow
              key={h.handNumber}
              hand={h}
              compact={compact}
              expanded={expandedHand === h.handNumber}
              onToggle={() =>
                setExpandedHand((cur) => (cur === h.handNumber ? null : h.handNumber))
              }
            />
          ))}
        </tbody>
        <tfoot>
          <tr className="totals-row">
            <td colSpan={metaColSpan} className="col-totals-label">
              Samlet stilling i dag
            </td>
            {totals.map((t, i) => (
              <td key={i} className={`col-score${scoreClass(t)}`}>
                {scoreLabel(t)}
              </td>
            ))}
            {compact ? <td className="col-expand" /> : null}
          </tr>
        </tfoot>
      </table>
    </div>
  );
}
