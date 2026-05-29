# Statistik-arkitektur og live-integration — Whist20

**Dato:** 2026-05-29  
**Branch:** `codex/performance-refactor-plan`  
**Formål:** Handoff-dokument til Codex. Beskriver den optimale caching-arkitektur for historiske statistikker og design af live-spil-integration.

---

## 1. De to datakilder — det centrale fund

Statistik-fanen og SwiftData-laget er i dag **fuldstændigt adskilt**:

| Datalayer | Kilde | Indhold | Ændrer sig? |
|-----------|-------|---------|-------------|
| **Historiske stats** | `whist_historical_data_v3.json` (bundlet) | 32 sessions, 903 spil, 3.612 resultater, 4 spillere | **Aldrig** i en session — kun ved ny app-version |
| **Live spil** | SwiftData (`GameDay`, `RecordedHand`) | Igangværende og gemte spil | **Ved hvert gemt spil** |

`StatistikTabView`, `HistoricalStatisticsEngine` og `HistoricalStatisticsPreparer` importerer ikke SwiftData. Alle statistikker beregnes udelukkende fra JSON.

**Konsekvens:** Alle eksisterende statistikker kan precomputes én gang og caches for hele app-sessionen. Der er ingen grund til at genberegne noget, hverken ved faneskift eller navigation.

---

## 2. Cache-strategi: hvad må aldrig genberegnes

### 2.1 Frossent for evigt (rene JSON-statistikker)

Disse afhænger kun af den statiske JSON og kan precomputes én gang i `Task.detached` ved app-start:

| Statistik | Engine-kald | Omfang |
|-----------|-------------|--------|
| Alle session-overviews | `sessionOverviews(from: data)` | 32 sessions |
| Spiller-profiler | `playerProfiles(from: data)` | 4 spillere + `gameDetails` |
| Spiltype-oversigter | `gameTypeOverviews(from:)` | Alle spiltyper |
| Trend-summaries | `playerTrendSummaries(from:)` + `gameTypeTrendSummaries(from:)` | Alle scopes |
| Score-streaks | `scoreStreakSummary(from:)` | Alle spil i rækkefølge |
| Distributions | `bidTrickDistribution`, `solGameDistribution`, `vipGameDistribution`, `trumpDistribution` | Simple aggregeringer |
| Snapshot (all scope) | `snapshot(from: data, scope: .all)` | Totals, timeline, issues |
| Scoped snapshots | `snapshot(scope: .recent, recentLimit: X)` for alle 6 limit-værdier (5, 10, 15, 20, 25, 50) | Fil­trerede subsets |
| Player session scores | `playerSessionScores(from: data)` | 32 × 4 entries |
| Datagrundlag | `snapshot(scope: .all).derivedIssueCounts` | Kvalitetsflags |

### 2.2 Opdateres ved gemt live-spil

Når et nyt spil gemmes via `onSaved`-callback i `AddHandView`, tilføjes det til live-laget og følgende stats recalculeres **billigt**:

| Statistik | Hvad der ændrer sig | Beregnings­omkostning |
|-----------|--------------------|-----------------------|
| Session-overview for aktiv session | Ét nyt spil + opdaterede summer | Lav |
| Samlet stilling (total pr. spiller) | Én addition pr. spiller | Triviel |
| Tidslinje (score-kurve) | Ét nyt punkt pr. spiller | Triviel |
| Snapshot `.current` | Filtrering + summer | Lav |
| Spiltype-oversigt (live-andel) | Ét nyt spil kategoriseres | Lav |

Alt andet — de 32 historiske sessions, historiske profiler, historiske streaks — forbliver uændret.

---

## 3. Målarkitektur

### 3.1 To-lags model

```
┌──────────────────────────────────────────────────────────┐
│  HistoricalStatisticsStore  (@StateObject i ContentView) │
│                                                          │
│  phase: .loading → .ready(FullModel)                     │
│                                                          │
│  FullModel = HistoricalStatisticsFullModel               │
│    ├─ frozen: FrozenStatistics     ← ren JSON, beregnet  │
│    │                                 én gang for evigt   │
│    └─ live:   LiveStatisticsLayer  ← SwiftData, opdateres│
│                                      ved hvert gem        │
└──────────────────────────────────────────────────────────┘
```

