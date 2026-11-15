import type { HandSummary } from "@/components/HandsTable";
import type { LiveSession } from "@/lib/liveSessionTypes";
import type {
  HistoricalGame,
  HistoricalPlayer,
  HistoricalPlayerResult,
  HistoricalSession,
} from "@/lib/stats/historicalTypes";

function csvCell(value: unknown): string {
  const text = value == null ? "" : String(value);
  return `"${text.replaceAll('"', '""')}"`;
}

export function safeFilename(value: string): string {
  return value
    .normalize("NFKD")
    .replace(/[^\w.-]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .toLowerCase() || "whist";
}

export function handExport(
  session: LiveSession,
  hand: HandSummary
): Record<string, unknown> {
  const names = session.playerNamesBySeat ?? [];
  return {
    sessionId: session.sessionId,
    sessionNumber: session.sessionNumber,
    sessionTitle: session.title,
    sessionStatus: session.status,
    handNumber: hand.handNumber,
    kind: hand.kind,
    caption: hand.caption,
    savedAt: hand.savedAt,
    scores: names.map((name, index) => ({
      player: name,
      score: hand.scoresBySeat[index] ?? 0,
    })),
    noteTitle: hand.noteTitle ?? null,
    noteText: hand.noteText ?? null,
    noteCreatedAt: hand.noteCreatedAt ?? null,
  };
}

export function handsCsv(session: LiveSession, hands: HandSummary[]): string {
  const names = session.playerNamesBySeat ?? [];
  const header = [
    "spilledag_id",
    "spilledag_nummer",
    "spilledag_navn",
    "spil_nummer",
    "type",
    "resume",
    "gemt_tidspunkt",
    ...names.flatMap((name) => [`${name}_navn`, `${name}_point`]),
    "note_titel",
    "note",
    "note_tidspunkt",
  ];
  const rows = hands.map((hand) => [
    session.sessionId,
    session.sessionNumber,
    session.title,
    hand.handNumber,
    hand.kind,
    hand.caption,
    hand.savedAt,
    ...names.flatMap((name, index) => [name, hand.scoresBySeat[index] ?? 0]),
    hand.noteTitle,
    hand.noteText,
    hand.noteCreatedAt,
  ]);
  return [header, ...rows]
    .map((row) => row.map(csvCell).join(","))
    .join("\r\n");
}

export function historicalGameExport(
  session: HistoricalSession,
  game: HistoricalGame,
  players: HistoricalPlayer[],
  results: HistoricalPlayerResult[]
): Record<string, unknown> {
  const scoreByPlayer = new Map(
    results.map((result) => [result.playerId, result.score])
  );
  return {
    sessionId: session.id,
    sessionNumber: session.sessionNumber,
    sessionDate: session.date ?? null,
    sessionLocation: session.location ?? null,
    gameId: game.id,
    gameNumber: game.gameNumberInSession,
    gameTypeRaw: game.gameTypeRaw ?? null,
    gameTypeNormalized: game.gameTypeNormalized ?? null,
    bidTricks: game.bidTricks ?? null,
    bidderIds: game.bidderIds ?? (game.bidderId ? [game.bidderId] : []),
    winnerIds: game.winnerIds ?? (game.winnerId ? [game.winnerId] : []),
    partnerId: game.partnerId ?? null,
    dealerId: game.dealerId ?? null,
    scores: [...players]
      .sort((a, b) => a.displayOrder - b.displayOrder)
      .map((player) => ({
        player: player.name,
        playerId: player.id,
        score: scoreByPlayer.get(player.id) ?? 0,
      })),
    qualityFlags: game.qualityFlags ?? [],
    correctionNote: game.correctionNote ?? null,
  };
}

export function historicalGameCsv(
  session: HistoricalSession,
  game: HistoricalGame,
  players: HistoricalPlayer[],
  results: HistoricalPlayerResult[]
): string {
  const data = historicalGameExport(session, game, players, results);
  const scores = data.scores as {
    player: string;
    playerId: string;
    score: number;
  }[];
  const header = [
    "spilledag_id",
    "spilledag_nummer",
    "dato",
    "sted",
    "spil_id",
    "spil_nummer",
    "spiltype",
    "bud_stik",
    "meldere",
    "vindere",
    "makker",
    "giver",
    ...scores.flatMap((score) => [
      `${score.player}_navn`,
      `${score.player}_point`,
    ]),
    "kvalitetsflag",
    "rettelsesnote",
  ];
  const row = [
    data.sessionId,
    data.sessionNumber,
    data.sessionDate,
    data.sessionLocation,
    data.gameId,
    data.gameNumber,
    data.gameTypeNormalized ?? data.gameTypeRaw,
    data.bidTricks,
    (data.bidderIds as string[]).join("; "),
    (data.winnerIds as string[]).join("; "),
    data.partnerId,
    data.dealerId,
    ...scores.flatMap((score) => [score.player, score.score]),
    (data.qualityFlags as string[]).join("; "),
    data.correctionNote,
  ];
  return [header, row].map((values) => values.map(csvCell).join(",")).join("\r\n");
}
