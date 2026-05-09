# Whist import — valideringspakke og næste beslutninger

Genereret: 2026-05-09T15:39:19

## Status

Import v1 er nu god nok til at bruge som grundlag for en **systematisk validering**, men den er ikke klar til at blive bundlet direkte ind i appen endnu.

| Måling | Antal |
|---|---:|
| Sessions importeret | 27 |
| Spil importeret | 744 |
| PlayerResult-rækker | 2976 |
| Issues i audit | 190 |
| Sessions med expected/imported mismatch | 8 |

## Felt-dækning

| Felt | Spil med felt | Ud af alle spil |
|---|---:|---:|
| Pointdata | 744 | 744 |
| Spiltype | 460 | 744 |
| Giver/dealer | 512 | 744 |
| Melder/Hvem | 398 | 744 |
| Makker | 0 | 744 |
| Score-sum = 0 eller tom kontrol | 713 | 744 |

## Største problemer lige nu

| Problem | Antal | Betydning |
|---|---:|---|
| `unknown_bidder_name` | 148 | Parseren tolker en kolonne som spillerfelt, men finder værdier som ikke matcher faste spillernavne. |
| `score_sum_not_zero` | 31 | De fire scoreværdier summerer ikke til 0. Kan være parserproblem eller reelt særtilfælde. |
| `expected_vs_imported_count_mismatch` | 8 | Antal importerede spil matcher ikke referenceantallet. |
| `unknown_dealer_name` | 3 | Giverfelt indeholder værdi, der ikke kan normaliseres til spiller. |

## Sessions der skal gennemgås først

| Session | Fane | Forventet | Importeret | Forskel | Handling |
|---:|---|---:|---:|---:|---|
| 3 | `03_25-02-2017` | 23 | 22 | -1 | Gennemgå parser/source rows |
| 4 | `04_Måske Berlin` | 30 | 29 | -1 | Gennemgå parser/source rows |
| 8 | `08_3-11-2018` | 51 | 50 | -1 | Gennemgå parser/source rows |
| 12b | `12_21-02-2020` | 27 | 35 | 8 | Gennemgå parser/source rows |
| 19 | `19a_13-01-2023_Fredag` | 8 | 40 | 32 | Gennemgå parser/source rows |
| 19 | `19c_13-01-2023_Brewdog fredag` | 8 | 10 | 2 | Gennemgå parser/source rows |
| 22 | `22_31-09-2023_RETTET` | 39 | 38 | -1 | Gennemgå parser/source rows |
| 23 | `23_27-06-2024` | 19 | 20 | 1 | Gennemgå parser/source rows |

## Prioriteret plan

### Trin 1 — Acceptér pointdata for de sikre sessions

Sessions med korrekt antal spil og uden alvorlige scoreproblemer kan bruges til de første statistikker: samlet score, gennemsnit, udvikling over tid, bedste/værste spil og bedste/værste spilledag.

### Trin 2 — Ret parseren på de 8 mismatches

De vigtigste faner at gennemgå er dem, hvor expected/imported ikke matcher. Det er sandsynligvis her, importeren enten tager for mange rækker med eller overser rigtige spilrækker.

### Trin 3 — Skil “Hvem/melder/vinder” bedre ad

`unknown_bidder_name` er den største issue-type. Den skyldes sandsynligvis, at nogle faner bruger kolonnerne forskelligt. Importeren skal derfor have fanetype-regler i stedet for én global fortolkning.

### Trin 4 — Lav første app-klare datasæt

Når mismatches er løst, bør næste output være `whist_historical_data_v1.json`, `whist_historical_data_v1_audit.md`, Swift `Codable` modeller og CoreData entity-skema.

## Filer i denne pakke

- `session_decision_list.csv` — hvilke sessions kan accepteres, og hvilke skal gennemgås
- `field_coverage_by_session.csv` — hvor mange spil pr. session har spiltype/giver/melder/makker
- `issue_summary.csv` — issue-typer og antal
- `issue_examples.csv` — alle konkrete issue-rækker
- `player_score_control.csv` — totalscore pr. spiller fra import v1
- `statistics_readiness.csv` — hvilke statistikker er klar nu

## Min anbefaling

Næste tekniske leverance bør være **import v2**, ikke app-UI. Import v2 skal fokusere på at løse de 8 mismatches, reducere `unknown_bidder_name`, afgøre om `partnerId` kan udledes, validere totalscore mod referenceark og eksportere ét samlet app-klart JSON-datasæt.
