# Whist import v3 - read-only audit

Genereret: 2026-05-17T10:22:36.010340+00:00

## Workbook

- SHA256: `a6c126c81f743c9ad5da54af3ac18e312459cc44d02e01d7b656d3ccce446bfa`
- Faner: 56
- Python: `3.12.13`
- openpyxl: `3.1.5`

## Arkstatus

| Ark | Rækker | Kolonner | Rolle |
|---|---:|---:|---|
| `SAMLET_alle regnskab_16-5-2026` | 755 | 77 | Primær spil-for-spil-kilde |
| `00_Regnskab_01` | 48 | 14 | Audit/kontrol |

## Primærkilde

- Header SHA256 række 3: `81b3ab246b88c09f0d1b9ded92f1c3eec10fa612e3e76b3d6dd1f6f0bfcc4b77`
- Summary/status-rækker for session 1-7: 7
- Spilrækker: 745
- Sessions med spilrækker: 25
- Score-sum = 0: 745
- Score-sum != 0: 0

## Samlet v3-dækning

- Importerbare spil på tværs af kilder: 903
- Sessions med importerbare spil: 31

## Session 19 samlet rækkefølge

- Rækker: 58
- Unikke spilnumre fra kolonne A: 54
- Dublet-spilnumre: 50, 51, 52, 53
- Nul-delta-rækker: 1
- CSV: `session19_combined_order.csv`

## Individuelle faner 1-7

- Importerbare spil: 158
- Manglende score-rækker: 0
- Score-sum != 0: 30

| Session | Fane | Importerbare spil | Accepteret forventet | Manglende score-rækker | Score-sum != 0 | Status |
|---|---|---:|---:|---:|---:|---|
| 1 | `01_21-06-2016` | 24 |  | 0 | 5 | individual_sheet_limited_source |
| 2 | `02_2492016` | 46 |  | 0 | 14 | individual_sheet_limited_source |
| 3 | `03_25-02-2017` | 22 | 22 | 0 | 7 | individual_sheet_limited_source |
| 4 | `04_Måske Berlin` | 29 | 29 | 0 | 4 | individual_sheet_limited_source |
| 5 | `05_22-09-2017_TOM` | 0 |  | 0 | 0 | empty_source_sheet |
| 6 | `06_23-09-2017` | 26 |  | 0 | 0 | individual_sheet_limited_source |
| 7 | `07_24-09-2017` | 11 |  | 0 | 0 | individual_sheet_limited_source |

## Issues

| Issue | Antal |
|---|---:|
| `date_mismatch` | 8 |
| `empty_source_sheet` | 1 |
| `expected_vs_imported_count_mismatch` | 1 |
| `individual_sheet_limited_source` | 6 |
| `score_sum_not_zero` | 30 |
| `session19_manual_review_required` | 1 |

## Sessions

| Session | Dato kontrol | Dato primær | Forventet | Accepteret forventet | Importeret | Kilde | Status |
|---|---|---|---:|---:|---:|---|---|
| 1 | 2016-06-21 |  | 24 |  | 24 | 01_21-06-2016 | individual_sheet_limited_source |
| 2 | 2016-09-24 |  | 46 |  | 46 | 02_2492016 | individual_sheet_limited_source |
| 3 | 2017-02-25 |  | 23 | 22 | 22 | 03_25-02-2017 | individual_sheet_limited_source |
| 4 | ? |  | 30 | 29 | 29 | 04_Måske Berlin | individual_sheet_limited_source |
| 5 | 2017-09-22 |  |  |  | 0 | 05_22-09-2017_TOM | empty_source_sheet |
| 6 | 2017-09-23 |  | 26 |  | 26 | 06_23-09-2017 | individual_sheet_limited_source |
| 7 | 2017-09-24 |  | 11 |  | 11 | 07_24-09-2017 | individual_sheet_limited_source |
| 8 | 2018-11-03 | 2018-11-03 | 51 | 50 | 50 | SAMLET_alle regnskab_16-5-2026 | ok |
| 9 | 2019-01-26 | 2019-01-26 | 41 |  | 41 | SAMLET_alle regnskab_16-5-2026 | ok |
| 10 | 2019-06-28 | 2019-06-28 | 32 |  | 32 | SAMLET_alle regnskab_16-5-2026 | ok |
| 11 | 2019-11-29 | 2019-11-29 | 26 |  | 26 | SAMLET_alle regnskab_16-5-2026 | ok |
| 12a | 2020-02-21 | 2020-02-21 | 8 |  | 8 | SAMLET_alle regnskab_16-5-2026 | ok |
| 12b | 2020-02-21 | 2020-02-21 | 27 |  | 27 | SAMLET_alle regnskab_16-5-2026 | ok |
| 13 | 2020-02-22 | 2020-02-22 | 31 |  | 31 | SAMLET_alle regnskab_16-5-2026 | ok |
| 14 | 2020-10-02 | 2020-10-02 | 27 |  | 27 | SAMLET_alle regnskab_16-5-2026 | ok |
| 15 | 2021-06-18 | 2021-06-18 | 18 |  | 18 | SAMLET_alle regnskab_16-5-2026 | ok |
| 16 | 2021-11-18 | 2021-11-18 | 27 |  | 27 | SAMLET_alle regnskab_16-5-2026 | ok |
| 17 | 2022-02-25 | 2022-02-25 | 25 |  | 25 | SAMLET_alle regnskab_16-5-2026 | ok |
| 18 | 2022-02-26 | 2022-02-26 | 40 |  | 40 | SAMLET_alle regnskab_16-5-2026 | ok |
| 19 | 2023-01-13 | 2023-01-13 | 8 |  | 58 | SAMLET_alle regnskab_16-5-2026 | manual_review_required |
| 20 | 2023-01-14 | 2023-01-14 | 30 |  | 30 | SAMLET_alle regnskab_16-5-2026 | ok |
| 21 | 2023-06-08 | 2023-06-08 | 22 |  | 22 | SAMLET_alle regnskab_16-5-2026 | ok |
| 22 | 2023-09-30 | 2023-09-30 | 39 |  | 39 | SAMLET_alle regnskab_16-5-2026 | ok |
| 23 | 2024-06-27 | 2023-09-30 | 19 |  | 19 | SAMLET_alle regnskab_16-5-2026 | ok |
| 24 | 2024-08-06 | 2023-09-30 | 17 |  | 17 | SAMLET_alle regnskab_16-5-2026 | ok |
| 25 | 2024-11-29 | 2023-09-30 | 20 |  | 20 | SAMLET_alle regnskab_16-5-2026 | ok |
| 26 | 2024-11-30 | 2023-09-30 | 29 |  | 29 | SAMLET_alle regnskab_16-5-2026 | ok |
| 27 | 2025-03-28 |  | 20 |  | 20 | SAMLET_alle regnskab_16-5-2026 | ok |
| 28 | 2025-06-14 | 2023-09-30 | 35 |  | 35 | SAMLET_alle regnskab_16-5-2026 | ok |
| 29 | 2025-09-26 | 2023-09-30 | 40 |  | 40 | SAMLET_alle regnskab_16-5-2026 | ok |
| 30 | 2025-11-21 | 2023-09-30 | 20 |  | 20 | SAMLET_alle regnskab_16-5-2026 | ok |
| 31 | 2025-11-22 | 2023-09-30 | 44 |  | 44 | SAMLET_alle regnskab_16-5-2026 | ok |
