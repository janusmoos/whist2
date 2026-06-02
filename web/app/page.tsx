"use client";

import { useEffect, useRef, useState } from "react";

type LiveSession = {
  schemaVersion?: number;
  sessionId?: string;
  title?: string;
  status?: string;
  handCount?: number;
  playerNamesBySeat?: string[];
  totalsBySeat?: number[];
  lastCompletedHandCaption?: string | null;
  pendingMeldingSummary?: string | null;
  pendingResultSummary?: string | null;
  pendingStep?: "melding" | "halve_trumf" | "resultat" | null;
  notesPublic?: string;
  updatedAt?: string;
  serverUpdatedAt?: string;
};

type PlayerStanding = {
  name: string;
  total: number;
  seat: number;
  rank: number;
};

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

function stepLabel(step: LiveSession["pendingStep"]): string | null {
  switch (step) {
    case "melding":
      return "Melding";
    case "halve_trumf":
      return "Trumf (halve)";
    case "resultat":
      return "Resultat";
    default:
      return null;
  }
}

function buildStandings(
  names: string[],
  totals: number[]
): PlayerStanding[] {
  if (names.length !== 4 || totals.length !== 4) return [];
  const players: PlayerStanding[] = names.map((name, i) => ({
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

function scoreLabel(total: number): string {
  if (total > 0) return `+${total}`;
  return String(total);
}

function SessionCard({
  s,
  index,
  now,
}: {
  s: LiveSession;
  index: number;
  now: number;
}) {
  const names = s.playerNamesBySeat ?? [];
  const totals = s.totalsBySeat ?? [];
  const standings = buildStandings(names, totals);
  const step = stepLabel(s.pendingStep);
  const serverIso = s.serverUpdatedAt ?? s.updatedAt;
  const secs = secondsSince(serverIso, now);
  const isStale = secs >= STALE_SECONDS;
  const isFinished = s.status === "finished";
  const key = s.sessionId ?? `row-${index}`;
  const handCount = s.handCount ?? 0;

  return (
    <article key={key} className={`card${isStale ? " card--stale" : ""}`}>
      <div className="card-top">
        <span className={`pill${isFinished ? " pill--done" : ""}`}>
          {isFinished ? "Afsluttet" : "Aktiv"}
        </span>
        <span
          className={`updated-time${isStale ? " updated-time--stale" : ""}`}
          title={serverIso ?? ""}
        >
          {isStale ? `Ingen data i ${secs} sek.` : relativeTimeLabel(secs)}
        </span>
      </div>

      <h2>{s.title ?? "Uden titel"}</h2>
      <p className="muted hand-count">
        {handCount} {handCount === 1 ? "kamp" : "kampe"} spillet
      </p>

      {standings.length === 4 ? (
        <div className="standings">
          {standings.map((p) => (
            <div
              key={p.seat}
              className={`standing-row${p.rank === 1 ? " standing-row--leader" : ""}`}
            >
              <span className="standing-rank">{p.rank}</span>
              <span className="standing-name">{p.name}</span>
              <span
                className={`standing-score${p.total > 0 ? " standing-score--pos" : p.total < 0 ? " standing-score--neg" : ""}`}
              >
                {scoreLabel(p.total)}
              </span>
            </div>
          ))}
        </div>
      ) : null}

      {s.lastCompletedHandCaption ? (
        <p className="caption-line">Seneste: {s.lastCompletedHandCaption}</p>
      ) : null}

      {s.pendingMeldingSummary ? (
        <div className="pending-block">
          {step ? <span className="pending-step">{step}</span> : null}
          <p className="pending-line">{s.pendingMeldingSummary}</p>
          {s.pendingResultSummary ? (
            <p className="pending-result">{s.pendingResultSummary}</p>
          ) : null}
        </div>
      ) : null}

      {s.notesPublic ? <p className="notes-line">{s.notesPublic}</p> : null}
    </article>
  );
}

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
  const isEmpty = sessions.length === 0 && !error;

  return (
    <main>
      <div className="site-header">
        <h1>Whist</h1>
        <span className="site-sub">live overblik</span>
      </div>

      {error ? (
        <div className="banner" role="alert">
          Kan ikke hente data — {error}
        </div>
      ) : null}

      {isEmpty ? (
        <p className="empty">Ingen aktive spilledage lige nu.</p>
      ) : null}

      {activeSessions.length > 0 ? (
        <section>
          <h3 className="section-heading">Aktivt spil</h3>
          <div className="grid">
            {activeSessions.map((s, i) => (
              <SessionCard key={s.sessionId ?? `a-${i}`} s={s} index={i} now={now} />
            ))}
          </div>
        </section>
      ) : null}

      {finishedSessions.length > 0 ? (
        <section className={activeSessions.length > 0 ? "section--below" : ""}>
          <h3 className="section-heading">Seneste spil</h3>
          <div className="grid">
            {finishedSessions.map((s, i) => (
              <SessionCard key={s.sessionId ?? `f-${i}`} s={s} index={i} now={now} />
            ))}
          </div>
        </section>
      ) : null}

      <p className="footer-note">Opdateres automatisk hvert 2. sekund.</p>
    </main>
  );
}
