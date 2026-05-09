# Codex-overdragelse: Whist historikimport v2

## Formål

Dette arbejde handler om at gøre det gamle Whist-regneark brugbart som datagrundlag for en iOS/iPadOS-app.

Målet er ikke at kopiere regnearket direkte ind i appen, men at oversætte det til en normaliseret datastruktur, som appen let kan bruge til statistik.

Det vigtigste princip er:

> Regnearket er importkilde. Appens database skal være den reelle strukturerede datakilde.

## Uploadet originalfil

Originalfilen var:

`Whist – resultater – samlet (2024)_AKTIV_forenkling af data.xlsx`

Filen indeholder 47 faner. De består af:

- individuelle spilledage
- samleark
- statistikark
- testark
- cache/skabelonark
- dublet-/kladdeark

## Overordnet analyse

Regnearket indeholder meget værdifulde historiske data, men strukturen er ikke ens på tværs af alle faner.

De vigtigste observationer:

1. De enkelte spilledagsfaner er den bedste primære kilde til rådata.
2. `STATISTIK_*`, `SAMLET_*`, `TEST_*`, `Claude Cache` og `_skabelon` bør ikke importeres som sandhedsdata.
3. Mange gamle spil mangler metadata som spiltype, giver/dealer, melder/vinder eller makker.
4. Det er ikke en fejl, at data mangler. Datamodellen skal understøtte `null`/optional værdier.
5. Alle statistikker i appen bør vise, hvor mange spil de er baseret på.
6. Statistik bør beregnes dynamisk fra rådata, ikke gemmes permanent.

## Beslutning: primær sandhed

Primær sandhed:

- de enkelte spilledagsfaner

Reference/kontrol:

- `00_Regnskab_01`
- `SAMLET_alle regnskab`

Ikke primær data:

- `STATISTIK_*`
- `TEST_*`
- `SAMLET_til diagram`
- `d_udvikling`
- `d_#09_26012019`
- `Claude Cache`
- `_skabelon`

Dubletregler:

- Brug `22_31-09-2023_RETTET`, ikke `22b_31-09-2023`.
- Brug `26_30-11-2024`, ikke `_26_30-11-2024...` eller `_27_30-11-2024...`.

## Filer produceret

### 1. `whist_import_audit_v2.py`

Python-scriptet, der læser originalregnearket og producerer normaliseret output.

Scriptet gør blandt andet:

- åbner `.xlsx`-filen
- gennemgår relevante faner
- ignorerer statistik-, test- og cacheark
- identificerer spilledagsark
- finder header-rækker
- finder scorekolonner
- skelner mellem kumulative scoreblokke og delta-/spilscoreblokke
- udtrækker sessions
- udtrækker games
- udtrækker fire playerResults pr. spil
- normaliserer spiller-navne
- forsøger at finde spiltype, giver/dealer, melder/vinder og makker
- håndterer manglende metadata som `null`
- laver audit-issues
- eksporterer både separate JSON-filer og ét samlet app-klart JSON-datasæt

Scriptet er en prototype, men v2 er allerede brugbart som grundlag for appens første import.

### 2. `whist_import_v2_output.zip`

ZIP-fil med hele v2-outputpakken.

Indeholder:

- `IMPORT_V2_REPORT.md`
- `whist_historical_data_v2.json`
- `sessions.json`
- `games.json`
- `player_results.json`
- `import_audit.json`
- `issues_v2.csv`
- `issue_summary_v2.csv`
- `session_validation_v2.csv`

### 3. `IMPORT_V2_REPORT.md`

Markdown-rapport med overblik over import v2.

Vigtige tal:

- Sessions: 27
- Spil: 744
- PlayerResult-rækker: 2.976
- Issues: 46

Feltdækning:

- Spiltype: 469 ud af 744 spil
- Giver/dealer: 515 ud af 744 spil
- Melder/vinder: 532 ud af 744 spil
- Makker: 165 ud af 744 spil
- Score-sum = 0: 714 ud af 744 spil