### 3.2 `HistoricalStatisticsFullModel` — ny samlet type

Erstatter `HistoricalStatisticsHubModel`. Indeholder **alt** forudberegnet:

```swift
struct HistoricalStatisticsFullModel {

    // ── Rå data (til destinations der behøver HistoricalWhistData) ──
    let historicalData: HistoricalWhistData

    // ── Frossede JSON-stats ──
    let allSnapshot: HistoricalStatisticsSnapshot
    let allSessionOverviews: [HistoricalSessionOverview]
    let playerSessionScores: [String: [HistoricalPlayerSessionScore]]
    let playerProfiles: [HistoricalPlayerProfile]
    let playerSummaries: [HistoricalPlayerScoreSummary]
    let gameTypeOverviews: [HistoricalGameTypeOverview]
    let trendSummaries: [HistoricalPlayerTrendSummary]
    let gameTypeTrendSummaries: [HistoricalGameTypeTrendSummary]
    let streakSummary: HistoricalScoreStreakSummary
    let bidTrickDistribution: [HistoricalBidTrickBucket]
    let solDistribution: [GameTypeSlice]
    let vipDistribution: [GameTypeSlice]
    let trumpDistribution: [GameTypeSlice]

    // Pregen af alle scope-kombinationer (6 limit-værdier × recent/all/current)
    let snapshotsByScope: [ScopeCacheKey: HistoricalStatisticsSnapshot]

    // ── Live-lag (opdateres uden at røre frozen-delen) ──
    var live: LiveStatisticsLayer

    // Hub-convenience
    var currentOverview: HistoricalSessionOverview? {
        live.currentSessionOverview ?? allSessionOverviews.last
    }
    var gameTypeCount: Int {
        gameTypeOverviews.count
    }
}

struct ScopeCacheKey: Hashable {
    var scope: HistoricalStatisticsScope
    var recentLimit: Int
}

struct LiveStatisticsLayer {
    /// Spil gemt i denne session (SwiftData → konverteret til HistoricalGame-form)
    var liveGames: [LiveGame] = []
    /// Override for current-session overview (nil = brug allSessionOverviews.last)
    var currentSessionOverview: HistoricalSessionOverview?
    /// Extra timeline-punkter der lægges oven på JSON-tidslinjen
    var extraTimelinePoints: [HistoricalScoreTimelinePoint] = []
}
```

### 3.3 `HistoricalStatisticsPreparer` — precompute alt i ét baggrundskald

```swift
enum HistoricalStatisticsPreparer {
    static func prepareFullModel(loader: HistoricalDataJSONLoader) throws -> HistoricalStatisticsFullModel {
        let data = try loader.load()

        // Alle frossede stats beregnes her — ét baggrundskald, aldrig igen
        let allSnapshot      = HistoricalStatisticsEngine.snapshot(from: data, scope: .all)
        let sessionOverviews = HistoricalStatisticsEngine.sessionOverviews(from: data)
        let playerSessions   = HistoricalStatisticsEngine.playerSessionScores(from: data)
        let profiles         = HistoricalStatisticsEngine.playerProfiles(from: data)
        let summaries        = HistoricalStatisticsEngine.playerScoreSummaries(from: data)
        let gameTypes        = HistoricalStatisticsPreparer.gameTypeOverviews(from: data)
        let trends           = HistoricalStatisticsEngine.playerTrendSummaries(from: data)
        let gameTypeTrends   = HistoricalStatisticsEngine.gameTypeTrendSummaries(from: data)
        let streaks          = HistoricalStatisticsEngine.scoreStreakSummary(from: data)
        let bidDist          = bidTrickDistribution(from: data)
        let solDist          = solGameDistribution(from: data)
        let vipDist          = vipGameDistribution(from: data)
        let trumpDist        = trumpDistribution(from: data)

        // Pregen af scoped snapshots for alle kombinationer brugt i UI
        var scopeCache: [ScopeCacheKey: HistoricalStatisticsSnapshot] = [:]
        let limits = [5, 10, 15, 20, 25, 50]
        for scope in HistoricalStatisticsScope.allCases {
            for limit in limits {
                let key = ScopeCacheKey(scope: scope, recentLimit: limit)
                scopeCache[key] = HistoricalStatisticsEngine.snapshot(from: data, scope: scope, recentSessionLimit: limit)
            }
        }

        return HistoricalStatisticsFullModel(
            historicalData: data,
            allSnapshot: allSnapshot,
            allSessionOverviews: sessionOverviews,
            playerSessionScores: playerSessions,
            playerProfiles: profiles,
            playerSummaries: summaries,
            gameTypeOverviews: gameTypes,
            trendSummaries: trends,
            gameTypeTrendSummaries: gameTypeTrends,
            streakSummary: streaks,
            bidTrickDistribution: bidDist,
            solDistribution: solDist,
            vipDistribution: vipDist,
            trumpDistribution: trumpDist,
            snapshotsByScope: scopeCache,
            live: LiveStatisticsLayer()
        )
    }
}
```

