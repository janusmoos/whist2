"use client";

import type { HandSummary } from "@/components/HandsTable";
import {
  DivergingBarChart,
  WinRateChart,
} from "@/components/stats/charts/StatsCharts";
import { GameTypeIconBarChart } from "@/components/stats/charts/GameTypeIconBarChart";
import { GameTypeCell } from "@/components/stats/GameTypeCell";
import { SessionGamesAccordionTable } from "@/components/stats/SessionGamesAccordionTable";
import { PlayerLinesChart } from "@/components/stats/PlayerLinesChart";
import { scoreClass, scoreLabel } from "@/lib/stats/format";
import { liveHandResume } from "@/lib/stats/gameResumeText";
import {
  computeSessionDayStats,
  gameTypeSummaryLabel,
} from "@/lib/stats/sessionDayStats";
import type { GameTypeIconKind } from "@/lib/stats/gameTypeIcons";

function StreakTile({
  title,
  streak,
  fallback,
}: {
  title: string;
  streak: { playerName: string; games: number; totalScore: number } | null;
  fallback: string;
}) {
  return (
    <article className="stats-streak-tile">
      <span className="stats-streak-tile-label">{title}</span>
      <span className="stats-streak-tile-main">
        {streak ? `${streak.playerName} · ${streak.games} spil` : fallback}
      </span>
      <div className="stats-streak-tile-foot">
        <span>I alt</span>
        <span className={scoreClass(streak?.totalScore ?? 0).trim()}>
          {streak ? scoreLabel(streak.totalScore) : "—"}
        </span>
      </div>
    </article>
  );
}

function OutcomeCard({
  title,
  handNumber,
  typeLabel,
  iconKind,
  playerName,
  score,
  tone,
}: {
  title: string;
  handNumber: number;
  typeLabel: string;
  iconKind: GameTypeIconKind;
  playerName: string;
  score: number;
  tone: "pos" | "neg";
}) {
  return (
    <article className={`stats-outcome-card stats-outcome-card--${tone} stats-outcome-card--wide`}>
      <span className="stats-outcome-label">{title}</span>
      <span className="stats-outcome-sub stats-outcome-sub--inline">
        Kamp #{handNumber} · <GameTypeCell label={typeLabel} iconKind={iconKind} />
      </span>
      <span className="stats-outcome-player">{playerName}</span>
      <span className={`stats-outcome-value${scoreClass(score)}`}>{scoreLabel(score)}</span>
    </article>
  );
}

export function SessionDayStatsPanel({
  hands,
  names,
}: {
  hands: HandSummary[];
  names: string[];
}) {
  const stats = computeSessionDayStats(hands, names);
  if (!stats) return null;

  const handMetaByNumber = new Map(
    stats.handRows.map((row) => [row.handNumber, row] as const)
  );

  const series = stats.playersBySeat.map((p) => ({
    id: String(p.seat),
    name: p.name,
    colorIndex: p.seat,
    points: stats.orderedHands.map((hand, i) => ({
      x: hand.handNumber,
      y: p.cumulative[i] ?? 0,
    })),
  }));

  const labelColumn = stats.playersBySeat.map((p) => ({
    name: p.name,
    score: p.total,
    colorIndex: p.seat,
  }));

  const divergingRows = stats.dayOutcomes.map((o) => ({
    label: o.name,
    left: o.losses,
    right: o.wins,
    colorIndex: o.seat,
  }));

  return (
    <div className="stats-detail session-day-stats">
      <p className="session-stats-lead">
        {stats.handCount} {stats.handCount === 1 ? "kamp" : "kampe"} ·{" "}
        {gameTypeSummaryLabel(stats.gameTypes)}
      </p>

      {stats.handCount >= 2 ? (
        <section className="stats-panel">
          <h3 className="stats-section-title">Udvikling</h3>
          <PlayerLinesChart
            series={series}
            labelColumn={labelColumn}
            showLegend={false}
            ariaLabel="Kumulativ stilling pr. spiller gennem spilledagen"
            height={136}
            xLabel="Spil"
          />
        </section>
      ) : null}

      <section className="stats-panel stats-panel--flat">
        <h3 className="stats-section-title">Dagens resultat</h3>
        <div className="stats-hub-standing-strip">
          {stats.playersBySeat.map((player) => (
            <article
              key={player.seat}
              className="stats-hub-standing-chip"
              style={{ borderColor: `var(--stats-line-${player.seat + 1})` }}
            >
              <span className="stats-hub-standing-name">{player.name.toUpperCase()}</span>
              <span className={`stats-hub-standing-score${scoreClass(player.total)}`}>
                {scoreLabel(player.total)}
              </span>
            </article>
          ))}
        </div>
      </section>

      {(stats.bestHand || stats.worstHand) && (
        <section className="stats-outcome-cards">
          {stats.bestHand ? (
            <OutcomeCard
              title="Største gevinst"
              handNumber={stats.bestHand.handNumber}
              typeLabel={handMetaByNumber.get(stats.bestHand.handNumber)?.typeLabel ?? "—"}
              iconKind={
                handMetaByNumber.get(stats.bestHand.handNumber)?.iconKind ?? { type: "unknown" }
              }
              playerName={stats.bestHand.playerName}
              score={stats.bestHand.score}
              tone="pos"
            />
          ) : null}
          {stats.worstHand ? (
            <OutcomeCard
              title="Største tab"
              handNumber={stats.worstHand.handNumber}
              typeLabel={handMetaByNumber.get(stats.worstHand.handNumber)?.typeLabel ?? "—"}
              iconKind={
                handMetaByNumber.get(stats.worstHand.handNumber)?.iconKind ?? { type: "unknown" }
              }
              playerName={stats.worstHand.playerName}
              score={stats.worstHand.score}
              tone="neg"
            />
          ) : null}
        </section>
      )}

      <section className="stats-streak-grid">
        <StreakTile
          title="Længste sejrsrække"
          streak={stats.streaks.longestWin}
          fallback="Ingen sejre"
        />
        <StreakTile
          title="Længste tabsrække"
          streak={stats.streaks.longestLoss}
          fallback="Ingen tab"
        />
      </section>

      <section className="stats-panel">
        <WinRateChart
          title="Sejrsprocent"
          rows={stats.dayOutcomes.map((o) => ({
            label: o.name,
            wins: o.wins,
            losses: o.losses,
            zeros: o.zeros,
          }))}
        />
      </section>

      <section className="stats-panel">
        <DivergingBarChart
          title="Tabte / vundne spil på dagen"
          rows={divergingRows}
          emptyText="Ingen spilresultater på dagen."
        />
      </section>

      <section className="stats-panel">
        <GameTypeIconBarChart slices={stats.gameTypeSlices} />
      </section>

      <section className="stats-panel">
        <h3 className="stats-section-title">Alle kampe</h3>
        <SessionGamesAccordionTable
          playerNames={names}
          rows={stats.handRows.map((row) => ({
            id: String(row.handNumber),
            gameNumber: row.handNumber,
            typeLabel: row.typeLabel,
            iconKind: row.iconKind,
            scores: row.scoresBySeat,
            resume: liveHandResume(row.caption) || null,
          }))}
        />
      </section>
    </div>
  );
}