Resterende issue-typer:

- `score_sum_not_zero`: 30
- `game_marker_without_scores`: 13
- `expected_vs_imported_count_mismatch`: 3

V2 forbedrede importen markant sammenlignet med v1:

- issues faldt fra 190 til 46
- `unknown_bidder_name` faldt fra 148 til 0
- makkerdata steg fra 0 til 165 spil
- melder/vinder steg fra 398 til 532 spil

### 4. `whist_historical_data_v2.json`

Den vigtigste fil for app-arbejdet.

Dette er det samlede app-klare historikdatasæt.

Top-level struktur:

```json
{
  "version": "2",
  "generatedAt": "...",
  "players": [],
  "sessions": [],
  "games": [],
  "playerResults": [],
  "auditSummary": {}
}
```

Denne fil bør bruges som første bundled importfil i Xcode.

### 5. `sessions.json`

Indeholder alle importerede spilledage.

Eksempel på session:

```json
{
  "id": "session_1_2016-06-21",
  "sessionNumber": "1",
  "date": "2016-06-21",
  "location": "Thomas, Vanløse",
  "sourceSheetName": "01_21-06-2016",
  "expectedGameCount": 24,
  "importedGameCount": 24,
  "missingScoreRows": 0,
  "qualityStatus": "ok",
  "cumulativeBlockStartColumn": 2,
  "deltaBlockStartColumn": 11,
  "preferredScoreBlockNumericRows": 24,
  "headerRow": 3,
  "columnMapping": {
    "game_type_col": 6,
    "bidder_col": null,
    "winner_col": null,
    "dealer_col": 7,
    "partner_col": null
  }
}
```

Vigtige felter:

- `id`: stabilt session-id
- `sessionNumber`: regnskabs-/spilledagsnummer, fx `1`, `12b`, `19a`
- `date`: dato, hvis kendt
- `location`: sted, hvis kendt
- `sourceSheetName`: oprindelig fane i regnearket
- `expectedGameCount`: forventet antal spil fra regnskabsoversigt, hvis fundet
- `importedGameCount`: antal spil faktisk importeret
- `qualityStatus`: `ok` eller warning-status
- `columnMapping`: hvilke kolonner parseren brugte

### 6. `games.json`

Indeholder alle importerede spil.

Eksempel på game:

```json
{
  "id": "session_1_2016-06-21_game_001",
  "sessionId": "session_1_2016-06-21",
  "sessionNumber": "1",
  "gameNumberInSession": 1,
  "sourceGameMarker": 1,
  "gameTypeRaw": null,
  "gameTypeNormalized": null,
  "bidTricks": null,
  "bidderId": null,
  "bidderIds": [],
  "winnerId": null,
  "winnerIds": [],
  "partnerId": null,
  "dealerId": null,
  "checksum": 0,
  "scoreSource": "delta_columns",
  "sourceSheetName": "01_21-06-2016",
  "sourceRow": 4,
  "qualityFlags": [
    "missing_game_type",
    "missing_bidder_or_winner",
    "missing_dealer",
    "missing_partner"
  ]
}
```

Vigtige felter:

- `id`: stabilt spil-id
- `sessionId`: relation til session
- `gameNumberInSession`: spilnummer indenfor spilledagen
- `gameTypeRaw`: rå tekst fra regnearket
- `gameTypeNormalized`: grov normaliseret spiltype, hvis fundet
- `bidTricks`: antal meldte stik, hvis parseren kan finde det
- `bidderId`: melder/vinder, hvis entydig
- `bidderIds`: liste ved flere spillere
- `winnerId`: vinder, hvis entydig
- `winnerIds`: liste ved flere spillere
- `partnerId`: makker, hvis registreret
- `dealerId`: giver/dealer, hvis registreret
- `checksum`: summen af fire spilleres score
- `scoreSource`: hvilken scoreblok der blev brugt
- `sourceSheetName`: oprindelig fane
- `sourceRow`: oprindelig række
- `qualityFlags`: advarsler for dette spil