### 3.4 `HistoricalStatisticsStore` — opdateret

```swift
@MainActor
final class HistoricalStatisticsStore: ObservableObject {
    enum Phase {
        case idle, loading
        case ready(HistoricalStatisticsFullModel)
        case failure(Error)
    }
    @Published private(set) var phase: Phase = .idle
    private var hasStartedLoading = false

    func loadIfNeeded() async {
        guard !hasStartedLoading else { return }
        hasStartedLoading = true
        phase = .loading
        let result = await Task.detached(priority: .userInitiated) {
            Result { try HistoricalStatisticsPreparer.prepareFullModel(loader: .init()) }
        }.value
        switch result {
        case .success(let model): phase = .ready(model)
        case .failure(let error): phase = .failure(error)
        }
    }

    /// Kaldes fra AddHandView.onSaved — opdaterer kun live-laget
    func gameWasSaved(_ gameDays: [GameDay]) {
        guard case .ready(var model) = phase else { return }
        model.live = LiveStatisticsLayer(from: gameDays, players: model.historicalData.players)
        phase = .ready(model)
    }
}
```

---

## 4. Destinations-views: ingen engine-kald (løser H1)

Alle NavigationLink-destinations modtager forudberegnede værdier fra `FullModel`:

```swift
// FØR (synkron beregning ved hvert tap):
private func playersOverviewView(_ data: HistoricalWhistData) -> some View {
    let profiles = HistoricalStatisticsEngine.playerProfiles(from: data)  // ← hang
    let summaries = HistoricalStatisticsEngine.playerScoreSummaries(from: data) // ← hang
    ...
}

// EFTER (ingen beregning — O(1) lookup):
private func playersOverviewView(_ model: HistoricalStatisticsFullModel) -> some View {
    let profiles = model.playerProfiles
    let summaries = model.playerSummaries
    ...
}
```

Samme mønster for `allSessionsView`, `gameTypesOverviewView`, `trendsOverviewView`, `dataQualityView`.

---

## 5. Live-spil-integration

### 5.1 Mapping: `RecordedHand` → `LiveGame`

Live-spil konverteres til en letvægts-struct der er kompatibel med statistik-motoren:

```swift
struct LiveGame: Equatable, Sendable {
    var id: String          // hand.id.uuidString
    var sessionId: String   // gameDay.id.uuidString
    var gameNumber: Int     // hand.handNumber
    var playedAt: Date      // hand.playedAt
    var kindRaw: String     // "normal" | "sol" | "duty"
    var scores: [String: Int]  // playerId → score (via seat → playerDisplayName mapping)
    var bidderPlayerId: String?  // fra bidderSeatRaw
    var partnerPlayerId: String? // fra partnerSeatRaw
}
```

**Mapping af seat → player id** er triviel og pålidelig:

```swift
extension Seat {
    // Matcher HistoricalPlayer.id i whist_historical_data_v3.json
    var historicalPlayerId: String { playerDisplayName }
    // North=Christian, East=Peter, South=Thomas, West=Janus
}
```

### 5.2 Hvad kan mappes fra `RecordedHand`

