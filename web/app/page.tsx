"use client";

import { useEffect, useState } from "react";

type LiveSession = {
  sessionId?: string;
  title?: string;
  status?: string;
  handCount?: number;
  playerNamesBySeat?: string[];
  totalsBySeat?: number[];
  lastCompletedHandCaption?: string | null;
  pendingMeldingSummary?: string | null;
  pendingResultSummary?: string | null;
  pendingStep?: string | null;
  notesPublic?: string;
  updatedAt?: string;
  serverUpdatedAt?: string;
};

function formatTime(iso: string | undefined) {
  if (!iso) return "—";
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return iso;
  return d.toLocaleString("da-DK", {
    day: "2-digit",
    month: "short",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  });
}

function stepLabel(step: string | null | undefined) {
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

export default function HomePage() {
  const [sessions, setSessions] = useState<LiveSession[]>([]);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;

    async function fetchSessions() {
      try {
        const res = await fetch("/api/sessions", { cache: "no-store" });
        const data = await res.json();
        if (!res.ok) {
          throw new Error(
            typeof data.error === "string" ? data.error : "Kunne ikke hente data"
          );
        }
        if (!cancelled) {
          setSessions(Array.isArray(data) ? data : []);
          setError(null);
        }
      } catch (e) {
        if (!cancelled) {
          setError(e instanceof Error ? e.message : "Netværksfejl");
        }
      }
    }

    fetchSessions();
    const id = setInterval(fetchSessions, 2000);
    return () => {
      cancelled = true;
      clearInterval(id);
    };
  }, []);

  return (
    <main>
      <h1>Whist — live overblik</h1>
      <p className="sub">
        Opdateres automatisk hvert 2. sekund, når appen sender ændringer (melding
        eller afsluttet spil).
      </p>

      {error ? (
        <div className="banner" role="status">
          {error}
        </div>
      ) : null}

      {sessions.length === 0 && !error ? (
        <p className="empty">Ingen aktive spilledage lige nu.</p>
      ) : null}

      <div className="grid">
        {sessions.map((s, index) => {
          const names = s.playerNamesBySeat ?? [];
          const totals = s.totalsBySeat ?? [];
          const step = stepLabel(s.pendingStep);
          const updated =
            s.serverUpdatedAt ?? s.updatedAt ?? undefined;
          const key = s.sessionId ?? `row-${index}`;

          return (
            <article key={key} className="card">
              <span className="pill">Aktiv</span>
              <h2>{s.title ?? "Uden titel"}</h2>
              <div className="muted">
                Kamp {s.handCount ?? 0} gemt
                {updated ? ` · Opdateret ${formatTime(updated)}` : null}
              </div>

              {s.notesPublic ? (
                <p className="muted" style={{ marginTop: "0.65rem" }}>
                  {s.notesPublic}
                </p>
              ) : null}

              {names.length === 4 && totals.length === 4 ? (
                <div className="row-scores">
                  {names.map((n, i) => (
                    <div key={i} className="score-pair">
                      <span>{n}</span>
                      <strong>{totals[i] ?? 0}</strong>
                    </div>
                  ))}
                </div>
              ) : null}

              {s.lastCompletedHandCaption ? (
                <p style={{ marginTop: "0.85rem", fontSize: "0.9rem" }}>
                  Seneste: {s.lastCompletedHandCaption}
                </p>
              ) : null}

              {s.pendingMeldingSummary ? (
                <div style={{ marginTop: "0.85rem", fontSize: "0.9rem" }}>
                  {step ? (
                    <div className="muted" style={{ marginBottom: "0.25rem" }}>
                      {step}
                    </div>
                  ) : null}
                  <div>{s.pendingMeldingSummary}</div>
                  {s.pendingResultSummary ? (
                    <div className="muted" style={{ marginTop: "0.35rem" }}>
                      {s.pendingResultSummary}
                    </div>
                  ) : null}
                </div>
              ) : null}
            </article>
          );
        })}
      </div>
    </main>
  );
}
