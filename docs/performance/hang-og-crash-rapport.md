# Hang- og crash-rapport — Whist20

**Dato:** 2026-05-29  
**Branch:** `codex/performance-refactor-plan`  
**Formål:** Komplet oversigt over identificerede hang- og crash-årsager. Klar til implementering i Codex.  
**Metode:** Statisk kodegennemgang af alle 39 Swift-filer i `Whist20/`.

---

## Oversigt

| # | Problem | Alvorlighed | Fil(er) |
|---|---------|-------------|---------|
| H1 | Statistik-destinations beregner synkront på main ved NavigationLink-tap | **Kritisk** | `StatistikTabView.swift` |
| H2 | Fane-skift genopretter views fra nul (`switch selectedTab`) | **Høj** | `ContentView.swift` |
| H3 | `latestPair` scanner alle dage/hænder i `body` | **Høj** | `SenesteSpilView.swift` |
| H4 | `migrateLegacyHandNumbersIfNeeded()` + `context.save()` i `onAppear` | **Høj** | 5 steder |
| H5 | `context.save()` på main thread ved autosave i melding | **Medium** | `HandDraftPersistence.swift` |
| H6 | Lokal backup-skrivning synkront ved «Gem» | **Medium** | `AddHandView.swift` |
| H7 | `scoreStanding` (O(hænder)) computed property genberegnes ved hvert body-hit | **Medium** | `GameDay.swift` |
| C1 | `fatalError` ved SwiftData-init — app-crash ved uforeneligt skema | **Høj** | `Whist20App.swift` |
| C2 | Force-unwrap `first!` på `applicationSupportDirectory` | **Lav** | `Whist20App.swift` |

Statistik-hubben og JSON-load er allerede løst med `HistoricalStatisticsStore` + `Task.detached`. Det er ikke gentaget her.

---

## H1 — Statistik-destinations: synkron beregning ved NavigationLink-tap (kritisk)

### Problem

Alle seks destination-views i statistikhubben kalder tunge engine-funktioner **direkte i `some View`-kroppen** — synkront på main thread, idet `NavigationStack` bygger destination-view'et:

| NavigationLink → destination | Synkron beregning ved tap |
|------------------------------|--------------------------|
| «Alle spilledage» | `sessionOverviews(from: data)` + `playerSessionScores(from: data)` → fuld `gameDetails` for alle 32 sessions |
| «Spillere» | `playerProfiles(from: data)` + `playerScoreSummaries(from: data)` → fuld `gameDetails` + session-scores |
| «Spiltyper» | `gameTypeOverviews(from:)` + 4× distributionfunktioner |
| «Tendenser» | `playerTrendSummaries(from:)` + `gameTypeTrendSummaries(from:)` + `snapshot(scope: selectedScope)` |
| «Datagrundlag» | `snapshot(from: data, scope: .all)` |

```swift
// StatistikTabView.swift linje 734–736
private func allSessionsView(_ data: HistoricalWhistData) -> some View {
    let overviews = HistoricalStatisticsEngine.sessionOverviews(from: data)        // ← main thread
    let playerSessionScores = HistoricalStatisticsEngine.playerSessionScores(from: data)  // ← main thread
```

```swift
// StatistikTabView.swift linje 1022–1024
private func playersOverviewView(_ data: HistoricalWhistData) -> some View {
    let profiles = HistoricalStatisticsEngine.playerProfiles(from: data)           // ← main thread
    let summaries = HistoricalStatisticsEngine.playerScoreSummaries(from: data)    // ← main thread
```

```swift
// StatistikTabView.swift linje 493–495
private func trendsContent(...) -> some View {
    let trends = HistoricalStatisticsEngine.playerTrendSummaries(from: data)       // ← main thread
    let gameTypeTrends = HistoricalStatisticsEngine.gameTypeTrendSummaries(from: data) // ← main thread
```

### Effekt på device

- Hang/freeze på 200 ms – 2+ sekunder afhængigt af funktion og enhed
- Watchdog-risiko ved «Alle spilledage» (fuld `sessionOverviews`)

### Løsning

**Mulighed A (anbefalet):** Udvid `HistoricalStatisticsHubModel` / `HistoricalStatisticsPreparer` med forudberegnede værdier for alle destinations og cache dem i `HistoricalStatisticsStore`. Alle destinations henter fra modellen — ingen beregning ved tap.

