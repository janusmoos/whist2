# Whist import v3 - beslutninger for ny historisk kilde

Oprettet: 2026-05-17

## Formål

Import v3 er et bevidst kildeskift for historisk statistik. v2/legacy bevares som immutable reference, mens v3 afprover den nye primare Excel-kilde og gor normalisering, audit og output reproducerbart for fremtidige builds.

## Primar sandhed og auditkilde

Primar sandhed for spil-for-spil-data:

- Workbook: `Whist – resultater – samlet (2024)_AKTIV_forenkling af data.xlsx`
- Lokal kilde ved oprettelse: `/Users/moos/Downloads/Whist – resultater – samlet (2024)_AKTIV_forenkling af data.xlsx`
- SHA256: `a6c126c81f743c9ad5da54af3ac18e312459cc44d02e01d7b656d3ccce446bfa`
- Ark: `SAMLET_alle regnskab_16-5-2026`

Audit/kontrolkilde:

- Ark: `00_Regnskab_01`
- Rolle: forventede sessionsmetadata, dato, sted, antal spil og regnskabstotaler.
- Begrænsning: arket må ikke overstyre feltværdier på spilrækker fra `SAMLET_alle regnskab_16-5-2026`.

## Legacy-bevaring

v2-kilden er legacy og må ikke ændres af v3-arbejdet:

- `docs/statistik/examples/v02/whist_historical_data_v2.json`
- `Whist20/Resources/HistoricalData/whist_historical_data_v2.json`
- `docs/statistik/examples/v02/whist_import_audit_v2.py`
- v2-rapporter og audit-output under `docs/statistik/examples/v02/`

Hvis en legacy-regression opdages under v3-arbejde, skal den logges som separat fund. v3-importen må ikke rette v2-output in place.

## Workbook-observationer fra read-only probe

Workbooken indeholder 56 faner. De to relevante ark findes.

`SAMLET_alle regnskab_16-5-2026`:

- Dimensioner: 755 rækker x 77 kolonner.
- Header-fingeraftryk for række 3: `81b3ab246b88c09f0d1b9ded92f1c3eec10fa612e3e76b3d6dd1f6f0bfcc4b77`.
- Række 1-2 indeholder gruppe-/formeloverskrifter.
- Række 3 er den stabile felt-header-række for v3.
- Række 4-10 repræsenterer session 1-7 som start-/slutstatus uden spilnummer.
- Række 11-755 indeholder 745 spilrækker.
- Spilrækker findes for 25 sessionsnøgler: `8`, `9`, `10`, `11`, `12a`, `12b`, `13` ... `31`.
- Score-sum for de fire delta-scorekolonner U-X er 0 på alle 745 observerede spilrækker.

`00_Regnskab_01`:

- Dimensioner: 48 rækker x 14 kolonner.
- Række 1-2 er header-/gruppeinformation.
- Række 3-35 indeholder sessionsmetadata for session `1` til `31` plus splittene `12a` og `12b`.
- Nederst findes en note om at samlet-arket kun indeholder spil fra runde/session 8.

## Kildeprioritet ved konflikt

1. Spilrækker, spillere, spiltype, melder, makker, giver, vinder og scores læses fra `SAMLET_alle regnskab_16-5-2026`.
2. Dato, sted, forventet antal spil og regnskabstotaler læses fra `00_Regnskab_01` til audit og sessionmetadata.
3. Hvis `00_Regnskab_01` og `SAMLET_alle regnskab_16-5-2026` er uenige, skal importeren logge en issue. Den må ikke lydløst blande felter.
4. Aggregerede statistikblokke i `SAMLET_alle regnskab_16-5-2026` importeres ikke som app-sandhed i første v3-pass. App-statistik beregnes fra normaliserede spil- og player-result-rækker.

Bekræftet datoregel 2026-05-17:

- `00_Regnskab_01` er sandhed for `session.date` og `session.location`.
- Datokolonnen i `SAMLET_alle regnskab_16-5-2026` bruges kun til audit.
- Hvis samlet-arkets dato afviger fra `00_Regnskab_01`, logges `date_mismatch`, men det overstyrer ikke sessionmetadata og ændrer ikke sessionens importstatus.

Bekræftet totalafstemningsregel 2026-05-17:

- Sluttotaler i `00_Regnskab_01` skal afstemmes mod sidste kumulative total pr. session i `SAMLET_alle regnskab_16-5-2026`.
- Hvis totalerne afviger, logges `control_total_mismatch`, medmindre afvigelsen er en dokumenteret fejl i kontrolarket.
- Kendt midlertidig kontrolarksfejl: session 27 har `Christian = -72` i `00_Regnskab_01`, men primærkilden har `Christian = -76`. Primærkilden er accepteret sandhed her, og audit logger `known_control_total_error` kun når netop denne gamle kontrolværdi optræder.
- Når næste workbook-revision har `Christian = -76` i `00_Regnskab_01`, skal undtagelsen ikke længere udløses; totalafstemningen skal da blive `ok`.

## Session 1-7

Den nye primære samlearkskilde har ikke spilrækker for session 1-7. v3 bruger derfor en kontrolleret hybridstrategi:

- Session 1-4 og 6-7 importeres fra de individuelle spilledagsfaner som `individual_sheet_limited_source`.
- Session 5 importeres ikke som games/playerResults, fordi fanen `05_22-09-2017_TOM` ikke indeholder regnskabsspil. Den bevares som `empty_source_sheet` i audit.
- Ingen syntetiske spil må genereres fra slutstatus-rækkerne i `SAMLET_alle regnskab_16-5-2026`.
- De individuelle faner for session 1-7 må levere scores/playerResults, men manglende metadata som melder, makker, giver og spiltype bliver `null`.
- Score-sum-afvigelser i session 1-4 er kendt historisk datakvalitet og skal bevares som audit issues, ikke automatisk korrigeres.

Bekræftet kildeafkodning 2026-05-17:

| Session | Fane | Status | Importerbare spil | Begrænsning |
|---:|---|---|---:|---|
| 1 | `01_21-06-2016` | `individual_sheet_limited_source` | 24 | Scores ja, metadata begrænset |
| 2 | `02_2492016` | `individual_sheet_limited_source` | 46 | Scores ja, metadata begrænset |
| 3 | `03_25-02-2017` | `individual_sheet_limited_source` | 22 | 13 markerede rækker mangler scoredata |
| 4 | `04_Måske Berlin` | `individual_sheet_limited_source` | 29 | Dato/sted usikkert, metadata begrænset |
| 5 | `05_22-09-2017_TOM` | `empty_source_sheet` | 0 | Ingen regnskabsspil i fanen |
| 6 | `06_23-09-2017` | `individual_sheet_limited_source` | 26 | Kun kumulative scores; deltas beregnes |
| 7 | `07_24-09-2017` | `individual_sheet_limited_source` | 11 | Kun kumulative scores; deltas beregnes |

Bekræftet session 3-regel 2026-05-17:

- Session 3 har kun 22 reelle spil, til og med række 25 i `03_25-02-2017`.
- Rækkerne efter række 25 ignoreres; de indeholder kun tomme scorefelter/formelrester og er ikke spil.
- `expectedGameCount = 23` fra `00_Regnskab_01` bevares som auditværdi, men overstyrer ikke importerede spil.
- Sidste reelle linje er: `22 54 234 148 -404 32 -32 66 32 -32`.

Bekræftet session 4-regel 2026-05-17:

- Session 4 har 29 reelle spil, til og med række 32 i `04_Måske Berlin`.
- `expectedGameCount = 30` fra `00_Regnskab_01` bevares som auditværdi, men overstyrer ikke importerede spil.
- Sidste reelle linje matcher slutscore i `00_Regnskab_01`: `29 -72 -256 138 186 -4 4 -4 -4 4`.
- Der genereres ikke et syntetisk spil 30.

Bekræftet session 8-regel 2026-05-17:

- Session 8 har 50 reelle spil.
- `SAMLET_alle regnskab_16-5-2026` refererer til `08_3-11-2018!A3:A53`, og den individuelle fane har spil 1-50.
- `expectedGameCount = 51` fra `00_Regnskab_01` bevares som auditværdi, men overstyrer ikke importerede spil.
- Slutscore efter spil 50 matcher `00_Regnskab_01`: `Thomas -92`, `Peter -84`, `Janus -180`, `Christian 356`.
- Der genereres ikke et syntetisk spil 51.

Foreløbig session 19-auditregel 2026-05-17:

- Session 19 består af tre faner: `19a_13-01-2023_Fredag`, `19b_13-01-2023_Færge mod Tyskla` og `19c_13-01-2023_Brewdog fredag`.
- Et samlet audit-ark genereres som `session19_combined_order.csv`.
- Rækkefølge i audit-arket følger `sourceGameMarker` fra kolonne A, derefter kildefane-rækkefølgen `19a`, `19b`, `19c`, og derefter originalt rækkenummer.
- `sourceGameMarker` er ikke unik, fordi 19c indeholder dubletter for 50, 51, 52 og 53. Derfor skal importen bruge `sequenceInSession` som stabil intern rækkefølge og bevare `sourceGameMarker` separat.
- CSV'en normaliserer kumulative og delta-scores til canonical kolonner for `Thomas`, `Peter`, `Janus` og `Christian`.
- Session 19 er ikke resolveret som importbeslutning. Den skal flagges som `session19_manual_review_required`, fordi dubletterne og nul-delta-rækken ikke har en sikker automatisk fortolkning.
- Session 19 inkluderes i første v3-bundle, men med tydeligt `manualReviewRequired`/quality flag. Den må ikke renses eller deduplikeres automatisk.

## Navne og normalisering

Canonical player ids i v3 forbliver:

- `Thomas`
- `Peter`
- `Janus`
- `Christian`

Normalisering skal være deterministisk og logges i importeren:

- Trim whitespace.
- Bevar kendte danske bogstaver i display values.
- Match case-insensitive for kendte spillernavne.
- Split sammensatte værdier i melder-/makkerfelter først efter eksplicit regel.
- Ukendte navne skal give audit issue, ikke stiltiende `null`.

Bekræftet navnemapping 2026-05-17:

| Råværdi | Canonical player |
|---|---|
| `Chrisitan` | `Christian` |
| `Jan` | `Janus` |
| `Janjusz` | `Janus` |
| `Jnaus` | `Janus` |
| `Peer` | `Peter` |
| `Janiz` | `Janus` |
| `Janjus` | `Janus` |
| `Jansicz` | `Janus` |

Bekræftet selvmakker-regel 2026-05-17:

- `Selvmakker` og `Selv makker` i `Makker` betyder ingen separat makker: `partnerId = null` og `isSelfPartner = true`.
- `Selvmakker` i `Melder` betyder, at melderen er selvmakker. Spilleren bestemmes fra kolonne J i `SAMLET_alle regnskab_16-5-2026` (`giver` i samlet-arkets header, men værdien svarer for den kontrollerede forekomst til `Vindende melding` i kildearket). Resultatet er `bidderId = <kolonne J>`, `partnerId = null` og `isSelfPartner = true`.
- Kontrolleret forekomst: session 24, spil 2, samlet-række 532 giver `bidderId = Janus`.

Bekræftet sammensat melder-/makker-regel 2026-05-17:

- Når `Melder` indeholder to personer i samme felt, skal første navn tolkes som melder og andet navn som makker.
- Separatorer i den aktuelle workbook: `/` og `+`.
- Eksempler: `Peter+Christian` betyder `bidderId = Peter`, `partnerId = Christian`; `Thomas/Peter` betyder `bidderId = Thomas`, `partnerId = Peter`.
- `Thoms` normaliseres til `Thomas` i denne kontekst.

## Output-kontrakt for første v3-pakke

Forventede artefakter:

- `docs/statistik/examples/v03/import_manifest_v3.json`
- `docs/statistik/examples/v03/import_manifest_v3.audit.json`
- `docs/statistik/examples/v03/IMPORT_V3_AUDIT.md`
- `docs/statistik/examples/v03/IMPORT_V3_REPORT.md`
- `docs/statistik/examples/v03/issues_v3.csv`
- `docs/statistik/examples/v03/session_validation_v3.csv`
- `docs/statistik/examples/v03/whist_historical_data_v3.json`

Første app-integration må først ske, når audit-output og manifest er genereret og sammenlignet med denne beslutningsfil.

## App-valg

Når v3-bundlen findes, skal appens default være ny primær kilde. Legacy v2 skal stadig kunne vælges eksplicit og vendes tilbage til. Se også `docs/statistik/dual_source_histories_statistik_brugerflade.md`.
