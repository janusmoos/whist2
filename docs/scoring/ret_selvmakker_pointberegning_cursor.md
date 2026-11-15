# Cursor-opgave: Ret pointberegning for selvmakker i Whist 2.0

## Formål

Ret **udelukkende** pointfordelingen ved normale kontraktspil, hvor `partner == declarer` (selvmakker), så alle scores er heltal uden afrunding, og spillet er nulsum. Undersøg først den faktiske implementering, og bevar eksisterende regler for beregning af kontraktens pointværdi.

## Kilde og afgrænsning

Dette oplæg bygger på dokumentet `pointberegning.md` (opdateret 14. november 2026), ikke på en direkte gennemlæsning af repositoryets Swift-kode. Kontrollér derfor funktionsnavne, typer, fortegnsregler og kontrolflow i de faktiske filer, før der ændres kode.

- Pointmotor: `Whist20/Domain/ScoringEngine.swift`, navnlig `selfPartnerScores`, `standardPartnershipScores` og `scoreNormalHand`.
- Input/visning/gem: `Whist20/Features/AddHandView.swift` (`HandInputDraft.finalScores()`).
- Tests: `Whist20Tests/ScoringEngineTests.swift`.
- Gemte deltas: `RecordedHand.scoresBySeatJSON` og efterfølgende `GameDayScoreAggregation`.

## Problemet

For almindelige makkerkontrakter er den beregnede kontraktpointværdi `P` **point pr. spiller på kontraktholdet**:

- Melder: `+P`
- Makker: `+P`
- To modspillere: `−P` hver

Når melderen er selvmakker, angiver den nuværende beskrivelse denne særregel:

1. Beregn `2 * P`.
2. Afrund beløbet **væk fra nul** til nærmeste multiplum af 3 (opad for positive tal, nedad for negative).
3. Giv det afrundede beløb til melderen og det modsatte beløb delt i tre til hver modspiller.

Dermed bliver resultaterne afhængige af en vilkårlig afrunding. Pointværdier som `P = 4` giver fx `2P = 8`, som afrundes til 9: melderen får `+9`, mens hver modspiller betaler `−3`. Det er nulsum, men det svarer ikke til, at **hver af de tre modspillere betaler den fulde pointværdi `P`**.

### Ønsket regel for selvmakker

Der er én melder og tre modspillere. **Hver modspiller betaler `P` direkte til melderen** ved vundet kontrakt, eller modtager `|P|` fra melderen ved tabt kontrakt.

```text
melder          =  3 * P
modspiller 1    = -P
modspiller 2    = -P
modspiller 3    = -P
```

`P` er den **fortegnsbestemte** kontraktpointværdi fra den eksisterende motor: positiv ved holdt kontrakt, negativ ved tabt kontrakt. Der er derfor ikke behov for en særskilt gren for tabte kontrakter. Brug heltalsaritmetik; **ingen `ceil`, `floor`, `round` eller division med 3**.

### Konkrete regressionseksempler

| P | Eksisterende afrundingsmetode (melder / hver modspiller) | Ønsket (melder / hver modspiller) |
|---:|---:|---:|
| +1 | +3 / −1 | +3 / −1 |
| +2 | +6 / −2 | +6 / −2 |
| +4 | +9 / −3 | **+12 / −4** |
| +8 | +18 / −6 | **+24 / −8** |
| +16 | +33 / −11 | **+48 / −16** |
| −4 | −9 / +3 | **−12 / +4** |
| −8 | −18 / +6 | **−24 / +8** |

Bemærk: For `P = 1` og `P = 2` giver den gamle formel tilfældigvis samme resultat som den ønskede. En test kun for *almindelige 8 præcis* (`P = 2`) kan derfor ikke afsløre fejlen.

## Implementeringsopgave i Cursor

1. **Find den faktiske selvmakkergren** i `ScoringEngine.swift`, og dokumentér kort, hvor afrundingen sker. Tjek, om der findes andre kald, helpers eller kopier af selvmakkerfordelingen.
2. **Udskift alene fordelingen** med `3 * P` til melderen og `-P` til de tre øvrige pladser. Respektér de eksisterende `Seat`-typer og returtyper; undlad at indføre en ny parallelt implementeret pointmotor.
3. **Lad `calculateBasePoints` og øvrige regler være uændrede**: grundpoint efter melding, spiltype-multiplikatorer, vundet/tabt kontrakt, storslem og VIP 3. med klør. Bevar normal makker-, sol- og duestraflogik.
4. **Fjern forældet afrundingskode og kommentarer**, hvis de alene bruges til selvmakker. Opdatér evt. hjælpetekster, hvis brugerfladen beskriver den gamle regel.
5. **Tilføj tests** efter planen nedenfor, og kør den relevante test-suite. Kontrollér også, at samme resultater vises i preview og gemmes i `scoresBySeatJSON`.
6. **Rapportér konkrete ændrede filer og testresultater**. Skeln mellem nyberegnede spil og allerede gemte resultater.

