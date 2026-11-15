import type { ReactNode } from "react";
import Link from "next/link";
import { SiteHeader } from "@/components/SiteHeader";

export function StatsPageShell({
  title,
  titleAdornment,
  lead,
  backHref = "/statistik",
  backLabel = "Statistik",
  children,
}: {
  title: string;
  titleAdornment?: ReactNode;
  lead?: string;
  backHref?: string;
  backLabel?: string;
  children: ReactNode;
}) {
  return (
    <main>
      <SiteHeader sub="statistik" />
      <nav className="stats-back" aria-label="Tilbage">
        <Link href={backHref}>← {backLabel}</Link>
      </nav>
      <header className="stats-page-head">
        <h2 className="stats-page-title">
          {titleAdornment ? (
            <span className="stats-page-title-adorn">{titleAdornment}</span>
          ) : null}
          <span>{title}</span>
        </h2>
        {lead ? <p className="stats-page-lead">{lead}</p> : null}
      </header>
      <div className="stats-page-body">{children}</div>
    </main>
  );
}
