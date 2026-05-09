# Whist import v2 — audit og app-klart datasæt

Genereret: 2026-05-09T15:49:06

## Kort status

| Måling | Antal |
|---|---:|
| Sessions | 27 |
| Spil | 744 |
| PlayerResult-rækker | 2976 |
| Issues | 46 |

## Felt-dækning

| Felt | Spil med felt | Ud af alle spil |
|---|---:|---:|
| Spiltype | 469 | 744 |
| Giver/dealer | 515 | 744 |
| Melder/vinder | 532 | 744 |
| Makker | 165 | 744 |
| Score-sum = 0 | 714 | 744 |

## Issues efter v2

| Issue | Antal |
|---|---:|
| `score_sum_not_zero` | 30 |
| `game_marker_without_scores` | 13 |
| `expected_vs_imported_count_mismatch` | 3 |

## Sessions

| Session | Ark | Forventet | Importeret | Manglende score-rækker | Status |
|---|---|---:|---:|---:|---|
| 1 | `01_21-06-2016` | 24 | 24 | 0 | ok |
| 2 | `02_2492016` | 46 | 46 | 0 | ok |
| 3 | `03_25-02-2017` | 23 | 22 | 13 | warning_missing_source_rows |
| 4 | `04_Måske Berlin` | 30 | 29 | 0 | warning_missing_source_rows |
| 6 | `06_23-09-2017` | 26 | 26 | 0 | ok |
| 7 | `07_24-09-2017` | 11 | 11 | 0 | ok |
| 8 | `08_3-11-2018` | 51 | 50 | 0 | warning_missing_source_rows |
| 9 | `09_26-01-2019` | 41 | 41 | 0 | ok |
| 10 | `10_28-06-2019` | 32 | 32 | 0 | ok |
| 11 | `11_29-11-2019` | 26 | 26 | 0 | ok |
| 12b | `12_21-02-2020` | 35 | 35 | 0 | ok |
| 13 | `13_22-02-2020` | 31 | 31 | 0 | ok |
| 14 | `14_02-10-2020` | 27 | 27 | 0 | ok |
| 15 | `15_18-06-2021` | 18 | 18 | 0 | ok |
| 16 | `16_18-11-2021` | 27 | 27 | 0 | ok |
| 17 | `17_25-02-2022` | 25 | 25 | 0 | ok |
| 18 | `18_26-02-2022` | 40 | 40 | 0 | ok |
| 19a | `19a_13-01-2023_Fredag` |  | 40 | 0 | ok |
| 19b | `19b_13-01-2023_Færge mod Tyskla` | 8 | 8 | 0 | ok |
| 19c | `19c_13-01-2023_Brewdog fredag` |  | 10 | 0 | ok |
| 20 | `20_14-01-2023_Stasi Lørdag` | 30 | 30 | 0 | ok |
| 21 | `21_08-06-2023` | 22 | 22 | 0 | ok |
| 22 | `22_31-09-2023_RETTET` | 39 | 39 | 0 | ok |
| 23 | `23_27-06-2024` | 19 | 19 | 0 | ok |
| 24 | `24_6-8-2024` | 17 | 17 | 0 | ok |
| 25 | `25_29-11-2024` | 20 | 20 | 0 | ok |
| 26 | `26_30-11-2024` | 29 | 29 | 0 | ok |

## Hvad er forbedret fra v1

- `Melding` og `Vindende melding` bliver nu vurderet ud fra kolonneindhold, ikke kun headernavn. Det reducerer fejlagtige `unknown_bidder_name` markant.
- `Makker` importeres nu, hvor kolonnen findes.
- Ark med delspil/fortsættelser håndteres bedre, især `12_21-02-2020` og Berlin 2023-arkene.
- Rækker efter tydelige summeringer som `I ALT` ignoreres, så duplikatrækker ikke importeres som spil.
- Der eksporteres nu ét samlet app-klart JSON-datasæt: `whist_historical_data_v2.json`.

## Anbefalet næste skridt

Brug v2-outputtet som grundlag for første Swift/Codable- og CoreData-model. De resterende issues bør behandles som datakvalitet, ikke som blocker for de første pointbaserede statistikker.
