# Whist import v3 - app-klart datasæt

Genereret: 2026-05-17T10:25:46.844218+00:00

## Kort status

| Måling | Antal |
|---|---:|
| Sessions | 32 |
| Spil | 903 |
| PlayerResult-rækker | 3612 |
| Issues | 47 |

## Beslutninger

- Session 1-4 og 6-7 importeres fra individuelle faner som begrænset kilde.
- Session 5 bevares som tom kilde uden spil.
- Session 19 inkluderes med `manual_review_required` quality flag.
- Dato/sted kommer fra `00_Regnskab_01`; samlet-arkets dato er audit-only.

## Issues fra audit

| Issue | Antal |
|---|---:|
| `date_mismatch` | 8 |
| `empty_source_sheet` | 1 |
| `expected_vs_imported_count_mismatch` | 1 |
| `individual_sheet_limited_source` | 6 |
| `score_sum_not_zero` | 30 |
| `session19_manual_review_required` | 1 |
