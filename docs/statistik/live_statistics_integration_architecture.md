# Live-statistik integration

Dato: 2026-05-31  
Branch: `codex/live-statistics-integration`  
Status: Analyse- og arkitekturforslag for første integrationsfase.

## Formål

Statistikmodulet skal vise et samlet billede af:

- importerede historiske v3-data fra `whist_historical_data_v3.json`
- lokalt registrerede SwiftData-spil fra `GameDay` og `RecordedHand`
- uafsluttet lokal kladde fra `PendingHand`, hvor den giver mening som "i gang"-signal

Performance-refaktorens intention bevares: tunge historiske beregninger skal ske én gang i en preparer/store, og UI-destinationsviews skal ikke genberegne store statistikker ved navigation.

## Nuværende input

### Historisk JSON

Kæde:

1. `HistoricalDataJSONLoader`
2. `HistoricalStatisticsPreparer.prepareHubModel(loader:)`
3. `HistoricalStatisticsStore.loadIfNeeded()`
4. `StatistikTabView`

Den nuværende `HistoricalStatisticsHubModel` indeholder:

- `data: HistoricalWhistData`
- `allSnapshot: HistoricalStatisticsSnapshot`
- `currentOverview: HistoricalSessionOverview?`
- `gameTypeCount: Int`

Det betyder, at kun forsiden af statistikfanen reelt får precomputede værdier. Flere destinationsviews kalder stadig `HistoricalStatisticsEngine` eller lokale fordelingsfunktioner synkront, blandt andet:

- `sessionOverviews(from:)`
- `playerSessionScores(from:)`
- `playerProfiles(from:)`
- `playerScoreSummaries(from:)`
- `snapshot(from:scope:recentSessionLimit:)`
- `playerTrendSummaries(from:)`
- `gameTypeTrendSummaries(from:)`
- `HistoricalStatisticsPreparer.gameTypeOverviews(from:)`
- lokale distributioner i `StatistikTabView`

### SwiftData live/local

Kæde:

1. `ContentView` henter alle `GameDay` med `@Query`.
2. `AddHandView` opretter `RecordedHand`, sletter `PendingHand`, gemmer context og kalder `onSaved`.
3. `ContentView` navigerer til den aktive spilledag og viser evt. toast.
4. `StatistikTabView` modtager i dag ikke `gameDays`, og `HistoricalStatisticsStore` har ingen live-opdatering.

`GameDay` giver:

- `id`, `createdAt`, `title`, `notes`, `endedAt`
- `seatOrderJSON`
- `hands: [RecordedHand]`
- `pendingHand: PendingHand?`
- `scoreStanding`

`RecordedHand` giver:

- stabilt `id`
- `playedAt`, `handNumber`
- `kindRaw` (`normal`, `sol`, `duty`)
- `resumeCaption` og `summaryLine`
- `scoresBySeatJSON`
- `bidderSeatRaw`, `partnerSeatRaw`, `partnerAceSuitRaw`
- `solAlliesSeatsJSON`

`PendingHand` bør ikke tælle i resultater. Den kan kun bruges til UI-status, fx "aktiv spilledag har et uafsluttet spil".

## Vigtig mapping

Historisk statistik arbejder med `HistoricalPlayer.id`, mens live-data arbejder med `Seat`.

De faste seat-navne er:

| Seat | Live-navn |
|---|---|
| north | Christian |
| east | Peter |
| south | Thomas |
| west | Janus |

Der bør derfor indføres en lille mapping-funktion fra `Seat.playerDisplayName` til `HistoricalPlayer.id` via case-insensitive navn. Den må ikke antage, at `Seat.rawValue + 1 == HistoricalPlayer.displayOrder`, fordi display order i historisk data kan være et visningsvalg og ikke en seat-kontrakt.

## Foreslået målarkitektur

### 1. Udvid full model frem for at erstatte engine

Lav en samlet model oven på eksisterende historisk format:

```swift
struct HistoricalStatisticsFullModel {
    let frozen: FrozenHistoricalStatistics
    var combined: CombinedStatistics
    var liveStatus: LiveStatisticsStatus
}
```

`FrozenHistoricalStatistics` er ren JSON og bygges én gang:

- `data`
- `allSnapshot`
- `sessionOverviews`
- `playerSessionScores`
- `playerProfiles`
- `playerSummaries`
- `gameTypeOverviews`
- `trendSummaries`
- `gameTypeTrendSummaries`
- `streakSummary`
- scope-cache for `current`, `recent` og `all` med de kendte recent-limits
- de distributioner, der i dag ligger lokalt i `StatistikTabView`

`CombinedStatistics` er det aktuelle statistikgrundlag:

