import type { LiveSession } from "@/lib/liveSessionTypes";

/**
 * The iOS app can have fewer local game days than the historical web dataset.
 * Treat the newest Neon snapshot as the next web game day instead of trusting
 * its device-local session number.
 */
export function mergeNewestLiveSession(
  liveSessions: LiveSession[],
  historicalSession: LiveSession | null,
  latestHistoricalNumber: number
): LiveSession[] {
  const historicalId = historicalSession?.sessionId;
  const newestLive = liveSessions.find(
    (session) => !historicalId || session.sessionId !== historicalId
  );

  const result: LiveSession[] = [];
  if (newestLive) {
    const localNumber = newestLive.sessionNumber ?? 0;
    result.push({
      ...newestLive,
      sessionNumber:
        localNumber > latestHistoricalNumber
          ? localNumber
          : latestHistoricalNumber + 1,
    });
  }
  if (historicalSession) {
    result.push(historicalSession);
  }
  return result;
}
