import { neon } from "@neondatabase/serverless";

/**
 * Opret tabel én gang i Neon SQL Editor:
 *
 * CREATE TABLE IF NOT EXISTS live_sessions (
 *   session_id UUID PRIMARY KEY,
 *   payload JSONB NOT NULL,
 *   updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
 * );
 * CREATE INDEX IF NOT EXISTS idx_live_sessions_updated ON live_sessions (updated_at DESC);
 */
export function getSql() {
  const url = process.env.DATABASE_URL;
  if (!url) {
    throw new Error("DATABASE_URL mangler (tilføj i Vercel / .env.local).");
  }
  return neon(url);
}
