# Web/live-overblik og live-statistik

Dato: 2026-06-02  
Branch: `codex/web-live-overblik-plan`  
Status: Arkitektur- og handoff-plan. Ingen produktkode er ændret i denne branch.

## Formål

Målet er at gøre live scores og relevant statistik tilgængelig på nettet uden at gøre iOS-appen langsommere, mere skrøbelig eller afhængig af en aktiv netforbindelse.

Webdelen skal i første omgang være et offentligt eller delt live-overblik over den aktuelle spilledag:

- aktuel stilling
- antal gemte spil
- seneste afsluttede spil
- igangværende melding/resultat som read-only status
- opdatering tæt på realtid, men uden hård realtidsbinding

På længere sigt kan webdelen udvides til egentlige statistikvisninger:

- live-dagens udvikling
- spilleroversigt for aktuel spilledag
- simple historiske nøgletal, hvis serveren får adgang til historisk datasæt
- delbare links pr. spilledag
- evt. QR/kode-baseret adgang

Det er vigtigt at holde denne løsning adskilt fra rigtig fler-enheds-input. Web/live-overblik er read-only distribution. Det løser ikke i sig selv konflikter, skriverettigheder eller at fire telefoner kan redigere samme hånd. Det spor kræver fortsat CloudKit eller egen backend med lås/lease, som beskrevet i `MULTI_DEVICE.md`.

## Hvorfor en separat branch er rigtig

En ny branch er den rigtige ramme, fordi web/live-overblik krydser flere systemgrænser:

- iOS-appens SwiftData og save/autosave-flow
- payload-kontrakt mellem app og API
- Next.js-webapp
- database og deployment
- sikkerhed, adgang og driftsfejl
- performancekrav for både app og web

Hvis det blandes ind i en design- eller statistik-UI-branch, bliver det svært at vide om en regression skyldes layout, live-statistik, netværk eller persistence. Branchens første opgave bør derfor være analyse, kontrakt og små sikre forbedringer.

## Eksisterende status i repoet

Der findes allerede en første version af både app-sync og web-overblik.

### iOS

Fil: `Whist20/Services/LiveSessionSync.swift`

Den eksisterende sync:

- læser `LiveSessionAPIBaseURL` og `LiveSessionAPISecret` fra `Whist20/AppInfoAdditions.plist`
- bygger et `LiveSessionPushPayload` fra `GameDay`
- sender `PUT /api/sessions/{sessionId}` med Bearer-token
- bruger en `LiveSessionSyncCoordinator` med kort debounce
- gør ingenting, hvis base URL eller secret ikke er konfigureret

Payloaden indeholder i dag:

- `sessionId`
- `updatedAt`
- `title`
- `status` (`active` eller `finished`)
- `handCount`
- `playerNamesBySeat`
- `totalsBySeat`
- `lastCompletedHandCaption`
- `pendingMeldingSummary`
- `pendingResultSummary`
- `pendingStep`
- `notesPublic`

Sync kaldes fra flere steder:

- ny spilledag oprettes i `NewGameDayView`
- spilledag afsluttes/genoptages i `GameDaySession`
- pending hand oprettes/opdateres/slettes i `HandDraftPersistence`

### Web

Mappe: `web/`

Eksisterende stack:

- Next.js App Router
- React
- Neon Postgres via `@neondatabase/serverless`
- `GET /api/sessions` returnerer aktive sessions
- `PUT /api/sessions/[sessionId]` upserter payload med Bearer-token
- `web/app/page.tsx` poller hvert 2. sekund og viser aktive sessions

Databasekommentar i `web/lib/db.ts` beskriver denne tabel:

```sql
CREATE TABLE IF NOT EXISTS live_sessions (
  session_id UUID PRIMARY KEY,
  payload JSONB NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_live_sessions_updated
ON live_sessions (updated_at DESC);
```

### Manglende konfiguration

`Whist20/AppInfoAdditions.plist` har tomme værdier:

- `LiveSessionAPIBaseURL`
- `LiveSessionAPISecret`

Webdelen kræver miljøvariabler:

- `DATABASE_URL`
- `LIVE_SESSION_API_SECRET`

Det betyder, at sync er designet til at være opt-in. Uden konfiguration påvirker den ikke appens netværk eller runtime-adfærd.

## Arkitekturprincipper

### 1. Appen er primær og må aldrig vente på nettet

