"use client";

import { SessionDayStatsPanel } from "@/components/SessionDayStats";
import { StatsPageShell } from "@/components/stats/StatsPageShell";
import { useLiveSessions } from "@/hooks/useLiveSessions";
import { getActiveSession } from "@/lib/liveSessionTypes";

export default function NuværendeSpilledagPage() {
  const { sessions, error, loading } = useLiveSessions();
  const active = getActiveSession(sessions);
  const names = active?.playerNamesBySeat ?? [];
  const hands = active?.hands ?? [];

  return (
    <StatsPageShell
      title="Nuværende spilledag"
      lead={
        active?.title
          ? `${active.title} — stilling, udvikling og spilfordeling for i dag.`
          : "Stilling, udvikling og spilfordeling for den aktive spilledag."
      }
    >
      {error ? (
        <div className="banner" role="alert">
          Kan ikke hente data — {error}
        </div>
      ) : null}

      {loading && !active ? (
        <p className="stats-loading">Indlæser…</p>
      ) : !active ? (
        <p className="stats-empty">Ingen aktiv spilledag lige nu.</p>
      ) : hands.length === 0 ? (
        <p className="stats-empty">
          Ingen afsluttede kampe endnu — statistik vises når det første spil er gemt.
        </p>
      ) : names.length === 4 ? (
        <SessionDayStatsPanel hands={hands} names={names} />
      ) : (
        <p className="stats-empty">Mangler spillernavne for at vise statistik.</p>
      )}
    </StatsPageShell>
  );
}
