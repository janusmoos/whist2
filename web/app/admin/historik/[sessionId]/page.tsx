import Link from "next/link";
import { redirect } from "next/navigation";
import { SiteHeader } from "@/components/SiteHeader";
import { isAdminAuthenticated } from "@/lib/adminAuth";
import { loadHistoricalData } from "@/lib/stats/loadHistoricalData";
import { gameTypeLabel } from "@/lib/stats/gameTypeClassifier";

type Props = { params: Promise<{ sessionId: string }> };

export const dynamic = "force-dynamic";

export default async function HistoricalAdminSessionPage({ params }: Props) {
  if (!(await isAdminAuthenticated())) redirect("/admin/login");

  const { sessionId } = await params;
  const data = loadHistoricalData();
  const session = data.sessions.find(
    (candidate) => candidate.id === sessionId
  );
  if (!session) redirect("/admin");
  const games = data.games
    .filter((game) => game.sessionId === session.id)
    .sort((a, b) => a.gameNumberInSession - b.gameNumberInSession);

  return (
    <main>
      <SiteHeader sub="admin" />
      <div className="admin-dashboard">
        <div className="admin-section-heading">
          <div>
            <p className="stats-eyebrow">Historisk eksport</p>
            <h2>Spilledag {session.sessionNumber}</h2>
            <p>
              {[session.date, session.location].filter(Boolean).join(" · ")}
            </p>
          </div>
          <Link className="admin-link-button" href="/admin">
            Tilbage til admin
          </Link>
        </div>

        <div className="admin-session-card">
          <div className="admin-hand-list">
            {games.map((game) => {
              const base = `/api/admin/export/historical/${encodeURIComponent(
                game.id
              )}`;
              return (
                <div className="admin-hand-row" key={game.id}>
                  <span>
                    <strong>Spil #{game.gameNumberInSession}</strong>
                    <small>{gameTypeLabel(game)}</small>
                  </span>
                  <span className="admin-export-links">
                    <a href={`${base}?format=json`}>JSON</a>
                    <a href={`${base}?format=csv`}>CSV</a>
                  </span>
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </main>
  );
}
