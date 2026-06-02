# Whist 2.0 — live overblik (web)

Read-only webapp der viser aktive Whist-spilledage i næsten-realtid.

Data sendes fra iOS-appen via `PUT /api/sessions/{sessionId}` og gemmes i Neon Postgres.
Webappen poller hvert 2. sekund og viser aktuelle stillingsoversigter.

## Stack

- [Next.js](https://nextjs.org/) App Router (React 19)
- [Neon Postgres](https://neon.tech/) via `@neondatabase/serverless`
- Hosted på [Vercel](https://vercel.com/) (anbefalet)

## Lokal udvikling

```bash
cd web
cp .env.example .env.local
# Udfyld DATABASE_URL og LIVE_SESSION_API_SECRET i .env.local
npm install
npm run dev
```

Åbn <http://localhost:3000>.

## Miljøvariabler

| Variabel | Beskrivelse |
|---|---|
| `DATABASE_URL` | Neon Postgres connection string |
| `LIVE_SESSION_API_SECRET` | Bearer-token som iOS-appen sender ved hvert push |

Se `.env.example` for skabelon.

**Secrets må aldrig commit'es.** Brug `.env.local` lokalt og Vercel-projekts environment variables i produktion.

## Database-schema

Kør én gang i Neon SQL Editor:

```sql
CREATE TABLE IF NOT EXISTS live_sessions (
  session_id UUID PRIMARY KEY,
  payload    JSONB NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_live_sessions_updated
  ON live_sessions (updated_at DESC);
```

## API

| Metode | Sti | Beskrivelse |
|---|---|---|
| `PUT` | `/api/sessions/{sessionId}` | Upsert af session-snapshot fra iOS-appen. Kræver `Authorization: Bearer <secret>`. |
| `GET` | `/api/sessions` | Returnerer alle aktive sessions (payload + serverUpdatedAt). |

## Payload-kontrakt (schema v1)

iOS-appen sender et JSON-objekt med følgende felter:

```ts
type LiveSessionPayloadV1 = {
  schemaVersion: 1;
  sessionId: string;          // UUID
  updatedAt: string;          // ISO 8601
  title: string;
  status: "active" | "finished";
  handCount: number;
  playerNamesBySeat: string[];   // [north, east, south, west]
  totalsBySeat: number[];        // samme rækkefølge
  lastCompletedHandCaption?: string | null;
  pendingMeldingSummary?: string | null;
  pendingResultSummary?: string | null;
  pendingStep?: "melding" | "halve_trumf" | "resultat" | null;
  notesPublic: string;           // maks 500 tegn
};
```

`schemaVersion` øges, når der tilføjes felter der breakende ændrer fortolkningen.

## Arkitekturprincipper

- **Appen er primær.** SwiftData-save sker altid først; web-sync er fire-and-forget.
- **Snapshots, ikke events.** PUT sender altid den fulde aktuelle sandhed.
- **Ingen rigtig fler-enheds-input.** Dette er read-only distribution — ikke fler-enheds-redigering.

For detaljeret arkitektur, se `docs/statistik/web_live_overblik_og_statistik_plan.md` i repo-roden.

## Deployment (Vercel + Neon)

1. Opret Neon-database og kør schema SQL ovenfor.
2. Forbind Vercel-projekt til dette repo (root: `web/`).
3. Sæt `DATABASE_URL` og `LIVE_SESSION_API_SECRET` i Vercel project settings → Environment Variables.
4. Deploy.
5. Test med:

```bash
curl -X PUT https://<din-url>/api/sessions/00000000-0000-0000-0000-000000000001 \
  -H "Authorization: Bearer <secret>" \
  -H "Content-Type: application/json" \
  -d '{"schemaVersion":1,"sessionId":"00000000-0000-0000-0000-000000000001","updatedAt":"2026-06-02T18:00:00Z","title":"Test","status":"active","handCount":0,"playerNamesBySeat":["Christian","Peter","Thomas","Janus"],"totalsBySeat":[0,0,0,0],"notesPublic":""}'
```

Se den fulde deployment-checkliste i `docs/statistik/web_live_overblik_og_statistik_plan.md`.