### Swift-pseudokode (tilpas til eksisterende API)

```swift
// points: Int — signed contract points for a single opponent transfer.
func selfPartnerScores(points: Int, declarer: Seat) -> [Seat: Int] {
    var scores: [Seat: Int] = [:]
    for seat in Seat.allCases {
        scores[seat] = seat == declarer ? 3 * points : -points
    }
    return scores
}
```

Ovenstående er **illustrativ pseudokode**: antagelser om `Seat.allCases`, signatur og returtype skal valideres i repositoryet.

## Testplan og acceptkriterier

Skriv tests via `scoreNormalHand` med realistiske inputs, ikke kun ved direkte kald til en intern helper. Supplér eventuelt med parameteriserede helper-tests.

- **Selvmakker, vundet:** mindst ét scenario med `P = +4` og ét med `P = +8` eller større. Forvent henholdsvis `(+12, −4, −4, −4)` og `(+24, −8, −8, −8)` med korrekt placering af melder.
- **Selvmakker, tabt:** mindst ét scenario med `P = −4`: forvent `(-12, +4, +4, +4)`.
- **Eksisterende eksempel:** almindelige 8, præcis 8 stik, selvmakker: `P = +2` → `(+6, −2, −2, −2)`.
- **Alle pladser:** kontrollér at fordelingen er uafhængig af, om melderen sidder Nord, Øst, Syd eller Vest.
- **Nulsum:** summen af alle fire scores skal være præcis `0` i hvert scenario.
- **Ingen afrunding:** for enhver heltalsværdi `P` skal melderens score være præcis `3*P` og hver modspillers præcis `-P`.
- **Ikke-regression:** almindelig makker (`+P,+P,-P,-P`), sol og duestraf skal give samme scores som før.
- **Særtilfælde:** verificér at storslem og VIP3+klør fortsat påvirker `P` før den nye fordeling, uden ekstra afrunding.

Testen skal konstruere de faktiske meldinger og stik, der giver den ønskede `P`, efter den eksisterende `calculateBasePoints`-formel. Undgå at hardcode en ubegrundet `P` som input til `scoreNormalHand`, hvis denne funktion selv udregner værdien.

## Eksisterende pointformel må ikke ændres

Ifølge kildedokumentet beregnes `P` således, med `B` som grundpoint, `M` som multiplikator og `diff = actual - bid`:

```text
Hvis diff >= 0: P = B * (diff + 2) * M
Hvis diff <  0: P = -B * abs(diff) * M
```

Efterfølgende ekstra multiplikatorer for storslem og VIP3+klør gælder stadig. Denne opgave ændrer **kun, hvordan den allerede beregnede `P` fordeles ved selvmakker**.

## Eksisterende historik: vigtig begrænsning

Ifølge `pointberegning.md` bliver scores beregnet én gang ved gem og lagret i `RecordedHand.scoresBySeatJSON`. `GameDayScoreAggregation`, web-visning og historikmoduler summerer eller læser gemte deltas og genberegner normalt ikke point. En kodeændring vil derfor **ikke automatisk rette tidligere gemte selvmakkerresultater**.

**Foretag ikke automatisk omskrivning af historiske data i denne opgave.** Hvis historik også skal korrigeres, så foreslå først en separat, sikker migrations-/auditplan med backup, identifikation af berørte spil, genberegning fra oprindelige inputs og efterkontrol af nulsum og totaler. Historiske importerede scores kan have andre oprindelser end den nuværende motor.

## Definition of done

- Den gamle `2 * P` + afrunding-til-multiplum-af-3-logik anvendes ikke længere ved selvmakker.
- Alle nye selvmakkerresultater følger nøjagtigt `(3P, -P, -P, -P)` med melder på den korrekte plads.
- Der bruges ingen afrunding eller floating-point til fordelingen.
- Nulsum er altid opfyldt.
- Alle relevante tests består; normal makker, sol og duestraf er uændret.
- Cursor leverer et kort resumé af kodeændringer, testkørsel og evt. uafklarede spørgsmål om historik.