Bemærk: `bidderId` og `winnerId` er ikke nødvendigvis konceptuelt perfekte endnu. I regnearket bruges felter som “Hvem”, “Vinder”, “Vindende melding” osv. forskelligt. Derfor bør appen i første omgang primært bruge disse som metadata, ikke som hård spilregel-logik.

### 7. `player_results.json`

Indeholder fire rækker pr. spil, én pr. spiller.

Eksempel:

```json
{
  "id": "session_1_2016-06-21_game_001_Thomas",
  "gameId": "session_1_2016-06-21_game_001",
  "playerId": "Thomas",
  "score": 8,
  "sourceSheetName": "01_21-06-2016",
  "sourceRow": 4
}
```

Dette er den vigtigste tabel for statistik.

Næsten alle pointbaserede statistikker kan beregnes ud fra `playerResults` kombineret med `games` og `sessions`.

### 8. `import_audit.json`

Indeholder importens auditinformation.

Bruges til at finde:

- mismatch mellem forventet og importeret antal spil
- score-rækker, hvor summen ikke er 0
- spilmarkører uden scores
- datakvalitetsproblemer

Denne fil bør ikke nødvendigvis importeres i appens brugerrettede database, men den er nyttig til udvikling, debug og datarensning.

### 9. `issues_v2.csv`

CSV-liste over konkrete issues.

Bruges til manuel kontrol.

Eksempler på issue-typer:

- `score_sum_not_zero`
- `game_marker_without_scores`
- `expected_vs_imported_count_mismatch`

### 10. `issue_summary_v2.csv`

CSV med optælling af issues pr. type.

### 11. `session_validation_v2.csv`

CSV med validering pr. session.

Bruges til hurtigt at se:

- forventet antal spil
- importeret antal spil
- antal manglende source-rækker
- status pr. spilledag

## Import v2-status

Importen er ikke perfekt, men den er god nok til at appen kan starte med historiske pointstatistikker.

### Solide områder

Disse kan bruges med høj tillid:

- sessions
- game-id'er
- playerResults
- pointscore pr. spiller
- totaler
- gennemsnit
- udvikling over tid
- chipleader over tid
- bedste/værste spil
- bedste/værste spilledag

### Delvist solide områder

Disse kan bruges, men bør vise datagrundlag/sample size:

- spiltype
- giver/dealer
- melder/vinder
- makker

### Ikke færdigt analyserede områder

Disse bør ikke bruges som hård logik endnu:

- fuld fortolkning af alle spiltype-varianter
- præcis sol/vip/halve/sang/storslem-regelberegning
- succesrate pr. melding baseret på kontraktlogik
- om `bidderId`, `winnerId` og `winnerIds` altid betyder det samme på tværs af alle faner

## Anbefalet CoreData-model

### Player

Felter:

- `id: String`
- `name: String`
- `displayOrder: Int16`
- `isActive: Bool`

Faste spillere:

- Thomas
- Peter
- Janus
- Christian

### Session

Felter:

- `id: String`
- `sessionNumber: String`
- `date: Date?`
- `location: String?`
- `sourceSheetName: String`
- `expectedGameCount: Int32`
- `importedGameCount: Int32`
- `qualityStatus: String`
- `createdAt: Date`
- `updatedAt: Date`

Relation:

- `games` → Game

### Game

Felter:

- `id: String`
- `gameNumberInSession: Int32`
- `sourceGameMarker: Int32`
- `gameTypeRaw: String?`
- `gameTypeNormalized: String?`
- `bidTricks: Int16`
- `bidderId: String?`
- `winnerId: String?`
- `partnerId: String?`
- `dealerId: String?`
- `checksum: Int32`
- `scoreSource: String`
- `sourceSheetName: String`
- `sourceRow: Int32`
- `qualityFlagsJSON: String?`

Relationer:

- `session` → Session
- `results` → PlayerResult

### PlayerResult

Felter:

