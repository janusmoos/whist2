import { NextResponse } from "next/server";
import { getSql } from "@/lib/db";

export const dynamic = "force-dynamic";

function unauthorized() {
  return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
}

export async function PUT(
  req: Request,
  ctx: { params: Promise<{ sessionId: string }> }
) {
  const secret = process.env.LIVE_SESSION_API_SECRET;
  if (!secret) {
    return NextResponse.json(
      { error: "LIVE_SESSION_API_SECRET er ikke konfigureret på serveren" },
      { status: 500 }
    );
  }

  const auth = req.headers.get("authorization") ?? "";
  if (auth !== `Bearer ${secret}`) {
    return unauthorized();
  }

  const { sessionId } = await ctx.params;
  const uuidRe =
    /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  if (!uuidRe.test(sessionId)) {
    return NextResponse.json({ error: "Ugyldigt sessionId" }, { status: 400 });
  }

  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Ugyldig JSON" }, { status: 400 });
  }

  if (typeof body !== "object" || body === null) {
    return NextResponse.json({ error: "Forventede et JSON-objekt" }, { status: 400 });
  }

  const payloadStr = JSON.stringify(body);

  try {
    const sql = getSql();
    await sql`
      INSERT INTO live_sessions (session_id, payload, updated_at)
      VALUES (${sessionId}::uuid, ${payloadStr}::jsonb, now())
      ON CONFLICT (session_id) DO UPDATE SET
        payload = EXCLUDED.payload,
        updated_at = now()
    `;
    return NextResponse.json({ ok: true });
  } catch (e) {
    const msg = e instanceof Error ? e.message : "Databasefejl";
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}