```swift
// I HistoricalStatisticsPreparer.prepareHubModel (kører i Task.detached):
struct HistoricalStatisticsHubModel {
    var data: HistoricalWhistData
    var allSnapshot: HistoricalStatisticsSnapshot
    var currentOverview: HistoricalSessionOverview?
    var gameTypeCount: Int
    // NYT:
    var allSessionOverviews: [HistoricalSessionOverview]
    var playerSessionScores: [String: [HistoricalPlayerSessionScore]]
    var playerProfiles: [HistoricalPlayerProfile]
    var playerSummaries: [HistoricalPlayerScoreSummary]
    var gameTypeOverviews: [HistoricalGameTypeOverview]
    var trendSummaries: [HistoricalPlayerTrendSummary]
    var gameTypeTrendSummaries: [HistoricalGameTypeTrendSummary]
    var bidTrickDistribution: [HistoricalBidTrickBucket]
    var solDistribution: [GameTypeSlice]
    var vipDistribution: [GameTypeSlice]
    var trumpDistribution: [GameTypeSlice]
}
```

Destinations modtager disse som parametre — ingen engine-kald.

**Mulighed B (hurtig gevinst):** Destination-views bruger `.task` + `@State` med loading-tilstand og kører engine-kald i `Task { await withCheckedContinuation { ... } }`.

---

## H2 — Fane-skift genopretter views fra nul (høj)

### Problem

`ContentView.body` bruger `switch selectedTab`, hvilket ødelægger og genopbygger hele view-hierarkiet ved hvert faneskift:

```swift
// ContentView.swift linje 31–45
switch selectedTab {
case .home:
    HomeView(navigationPath: $homeNavigationPath)
case .recentGames:
    NavigationStack { SenesteSpilView(...) }
case .activeGames:
    ActiveSpilTabView(openMeldingSheet: openMeldingSheet)
case .statistics:
    StatistikTabView(store: statisticsStore)
}
```

Hver gang brugeren skifter fane:
- `@Query` re-fetches fra SwiftData
- `@State` nulstilles (navigationStack m.m.)
- Layout og rendering starter forfra
- Statistik-store er korrekt cached, men de øvrige faner betaler cold-start

### Løsning

Brug `ZStack` med `.opacity` og `allowsHitTesting`, så alle faner forbliver i view-hierarkiet:

```swift
ZStack {
    HomeView(navigationPath: $homeNavigationPath)
        .opacity(selectedTab == .home ? 1 : 0)
        .allowsHitTesting(selectedTab == .home)

    NavigationStack { SenesteSpilView() }
        .opacity(selectedTab == .recentGames ? 1 : 0)
        .allowsHitTesting(selectedTab == .recentGames)

    ActiveSpilTabView(openMeldingSheet: openMeldingSheet)
        .opacity(selectedTab == .activeGames ? 1 : 0)
        .allowsHitTesting(selectedTab == .activeGames)

    StatistikTabView(store: statisticsStore)
        .opacity(selectedTab == .statistics ? 1 : 0)
        .allowsHitTesting(selectedTab == .statistics)
}
```

Alternativt: `.hidden()` / `TabView` med custom tab bar (Apple-anbefalet mønster).

**Bemærk:** `.task` på Statistik-view bør gennemgås — `loadIfNeeded()` kalder kun én gang (`hasStartedLoading`-flag), så det er allerede robust. Øvrige faner behøver blot at leve videre.

---

## H3 — `latestPair` scanner alle dage og hænder i `body` (høj)

### Problem

```swift
// SenesteSpilView.swift linje 21–35
private var latestPair: (gameDay: GameDay, hand: RecordedHand)? {
    var best: (GameDay, RecordedHand)?
    for day in gameDays {          // alle spilledage
        for hand in day.hands {    // alle hænder pr. dag
            ...
        }
    }
    return best
}
```

Dette er en computed property der evalueres ved **hver** `body`-render. `gameDays` er et SwiftData `@Query`-resultat — adgang til `day.hands` udløser lazy-loading af relationships fra SQLite for hvert element i løkken. Jo flere spilledage og hænder, desto tungere.