iOS-appen skal fortsat fungere fuldt offline. Gem af hånd, pending draft, spilledag og statistik må ikke afhænge af webserveren.

Regel:

- SwiftData-save sker først.
- Web-sync er fire-and-forget.
- Fejl i web-sync må højst logges i debug.
- Der må ikke vises blokkerende fejl i spilflowet, medmindre brugeren eksplicit åbner en sync-statusside.

### 2. Send snapshots, ikke events

Serveren bør modtage den aktuelle sandhed for en spilledag som snapshot, ikke en strøm af del-events.

Fordele:

- mistede requests kan indhentes af næste snapshot
- serveren behøver ikke rekonstruere state
- payload-kontrakten er enkel
- web-UI kan rendere direkte fra seneste kendte snapshot
- idempotent `PUT` passer godt til dårlig mobilforbindelse

Fortsæt derfor med `PUT /api/sessions/{sessionId}` som primær write-model.

### 3. Hold payload lille og stabil

Appen skal ikke sende hele historikken ved hver ændring. Første webfase bør nøjes med aktiv spilledags status og nøgletal.

Anbefalet payload v1:

```ts
type LiveSessionPayloadV1 = {
  schemaVersion: 1;
  sessionId: string;
  updatedAt: string;
  title: string;
  status: "active" | "finished";
  handCount: number;
  playerNamesBySeat: string[];
  totalsBySeat: number[];
  lastCompletedHandCaption?: string | null;
  pendingMeldingSummary?: string | null;
  pendingResultSummary?: string | null;
  pendingStep?: "melding" | "halve_trumf" | "resultat" | null;
  notesPublic: string;
};
```

`schemaVersion` bør tilføjes tidligt, før webdelen vokser. Den gør det lettere at ændre format senere uden at knække gamle deployments.

### 4. Web-statistik skal beregnes server-/web-side fra serverdata

Når webdelen får statistik, bør den ikke kalde ind i iOS-appens statistikengine. Den skal bruge den data, serveren allerede har modtaget.

Første statistik på web bør derfor være lokal for den aktive session:

- stilling
- føring/placering
- sidste spil
- antal spil
- evt. simple ændringer siden sidste snapshot, hvis payload senere inkluderer håndliste

Hvis web senere skal vise historisk statistik, bør det være et separat datagrundlag:

- enten bundlet historisk JSON i webappen
- eller en server-import af `whist_historical_data_v3.json`
- eller en særskilt API for historiske stats

Det må ikke få iOS-appen til at sende alle historiske data.

### 5. Ingen negativ performance i iOS

Alle ændringer skal vurderes mod dette krav:

- `ModelContext.save()` må ikke vente på netværk.
- Payload-bygning må ikke ske for ofte under draft-autosave.
- Netværksfejl må ikke trigge retry-loops på main actor.
- Statistikfanens live adapter må ikke blandes sammen med web-sync.

Det eksisterende design er på rette vej, fordi sync er debounced og netværk sker i en actor. Der er dog stadig nogle forbedringer, der bør prioriteres før en offentlig deployment.

## Performance-analyse for iOS

### Nuværende risikopunkter

1. `HandDraftPersistence` kan kalde `schedulePush` ved pending-opdateringer. Hvis draft autosaves ofte, kan der komme mange sync-forsøg.
2. `LiveSessionSnapshotBuilder.makePayload(from:)` læser totals via `gameDay.scoreStanding`, som aggregerer hænder. For få hænder er det billigt, men det bør forblive begrænset til aktiv spilledag.
3. `pushNow` fetcher `GameDay` på main actor efter debounce. Det er okay for en enkelt dag, men der bør ikke laves bred fetch eller tung historisk statistik her.
4. Request-body sendes uden retry-kø. Ved netværksfejl tabes snapshot, men næste ændring sender igen. Det er acceptabelt for live-overblik, men skal dokumenteres.

### Anbefalede app-forbedringer

#### A. Længere og adaptiv debounce for pending

Gemte hænder bør pushe hurtigt. Pending draft kan tåle lidt mere forsinkelse.

Foreslået adfærd:

- ny/afsluttet hånd: 150-300 ms debounce
- pending melding/resultat: 800-1500 ms debounce
- afslut/genoptag spilledag: 150-300 ms debounce

Det reducerer netværksstøj, når brugeren trykker rundt i meldingsflowet.

#### B. Fingerprint før send