- `data: HistoricalWhistData`
- samme precomputede view-data som `FrozenHistoricalStatistics`, men beregnet på historik + live-spil
- `sourceSummary`, fx historiske sessions, live sessions, live hands

På kort sigt kan `CombinedStatistics` bygges ved at adaptere SwiftData til ekstra `HistoricalSession`, `HistoricalGame` og `HistoricalPlayerResult` og derefter genbruge `HistoricalStatisticsEngine`. Det holder risikoen lav, fordi UI og engine fortsætter med samme domænetyper.

### 2. Indfør adapter som separat domænelag

Ny type:

```swift
enum LiveHistoricalStatisticsAdapter {
    static func combinedData(
        historicalData: HistoricalWhistData,
        gameDays: [GameDay]
    ) -> LiveHistoricalStatisticsResult
}
```

Adapteren bør:

- ignorere `PendingHand` som resultatrække
- inkludere både aktive og afsluttede `GameDay`, så lokale registrerede dage ikke forsvinder fra "Alle"
- sortere `GameDay` kronologisk efter `createdAt` og hænder efter `handNumber`, fallback `playedAt`
- skabe session-id'er som `live-\(gameDay.id.uuidString.lowercased())`
- skabe game-id'er som `live-\(hand.id.uuidString.lowercased())`
- sætte `sourceSheetName` til fx `SwiftData`
- sætte `scoreSource` til fx `live_local`
- beregne `checksum` fra de fire live-scorer
- mappe bidder/partner/dealer via `Seat -> HistoricalPlayer`
- markere manglende mapping eller ikke-nulsum som quality flags

Første version bør være konservativ med metadata:

- `normal` kan mappe til `Almindelige` eller en subtype fra `resumeCaption`, hvis parseren er sikker.
- `sol` kan mappe til `Sol`.
- `duty` kan mappe til `Duestraf`.
- Hvis metadata ikke er sikker, skal scores stadig med i totals, sessions, timeline og spillerprofiler, mens spiltype-analyser kun tæller sikre typer.

### 3. Lad store eje kombinationen

`HistoricalStatisticsStore` bør have to opdateringsveje:

```swift
func loadIfNeeded(gameDays: [GameDay]) async
func gameDaysDidChange(_ gameDays: [GameDay])
```

`loadIfNeeded` bygger frozen JSON i baggrunden og kombinerer derefter med aktuelle `gameDays` på main actor. `gameDaysDidChange` genbruger frozen-modellen og reberegner kun combined-laget, når SwiftData ændrer sig.

Det kan først implementeres simpelt ved at reberegne combined view-data for alle lokale `GameDay`, fordi den lokale mængde er lille. Senere kan man optimere til inkrementelle opdateringer pr. saved hand, men det er ikke nødvendigt som første kodefase.

### 4. Gør UI afhængig af precomputede modeller

`StatistikTabView` bør modtage `gameDays` fra `ContentView`:

```swift
StatistikTabView(store: statisticsStore, gameDays: gameDays)
```

Viewet skal derefter bruge `model.combined` til standardvisningen. Det historiske rene snapshot kan stadig være tilgængeligt som datakvalitets- eller kildevisning, men ikke som standard total.

Destinationsviews bør ændres i små commits, så de modtager precomputede arrays i stedet for rå `HistoricalWhistData`, begyndende med:

1. "Alle spilledage"
2. "Spillere"
3. "Spiltyper"
4. "Tendenser"
5. "Datagrundlag"

## Anbefalet implementeringsrækkefølge

1. Flyt alle tunge eksisterende statistikberegninger fra `StatistikTabView` til `HistoricalStatisticsPreparer` uden live-data endnu.
2. Tilføj tests for full model, scope-cache og at UI-hjælpedata svarer til gamle engine-kald.
3. Tilføj `LiveHistoricalStatisticsAdapter` med unit tests for:
   - seat-navn til player-id
   - en live `GameDay` bliver til én session
   - scores summer korrekt
   - active og ended days inkluderes
   - `PendingHand` ikke tælles med
4. Lad store bygge `combined` ud fra frozen historik + live adapter.
5. Giv `StatistikTabView` `gameDays`, og skift statistikforsiden til combined data.
6. Flyt destinationsviews over på precomputede combined værdier.
7. Kør fuld test og build/launch på iPhone Xs simulator.

## Acceptkriterier for første kodefase

- Historiske tal er uændrede, når der ikke findes lokale `GameDay`.
- En lokal gemt hånd ændrer totals, aktuel spilledag, timeline og antal spil i statistikfanen.
- `PendingHand` ændrer ikke totals.
- Gamle branches bruges ikke som integrationskilde.
- Statistikfanen har færre eller ingen direkte engine-kald i navigation-destinations.
- iPhone Xs simulator build/test/launch er grøn efter kodeændringer.

