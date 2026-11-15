import { NextResponse } from "next/server";
import { isAdminAuthenticated } from "@/lib/adminAuth";
import {
  handExport,
  handsCsv,
  safeFilename,
} from "@/lib/adminExports";
import { getSql } from "@/lib/db";
import type { LiveSession } from "@/lib/liveSessionTypes";

type Context = { params: Promise<{ sessionId: string }> };

export async function GET(req: Request, context: Context) {
  if (!(await isAdminAuthenticated())) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const { sessionId } = await context.params;
  const uuidRe =
    /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  if (!uuidRe.test(sessionId)) {
    return NextResponse.json({ error: "Ugyldigt session-id." }, { status: 400 });
  }

  const url = new URL(req.url);
  const format = url.searchParams.get("format") === "csv" ? "csv" : "json";
  const handNumberRaw = url.searchParams.get("hand");
  const handNumber = handNumberRaw ? Number(handNumberRaw) : null;

  const sql = getSql();
  const rows = await sql`
    SELECT session_id, payload, updated_at
    FROM live_sessions
    WHERE session_id = ${sessionId}::uuid
    LIMIT 1
  `;
  if (rows.length === 0) {
    return NextResponse.json({ error: "Spilledagen findes ikke." }, { status: 404 });
  }

  const session = {
    ...(rows[0].payload as Record<string, unknown>),
    sessionId: String(rows[0].session_id),
    serverUpdatedAt: rows[0].updated_at,
  } as LiveSession;
  const allHands = session.hands ?? [];
  const hands =
    handNumber == null
      ? allHands
      : allHands.filter((hand) => hand.handNumber === handNumber);
  if (handNumber != null && hands.length === 0) {
    return NextResponse.json({ error: "Spillet findes ikke." }, { status: 404 });
  }

  const stem = safeFilename(
    `${session.title ?? "spilledag"}${
      handNumber == null ? "" : `-spil-${handNumber}`
    }`
  );
  if (format === "csv") {
    return new NextResponse(handsCsv(session, hands), {
      headers: {
        "Content-Type": "text/csv; charset=utf-8",
        "Content-Disposition": `attachment; filename="${stem}.csv"`,
        "Cache-Control": "private, no-store",
      },
    });
  }

  const data =
    handNumber == null
      ? {
          exportedAt: new Date().toISOString(),
          serverUpdatedAt: session.serverUpdatedAt,
          session,
        }
      : handExport(session, hands[0]);
  return new NextResponse(JSON.stringify(data, null, 2), {
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      "Content-Disposition": `attachment; filename="${stem}.json"`,
      "Cache-Control": "private, no-store",
    },
  });
}
