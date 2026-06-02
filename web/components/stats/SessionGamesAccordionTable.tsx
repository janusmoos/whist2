"use client";

import Link from "next/link";
import { Fragment, useState, type MouseEvent } from "react";
import { GameTypeCell } from "@/components/stats/GameTypeCell";
import type { GameTypeIconKind } from "@/lib/stats/gameTypeIcons";
import { SuitColoredText } from "@/components/SuitColoredText";
import { scoreClass, scoreLabel } from "@/lib/stats/format";

export type SessionGameTableRow = {
  id: string;
  gameNumber: number;
  typeLabel?: string | null;
  iconKind?: GameTypeIconKind;
  scores: number[];
  resume: string | null;
  href?: string;
};

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
      className="hands-table-expand stats-games-accordion-expand"
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

function GameNumberCell({ row }: { row: SessionGameTableRow }) {
  const label = `#${row.gameNumber}`;
  if (row.href) {
    return (
      <Link href={row.href} className="stats-games-accordion-link">
        {label}
      </Link>
    );
  }
  return <span className="stats-games-accordion-num">{label}</span>;
}

function AccordionRow({
  row,
  expanded,
  onToggle,
}: {
  row: SessionGameTableRow;
  expanded: boolean;
  onToggle: () => void;
}) {
  const label = `spil ${row.gameNumber}`;
  const hasResume = Boolean(row.resume?.trim());

  return (
    <Fragment>
      <tr
        className={hasResume ? "stats-games-accordion-row stats-games-accordion-row--interactive" : undefined}
        onClick={hasResume ? onToggle : undefined}
        onKeyDown={
          hasResume
            ? (e) => {
                if (e.key === "Enter" || e.key === " ") {
                  e.preventDefault();
                  onToggle();
                }
              }
            : undefined
        }
        tabIndex={hasResume ? 0 : undefined}
        role={hasResume ? "button" : undefined}
        aria-expanded={hasResume ? expanded : undefined}
      >
        <td>
          <GameNumberCell row={row} />
        </td>
        <td>
          <GameTypeCell label={row.typeLabel} iconKind={row.iconKind} />
        </td>
        {row.scores.map((score, i) => (
          <td key={i} className={scoreClass(score)}>
            {scoreLabel(score)}
          </td>
        ))}
        <td className="stats-games-accordion-expand-col">
          {hasResume ? (
            <ExpandToggle
              expanded={expanded}
              onToggle={(e) => {
                e.stopPropagation();
                onToggle();
              }}
              label={label}
            />
          ) : null}
        </td>
      </tr>
      {hasResume && expanded ? (
        <tr className="hands-table-resume-row stats-games-accordion-resume-row">
          <td colSpan={3 + row.scores.length}>
            <div className="hands-table-resume-box">
              <SuitColoredText text={row.resume!} />
            </div>
          </td>
        </tr>
      ) : null}
    </Fragment>
  );
}

export function SessionGamesAccordionTable({
  playerNames,
  rows,
}: {
  playerNames: string[];
  rows: SessionGameTableRow[];
}) {
  const [expandedId, setExpandedId] = useState<string | null>(null);

  if (rows.length === 0) {
    return <p className="stats-empty">Ingen spil at vise.</p>;
  }

  return (
    <div className="stats-games-table-wrap">
      <table className="stats-games-table stats-games-table--accordion">
        <thead>
          <tr>
            <th>#</th>
            <th>Type</th>
            {playerNames.map((name) => (
              <th key={name}>{name}</th>
            ))}
            <th className="stats-games-accordion-expand-col" aria-label="Resumé" />
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <AccordionRow
              key={row.id}
              row={row}
              expanded={expandedId === row.id}
              onToggle={() => setExpandedId((cur) => (cur === row.id ? null : row.id))}
            />
          ))}
        </tbody>
      </table>
    </div>
  );
}
