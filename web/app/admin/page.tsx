import { redirect } from "next/navigation";
import { AdminDashboard } from "@/components/admin/AdminDashboard";
import { SiteHeader } from "@/components/SiteHeader";
import { isAdminAuthenticated } from "@/lib/adminAuth";
import { getSql } from "@/lib/db";
import {
  getLiveControl,
  LIVE_CONTROL_SESSION_ID,
} from "@/lib/liveControl";
import type { LiveSession } from "@/lib/liveSessionTypes";
import { loadHistoricalData } from "@/lib/stats/loadHistoricalData";

export const dynamic = "force-dynamic";
export const metadata = {
  title: "Admin — Whistklubben",
};

export default async function AdminPage() {
  if (!(await isAdminAuthenticated())) redirect("/admin/login");

  const sql = getSql();
  const [control, rows] = await Promise.all([
    getLiveControl(),
    sql`
      SELECT session_id, payload, updated_at
      FROM live_sessions
      WHERE session_id <> ${LIVE_CONTROL_SESSION_ID}::uuid
      ORDER BY updated_at DESC
    `,
  ]);
  const sessions = rows.map((row) => ({
    ...(row.payload as Record<string, unknown>),
    sessionId: String(row.session_id),
    serverUpdatedAt: new Date(row.updated_at as string | Date).toISOString(),
  })) as LiveSession[];
  const historicalData = loadHistoricalData();
  const historicalSessions = historicalData.sessions.map((session) => ({
    id: session.id,
    sessionNumber: session.sessionNumber,
    date: session.date ?? null,
    location: session.location ?? null,
    gameCount: historicalData.games.filter(
      (game) => game.sessionId === session.id
    ).length,
  }));

  return (
    <main>
      <SiteHeader sub="admin" />
      <AdminDashboard
        initialControl={control}
        sessions={sessions}
        historicalSessions={historicalSessions}
      />
    </main>
  );
}
