export type StatsNavItem = {
  href: string;
  title: string;
  subtitle: string;
  metric: string;
  icon: StatsNavIcon;
  /** Kun link når der er en aktiv spilledag (live). */
  requiresActiveSession?: boolean;
  /** Kræver klub-historik (fase 2). */
  phase2?: boolean;
};

export type StatsNavIcon =
  | "calendar"
  | "sessions"
  | "players"
  | "game-types"
  | "trends"
  | "data";

/** Spejler navigationskortene i appens StatistikTabView. */
export const STATS_HUB_NAV: StatsNavItem[] = [
  {
    href: "/statistik/nuværende-spilledag",
    title: "Nuværende spilledag",
    subtitle: "Stilling, udvikling og spilfordeling for i dag",
    metric: "live",
    icon: "calendar",
    requiresActiveSession: true,
  },
  {
    href: "/statistik/alle-spilledage",
    title: "Alle spilledage",
    subtitle: "Dato, sted, resultater og spil-detaljer",
    metric: "—",
    icon: "sessions",
    phase2: true,
  },
  {
    href: "/statistik/spillere",
    title: "Spillere",
    subtitle: "Profiler, bedste/værste spil og meldinger",
    metric: "4",
    icon: "players",
    phase2: true,
  },
  {
    href: "/statistik/spiltyper",
    title: "Spiltyper",
    subtitle: "Succes pr. type med tydelig sample size",
    metric: "—",
    icon: "game-types",
    phase2: true,
  },
  {
    href: "/statistik/tendenser",
    title: "Tendenser",
    subtitle: "Udvikling over tid og seneste perioder",
    metric: "5–50",
    icon: "trends",
    phase2: true,
  },
  {
    href: "/statistik/datagrundlag",
    title: "Datagrundlag",
    subtitle: "Importkvalitet, feltdækning og planlagte forbedringer",
    metric: "—",
    icon: "data",
    phase2: true,
  },
];

export const SITE_MENU_NAV = [
  { href: "/", label: "Live overblik" },
  { href: "/statistik", label: "Statistik" },
  ...STATS_HUB_NAV.map((item) => ({
    href: item.href,
    label: item.title,
    indent: true as const,
  })),
];
