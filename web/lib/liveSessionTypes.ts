import type { HandSummary } from "@/components/HandsTable";
import type { PosterSnapshot } from "@/lib/posterTypes";

export type LiveSession = {
  schemaVersion?: number;
  sessionId?: string;
  sessionNumber?: number;
  title?: string;
  status?: string;
  handCount?: number;
  playerNamesBySeat?: string[];
  totalsBySeat?: number[];
  lastCompletedHandCaption?: string | null;
  hands?: HandSummary[];
  pendingPoster?: PosterSnapshot | null;
  lastHandPoster?: PosterSnapshot | null;
  pendingMeldingSummary?: string | null;
  pendingResultSummary?: string | null;
  pendingStep?: "melding" | "halve_trumf" | "resultat" | null;
  notesPublic?: string;
  updatedAt?: string;
  serverUpdatedAt?: string;
};

export function getActiveSession(sessions: LiveSession[]): LiveSession | null {
  return sessions.find((s) => s.status !== "finished") ?? null;
}
