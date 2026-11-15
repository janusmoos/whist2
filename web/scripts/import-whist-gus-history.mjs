import fs from "node:fs";
import path from "node:path";

const root = path.resolve(import.meta.dirname, "../..");
const backupPath = path.join(root, "exports", "Whist-gus-seneste-backup.json");
const targets = [
  path.join(root, "Whist20", "Resources", "HistoricalData", "whist_historical_data_v3.json"),
  path.join(root, "docs", "statistik", "examples", "v03", "whist_historical_data_v3.json"),
  path.join(root, "web", "data", "whist_historical_data_v3.json"),
];

const backupDocument = JSON.parse(fs.readFileSync(backupPath, "utf8"));
const backup = backupDocument.backup;
const playerNames = backup.playerNamesBySeat;
const sessionId = `live-${String(backup.sessionId).toLowerCase()}`;
const sessionNumber = "32";
const sourceName = "Neon backup · Whist-gus";

function gameType(hand) {
  const caption = hand.caption.toLowerCase();
  if (caption.includes("ren sol")) return "Ren sol";
  if (hand.kind === "sol") return "Sol";
  if (caption.includes("vip")) return "VIP";
  if (caption.includes("halve")) return "Halve";
  if (caption.includes("gode")) return "Gode";
  if (caption.includes("sans")) return "Sans";
  if (hand.kind === "duty") return "Duestraf";
  return "Almindelige";
}

function bidder(hand) {
  return playerNames.find((name) =>
    hand.caption.toLocaleLowerCase("da").startsWith(name.toLocaleLowerCase("da"))
  ) ?? null;
}

function partner(hand, bidderId) {
  if (!bidderId || hand.kind !== "normal") return null;
  if (hand.caption.toLowerCase().includes("selvmakker")) return bidderId;
  const bidderIndex = playerNames.indexOf(bidderId);
  const bidderScore = hand.scoresBySeat[bidderIndex] ?? 0;
  const sameSide = playerNames.filter(
    (_, index) =>
      index !== bidderIndex &&
      Math.sign(hand.scoresBySeat[index] ?? 0) === Math.sign(bidderScore)
  );
  return sameSide.length === 1 ? sameSide[0] : null;
}

function parseBidTricks(caption) {
  const match = caption.match(/meldte\s+(\d+)/i);
  return match ? Number(match[1]) : null;
}

function parseActualTricks(caption, bidTricks) {
  if (bidTricks == null) return null;
  const match = caption.match(/\|\|\s*([+-]?\d+)/);
  return match ? Math.max(0, Math.min(13, bidTricks + Number(match[1]))) : null;
}

function importInto(data) {
  data.sessions = data.sessions.filter((session) => session.id !== sessionId);
  const oldGameIds = new Set(
    data.games.filter((game) => game.sessionId === sessionId).map((game) => game.id)
  );
  data.games = data.games.filter((game) => game.sessionId !== sessionId);
  data.playerResults = data.playerResults.filter(
    (result) => !oldGameIds.has(result.gameId)
  );

  data.sessions.push({
    id: sessionId,
    sessionNumber,
    date: "2026-06-13",
    location: "Peter · Whist og saunagus",
    sourceSheetName: sourceName,
    expectedGameCount: backup.hands.length,
    importedGameCount: backup.hands.length,
    missingScoreRows: 0,
    qualityStatus: "server_backup",
    cumulativeBlockStartColumn: null,
    deltaBlockStartColumn: null,
    preferredScoreBlockNumericRows: null,
    headerRow: null,
    columnMapping: null,
  });

  for (const hand of backup.hands) {
    const gameId = `${sessionId}-game-${String(hand.handNumber).padStart(3, "0")}`;
    const bidderId = bidder(hand);
    const bidTricks = parseBidTricks(hand.caption);
    const scores = Object.fromEntries(
      playerNames.map((name, index) => [name, hand.scoresBySeat[index] ?? 0])
    );
    const winners = playerNames.filter((name) => scores[name] > 0);
    data.games.push({
      id: gameId,
      sessionId,
      sessionNumber,
      gameNumberInSession: hand.handNumber,
      sourceGameMarker: hand.handNumber,
      gameTypeRaw: gameType(hand),
      gameTypeNormalized: gameType(hand),
      resumeCaption: hand.caption,
      playedAt: hand.savedAt,
      bidTricks,
      actualTricksTaken: parseActualTricks(hand.caption, bidTricks),
      bidderId,
      bidderIds: bidderId ? [bidderId] : [],
      winnerId: winners.length === 1 ? winners[0] : null,
      winnerIds: winners,
      partnerId: partner(hand, bidderId),
      dealerId: playerNames[hand.handNumber % playerNames.length],
      checksum: hand.scoresBySeat.reduce((sum, score) => sum + score, 0),
      scoreSource: "server_backup",
      sourceSheetName: sourceName,
      sourceRow: hand.handNumber,
      qualityFlags: [],
    });
    for (const [playerId, score] of Object.entries(scores)) {
      data.playerResults.push({
        id: `${gameId}-${playerId}`,
        gameId,
        playerId,
        score,
        sourceSheetName: sourceName,
        sourceRow: hand.handNumber,
      });
    }
  }

  data.generatedAt = new Date().toISOString();
  const totals = Object.fromEntries(data.players.map((player) => [player.id, 0]));
  for (const result of data.playerResults) {
    totals[result.playerId] = (totals[result.playerId] ?? 0) + result.score;
  }
  const resultsByGame = new Map();
  for (const result of data.playerResults) {
    const values = resultsByGame.get(result.gameId) ?? [];
    values.push(result.score);
    resultsByGame.set(result.gameId, values);
  }
  data.auditSummary.importedSessions = data.sessions.length;
  data.auditSummary.importedGames = data.games.length;
  data.auditSummary.playerResultRows = data.playerResults.length;
  data.auditSummary.playerTotals = totals;
  data.auditSummary.fieldCounts.gameType = data.games.filter(
    (game) => game.gameTypeNormalized || game.gameTypeRaw
  ).length;
  data.auditSummary.fieldCounts.dealer = data.games.filter(
    (game) => game.dealerId
  ).length;
  data.auditSummary.fieldCounts.bidder_or_winner = data.games.filter(
    (game) => game.bidderIds?.length || game.winnerIds?.length
  ).length;
  data.auditSummary.fieldCounts.partner = data.games.filter(
    (game) => game.partnerId
  ).length;
  data.auditSummary.fieldCounts.score_sum_zero = [...resultsByGame.values()].filter(
    (scores) => scores.reduce((sum, score) => sum + score, 0) === 0
  ).length;
  return data;
}

const canonical = importInto(
  JSON.parse(fs.readFileSync(targets[0], "utf8"))
);
const output = `${JSON.stringify(canonical, null, 2)}\n`;
for (const target of targets) {
  fs.mkdirSync(path.dirname(target), { recursive: true });
  fs.writeFileSync(target, output);
}

console.log(
  JSON.stringify({
    sessionId,
    sessions: canonical.sessions.length,
    games: canonical.games.length,
    results: canonical.playerResults.length,
  })
);
