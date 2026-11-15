# Pointberegning i Whist 2.0

Dokument til gennemgang af pointlogik (fx med Claude).  
**Sidst opdateret:** 2026-11-14

## Sprog og stack

| Del | Sprog / framework |
|-----|-------------------|
| **iOS-app (Whist20)** — her beregnes point | **Swift** + **SwiftUI** |
| Web (live-overblik + statistik) | TypeScript / Next.js (React) |
| Historik-import / audit-scripts | Python |

**Facit for live point er Swift-motoren `ScoringEngine`.** Web og historik genberegner typisk ikke; de bruger gemte eller importerede deltas.

---

## 1. Hvordan det bør fungere (regelsæt)

Fire spillere (pladser: Nord / Øst / Syd / Vest). Hvert spil er **nulsum**: summen af de fire scores skal være 0.

Der er tre hovedtyper: normalt kontraktspil, sol og duestraf.

### A. Normalt kontraktspil (makker)

**Input:** spiltype, meldte stik (8–13), faktiske stik til kontraktholdet (0–13), melder, makker (eller selvmakker), evt. trumf.

**Grundpoint efter melding:**

| Melding | Grundpoint |
|--------|------------|
| 8 | 1 |
| 9 | 2 |
| 10 | 4 |
| 11 | 8 |
| 12 | 16 |
| 13 | 32 |

**Spiltype-multiplikator:**

| Type | × |
|------|---|
| Almindelige | 1 |
| Sans / Halve / Gode | 2 |
| VIP 1. | 2 |
| VIP 2. | 4 |
| VIP 3. | 8 |

Lad `diff = actual − bid`, `B` = grundpoint, `M` = multiplikator.

**Hvis kontrakten holdes** (`diff ≥ 0`):

```text
points = (B × (diff + 1) + B) × M
```

svarende til `B × (diff + 2) × M`.

Derefter ekstra:

- **Storslem vundet:** hvis `actual == 13` → ×2
- **VIP i tredje + klør som trumf:** → ×2 (legacy-paritet)

**Hvis kontrakten går ned** (`diff < 0`):

```text
points = −(B × |diff| × M)
```

- **Storslem tabt:** hvis `actual == 0` → ×2 (stadig negativt)

`points` (`P`) er beløbet **pr. spiller på kontraktholdet**.

**Fordeling (almindelig makker):**  
melder `+P`, makker `+P`, de to andre `−P` hver.

**Selvmakker** (`partner == melder`):  
Start fra “to kontraktsider” = `2P`. Afrund til nærmeste multiplum af 3 (ceil hvis positiv, floor hvis negativ). Melder får det afrundede beløb; hver af de tre andre får `−beløb / 3`.

Eksempel: almindelige 8 præcis → `P = 2` → `2P = 4` → afrundet 6 → melder +6, øvrige −2.

### B. Sol

| Sol | Max stik | Point pr. “modstander-enhed” (ppo) |
|-----|----------|-------------------------------------|
| Sol | ≤ 1 | 4 |
| Ren sol | ≤ 0 | 8 |
| Halv bordlægger | ≤ 0 | 16 |
| Bordlægger | ≤ 0 | 32 |

“Går med”-spillere + melder = kontraktsiden. Resten = modstandere.

For hver på kontraktsiden:

- stik ≤ max → `+ppo × antal_modstandere`
- ellers → `−ppo × antal_modstandere`

Hver modstander får sum over alle på kontraktsiden: `−ppo` hvis den spillers score > 0, ellers `+ppo`.

### C. Duestraf

Én spiller: **−72**. De tre andre: **+24** hver.

---

## 2. Hvordan det er lavet i koden

### Arkitektur (live spil)

```text
UI / kladde (AddHandView / HandInputDraft)
    → ScoringEngine.scoreNormalHand / scoreSolHand / dutyScores
    → HandScorePersistence.encodeScores → RecordedHand.scoresBySeatJSON
    → GameDay.scoreStanding via GameDayScoreAggregation (kumulativ sum)
    → Live sync / backup / UI læser de gemte deltas (genberegner ikke)
```

**Vigtigt:** Point beregnes **én gang ved gem**. Senere visning summerer kun gemte deltas. Der er **ingen** parallel `ScoringEngine` i web/TypeScript.

### Kernemotor: `ScoringEngine`

Fil: `Whist20/Domain/ScoringEngine.swift`

- `calculateBasePoints` — formlen ovenfor (inkl. storslem ×2 og VIP3+klør ×2)
- `standardPartnershipScores` / `selfPartnerScores` — fordeling
- `scoreSolHand` — sol-loop (samme som legacy)
- `dutyScores` — −72 / +24

Kommentar i koden: paritet med `PointCalculationService` i Whist 0.6.

### Typer / multiplikatorer

Fil: `Whist20/Domain/WhistGameTypes.swift`

- `NormalGameType.baseMultiplier`
- `VipLevel.multiplier`
- `SolType.pointsPerOpponent` / `maxAllowedTricks`

### Indgang fra UI

Fil: `Whist20/Features/AddHandView.swift` (`HandInputDraft`)

- `resolvedNormalGameType()` — mappe alm/sans/halve/gode/vip
- `effectiveTrumpForScoring()`:
  - gode → altid klør
  - almindelige → valgt trumf
  - VIP / halve → trumf efter spil
  - sans → nil
