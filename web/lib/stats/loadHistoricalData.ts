import fs from "node:fs";
import path from "node:path";
import type { HistoricalWhistData } from "@/lib/stats/historicalTypes";

let cached: HistoricalWhistData | null = null;

export function loadHistoricalData(): HistoricalWhistData {
  if (cached) return cached;

  const candidates = [
    path.join(process.cwd(), "data", "whist_historical_data_v3.json"),
    path.join(
      process.cwd(),
      "..",
      "Whist20",
      "Resources",
      "HistoricalData",
      "whist_historical_data_v3.json"
    ),
  ];

  for (const filePath of candidates) {
    if (!fs.existsSync(filePath)) continue;
    const raw = fs.readFileSync(filePath, "utf8");
    cached = JSON.parse(raw) as HistoricalWhistData;
    return cached;
  }

  throw new Error(
    "whist_historical_data_v3.json mangler. Kør npm run prebuild i web/."
  );
}

export function clearHistoricalDataCache() {
  cached = null;
}
