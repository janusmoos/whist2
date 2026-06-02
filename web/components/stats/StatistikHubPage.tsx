"use client";

import { StatsHubOverview } from "@/components/stats/StatsHubOverview";
import { StatsNavCard } from "@/components/stats/StatsNavCard";
import { SiteHeader } from "@/components/SiteHeader";
import { useClubStats } from "@/hooks/useClubStats";
import { useLiveSessions } from "@/hooks/useLiveSessions";
import { getActiveSession } from "@/lib/liveSessionTypes";
import { STATS_HUB_NAV } from "@/lib/stats/navigation";

function metricForItem(
  item: (typeof STATS_HUB_NAV)[number],
  handCount: number,
  hasActive: boolean,
  hubSessions: number | null,
  hubPlayers: number | null
): string {
  if (item.href === "/statistik/nuværende-spilledag") {
    if (!hasActive) return "—";
    return `${handCount} spil`;
  }
  if (item.href === "/statistik/alle-spilledage" && hubSessions != null) {
    return String(hubSessions);
  }
  if (item.href === "/statistik/spillere" && hubPlayers != null) {
    return String(hubPlayers);
  }
  if (item.href === "/statistik/datagrundlag" && hubSessions != null) {
    return String(hubSessions);
  }
  return item.metric;
}

export function StatistikHubPage() {
  const { sessions, error: liveError } = useLiveSessions();
  const { model, error: statsError, loading: statsLoading } = useClubStats();
  const active = getActiveSession(sessions);
  const handCount = active?.handCount ?? 0;
  const error = liveError ?? statsError;

  return (
    <main>
      <SiteHeader sub="statistik" />

      {error ? (
        <div className="banner" role="alert">
          Kan ikke hente data — {error}
        </div>
      ) : null}

      <header className="stats-page-head stats-page-head--hub">
        <h2 className="stats-page-title">Statistik</h2>
        <p className="stats-page-lead">
          Samlet klub-overblik og samme sektioner som i appen.
        </p>
      </header>

      {statsLoading && !model ? (
        <p className="stats-loading">Indlæser statistik…</p>
      ) : (
        <>
          <StatsHubOverview hub={model?.hub ?? null} activeSession={active} />

          <nav className="stats-hub-nav" aria-label="Statistiksektioner">
            {STATS_HUB_NAV.map((item) => {
              const needsActive = item.requiresActiveSession && !active;
              const disabled = needsActive;
              return (
                <StatsNavCard
                  key={item.href}
                  href={item.href}
                  title={item.title}
                  subtitle={item.subtitle}
                  icon={item.icon}
                  metric={metricForItem(
                    item,
                    handCount,
                    Boolean(active),
                    model?.hub.sessionCount ?? null,
                    model?.hub.playerSummaries.length ?? null
                  )}
                  disabled={disabled}
                />
              );
            })}
          </nav>
        </>
      )}
    </main>
  );
}