- `finalScores()` kalder motoren; duestraf kan også være duty-toggle på normalt spil
- Ved gem: scores → JSON på `RecordedHand`

### Akkumulering

Fil: `Whist20/Domain/GameDayScoreAggregation.swift`

Sorterer hænder (`handNumber`, ellers `playedAt`) og summerer seat-scores til standing + steps. **Ingen** ny pointformel.

### Historik (vigtig forskel)

Historiske spil i JSON har **allerede** `playerResults[].score`.  
`HistoricalStatisticsEngine` / preparer **aggregerer** dem — de kalder **ikke** `ScoringEngine`.

`StatistikTabView` har en **lokal kopi** af kontraktformlen (`historicalContractScore`) kun til at **gætte** `actualTricks` ud fra gemt score. Den mangler typisk VIP3+klør-ekstra ×2 — kun til inference, ikke til at sætte point.

### Web

Viser/aggregerer gemte scores fra live payload / historisk data. **Ingen** pointmotor.

---

## 3. Filer og scripts (inventar)

### Beregner point (sandhed for nye spil)

| Fil | Rolle |
|-----|--------|
| `Whist20/Domain/ScoringEngine.swift` | **Primær pointmotor** |
| `Whist20/Domain/WhistGameTypes.swift` | Multiplikatorer, sol-ppo, max stik, VIP-niveauer |
| `Whist20/Domain/Seat.swift` | Fire pladser |

### Kalder motoren / bygger input

| Fil | Rolle |
|-----|--------|
| `Whist20/Features/AddHandView.swift` | `HandInputDraft.finalScores()`, preview, gem |
| `Whist20/Features/ScoringDemoView.swift` | Demo-scenarier til manuel check |

### Gemmer / summerer (ikke ny formel)

| Fil | Rolle |
|-----|--------|
| `Whist20/Persistence/RecordedHand.swift` | `scoresBySeatJSON`, `HandScorePersistence` |
| `Whist20/Domain/GameDayScoreAggregation.swift` | Kumulativ standing |
| `Whist20/Persistence/GameDay.swift` | `scoreStanding` |
| `Whist20/Persistence/HandDraftPersistence.swift` | Kladde inkl. VIP3+klør-flag |
| `Whist20/Services/LiveSessionSync.swift` | Sender gemte scores til web |
| `Whist20/Services/LocalGameBackupService.swift` | Backup af gemte scores |

### Tests

| Fil | Rolle |
|-----|--------|
| `Whist20Tests/ScoringEngineTests.swift` | Alm 8, Sans 9→10, selvmakker, due, sol |
| `Whist20Tests/GameDayScoreAggregationTests.swift` | Summering/orden |

### Historik / audit (importerede scores, ikke motor)

| Fil | Rolle |
|-----|--------|
| `Whist20/Domain/HistoricalStatisticsEngine.swift` | Statistik på gemte deltas |
| `Whist20/Domain/HistoricalStatisticsPreparer.swift` | Forberedelse af historik+live |
| `Whist20/Features/StatistikTabView.swift` | Parallel formel kun til stik-inference |
| `docs/statistik/tools/audit_score_consistency.py` | Audit af scorekonsistens |
| `docs/statistik/examples/v03/whist_import_v3.py` (+ audit-scripts) | Import af deltas fra Excel |
| `Whist20/Resources/HistoricalData/whist_historical_data_v3.json` | Bundt med færdige scores |

### Web (visning)

| Fil | Rolle |
|-----|--------|
| `web/lib/stats/*`, `web/components/*` | Viser/aggregerer — **ingen** `ScoringEngine`-ækvivalent |

---

## 4. Ting at tjekke ved gennemgang

1. **Win-formel:** `(B*(diff+1)+B)*M` = `B*(diff+2)*M` — bekræftet af test Sans 9 taget 10 → 12.
2. **Nedgang** bruger kun `B*|diff|*M` (ingen “+B”-term som ved holdt kontrakt).
3. **Storslem:** ×2 ved 13 (vundet) og ved 0 (tabt), efter type-multiplikator.
4. **VIP 3. + klør:** ekstra ×2 i motoren; trumf kommer fra `effectiveTrumpForScoring()`.
5. **Selvmakker-afrunding** til multiplum af 3 (ceil+/floor−).
6. **Sol:** hver “går med” scores individuelt; modstandere spejler pr. person.
7. **Duestraf** er fixed −72/+24, ikke afledt af stik.
8. **Historik ≠ motor:** forkerte historiske tal er datafejl, ikke nødvendigvis bug i `ScoringEngine`.
9. **Test-dækning er tynd:** få cases (ingen VIP3+klør, ingen storslem, ingen ren sol/bordlægger, ingen tabt kontrakt i unit tests).

---

## 5. Hurtige referenceeksempler (fra tests)

| Scenario | Resultat |
|----------|----------|
| Alm. 8 præcis, makker | +2 / +2 / −2 / −2 |
| Sans 9 taget 10 | +12 / +12 / −12 / −12 |
| Alm. 8 præcis, selvmakker | melder +6, øvrige −2 |
| Duestraf | −72 til én, +24 til de tre |
| Sol (normal), melder alene vinder (0 stik) | melder +12, øvrige −4 |
