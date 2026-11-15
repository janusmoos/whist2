import { NextResponse } from "next/server";
import {
  historicalGameCsv,
  historicalGameExport,
  safeFilename,
} from "@/lib/adminExports";
import { isAdminAuthenticated } from "@/lib/adminAuth";
import { loadHistoricalData } from "@/lib/stats/loadHistoricalData";

type Context = { params: Promise<{ gameId: string }> };

export async function GET(req: Request, context: Context) {
  if (!(await isAdminAuthenticated())) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const { gameId } = await context.params;
  const data = loadHistoricalData();
  const game = data.games.find((candidate) => candidate.id === gameId);
  if (!game) {
    return NextResponse.json({ error: "Spillet findes ikke." }, { status: 404 });
  }
  const session = data.sessions.find(
    (candidate) => candidate.id === game.sessionId
  );
  if (!session) {
    return NextResponse.json(
      { error: "Spilledagen findes ikke." },
      { status: 404 }
    );
  }
  const results = data.playerResults.filter(
    (result) => result.gameId === game.id
  );
  const format = new URL(req.url).searchParams.get("format");
  const stem = safeFilename(
    `spilledag-${session.sessionNumber}-spil-${game.gameNumberInSession}`
  );

  if (format === "csv") {
    return new NextResponse(
      historicalGameCsv(session, game, data.players, results),
      {
        headers: {
          "Content-Type": "text/csv; charset=utf-8",
          "Content-Disposition": `attachment; filename="${stem}.csv"`,
          "Cache-Control": "private, no-store",
        },
      }
    );
  }

  return new NextResponse(
    JSON.stringify(
      historicalGameExport(session, game, data.players, results),
      null,
      2
    ),
    {
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Content-Disposition": `attachment; filename="${stem}.json"`,
        "Cache-Control": "private, no-store",
      },
    }
  );
}
