"use client";

import Link from "next/link";
import {
  DivergingBarChart,
  WinRateChart,
} from "@/components/stats/charts/StatsCharts";
import { GameTypeIconBarChart } from "@/components/stats/charts/GameTypeIconBarChart";
import { GameTypeCell } from "@/components/stats/GameTypeCell";
import { SessionGamesAccordionTable } from "@/components/stats/SessionGamesAccordionTable";
import { PlayerLinesChart } from "@/components/stats/PlayerLinesChart";
import { StatsPageShell } from "@/components/stats/StatsPageShell";
import { useClubStats } from "@/hooks/useClubStats";
import { scoreClass, scoreLabel } from "@/lib/stats/format";
import { sessionDisplayTitle } from "@/lib/stats/historicalEngine";
import { gamePath, sessionPath } from "@/lib/stats/paths";
import type { SessionDetail } from "@/lib/stats/historicalTypes";

function SessionDetailContent({ detail }: { detail: SessionDetail }) {
  const playerNames = Object.fromEntries(
    detail.playerTotals.map((p) => [p.player.id, p.player.name])
  );

  const bestGame = detail.bestGameId
    ? detail.games.find((g) => g.id === detail.bestGameId)
    : null;
  const worstGame = detail.worstGameId
    ? detail.games.find((g) => g.id === detail.worstGameId)
    : null;

  const series = detail.playerTotals.map((row, colorIndex) => ({
    id: row.player.id,
    name: row.player.name,
    colorIndex,
    points: detail.progressPoints
      .filter((p) => p.playerId === row.player.id)
      .map((p) => ({ x: p.gameNumber, y: p.cumulativeScore })),
  }));

  return (
    <div className="stats-detail">
      <p className="stats-detail-sub">{sessionDisplayTitle(detail.session)}</p>

      <section className="stats-panel">
        <h3 className="stats-section-title">Udvikling</h3>
        <PlayerLinesChart
          series={series}
          ariaLabel="Kumulativ stilling gennem spilledagen"
          height={160}
          xLabel="Spilnummer"
        />
      </section>

      <section className="stats-panel">
        <h3 className="stats-section-title">Dagens resultat</h3>
        <div className="stats-hub-standing-strip">
          {detail.playerTotals.map((row, i) => (
            <article
              key={row.player.id}
              className="stats-hub-standing-chip"
              style={{ borderColor: `var(--stats-line-${i + 1})` }}
            >
              <span className="stats-hub-standing-name">{row.player.name.toUpperCase()}</span>
              <span className={`stats-hub-standing-score${scoreClass(row.score)}`}>
                {scoreLabel(row.score)}
              </span>
            </article>
          ))}
        </div>
      </section>

      {(detail.bestGameId || detail.worstGameId) && (
        <section className="stats-panel stats-outcome-cards">
          {detail.bestGameId && bestGame ? (
            <Link href={gamePath(detail.bestGameId)} className="stats-outcome-card stats-outcome-card--pos">
              <span className="stats-outcome-label">Største gevinst</span>
              <span className="stats-outcome-sub">
                Spil #{bestGame.gameNumber} ·{" "}
                <GameTypeCell label={bestGame.gameType} iconKind={bestGame.iconKind} />
              </span>
              <span className="stats-outcome-value">{scoreLabel(detail.bestGameScore ?? 0)}</span>
            </Link>
          ) : null}
          {detail.worstGameId && worstGame ? (
            <Link href={gamePath(detail.worstGameId)} className="stats-outcome-card stats-outcome-card--neg">
              <span className="stats-outcome-label">Største tab</span>
              <span className="stats-outcome-sub">
                Spil #{worstGame.gameNumber} ·{" "}
                <GameTypeCell label={worstGame.gameType} iconKind={worstGame.iconKind} />
              </span>
              <span className="stats-outcome-value">{scoreLabel(detail.worstGameScore ?? 0)}</span>
            </Link>
          ) : null}
        </section>
      )}

      <section className="stats-panel">
        <WinRateChart
          title="Sejrsprocent (vundne vs. tabte spil)"
          rows={detail.dayOutcomes.map((o) => ({
            label: playerNames[o.playerId] ?? o.playerId,
            wins: o.wins,
            losses: o.losses,
            zeros: o.zeros,
          }))}
        />
      </section>

      <section className="stats-panel">
        <DivergingBarChart
          title="Tabte / vundne spil på dagen"
          rows={detail.dayOutcomes.map((o, i) => ({
            label: playerNames[o.playerId] ?? o.playerId,
            left: o.losses,
            right: o.wins,
            colorIndex: i,
          }))}
        />
      </section>

      {detail.gameTypeCounts.length > 0 ? (
        <section className="stats-panel">
          <GameTypeIconBarChart
            title="Spiltyper på dagen"
            slices={detail.gameTypeCounts.map((g) => ({
              title: g.type,
              count: g.count,
              iconKind: g.iconKind,
            }))}
          />
        </section>
      ) : null}

      <section className="stats-panel">
        <h3 className="stats-section-title">Alle spil</h3>
        <SessionGamesAccordionTable
          playerNames={detail.playerTotals.map((p) => p.player.name)}
          rows={detail.games.map((g) => ({
            id: g.id,
            gameNumber: g.gameNumber,
            typeLabel: g.gameType,
            iconKind: g.iconKind,
            scores: detail.playerTotals.map((p) => g.scores[p.player.id] ?? 0),
            resume: g.resume,
            href: gamePath(g.id),
          }))}
        />
      </section>
    </div>
  );
}

export function SessionDetailView({ sessionIndex }: { sessionIndex: number }) {
  const { model, error, loading } = useClubStats();
  const detail = model?.sessionDetails.find((d) => d.sessionIndex === sessionIndex);

  return (
    <StatsPageShell
      title={detail ? `Spilledag ${detail.session.sessionNumber}` : `Spilledag ${sessionIndex}`}
      backHref="/statistik/alle-spilledage"
      backLabel="Alle spilledage"
    >
      {error ? (
        <div className="banner" role="alert">
          Kan ikke hente data — {error}
        </div>
      ) : null}
      {loading && !detail ? <p className="stats-loading">Indlæser…</p> : null}
      {!loading && !detail ? (
        <p className="stats-empty">
          Spilledag #{sessionIndex} findes ikke.{" "}
          <Link href="/statistik/alle-spilledage">Tilbage til oversigt</Link>
        </p>
      ) : null}
      {detail ? <SessionDetailContent detail={detail} /> : null}
    </StatsPageShell>
  );
}

export function LiveSessionDetailLink({ sessionNumber }: { sessionNumber?: number }) {
  if (sessionNumber == null) return null;
  return (
    <p className="stats-live-link">
      <Link href={sessionPath(sessionNumber)}>Se historisk spilledagsdetalje →</Link>
    </p>
  );
}
