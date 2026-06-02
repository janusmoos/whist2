import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const webRoot = path.join(__dirname, "..");
const target = path.join(webRoot, "data", "whist_historical_data_v3.json");
const source = path.join(
  webRoot,
  "..",
  "Whist20",
  "Resources",
  "HistoricalData",
  "whist_historical_data_v3.json"
);

if (fs.existsSync(target)) {
  process.exit(0);
}

if (!fs.existsSync(source)) {
  console.warn("[ensure-historical-data] Kildefil mangler:", source);
  process.exit(0);
}

fs.mkdirSync(path.dirname(target), { recursive: true });
fs.copyFileSync(source, target);
console.log("[ensure-historical-data] Kopiér historisk JSON til web/data");
