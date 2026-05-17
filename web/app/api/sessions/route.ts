import { NextResponse } from "next/server";
import { getSql } from "@/lib/db";

export const dynamic = "force-dynamic";

export async function GET() {
  try {
    const sql = getSql();
    const rows = await sql`
      SELECT payload, updated_at
      FROM live_sessions
      WHERE payload->>'status' = 'active'
      ORDER BY updated_at DESC
      LIMIT 30
    `;
    const out = rows.map((r) => ({
      ...(r.payload as Record<string, unknown>),
      serverUpdatedAt: r.updated_at,
    }));
    return NextResponse.json(out);
  } catch (e) {
    const msg = e instanceof Error ? e.message : "Ukendt fejl";
    return NextResponse.json({ error: msg }, { status: 503 });
  }
}