`latestPair` kaldes to steder i `body` (linje 54 og 99), og `handsNewestFirst` sorterer igen relationshipdata synkront.

Derudover: `onAppear` kalder `migrateLegacyHandNumbersIfNeeded()` + `context.save()` — se H4.

### Løsning

```swift
// Erstat computed property med @State + onChange:
@State private var latestPair: (gameDay: GameDay, hand: RecordedHand)?

// I .task / .onChange(of: gameDays):
private func refreshLatestPair() {
    // Én gang; kan isoleres til baggrund hvis det vokser
    latestPair = gameDays.lazy
        .flatMap { day in day.hands.map { (day, $0) } }
        .max { $0.1.playedAt < $1.1.playedAt }
}
```

Alternativt: brug en dedikeret `@Query` med `fetchLimit: 1` og sort på `playedAt`.

---

## H4 — `migrateLegacyHandNumbersIfNeeded()` + `context.save()` i `onAppear` (høj)

### Problem

Migration og disk-save kører synkront i `onAppear` på main thread på **5 steder**:

| Fil | Linje |
|-----|-------|
| `SenesteSpilView.swift` | 100–101 |
| `GameDayStartView.swift` | 69–70 og 406–407 |
| `PointStandingView.swift` | 83–84 |
| `HandDetailView.swift` | 65–66 |

```swift
// SenesteSpilView.swift linje 98–103
.onAppear {
    if let day = latestPair?.gameDay {
        day.migrateLegacyHandNumbersIfNeeded()
        try? modelContext.save()          // ← synkron disk-skrivning
    }
}
```

`migrateLegacyHandNumbersIfNeeded()` sorterer og tildeler numre til alle hænder (`hands.sorted { ... }`) — `hands` er en SwiftData-relationship der lazy-loades. `context.save()` skriver til SQLite synkront.

Disse views åbnes ved navigation og faneskift — hvert «klik» kan udløse en synkron disk-skrivning.

### Løsning

Migrationen er i praksis en engangsoperation (`guard hands.contains(where: { $0.handNumber < 1 })`). Når data er migreret, er kaldet hurtigt. Men `context.save()` er unødvendig hver gang:

```swift
.onAppear {
    guard let day = latestPair?.gameDay else { return }
    guard day.hands.contains(where: { $0.handNumber < 1 }) else { return }
    day.migrateLegacyHandNumbersIfNeeded()
    try? modelContext.save()   // kun hvis faktisk migration skete
}
```

Bedre langsigt: flyt migration til en post-launch `Task` én gang i app-lifecycle (fx efter `GameDayEndedAtMigration.runIfNeeded`), og fjern alle `onAppear`-kald.

---

## H5 — `context.save()` på main thread i melding-autosave (medium)

### Problem

```swift
// HandDraftPersistence.swift linje 127
try? context.save()
```

Kaldes fra `ResultStepView` via:
- `onAppear` (umiddelbart ved trin-skift)
- `scheduleResultAutosave()` med 1 sekunds debounce (forbedret fra 500 ms tidligere)
- `onDisappear` → `persistResultDraftIfNeeded`

Autosave er allerede markant forbedret (debounce øget til 1 s, `scheduleSync: false` ved tick). Resterende risiko: `onAppear` og `onDisappear` sker altid synkront på main.

### Løsning (kort sigt)

`onAppear`-save er nødvendig for crash-recovery. Kan ikke nemt flyttes til baggrund uden `@ModelActor`. Sikr at `guard existing.draftJSON != json` tjekket (allerede implementeret) forhindrer unødvendig disk-skrivning.

**Mellemlang sigt:** `@ModelActor actor PendingHandStore` der ejer pending-kladde-konteksten. Main thread sender kun `PersistentIdentifier` + JSON-streng.

---

## H6 — Lokal backup-skrivning synkront ved «Gem» (medium)

### Problem

```swift
// AddHandView.swift linje 1126
let backupMessage = AddHandLocalBackupNotice.message(afterWritingBackupFor: gameDay)
```

`AddHandLocalBackupNotice.message` kalder `LocalGameBackupService.writeBackup(for:)` synkront — fil-I/O (JSON-encode + skriv til disk) på main thread som del af gem-flowet.

### Løsning