| `HistoricalGame`-felt | Fra `RecordedHand` | Pålidelighed |
|----------------------|--------------------|--------------|
| `id` | `hand.id.uuidString` | ✓ Altid |
| `sessionId` | `hand.gameDay?.id.uuidString` | ✓ Altid |
| `gameNumberInSession` | `hand.handNumber` | ✓ Altid |
| `playedAt` / dato | `hand.playedAt` | ✓ Altid |
| Scores pr. spiller | `hand.scoresBySeatJSON` → seat → playerId | ✓ Altid |
| `bidderId` | `hand.bidderSeatRaw` → `.historicalPlayerId` | ✓ Når sat (-1 = sol/duty) |
| `partnerId` | `hand.partnerSeatRaw` → `.historicalPlayerId` | ✓ Når sat |
| Overordnet spiltype | `hand.kindRaw` ("normal"/"sol"/"duty") | ✓ Altid |
| **`gameTypeNormalized`** | **Ikke gemt explicit** | ⚠️ Kun fra `resumeCaption`-parsing |
| **`bidTricks`** | **Ikke gemt explicit** | ⚠️ Kun fra `resumeCaption`-parsing |

### 5.3 Designbegrænsning og anbefalet løsning

`RecordedHand` gemmer ikke `normalSubtype` (alm/sans/halve/gode/vip) eller `bidTricks` som egne felter — kun `kindRaw` og `resumeCaption` som fritekst.

**Anbefalet løsning:** Tilføj to nye felter til `RecordedHand` (SwiftData-migration):

```swift
@Model final class RecordedHand {
    // ... eksisterende felter ...

    /// Fx "alm", "sans", "gode", "halve", "vip", "sol", "duty"
    /// Til live-integration i statistik og fremtidig filtering
    var gameTypeNormalized: String = ""

    /// Meldt antal stik (kun relevant for normale spil)
    var bidTricksCount: Int = 0
}
```

Udfyldes ved gem i `AddHandView` (fra `draft.normalSubtype.rawValue` og `draft.bidTricks`). Ældre `RecordedHand`-rækker beholder `""` og `0` — motoren håndterer dette som «ukendt type» (samme som i JSON).

Dette er **ikke** et krav for at påbegynde live-integrationen (scores alene er nok til stilling og tidslinje), men giver fuld spiltype-statistik for live-spil.

### 5.4 Trigger: `onSaved` i `AddHandView`

```swift
// I ContentView:
AddHandView(
    gameDay: day,
    onSaved: { _, _ in
        statisticsStore.gameWasSaved(gameDays)
    }
)
```

`gameWasSaved` kører kun `LiveStatisticsLayer(from:)` — ingen genberegning af de frossede historiske stats. Koster microsekunder.

### 5.5 `LiveStatisticsLayer` — beregning ved nyt spil

```swift
extension LiveStatisticsLayer {
    init(from gameDays: [GameDay], players: [HistoricalPlayer]) {
        // Find aktiv spilledag (gameDays er allerede @Query-sorteret)
        guard let activeDay = GameDay.activeDay(in: gameDays) else {
            self = LiveStatisticsLayer(); return
        }

        // Konvertér hænder til LiveGame
        liveGames = activeDay.hands.map { LiveGame(from: $0, gameDay: activeDay) }

        // Byg current-session overview (billig operation: kun få spil)
        currentSessionOverview = buildCurrentSessionOverview(
            from: activeDay,
            players: players
        )

        // Tidslinje-punkter (én point pr. spiller pr. spil)
        extraTimelinePoints = buildTimelinePoints(from: activeDay, players: players)
    }
}
```

---

## 6. Implementeringsplan til Codex

### Fase 1 — Precompute alt (løser hang H1, ingen live-integration endnu)

**Opgave 1.1:** Opret `HistoricalStatisticsFullModel` i `HistoricalStatisticsPreparer.swift`  
- Tilføj alle frossede felter  
- Tilføj `snapshotsByScope: [ScopeCacheKey: HistoricalStatisticsSnapshot]`  
- Behold `live: LiveStatisticsLayer = LiveStatisticsLayer()` (tom til fase 2)

**Opgave 1.2:** Udvid `prepareHubModel` til `prepareFullModel`  
- Kald alle engine-funktioner i ét baggrundskald  
- Pregen af alle scope-kombinationer (6 limits × 3 scopes = 18 snapshots)

**Opgave 1.3:** Opdater `HistoricalStatisticsStore`  
- Skift `HistoricalStatisticsHubModel` → `HistoricalStatisticsFullModel`  
- Tilføj `gameWasSaved(_:)` method (stub der opdaterer live-lag)

