import type { LiveSession } from "@/lib/liveSessionTypes";
import { canonicalGameType } from "@/lib/stats/gameTypeClassifier";
import { historicalGameResume } from "@/lib/stats/gameResumeText";
import type {
  HistoricalGame,
  HistoricalWhistData,
} from "@/lib/stats/historicalTypes";

const liveSeatOrder = ["Christian", "Peter", "Thomas", "Janus"];

function liveKind(game: HistoricalGame): string {
  const type = canonicalGameType(game);
  if (type === "Sol" || type === "Ren sol" || type === "Bordlægger" || type === "Halv bordlægger") {
    return "sol";
  }
  if (type === "Duestraf") return "duty";
  return "normal";
}

export function latestHistoricalSessionNumber(data: HistoricalWhistData): number {
  return data.sessions.reduce((latest, session) => {
    const value = Number.parseInt(session.sessionNumber, 10);
    return Number.isFinite(value) ? Math.max(latest, value) : latest;
  }, 0);
}

export function latestHistoricalLiveSession(data: HistoricalWhistData): LiveSession | null {
  const latestNumber = latestHistoricalSessionNumber(data);
  const session = [...data.sessions]
    .reverse()
    .find((candidate) => Number.parseInt(candidate.sessionNumber, 10) === latestNumber);
  if (!session) return null;

  const games = data.games
    .filter((game) => game.sessionId === session.id)
    .sort((a, b) => a.gameNumberInSession - b.gameNumberInSession);
  const resultsByGame = new Map<string, Map<string, number>>();
  for (const result of data.playerResults) {
    if (!resultsByGame.has(result.gameId)) {
      resultsByGame.set(result.gameId, new Map());
    }
    resultsByGame.get(result.gameId)!.set(result.playerId, result.score);
  }

  const totals = new Map(liveSeatOrder.map((playerId) => [playerId, 0]));
  const hands = games.map((game) => {
    const scores = resultsByGame.get(game.id) ?? new Map<string, number>();
    const scoresBySeat = liveSeatOrder.map((playerId) => scores.get(playerId) ?? 0);
    for (const [index, playerId] of liveSeatOrder.entries()) {
      totals.set(playerId, (totals.get(playerId) ?? 0) + scoresBySeat[index]);
    }
    const scoreRecord = Object.fromEntries(scores);
    return {
      handNumber: game.gameNumberInSession,
      kind: liveKind(game),
      caption:
        historicalGameResume(game, data.players, scoreRecord) ??
        `Spil #${game.gameNumberInSession}`,
      scoresBySeat,
      savedAt: session.date
        ? `${session.date}T12:00:${String(game.gameNumberInSession).padStart(2, "0")}Z`
        : undefined,
      noteText: game.correctionNote,
    };
  });

  const titleParts = [`Spilledag ${session.sessionNumber}`];
  if (session.date) titleParts.push(session.date);
  if (session.location) titleParts.push(session.location);

  return {
    schemaVersion: 2,
    sessionId: session.id,
    sessionNumber: latestNumber,
    title: titleParts.join(" · "),
    status: "finished",
    handCount: games.length,
    playerNamesBySeat: liveSeatOrder,
    totalsBySeat: liveSeatOrder.map((playerId) => totals.get(playerId) ?? 0),
    lastCompletedHandCaption: hands.at(-1)?.caption ?? null,
    hands,
    notesPublic: "",
    updatedAt: session.date ? `${session.date}T12:00:00Z` : data.generatedAt,
    serverUpdatedAt: data.generatedAt,
  };
}
