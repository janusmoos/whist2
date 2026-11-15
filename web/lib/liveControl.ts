import { getSql } from "@/lib/db";

export const LIVE_CONTROL_SESSION_ID = "00000000-0000-0000-0000-000000000000";

export type LiveControl = {
  enabled: boolean;
  changedAt: string | null;
};

type ControlPayload = {
  type?: string;
  enabled?: boolean;
  changedAt?: string;
};

export function controlFromPayload(payload: unknown): LiveControl {
  const value = (payload ?? {}) as ControlPayload;
  return {
    enabled: value.type !== "live_control" || value.enabled !== false,
    changedAt: typeof value.changedAt === "string" ? value.changedAt : null,
  };
}

export async function getLiveControl(): Promise<LiveControl> {
  const sql = getSql();
  const rows = await sql`
    SELECT payload
    FROM live_sessions
    WHERE session_id = ${LIVE_CONTROL_SESSION_ID}::uuid
    LIMIT 1
  `;
  return rows.length > 0
    ? controlFromPayload(rows[0].payload)
    : { enabled: true, changedAt: null };
}

export async function setLiveControl(enabled: boolean): Promise<LiveControl> {
  const sql = getSql();
  const changedAt = new Date().toISOString();
  const payload = JSON.stringify({
    type: "live_control",
    enabled,
    changedAt,
  });
  await sql`
    INSERT INTO live_sessions (session_id, payload, updated_at)
    VALUES (${LIVE_CONTROL_SESSION_ID}::uuid, ${payload}::jsonb, now())
    ON CONFLICT (session_id) DO UPDATE SET
      payload = EXCLUDED.payload,
      updated_at = now()
  `;
  return { enabled, changedAt };
}
