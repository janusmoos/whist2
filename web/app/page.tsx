"use client";

import { useEffect, useRef, useState } from "react";

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

function stepLabel(step: LiveSession["pendingStep"]): string | null {
  switch (step) {
    case "melding":     return "Melding";
    case "halve_trumf": return "Trumf (halve)";
    case "resultat":    return "Resultat";
    default:            return null;
  }
}

function scoreLabel(n: number): string {
  return n > 0 ? `+${n}` : String(n);
}

function scoreClass(n: number): string {
  if (n > 0) return " score--pos";
  if (n < 0) return " score--neg";
  return " score--zero";
}

function kindSymbol(kind: string): string {
  if (kind === "sol")   return "☀";
  if (kind === "duty")  return "D";
  return "";
}

// ── Komponent: hændstabel ────────────────────────────────────────────────────

function HandsTable({
  hands,
  names,
  totals,
}: {
  hands: HandSummary[];
  names: string[];
  totals: number[];
}) {
  if (hands.length === 0) {
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
            <th className="col-caption"></th>
            {names.map((n, i) => (
              <th key={i} className="col-score">
                {n}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {reversed.map((h) => {
            const sym = kindSymbol(h.kind);
            return (
              <tr key={h.handNumber}>
                <td className="col-num">{h.handNumber}</td>
                <td className="col-caption">
                  {sym ? <span className="kind-sym">{sym}</span> : null}
                  {h.caption}
                </td>
                {h.scoresBySeat.map((s, i) => (
                  <td key={i} className={`col-score${scoreClass(s)}`}>
                    {scoreLabel(s)}
                  </td>
                ))}
              </tr>
            );
          })}
        </tbody>
        <tfoot>
          <tr className="totals-row">
            <td className="col-num">∑</td>
            <td className="col-caption"></td>
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

// ── Komponent: "Aktivt spil"-boks ────────────────────────────────────────────

function ActiveBox({ s }: { s: LiveSession }) {
  const step = stepLabel(s.pendingStep);

  if (!s.pendingMeldingSummary) {
    return (
      <div className="info-box">
        <span className="box-label">Aktivt spil</span>
        <p className="box-empty">Afventer næste kamp…</p>
      </div>
    );
  }

  return (
    <div className="info-box info-box--active">
      <span className="box-label">Aktivt spil</span>
      {step ? <span className="box-step">{step}</span> : null}
      <p className="box-main">{s.pendingMeldingSummary}</p>
      {s.pendingResultSummary ? (
        <p className="box-sub">{s.pendingResultSummary}</p>
      ) : null}
    </div>
  );
}

// ── Komponent: "Seneste afsluttede spil"-boks ────────────────────────────────

function LastHandBox({
  hands,
  names,
}: {
  hands: HandSummary[];
  names: string[];
}) {
  const last = hands.length > 0 ? hands[hands.length - 1] : null;

  if (!last) {
    return (
      <div className="info-box">
        <span className="box-label">Seneste afsluttede spil</span>
        <p className="box-empty">Ingen afsluttede kampe endnu.</p>
      </div>
    );
  }

  const sym = kindSymbol(last.kind);

  return (
    <div className="info-box">
      <span className="box-label">Seneste afsluttede spil</span>
      <p className="box-main">
        {sym ? <span className="kind-sym">{sym} </span> : null}
        {last.caption}
      </p>
      <div className="last-hand-scores">
        {last.scoresBySeat.map((s, i) => (
          <div key={i} className="last-hand-cell">
            <span className="last-hand-name">{names[i]}</span>
            <span className={`last-hand-score${scoreClass(s)}`}>
              {scoreLabel(s)}
            </span>
          </div>
        ))}
      </div>
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

  return (
    <div className={isStale ? "session-stale" : undefined}>
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
        <ActiveBox s={s} />
        <LastHandBox hands={hands} names={names} />
      </div>

      {names.length === 4 ? (
        <section className="hands-section">
          <h3 className="section-label">Alle spilledagens kampe</h3>
          <HandsTable hands={hands} names={names} totals={totals} />
        </section>
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
        <HandsTable hands={hands} names={names} totals={totals} />
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
        <h1>Whist</h1>
        <span className="site-sub">live overblik</span>
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