- `id: String`
- `playerId: String`
- `score: Int32`
- `sourceSheetName: String`
- `sourceRow: Int32`

Relation:

- `game` → Game

### ImportVersion / ImportRun

Felter:

- `id: String`
- `version: String`
- `sourceFileName: String`
- `importedAt: Date`
- `dataHash: String?`
- `sessionsImported: Int32`
- `gamesImported: Int32`
- `playerResultsImported: Int32`

Bruges til at undgå dobbeltimport.

## Anbefalede Swift Codable-modeller

Start med rene Codable-modeller før CoreData.

```swift
struct WhistHistoricalData: Codable {
    let version: String
    let generatedAt: String
    let players: [ImportedPlayer]
    let sessions: [ImportedSession]
    let games: [ImportedGame]
    let playerResults: [ImportedPlayerResult]
    let auditSummary: AuditSummary?
}

struct ImportedPlayer: Codable {
    let id: String
    let name: String
    let displayOrder: Int
}

struct ImportedSession: Codable {
    let id: String
    let sessionNumber: String
    let date: String?
    let location: String?
    let sourceSheetName: String
    let expectedGameCount: Int?
    let importedGameCount: Int
    let missingScoreRows: Int
    let qualityStatus: String
}

struct ImportedGame: Codable {
    let id: String
    let sessionId: String
    let sessionNumber: String
    let gameNumberInSession: Int
    let sourceGameMarker: Int?
    let gameTypeRaw: String?
    let gameTypeNormalized: String?
    let bidTricks: Int?
    let bidderId: String?
    let bidderIds: [String]
    let winnerId: String?
    let winnerIds: [String]
    let partnerId: String?
    let dealerId: String?
    let checksum: Int?
    let scoreSource: String
    let sourceSheetName: String
    let sourceRow: Int
    let qualityFlags: [String]
}

struct ImportedPlayerResult: Codable {
    let id: String
    let gameId: String
    let playerId: String
    let score: Int
    let sourceSheetName: String
    let sourceRow: Int
}
```

Codex bør kontrollere den præcise JSON-struktur i `whist_historical_data_v2.json`, især `auditSummary`, før endelig Swift-kode genereres.

## Anbefalet næste udvikleropgave i Codex

### Opgave 1: Tilføj JSON-filen som bundled resource

Læg `whist_historical_data_v2.json` i Xcode-projektet.

Sørg for:

- filen er tilføjet til target membership
- filen kan findes via `Bundle.main.url(forResource:withExtension:)`

### Opgave 2: Lav JSON-loader

Lav fx:

```swift
final class HistoricalDataJSONLoader {
    func load() throws -> WhistHistoricalData
}
```

Loaderen skal:

1. finde `whist_historical_data_v2.json` i bundle
2. læse data
3. decode med `JSONDecoder`
4. returnere `WhistHistoricalData`

### Opgave 3: Lav CoreData-importer

Lav fx:

```swift
final class HistoricalDataImporter {
    func importIfNeeded(context: NSManagedObjectContext) throws
}
```

Den skal:

1. tjekke om importversion `2` allerede er importeret
2. oprette de fire faste spillere
3. oprette sessions
4. oprette games
5. oprette playerResults
6. gemme ImportVersion
7. undgå dubletter via stabile string IDs

### Opgave 4: Lav første statistikservice

Start simpelt.

Lav fx:

```swift
struct PlayerScoreSummary {
    let playerId: String
    let totalScore: Int
    let gamesPlayed: Int
    let averageScore: Double
}

final class StatisticsEngine {
    func playerScoreSummaries(context: NSManagedObjectContext) throws -> [PlayerScoreSummary]
}
```

Første statistik bør kun bruge `PlayerResult`.

Det er den mest robuste datakilde.

### Opgave 5: Lav første statistikskærm

Vis:

- spiller
- samlet score
- antal spil
- gennemsnit pr. spil

Dette er den rigtige første UI-test, fordi den beviser, at import, CoreData og statistik virker.

