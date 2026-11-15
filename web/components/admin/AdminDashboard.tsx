"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import type { LiveControl } from "@/lib/liveControl";
import type { LiveSession } from "@/lib/liveSessionTypes";

function localDate(value: string | null | undefined): string {
  if (!value) return "Ukendt";
  return new Intl.DateTimeFormat("da-DK", {
    dateStyle: "medium",
    timeStyle: "short",
  }).format(new Date(value));
}

function exportHref(
  sessionId: string,
  format: "json" | "csv",
  hand?: number
): string {
  const params = new URLSearchParams({ format });
  if (hand != null) params.set("hand", String(hand));
  return `/api/admin/export/${sessionId}?${params}`;
}

export function AdminDashboard({
  initialControl,
  sessions,
  historicalSessions,
}: {
  initialControl: LiveControl;
  sessions: LiveSession[];
  historicalSessions: {
    id: string;
    sessionNumber: string;
    date: string | null;
    location: string | null;
    gameCount: number;
  }[];
}) {
  const router = useRouter();
  const [control, setControl] = useState(initialControl);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function setEnabled(enabled: boolean) {
    setBusy(true);
    setError(null);
    const response = await fetch("/api/admin/live-control", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ enabled }),
    });
    const body = (await response.json().catch(() => null)) as
      | LiveControl
      | { error?: string }
      | null;
    if (!response.ok || !body || !("enabled" in body)) {
      setError(
        body && "error" in body && body.error
          ? body.error
          : "Status kunne ikke ændres."
      );
    } else {
      setControl(body);
    }
    setBusy(false);
  }

  async function logout() {
    await fetch("/api/admin/logout", { method: "POST" });
    router.replace("/admin/login");
    router.refresh();
  }

  return (
    <div className="admin-dashboard">
      <section
        className={`admin-control-card ${
          control.enabled ? "admin-control-card--on" : "admin-control-card--off"
        }`}
      >
        <div>
          <p className="stats-eyebrow">Live-system</p>
          <h2>{control.enabled ? "Live-opdatering kører" : "Live-opdatering er pauset"}</h2>
          <p>
            {control.enabled
              ? "Appen kan sende data, og forsiden opdaterer automatisk."
              : "Uploads afvises, og forsiden pinger ikke hvert andet sekund. Statistikken virker fortsat."}
          </p>
          <p className="admin-muted">
            Senest ændret: {localDate(control.changedAt)}
          </p>
        </div>
        <button
          type="button"
          className="admin-primary-button"
          disabled={busy}
          onClick={() => setEnabled(!control.enabled)}
        >
          {busy
            ? "Arbejder…"
            : control.enabled
              ? "Sæt live-systemet på pause"
              : "Start live-systemet"}
        </button>
        {error ? <p className="admin-error">{error}</p> : null}
      </section>

      <div className="admin-section-heading">
        <div>
          <p className="stats-eyebrow">Serverdata</p>
          <h2>Eksportér spil</h2>
          <p>Download hele spilledagen eller et enkelt spil som JSON eller CSV.</p>
        </div>
        <button type="button" className="admin-link-button" onClick={logout}>
          Log ud
        </button>
      </div>

      <div className="admin-session-list">
        {sessions.map((session) => {
          const id = session.sessionId;
          if (!id) return null;
          const hands = session.hands ?? [];
          return (
            <details className="admin-session-card" key={id}>
              <summary>
                <span>
                  <strong>{session.title ?? "Uden titel"}</strong>
                  <small>
                    {hands.length} spil · serverbackup {localDate(session.serverUpdatedAt)}
                  </small>
                </span>
                <span className="admin-summary-actions">
                  <a href={exportHref(id, "json")}>Hele dagen JSON</a>
                  <a href={exportHref(id, "csv")}>Hele dagen CSV</a>
                </span>
              </summary>
              <div className="admin-hand-list">
                {hands.map((hand) => (
                  <div className="admin-hand-row" key={hand.handNumber}>
                    <span>
                      <strong>Spil #{hand.handNumber}</strong>
                      <small>{hand.caption}</small>
                    </span>
                    <span className="admin-export-links">
                      <a href={exportHref(id, "json", hand.handNumber)}>JSON</a>
                      <a href={exportHref(id, "csv", hand.handNumber)}>CSV</a>
                    </span>
                  </div>
                ))}
              </div>
            </details>
          );
        })}
      </div>

      <div className="admin-section-heading">
        <div>
          <p className="stats-eyebrow">Statistikdata</p>
          <h2>Historiske spil</h2>
          <p>Vælg en spilledag for at eksportere et af de historiske spil.</p>
        </div>
      </div>

      <div className="admin-history-grid">
        {historicalSessions.map((session) => (
          <Link
            className="admin-history-card"
            href={`/admin/historik/${encodeURIComponent(session.id)}`}
            key={session.id}
          >
            <strong>Spilledag {session.sessionNumber}</strong>
            <small>
              {[session.date, session.location].filter(Boolean).join(" · ")}
            </small>
            <span>{session.gameCount} spil</span>
          </Link>
        ))}
      </div>
    </div>
  );
}