**Opgave 1.4:** Opdater alle destinations i `StatistikTabView`  
- `allSessionsView` modtager `model.allSessionOverviews` + `model.playerSessionScores`  
- `playersOverviewView` modtager `model.playerProfiles` + `model.playerSummaries`  
- `gameTypesOverviewView` modtager `model.gameTypeOverviews` + de fire distributions  
- `trendsOverviewView` modtager `model.snapshotsByScope[key]` + `model.trendSummaries`  
- `dataQualityView` modtager `model.allSnapshot`  
- **Ingen** engine-kald i nogen destination — kun modeldata

**Forventet effekt:** Alle hangs ved Navigation-taps i Statistik elimineres. Destinations åbner øjeblikkeligt.

### Fase 2 — Live-spil-integration

**Opgave 2.1:** Opret `LiveGame` struct og `LiveStatisticsLayer` i ny fil `LiveStatisticsLayer.swift`  
- `LiveGame.init(from: RecordedHand, gameDay: GameDay)`  
- `LiveStatisticsLayer.init(from: [GameDay], players: [HistoricalPlayer])`

**Opgave 2.2:** Tilføj `gameWasSaved` i `HistoricalStatisticsStore`  
- Kald `LiveStatisticsLayer(from: gameDays, players:)` — let beregning, kører på main  
- `phase = .ready(updatedModel)` → `StatistikTabView` opdateres automatisk

**Opgave 2.3:** Kobl `onSaved` i `ContentView` → `statisticsStore.gameWasSaved(gameDays)`  

**Opgave 2.4 (valgfri, forbedrer spiltype-stats):** Udvid `RecordedHand` med `gameTypeNormalized: String` og `bidTricksCount: Int`  
- SwiftData migration (tilføj felter med default-værdier — ingen migration-plan kræves ved additive felter)  
- Udfyld ved gem i `AddHandView.save()` fra `draft.normalSubtype` og `draft.bidTricks`

**Opgave 2.5:** Vis live-spil i `currentDayView`  
- `model.currentOverview` returnerer live-override hvis sat, ellers JSON's last session  
- Tidslinje vises med `model.allSnapshot.timelinePoints + model.live.extraTimelinePoints`

### Fase 3 — Øvrige hangs (se hang-og-crash-rapport.md)

- H2: ZStack-faner i `ContentView`  
- H3: Cache `latestPair` i `SenesteSpilView`  
- H4: Guard migration mod unødvendig `save()`

---

## 7. Hvad der IKKE skal ændres

- `HistoricalStatisticsEngine` — motoren er korrekt; ændres ikke
- `HistoricalDataJSONLoader` — uændret
- `HandDraftPersistence` / meldingsflow — uberørt af statistik-arkitektur
- JSON-filen — er statisk; ingen auto-reload logik

---

## 8. Invarianter Codex skal respektere

1. **`HistoricalStatisticsStore.loadIfNeeded()` kaldes kun én gang** (via `hasStartedLoading`-flag). Ingen reload ved faneskift.
2. **Frossede stats må aldrig genberegnes** efter initial load — de er immutable `let`-felter.
3. **Live-lag er additiv** — skriv aldrig tilbage til `historicalData` eller frossede felter.
4. **`StatistikTabView`-body og alle destinations må ikke kalde engine-funktioner** — kun læse fra model.
5. **`gameWasSaved` kører på `@MainActor`** — ingen async/await nødvendig; beregningen er triviel.
6. **Player id-mapping:** `Seat.historicalPlayerId == Seat.playerDisplayName` — afhænger af at JSON-spillere hedder "Christian", "Peter", "Thomas", "Janus". Verificér ved unit-test.

---

## 9. Acceptkriterier

- [ ] Alle NavigationLink-destinations i Statistik åbner uden mærkbar forsinkelse (< 50 ms)
- [ ] `HistoricalStatisticsEngine` kaldes nul gange fra SwiftUI-body eller destinations-view-kroppe
- [ ] Nyt gemt spil afspejles i `currentDayView` / stilling uden genindlæsning af JSON
- [ ] Historiske sessions-data forbliver uændret ved gem af nyt spil
- [ ] `HistoricalStatisticsEngineTests` og live-mapping-tests er grønne i CI

---

*Rapport baseret på kodegennemgang 2026-05-29. Repo: `janusmoos/whist2`, branch `codex/performance-refactor-plan`.*