## Statistikprincipper

Alle statistikker bør returnere datagrundlag.

Eksempel:

```swift
struct StatisticResult<Value> {
    let value: Value?
    let sampleSize: Int
    let eligibleCount: Int
    let totalGames: Int
    let warnings: [String]
}
```

Eksempel i UI:

> Gennemsnit som giver: 4,7 point. Baseret på 83 spil med registreret giver ud af 744 spil.

Dette er vigtigt, fordi mange historiske spil mangler metadata.

## Vigtigt om manglende data

Manglende metadata er ikke nødvendigvis fejl.

Eksempler:

- gamle spil mangler ofte spiltype
- gamle spil mangler ofte melder/vinder
- nogle spil mangler giver
- makker findes kun i 165 af 744 spil

Derfor:

- brug optionals
- brug `qualityFlags`
- vis sample size i statistik
- undgå at opfinde værdier

## Første statistikker, der bør bygges

Disse er sikre at lave nu:

1. samlet score pr. spiller
2. antal spil pr. spiller
3. gennemsnit pr. spil
4. bedste enkeltspil pr. spiller
5. værste enkeltspil pr. spiller
6. scoreudvikling over tid
7. samlet stilling efter hver spilledag
8. chipleader over tid

Disse bør vente eller markeres med sample size:

1. statistik pr. spiltype
2. statistik som giver
3. statistik som melder/vinder
4. statistik med makker
5. succesrate pr. melding
6. solo vs makker

## Kendte resterende problemer i v2

### 1. `score_sum_not_zero` — 30 spil

Normalt bør summen af fire spilleres score være 0.

30 spil bryder dette.

Det kan skyldes:

- gamle regnskabsregler
- manuelle fejl
- parseren har valgt forkert scoreblok/række
- særlige spil med ikke-nulsum

Disse spil er importeret, men markeret i audit.

### 2. `game_marker_without_scores` — 13 tilfælde

Parseren fandt noget, der lignede en spilmarkør, men ikke fire gyldige scores.

Dette er især relevant i gamle eller rodede faner.

### 3. `expected_vs_imported_count_mismatch` — 3 sessions

Tre sessions har mismatch mellem forventet og importeret antal spil.

De er ikke nødvendigvis kritiske, da forventet antal fra oversigtsark ikke altid passer perfekt til delark/fortsættelser.

## Anbefalet prioritering

1. Brug v2 JSON til første CoreData-import.
2. Byg pointbaseret statistik først.
3. Lav UI for total/gennemsnit/udvikling.
4. Først derefter: arbejd videre med datarensning af de 46 issues.
5. Når pointstatistik virker: udbyg med spiltype, giver, makker og melder-statistik.

## Kort prompt til Codex

Brug denne prompt i Codex:

```text
Jeg bygger en Swift/iOS Whist-statistikapp. Jeg har en bundled JSON-fil `whist_historical_data_v2.json` med historiske data. Filen har top-level felterne `version`, `generatedAt`, `players`, `sessions`, `games`, `playerResults` og `auditSummary`.

Lav Swift Codable-modeller til JSON-filen, en `HistoricalDataJSONLoader`, og en `HistoricalDataImporter`, der importerer data til CoreData-entiteterne Player, Session, Game, PlayerResult og ImportVersion. Brug stabile String IDs til at undgå dubletter. Start med en simpel `StatisticsEngine`, der kan beregne samlet score, antal spil og gennemsnit pr. spiller ud fra PlayerResult.

Manglende metadata som gameType, dealer, bidder/winner og partner skal være optional. Statistikker skal senere kunne vise sample size, så bevar qualityFlags og sourceSheetName/sourceRow.
```

## Absolut vigtigste arkitekturbeslutning

Brug ikke Google Sheets-regnearket som appens primære database.

Brug det kun som importkilde.

Appen bør eje:

- den normaliserede datamodel
- relationerne
- statistiklogikken
- filtrering
- caching
- fremtidige spil

Det er den rigtige vej videre.
