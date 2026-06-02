"use client";

import { useEffect, useRef, useState } from "react";
import { PosterBox } from "@/components/PosterBox";
import { ThemeMenu } from "@/components/ThemeMenu";
import { GameTypeIcon, gameTypeIconKindFromHand } from "@/components/GameTypeIcon";
import { SuitColoredText } from "@/components/SuitColoredText";
import { posterFromCaption } from "@/lib/parsePosterFallback";
import type { PosterSnapshot } from "@/lib/posterTypes";

// ── Typer ────────────────────────────────────────────────────────────────────

type HandSummary = {
  handNumber: number;
  kind: string;
  caption: string;
  scoresBySeat: number[];
};

type LiveSession = {
  schemaVersion?: number;
  sessionId?: string;
  title?: string;
  status?: string;
  handCount?: number;
  playerNamesBySeat?: string[];
  totalsBySeat?: number[];
  lastCompletedHandCaption?: string | null;
  hands?: HandSummary[];
  pendingPoster?: PosterSnapshot | null;
  lastHandPoster?: PosterSnapshot | null;
  pendingMeldingSummary?: string | null;
  pendingResultSummary?: string | null;
  pendingStep?: "melding" | "halve_trumf" | "resultat" | null;
  notesPublic?: string;
  updatedAt?: string;
  serverUpdatedAt?: string;
};

// ── Hjælpefunktioner ─────────────────────────────────────────────────────────

const STALE_SECONDS = 20;

function secondsSince(iso: string | undefined, now: number): number {
  if (!iso) return Infinity;
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return Infinity;
  return Math.floor((now - d.getTime()) / 1000);
}

function relativeTimeLabel(secs: number): string {
  if (!isFinite(secs)) return "—";
  if (secs < 5) return "nu";
  if (secs < 60) return `${secs} sek. siden`;
  const mins = Math.floor(secs / 60);
  if (mins < 60) return `${mins} min. siden`;
  return `${Math.floor(mins / 60)} t. siden`;
}

function scoreLabel(n: number): string {
  return n > 0 ? `+${n}` : String(n);
}

function scoreClass(n: number): string {
  const v = Number(n);
  if (v > 0) return " score--pos";
  if (v < 0) return " score--neg";
  return " score--zero";
}

function kindSymbol(_kind: string): string {
  return "";
}

// kindSymbol fjernet — spiltype vises via GameTypeIcon-kolonne

function buildStandings(names: string[], totals: number[]) {
  if (names.length !== 4 || totals.length !== 4) return [];
  const players = names.map((name, i) => ({
    name,
    total: totals[i] ?? 0,
    seat: i,
    rank: 0,
  }));
  players.sort((a, b) => b.total - a.total);
  let rank = 1;
  for (let i = 0; i < players.length; i++) {
    if (i > 0 && players[i].total < players[i - 1].total) rank = i + 1;
    players[i].rank = rank;
  }
  return players;
}

// ── Komponent: stilling (fallback når hands[] mangler) ─────────────────────

function StandingsStrip({
  names,
  totals,
}: {
  names: string[];
  totals: number[];
}) {
  const standings = buildStandings(names, totals);
  if (standings.length !== 4) return null;

  return (
    <div className="standings">
      {standings.map((p) => (
        <div
          key={p.seat}
          className={`standing-row${p.rank === 1 ? " standing-row--leader" : ""}`}
        >
          <span className="standing-rank">{p.rank}</span>
          <span className="standing-name">{p.name}</span>
          <span
            className={`standing-score${scoreClass(p.total)}`}
          >
            {scoreLabel(p.total)}
          </span>
        </div>
      ))}
    </div>
  );
}

function resolvePendingPoster(s: LiveSession): PosterSnapshot | null {
  if (s.pendingPoster) return s.pendingPoster;
  if (s.pendingMeldingSummary) {
    return posterFromCaption(s.pendingMeldingSummary, "MELDER");
  }
  return null;
}