```swift
// Flyt til Task efter dismiss:
onSaved?(gameDay.id, "")  // dismiss med det samme
Task.detached(priority: .utility) {
    let msg = AddHandLocalBackupNotice.message(afterWritingBackupFor: gameDay)
    await MainActor.run { /* vis toast hvis nødvendigt */ }
}
```

Eller: kald backup-skrivning asynkront og vis besked efterfølgende via `onSaved`-callback.

---

## H7 — `scoreStanding` genberegnes ved hvert body-hit (medium)

### Problem

```swift
// GameDay.swift linje 63–65
var scoreStanding: GameDayStanding {
    GameDayScoreAggregation.standing(from: hands.map(\.scoreContribution))
}
```

`scoreStanding` er en computed property. Den bruges i `SenesteSpilDaySummarySection` og andre views direkte fra `gameDay`. Hvert body-hit der sender `gameDay` ned ad view-hierarkiet kan udløse en ny sortering og akkumulering af alle hænder.

For få hænder (< 30) er dette ubetydeligt, men ved mange kampe og hyppige invalidationer (SwiftData-ændringer) kan det mærkes.

### Løsning (lav prioritet)

Cache i view der bruger det:
```swift
@State private var standing: GameDayStanding = .empty
.onChange(of: gameDay.hands.count) { standing = gameDay.scoreStanding }
.onAppear { standing = gameDay.scoreStanding }
```

Eller marker `scoreStanding` med `@Transient` / `nonisolated` og undgå gentagne kald i body.

---

## C1 — `fatalError` ved SwiftData-init (høj)

### Problem

```swift
// Whist20App.swift linje 45
fatalError("Kunne ikke starte SwiftData: \(error)")
```

Sker kun hvis skema er uforeneligt med eksisterende store **efter** at appen allerede har slettet og forsøgt igen. I praksis sjælden på produktionsenheder, men det er en **urecoverbar crash** ved launch.

### Løsning

I stedet for `fatalError`: vis en fejlskærm med instruktioner til at slette appen og geninstallere, eller tilbyd at nulstille lokale data:

```swift
} catch {
    // Gem fejlen; vis fejlUI i WindowGroup
    self.startupError = error
}
```

---

## C2 — Force-unwrap på `applicationSupportDirectory` (lav)

### Problem

```swift
// Whist20App.swift linje 15
let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
```

`first!` crasher hvis `applicationSupportDirectory` ikke returnerer nogen URLs — ekstremt usandsynligt på iOS, men teknisk set en crash-risiko.

### Løsning

```swift
guard let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
    // fallback til temporaryDirectory eller log fejl
    return URL.temporaryDirectory.appendingPathComponent("Whist20")
}
```

---

## Anbefalet implementeringsrækkefølge for Codex

| Prioritet | Problem | Forventet effekt |
|-----------|---------|-----------------|
| 1 | **H1** — Precompute alle Statistik-destinations i `HistoricalStatisticsHubModel` | Eliminerer hang ved alle navigations-taps i Statistik |
| 2 | **H2** — ZStack-faner i `ContentView` | Eliminerer cold-start-hang ved faneskift |
| 3 | **H3** — Cache `latestPair` i `@State` | Eliminerer body-scanning i Seneste spil |
| 4 | **H4** — Guard migration mod unødvendig `save()` | Reducerer disk-I/O ved navigation |
| 5 | **H6** — Backup-skrivning off main | Hurtigere gem-afslutning |
| 6 | **H5** — `@ModelActor` for pending (mellemlang sigt) | Fjerner save fra main |
| 7 | **C1** — Erstat `fatalError` med fejl-UI | Bedre brugeroplevelse ved skema-fejl |
| 8 | **H7** + **C2** | Kosmetiske forbedringer |

---

## Verifikation

- **Instruments → Hangs** på fysisk iPhone: reproducér faneskift og Statistik-navigation.
- **Instruments → Time Profiler**: main thread under NavigationLink-tap til «Alle spilledage».
- Debug-log fra `AddHandPerfTrace` (allerede instrumenteret i AddHandView): afslør save-tider.
- Acceptkriterier: ingen hang > 200 ms ved tap, ingen `0x8badf00d` i crashlog.

---

*Rapport baseret på kodegennemgang 2026-05-29. Repo: `janusmoos/whist2`, branch `codex/performance-refactor-plan`.*
