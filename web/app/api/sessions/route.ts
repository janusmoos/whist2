import { NextResponse } from "next/server";
import { getSql } from "@/lib/db";
import {
  latestHistoricalLiveSession,
  latestHistoricalSessionNumber,
} from "@/lib/latestHistoricalSession";
import type { LiveSession } from "@/lib/liveSessionTypes";
import {
  controlFromPayload,
  LIVE_CONTROL_SESSION_ID,
} from "@/lib/liveControl";
import { mergeNewestLiveSession } from "@/lib/mergeLiveSessions";
import { loadHistoricalData } from "@/lib/stats/loadHistoricalData";

export const dynamic = "force-dynamic";

export async function GET() {
  try {
    const sql = getSql();
    const rows = await sql`
      SELECT session_id, payload, updated_at
      FROM live_sessions
      ORDER BY updated_at DESC
      LIMIT 30
    `;
    const controlRow = rows.find(
      (row) => String(row.session_id) === LIVE_CONTROL_SESSION_ID
    );
    const control = controlFromPayload(controlRow?.payload);
    const historicalData = loadHistoricalData();
    const latestHistoricalNumber = latestHistoricalSessionNumber(historicalData);
    const historicalSession = latestHistoricalLiveSession(historicalData);
    const liveSessions = rows
      .filter((row) => String(row.session_id) !== LIVE_CONTROL_SESSION_ID)
      .map((r) => ({
        ...(r.payload as Record<string, unknown>),
        serverUpdatedAt: r.updated_at,
      })) as LiveSession[];
    const out = mergeNewestLiveSession(
      control.enabled ? liveSessions : [],
      historicalSession,
      latestHistoricalNumber
    );
    return NextResponse.json(
      {
        liveEnabled: control.enabled,
        changedAt: control.changedAt,
        sessions: out,
      },
      { headers: { "Cache-Control": "no-store" } }
    );
  } catch (e) {
    const msg = e instanceof Error ? e.message : "Ukendt fejl";
    return NextResponse.json({ error: msg }, { status: 503 });
  }
}
