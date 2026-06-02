import { NextResponse } from "next/server";
import { buildClubStatsModel } from "@/lib/stats/historicalEngine";
import { loadHistoricalData } from "@/lib/stats/loadHistoricalData";

export const revalidate = 3600;

export async function GET() {
  try {
    const data = loadHistoricalData();
    const model = buildClubStatsModel(data);
    return NextResponse.json(model);
  } catch (e) {
    const msg = e instanceof Error ? e.message : "Statistikfejl";
    return NextResponse.json({ error: msg }, { status: 503 });
  }
}
