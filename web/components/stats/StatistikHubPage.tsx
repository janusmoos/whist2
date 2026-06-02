"use client";

import { SiteHeader } from "@/components/SiteHeader";
import { StatsHubOverview } from "@/components/stats/StatsHubOverview";
import { StatsNavCard } from "@/components/stats/StatsNavCard";
import { useLiveSessions } from "@/hooks/useLiveSessions";
import { getActiveSession } from "@/lib/liveSessionTypes";
import { STATS_HUB_NAV } from "@/lib/stats/navigation";

function metricForItem(
  item: (typeof STATS_HUB_NAV)[number],
  handCount: number,
  hasActive: boolean
): string {
  if (item.href === "/statistik/nuværende-spilledag") {
    if (!hasActive) return "—";
    return `${handCount} ${handCount === 1 ? "spil" : "spil"}`;
  }
  return item.metric;
}

export function StatistikHubPage() {
  const { sessions, error, loading } = useLiveSessions();
  const active = getActiveSession(sessions);
  const handCount = active?.handCount ?? 0;

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
          Samme opdeling som i appen — spilledags-statistik live, klub-statistik kommer
          i næste fase.
        </p>
      </header>

      {loading && !active ? (
        <p className="stats-loading">Indlæser statistik…</p>
      ) : (
        <>
          <StatsHubOverview session={active} />

          <nav className="stats-hub-nav" aria-label="Statistiksektioner">
            {STATS_HUB_NAV.map((item) => {
              const needsActive = item.requiresActiveSession && !active;
              return (
                <StatsNavCard
                  key={item.href}
                  href={item.href}
                  title={item.title}
                  subtitle={item.subtitle}
                  icon={item.icon}
                  metric={metricForItem(item, handCount, Boolean(active))}
                  disabled={needsActive}
                />
              );
            })}
          </nav>
        </>
      )}
    </main>
  );
}