Gem seneste sendte fingerprint pr. `GameDay`.

Fingerprint kan bygges af:

- `status`
- `handCount`
- totals
- pending step
- pending summary strings
- last completed hand caption
- notesPublic

Hvis fingerprint er uændret efter debounce, sendes der ikke.

Dette beskytter mod gentagne saves, der ikke ændrer public state.

#### C. Ingen synkrone webkald fra statistikfanen

Statistikfanen bruger i dag `HistoricalStatisticsStore` og `LiveHistoricalStatisticsAdapter` til lokal kombineret statistik. Web-sync skal blive i `Services/LiveSessionSync.swift` og må ikke kobles til `StatistikTabView`.

Statistikvisning i appen og web-publicering er to forskellige outputs fra SwiftData:

- app-statistik: lokal, rig, intern
- web-overblik: lille snapshot, offentlig/delt

#### D. Begræns payload til aktiv dag

Web-sync bør som udgangspunkt kun sende den `GameDay`, der blev ændret. Den skal ikke sende alle `gameDays`.

Når en dag afsluttes, kan serveren beholde den i databasen, men `GET /api/sessions` kan filtrere til aktive sessions. Senere kan der laves `GET /api/sessions/{id}` for delbare links til både aktive og afsluttede.

#### E. Background retry først senere

En robust retry-kø er nyttig, men bør ikke være første fase. Den kan gøre appen mere kompleks.

Fase 1 bør acceptere:

- hvis et snapshot fejler, vises serverens seneste kendte state
- næste ændring sender et nyt snapshot
- appen blokerer aldrig

Fase 2 kan tilføje en lille in-memory retry med max 1-2 forsøg og exponential backoff. Persistent offline-kø bør kun tilføjes, hvis produktet kræver det.

## Server- og webarkitektur

### API-kontrakt

Behold:

- `PUT /api/sessions/[sessionId]`
- `GET /api/sessions`

Tilføj senere:

- `GET /api/sessions/[sessionId]` til delbart link
- evt. `GET /api/health` til deployment-check
- evt. `GET /api/sessions/[sessionId]/history`, hvis serveren begynder at gemme håndhistorik

### Database v1

Eksisterende `live_sessions` kan bruges til første version.

Anbefalet udvidelse:

```sql
ALTER TABLE live_sessions
ADD COLUMN IF NOT EXISTS status TEXT
GENERATED ALWAYS AS (payload->>'status') STORED;

CREATE INDEX IF NOT EXISTS idx_live_sessions_status_updated
ON live_sessions (status, updated_at DESC);
```

Hvis Neon ikke understøtter ønsket generated-column flow i den valgte opsætning, kan status blot forblive JSONB-filter i første fase. Tabellen er lille.

### Database v2: session events eller hand snapshots

Hvis webstatistik skal vise udvikling over tid, er seneste snapshot ikke nok. Der er to mulige retninger:

#### Mulighed 1: Payload indeholder håndliste

Appen sender en kompakt liste over gemte hænder for den aktuelle spilledag.

Fordel:

- serveren forbliver simpel
- web kan tegne live-graf efter refresh

Ulempe:

- payload vokser med antal hænder
- appen skal serialisere mere data ved hvert push

Dette er acceptabelt ved whist-størrelser, hvis håndlisten holdes kompakt.

#### Mulighed 2: Server gemmer snapshot-historik

Serveren gemmer seneste snapshot i `live_sessions` og append-only snapshots i `live_session_snapshots`.

Fordel:

- web kan vise historisk udvikling uden større app-payload
- bedre debug og drift

Ulempe:

- database vokser
- kræver oprydningspolitik
- kan gemme meget pending-tekst, hvis snapshots tages ved hvert draft-save

Anbefaling:

Start med mulighed 1, men kun for gemte hænder, ikke pending draft-events. Tilføj håndliste som `completedHands` i schema v2.

### Foreslået payload v2 for webstatistik

```ts
type LiveCompletedHandV2 = {
  id: string;
  handNumber: number;
  playedAt: string;
  kindRaw: "normal" | "sol" | "duty" | string;
  caption: string;
  scoresBySeat: number[];
  bidderSeat?: number | null;
  partnerSeat?: number | null;
};

type LiveSessionPayloadV2 = LiveSessionPayloadV1 & {
  schemaVersion: 2;
  completedHands: LiveCompletedHandV2[];
};
```

Dette giver web mulighed for:

- scorekurve pr. spiller
- sidste N spil
- største hop/fald
- spiltype-fordeling for live-dagen
- simpel spillerprofil for aktuel dag

Det bør ikke indføres, før v1 er deployet og stabil.

## Sikkerhed og privatliv

### Bearer-token

Serveren kræver allerede `LIVE_SESSION_API_SECRET`, og iOS sender `LiveSessionAPISecret`.

Regler:

- secret må ikke commit'es i repoet
- Vercel/hosting bruger env var
- iOS secret sættes via build config, xcconfig, CI secret eller manuel lokal plist for test
- token bør kunne roteres uden kodeændring

### Offentlig data

`notesPublic` afkortes allerede til 500 tegn. Det er godt, men produktet bør beslutte om noter overhovedet skal publiceres.

Anbefaling for første offentlige version:

- behold `notesPublic`, men vis den diskret
- overvej en app-indstilling: "Del noter på live-overblik"
- send aldrig intern debug, lokal device-info eller fuld draft JSON

### Adgang til webside

Første version kan være et lukket link uden login, hvis URL'en ikke markedsføres. Det er dog ikke egentlig sikkerhed.

Mulige niveauer:

1. Offentlig oversigt over alle aktive sessions.
2. Delbart session-link med ukendt UUID.
3. Session-link med ekstra public share token.
4. Login eller password.

Anbefaling:

- Fase 1: offentlig oversigt til intern test.
- Fase 2: `GET /sessions/{sessionId}` og fjern global liste fra offentlig visning, hvis data skal deles mere kontrolleret.
- Fase 3: share token, hvis websiden skal bruges uden for lille testkreds.

## Web-UX plan

Første skærm skal være selve live-overblikket, ikke en landing page.

### Fase 1: Stabilt live-overblik

Vis:

- spilledagens navn
- aktiv/afsluttet status
- "opdateret for X sekunder siden"
- fire spilleres aktuelle score
- tydelig leder/placering
- seneste afsluttede spil
- igangværende melding/resultat
- netværksstatus: "forbindelse tabt" eller "venter på data"

Undgå:

- tung grafik
- store marketing-heroer
- forklarende hjælpetekst
- mange dekorative cards

### Fase 2: Session-detalje

Tilføj `/sessions/[sessionId]`.

Vis:

- live-scoretavle
- lille scorekurve
- seneste 5-10 spil
- pending status øverst, hvis en hånd er i gang

### Fase 3: Live-statistik

Når `completedHands` findes i payload:

- pointudvikling over tid
- spiltype-fordeling
- bedste/værste hånd
- antal meldinger pr. spiller
- nulsum/kvalitetsadvarsel hvis scores ikke summerer til 0

### Fase 4: Historisk statistik på web

Kun hvis det ønskes som særskilt produkt:

- importer/bundle `whist_historical_data_v3.json` i web
- genimplementer små udvalgte statistikker i TypeScript
- eller lav en server-preparer baseret på samme JSON-format

Dette er ikke nødvendigt for live-overblik.

## App-integration plan

### Fase A: Kontrakt og konfiguration

Opgaver:

- tilføj `schemaVersion` til `LiveSessionPushPayload`
- dokumenter env vars og plist-konfiguration
- tilføj en `web/README.md`
- overvej `.env.example` i `web/`
- bevar tomme secrets i repoet

Accept:

- appen bygger uden konfiguration
- web-sync er inaktiv uden base URL og secret
- API afviser uden secret

### Fase B: Performance-sikring i sync

Opgaver:

- indfør fingerprint, så identiske snapshots ikke sendes igen
- giv pending-flow en længere debounce end gemt hånd
- hold `LiveSessionSnapshotBuilder` fri for historisk statistik
- tilføj unit tests for payload-builder, hvis muligt uden tung SwiftData-setup

Accept:

- gem af hånd føles uændret i appen
- draft-navigation spammer ikke serveren
- sync-fejl påvirker ikke UI-flow

### Fase C: Web v1 polish

Opgaver:

- forbedr web-UI til en rolig, scanbar scoreboard-side
- vis relative opdateringstider
- vis status for stale data, fx efter 20 sekunder uden server update
- håndter tom liste, 503 og ugyldigt payload pænt
- valider payload med en lille runtime-guard i API/UI

Accept:

- `npm run build` passerer
- siden fungerer med en mocked eller seeded session
- mobil og desktop layout har ingen overlap

