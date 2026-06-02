import Link from "next/link";
import type { StatsNavIcon } from "@/lib/stats/navigation";

function StatsNavIconGlyph({ icon }: { icon: StatsNavIcon }) {
  const label: Record<StatsNavIcon, string> = {
    calendar: "◷",
    sessions: "◎",
    players: "▤",
    "game-types": "♣",
    trends: "↗",
    data: "☑",
  };
  return (
    <span className="stats-nav-icon" aria-hidden="true">
      {label[icon]}
    </span>
  );
}

export function StatsNavCard({
  href,
  title,
  subtitle,
  metric,
  icon,
  disabled,
}: {
  href: string;
  title: string;
  subtitle: string;
  metric: string;
  icon: StatsNavIcon;
  disabled?: boolean;
}) {
  const body = (
    <>
      <StatsNavIconGlyph icon={icon} />
      <div className="stats-nav-copy">
        <strong className="stats-nav-title">{title}</strong>
        <span className="stats-nav-subtitle">{subtitle}</span>
      </div>
      <span className="stats-nav-metric">{metric}</span>
      <span className="stats-nav-chevron" aria-hidden="true">
        ›
      </span>
    </>
  );

  if (disabled) {
    return (
      <div className="stats-nav-card stats-nav-card--disabled" aria-disabled="true">
        {body}
      </div>
    );
  }

  return (
    <Link href={href} className="stats-nav-card">
      {body}
    </Link>
  );
}
