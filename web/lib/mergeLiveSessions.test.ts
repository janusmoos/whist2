import assert from "node:assert/strict";
import test from "node:test";
import type { LiveSession } from "./liveSessionTypes";
import { mergeNewestLiveSession } from "./mergeLiveSessions";

const historical: LiveSession = {
  sessionId: "historical-31",
  sessionNumber: 31,
  status: "finished",
};

test("promotes a device-local session number after the historical dataset", () => {
  const result = mergeNewestLiveSession(
    [
      {
        sessionId: "new-live-day",
        sessionNumber: 1,
        status: "active",
      },
    ],
    historical,
    31
  );

  assert.equal(result[0]?.sessionId, "new-live-day");
  assert.equal(result[0]?.sessionNumber, 32);
  assert.equal(result[1]?.sessionNumber, 31);
});

test("uses the newest snapshot and ignores an older abandoned active session", () => {
  const result = mergeNewestLiveSession(
    [
      {
        sessionId: "newest-finished-day",
        sessionNumber: 1,
        status: "finished",
      },
      {
        sessionId: "old-active-test",
        sessionNumber: 4,
        status: "active",
      },
    ],
    historical,
    31
  );

  assert.equal(result.length, 2);
  assert.equal(result[0]?.sessionId, "newest-finished-day");
  assert.equal(result[0]?.sessionNumber, 32);
});

test("preserves a valid web session number", () => {
  const result = mergeNewestLiveSession(
    [{ sessionId: "day-35", sessionNumber: 35, status: "active" }],
    historical,
    31
  );

  assert.equal(result[0]?.sessionNumber, 35);
});