### Fase D: Deployment

Opgaver:

- opret Neon database
- kør schema SQL
- deploy `web/` til Vercel eller tilsvarende
- sæt `DATABASE_URL`
- sæt `LIVE_SESSION_API_SECRET`
- konfigurer appens base URL og secret lokalt/test-build
- test PUT med `curl`
- test fra app/simulator

Accept:

- `GET /api/sessions` returnerer aktiv spilledag efter app-save
- webside opdaterer uden reload
- afsluttet spilledag forsvinder fra global aktiv-liste

### Fase E: Payload v2 og webstatistik

Opgaver:

- tilføj kompakt `completedHands`
- tegn scorekurve
- vis seneste spil som liste
- beregn live-dagens simple stats i TypeScript

Accept:

- payloadstørrelse er stadig lille for realistiske spilledage
- appen sender kun efter debounce/fingerprint
- webstatistik matcher appens stilling for aktuel dag

## Teststrategi

### iOS

Kør:

```bash
xcodebuild \
  -project "Whist20.xcodeproj" \
  -scheme "Whist20" \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  test
```

Fokustests:

- payload builder med aktiv spilledag
- payload builder med afsluttet spilledag
- pending melding uden gemt hånd
- seneste hånd caption
- notes truncation
- fingerprint ændrer sig kun ved public state-ændring

### Web

Kør:

```bash
cd web
npm run build
```

Supplerende testmuligheder:

- API PUT uden token giver 401
- API PUT med ugyldigt UUID giver 400
- API PUT med valid payload upserter
- API GET filtrerer kun active
- UI håndterer tom liste og stale update

Hvis der ikke ønskes en fuld testframework i første omgang, kan en lille `web/scripts/seed-session.mjs` eller dokumenterede `curl`-kommandoer være nok.

## Deployment-checkliste

1. Opret Neon database.
2. Kør schema SQL fra `web/lib/db.ts`.
3. Deploy `web/` til Vercel.
4. Sæt `DATABASE_URL`.
5. Sæt `LIVE_SESSION_API_SECRET`.
6. Test `GET /api/sessions` uden data.
7. Test `PUT /api/sessions/{uuid}` med Bearer-token.
8. Sæt appens `LiveSessionAPIBaseURL`.
9. Sæt appens `LiveSessionAPISecret`.
10. Start spilledag i simulator.
11. Bekræft webopdatering.
12. Gem hånd og bekræft scoreopdatering.
13. Lav pending melding og bekræft pending-status.
14. Afslut spilledag og bekræft at den ikke vises i aktiv oversigt.

## Cursor-handoff: anbefalet arbejdsrækkefølge

Arbejd i små commits:

1. Dokumentation og konfiguration:
   - `web/README.md`
   - `web/.env.example`
   - `schemaVersion` i payload

2. iOS performance-sikring:
   - fingerprint i `LiveSessionSyncCoordinator`
   - separat debounce for pending vs. saved hand
   - evt. tests for snapshot builder

3. Web v1:
   - forbedr `web/app/page.tsx`
   - bedre responsive scoreboard layout i `web/app/globals.css`
   - vis stale/relative time

4. API robusthed:
   - payload validation
   - bedre fejlbeskeder
   - evt. `GET /api/health`

5. Deployment:
   - Neon SQL
   - Vercel env vars
   - manual smoke test med simulator

6. Web-statistik v2:
   - tilføj `completedHands`
   - session detail route
   - scorekurve og seneste spil

## Åbne beslutninger

Disse skal afklares, før webdelen gøres bredt tilgængelig:

- Skal global `/` vise alle aktive sessions, eller skal brugere kun kende et session-link?
- Skal noter publiceres?
- Skal afsluttede spilledage kunne ses på web?
- Skal webdelen være offentlig, share-token-baseret eller passwordbeskyttet?
- Skal webstatistik kun vise live-dagen, eller også historisk statistik?
- Skal appen have en synlig "live-sync aktiv" indikator?

## Anbefalet næste konkrete commit

Første kodecommit bør være lille:

- tilføj `schemaVersion` til iOS payload
- tilføj `web/README.md`
- tilføj `web/.env.example`
- opdater webtypen i `page.tsx`
- kør iOS tests og `npm run build`

Derefter kan performanceforbedringer og web-UI-polish laves uden at ændre datakontrakten igen med det samme.