function resolveLastHandPoster(
  s: LiveSession,
  hands: HandSummary[],
  names: string[]
): PosterSnapshot | null {
  if (s.lastHandPoster) return s.lastHandPoster;
  const last = hands.length > 0 ? hands[hands.length - 1] : null;
  if (last) {
    const base = posterFromCaption(last.caption, "MELDTE");
    return {
      ...base,
      scoreItems: last.scoresBySeat.map((score, i) => ({
        name: names[i] ?? `#${i + 1}`,
        score,
        role: "none" as const,
      })),
    };
  }
  if (s.lastCompletedHandCaption) {
    return posterFromCaption(s.lastCompletedHandCaption, "MELDTE");
  }
  return null;
}

// ── Komponent: hændstabel ────────────────────────────────────────────────────

function HandsTable({
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
  if (hands.length === 0) {
    if ((handCount ?? 0) > 0 && lastCaption) {
      return (
        <div className="table-wrap">
          <table className="hands-table">
            <thead>
              <tr>
                <th className="col-num">#</th>
                <th className="col-type" aria-label="Spiltype" />
                <th className="col-caption"></th>
                {names.map((n, i) => (
                  <th key={i} className="col-score">
                    {n}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              <tr>
                <td className="col-num">{handCount}</td>
                <td className="col-type" />
                <td className="col-caption">
                  <SuitColoredText text={lastCaption.replace(/\|\|[^|]*/g, "")} />
                </td>
                {totals.map((_, i) => (
                  <td key={i} className="col-score score--zero">—</td>
                ))}
              </tr>
            </tbody>
            <tfoot>
              <tr className="totals-row">
                <td colSpan={3} className="col-totals-label">
                  Samlet stilling i dag
                </td>
                {totals.map((t, i) => (
                  <td key={i} className={`col-score${scoreClass(t)}`}>
                    {scoreLabel(t)}
                  </td>
                ))}
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

  // Vis nyeste øverst
  const reversed = [...hands].reverse();

  return (
    <div className="table-wrap">
      <table className="hands-table">
        <thead>
          <tr>
            <th className="col-num">#</th>
            <th className="col-type" aria-label="Spiltype" />
            <th className="col-caption"></th>
            {names.map((n, i) => (
              <th key={i} className="col-score">
                {n}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {reversed.map((h) => (
            <tr key={h.handNumber}>
              <td className="col-num">#{h.handNumber}</td>
              <td className="col-type">
                <GameTypeIcon kind={gameTypeIconKindFromHand(h.kind, h.caption)} />
              </td>
              <td className="col-caption">
                <SuitColoredText text={h.caption.replace(/\|\|[^|]*/g, "")} />
              </td>
              {h.scoresBySeat.map((s, i) => (
                <td key={i} className={`col-score${scoreClass(s)}`}>
                  {scoreLabel(s)}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
        <tfoot>
          <tr className="totals-row">
            <td colSpan={3} className="col-totals-label">
              Samlet stilling i dag
            </td>
            {totals.map((t, i) => (
              <td key={i} className={`col-score${scoreClass(t)}`}>
                {scoreLabel(t)}
              </td>
            ))}
          </tr>
        </tfoot>
      </table>
    </div>
  );
}

// ── Komponent: fuld aktiv spilledag ─────────────────────────────────────────

function ActiveSessionView({ s, now }: { s: LiveSession; now: number }) {
  const names = s.playerNamesBySeat ?? [];
  const totals = s.totalsBySeat ?? [];
  const hands = s.hands ?? [];
  const serverIso = s.serverUpdatedAt ?? s.updatedAt;
  const secs = secondsSince(serverIso, now);
  const isStale = secs >= STALE_SECONDS;
  const handCount = s.handCount ?? 0;
  const pendingPoster = resolvePendingPoster(s);
  const lastHandPoster = resolveLastHandPoster(s, hands, names);

  return (
    <div>
      <div className="session-header">
        <h2 className="session-title">{s.title ?? "Uden titel"}</h2>
        <div className="session-meta-row">
          <span className="session-meta">
            {handCount} {handCount === 1 ? "kamp" : "kampe"} spillet
          </span>
          <span
            className={`updated-time${isStale ? " updated-time--stale" : ""}`}
            title={serverIso ?? ""}
          >
            {isStale ? `Ingen data i ${secs} sek.` : relativeTimeLabel(secs)}
          </span>
        </div>
      </div>

      <div className="two-box-row">
        <PosterBox
          title="Aktivt spil"
          live
          poster={pendingPoster}
          emptyText="Afventer næste kamp…"
        />
        <PosterBox
          title="Seneste afsluttede spil"
          poster={lastHandPoster}
          emptyText="Ingen afsluttede kampe endnu."
        />
      </div>

      {names.length === 4 && hands.length === 0 && (handCount ?? 0) > 0 ? (
        <StandingsStrip names={names} totals={totals} />
      ) : null}

      {names.length === 4 ? (
        <PosterBox title="Alle spilledagens kampe">
          <HandsTable
            hands={hands}
            names={names}
            totals={totals}
            handCount={handCount}
            lastCaption={s.lastCompletedHandCaption}
          />
        </PosterBox>
      ) : null}

      {s.notesPublic ? <p className="notes-line">{s.notesPublic}</p> : null}
    </div>
  );
}

// ── Komponent: kompakt afsluttet spilledag ───────────────────────────────────

function FinishedSessionCard({ s }: { s: LiveSession }) {
  const names = s.playerNamesBySeat ?? [];
  const totals = s.totalsBySeat ?? [];
  const hands = s.hands ?? [];
  const handCount = s.handCount ?? 0;

  return (
    <article className="card">
      <div className="card-top">
        <span className="pill pill--done">Afsluttet</span>
      </div>
      <h2>{s.title ?? "Uden titel"}</h2>
      <p className="hand-count muted">
        {handCount} {handCount === 1 ? "kamp" : "kampe"} spillet
      </p>
      {names.length === 4 ? (
        <HandsTable
          hands={hands}
          names={names}
          totals={totals}
          handCount={handCount}
          lastCaption={s.lastCompletedHandCaption}
        />
      ) : null}
    </article>
  );
}

// ── Hoved-side ───────────────────────────────────────────────────────────────

export default function HomePage() {
  const [sessions, setSessions] = useState<LiveSession[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [now, setNow] = useState(() => Date.now());
  const cancelledRef = useRef(false);

  useEffect(() => {
    cancelledRef.current = false;

    async function fetchSessions() {
      try {
        const res = await fetch("/api/sessions", { cache: "no-store" });
        const data = await res.json();
        if (!res.ok) {
          throw new Error(
            typeof data.error === "string" ? data.error : "Serverfejl"
          );
        }
        if (!cancelledRef.current) {
          setSessions(Array.isArray(data) ? data : []);
          setError(null);
        }
      } catch (e) {
        if (!cancelledRef.current) {
          setError(e instanceof Error ? e.message : "Netværksfejl");
        }
      }
    }

    fetchSessions();
    const id = setInterval(fetchSessions, 2000);
    return () => {
      cancelledRef.current = true;
      clearInterval(id);
    };
  }, []);

  useEffect(() => {
    const id = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(id);
  }, []);

  const activeSessions = sessions.filter((s) => s.status !== "finished");
  const finishedSessions = sessions.filter((s) => s.status === "finished");
  const activeSession = activeSessions[0] ?? null;

  return (
    <main>
      <div className="site-header">
        <div className="site-header-brand">
          <h1>Whist</h1>
          <span className="site-sub">live overblik</span>
        </div>
        <ThemeMenu />
      </div>

      {error ? (
        <div className="banner" role="alert">
          Kan ikke hente data — {error}
        </div>
      ) : null}

      {sessions.length === 0 && !error ? (
        <p className="empty">Ingen aktive spilledage lige nu.</p>
      ) : null}

      {activeSession ? (
        <ActiveSessionView s={activeSession} now={now} />
      ) : null}

      {finishedSessions.length > 0 ? (
        <section className={activeSession ? "section--below" : ""}>
          <h3 className="section-heading">Seneste spil</h3>
          <div className="grid">
            {finishedSessions.map((s, i) => (
              <FinishedSessionCard key={s.sessionId ?? `f-${i}`} s={s} />
            ))}
          </div>
        </section>
      ) : null}

      <p className="footer-note">Opdateres automatisk hvert 2. sekund.</p>
    </main>
  );
}
