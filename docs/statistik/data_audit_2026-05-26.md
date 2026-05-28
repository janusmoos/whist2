# Historisk data-audit: scorekonsistens

Genereret: 2026-05-26T23:46:25

## Formål

Denne audit er lavet efter fundet i Spilledag 30, Spil 1, hvor appens importerede delta-score ikke matchede den kumulative score i regnearket. Audit'en sammenligner eksplicitte delta-kolonner (U:X) med den delta, der kan udledes af kumulative scorekolonner (C:F), og sammenligner de workbook-versioner, der findes lokalt.

## Workbook-versioner

| Workbook | SHA-256 | Læste spilrækker | Delta/kumulativ mismatch | Delta-sum != 0 |
|---|---|---:|---:|---:|
| `Whist – resultater – samlet (2024)_AKTIV_forenkling af data.xlsx` | `a6c126c81f743c9ad5da54af3ac18e312459cc44d02e01d7b656d3ccce446bfa` | 745 | 2 | 0 |
| `Whist – resultater – samlet (2024)_AKTIV_forenkling af data-2.xlsx` | `f7d221789d3e6c133780b5fe24af57934715e578b7837288b8bf8d8d6b480a08` | 745 | 0 | 0 |
| `Whist – resultater – samlet (2024)_AKTIV_forenkling af data-3.xlsx` | `359756845732b51a48fd2211308da84769748eedcabd1bac9f14548fef9f0f73` | 745 | 0 | 0 |


## Aktuel app-data efter reimport

| Måling | Værdi |
|---|---|
| Kilde-workbook | `Whist – resultater – samlet (2024)_AKTIV_forenkling af data-3.xlsx` |
| Kilde-SHA256 | `359756845732b51a48fd2211308da84769748eedcabd1bac9f14548fef9f0f73` |
| App-data genereret | 2026-05-26T21:26:27.608817+00:00 |
| Spil i app-JSON | 903 |
| PlayerResult-rækker | 3612 |

Direkte kontrol af de to sikre fejl i appens JSON:

- Spilledag 30, Spil 1: Thomas -24, Peter +24, Janus -24, Christian +24
- Spilledag 31, Spil 1: Thomas +8, Peter -8, Janus -8, Christian +8


## Sikre delta/kumulativ-fejl

Disse rækker har eksplicitte delta-tal, som ikke matcher ændringen i de kumulative scorekolonner.

| workbook | sourceRow | session | game | gameTypeRaw | explicitDelta | expectedDelta |
| --- | --- | --- | --- | --- | --- | --- |
| Whist – resultater – samlet (2024)_AKTIV_forenkling af data.xlsx | 692 | 30 | 1 | 9 Alm Peter | Thomas -224, Peter +360, Janus -120, Christian -16 | Thomas -24, Peter +24, Janus -24, Christian +24 |
| Whist – resultater – samlet (2024)_AKTIV_forenkling af data.xlsx | 712 | 31 | 1 | 9 halve | Thomas -52, Peter +36, Janus +20, Christian -4 | Thomas +8, Peter -8, Janus -8, Christian +8 |


CSV: `docs/statistik/audit/score_delta_mismatches_2026-05-26.csv`

## Delta-sum-fejl

Disse rækker har eksplicitte delta-tal, der ikke summerer til nul.

_Ingen fund._


CSV: `docs/statistik/audit/score_sum_issues_2026-05-26.csv`

## Forskelle mellem workbook-versioner

Disse spil har forskellige importerbare værdier mellem de lokale workbook-versioner.

| workbook | sourceRow | session | game | gameTypeRaw | explicitDelta | expectedDelta |
| --- | --- | --- | --- | --- | --- | --- |
| Whist – resultater – samlet (2024)_AKTIV_forenkling af data.xlsx | 412 | 19 | 50 | 9 gode | Thomas -8, Peter +8, Janus -8, Christian +8 | Thomas -8, Peter +8, Janus -8, Christian +8 |
| Whist – resultater – samlet (2024)_AKTIV_forenkling af data.xlsx | 413 | 19 | 50 | 9 halve | Thomas +16, Peter +16, Janus -16, Christian -16 | Thomas +16, Peter +16, Janus -16, Christian -16 |
| Whist – resultater – samlet (2024)_AKTIV_forenkling af data-2.xlsx | 412 | 19 | 50 | 9 gode | Thomas -8, Peter +8, Janus -8, Christian +8 | Thomas -8, Peter +8, Janus -8, Christian +8 |
| Whist – resultater – samlet (2024)_AKTIV_forenkling af data-2.xlsx | 413 | 19 | 50 | 9 halve | Thomas +16, Peter +16, Janus -16, Christian -16 | Thomas +16, Peter +16, Janus -16, Christian -16 |
| Whist – resultater – samlet (2024)_AKTIV_forenkling af data-3.xlsx | 412 | 19 | 50 | 9 gode | Thomas -8, Peter +8, Janus -8, Christian +8 | Thomas -8, Peter +8, Janus -8, Christian +8 |
| Whist – resultater – samlet (2024)_AKTIV_forenkling af data-3.xlsx | 413 | 19 | 50 | 9 halve | Thomas +16, Peter +16, Janus -16, Christian -16 | Thomas +16, Peter +16, Janus -16, Christian -16 |
| Whist – resultater – samlet (2024)_AKTIV_forenkling af data.xlsx | 414 | 19 | 51 | 9 halve | Thomas +8, Peter -8, Janus -8, Christian +8 | Thomas +8, Peter -8, Janus -8, Christian +8 |
| Whist – resultater – samlet (2024)_AKTIV_forenkling af data.xlsx | 415 | 19 | 51 | 9 gode | Thomas +8, Peter -8, Janus +8, Christian -8 | Thomas +8, Peter -8, Janus +8, Christian -8 |
| Whist – resultater – samlet (2024)_AKTIV_forenkling af data-2.xlsx | 414 | 19 | 51 | 9 halve | Thomas +8, Peter -8, Janus -8, Christian +8 | Thomas +8, Peter -8, Janus -8, Christian +8 |
| Whist – resultater – samlet (2024)_AKTIV_forenkling af data-2.xlsx | 415 | 19 | 51 | 9 gode | Thomas +8, Peter -8, Janus +8, Christian -8 | Thomas +8, Peter -8, Janus +8, Christian -8 |
| Whist – resultater – samlet (2024)_AKTIV_forenkling af data-3.xlsx | 414 | 19 | 51 | 9 halve | Thomas +8, Peter -8, Janus -8, Christian +8 | Thomas +8, Peter -8, Janus -8, Christian +8 |
| Whist – resultater – samlet (2024)_AKTIV_forenkling af data-3.xlsx | 415 | 19 | 51 | 9 gode | Thomas +8, Peter -8, Janus +8, Christian -8 | Thomas +8, Peter -8, Janus +8, Christian -8 |

_Viser 12 af 45 fund. Se CSV for hele listen._


CSV: `docs/statistik/audit/workbook_version_differences_2026-05-26.csv`

## Konklusion

- Den oprindelige workbook `Whist – resultater – samlet (2024)_AKTIV_forenkling af data.xlsx` indeholder 2 sikre delta/kumulativ-fejl: Spilledag 30, Spil 1, Spilledag 31, Spil 1.
- Appens aktuelle v3-data er reimporteret fra den rettede workbook `...data-3.xlsx`, som har 0 delta/kumulativ-fejl i den primære kilde.
- Direkte kontrol af appens JSON bekræfter, at Spilledag 30, Spil 1 og Spilledag 31, Spil 1 nu bruger de korrigerede scorer.
- Der er versionsforskelle på 11 spilnøgler: 19/50, 19/51, 19/52, 19/53, 25/2, 25/3, 25/4, 25/5, 25/6, 30/1, 31/1. Nogle af dem ligger i Spilledag 19, hvor der historisk er dublet-/manual-review-problemer; de sikre deltafejl ligger i Spilledag 30 og 31.
- Repo-kopien under `docs/statistik/examples` er en ældre/afkortet kilde uden de nyeste rækker i `SAMLET_alle regnskab_16-5-2026`, og bør ikke bruges som sandhedskilde for de seneste spilledage.

## Anbefaling

1. Behandl `...data-3.xlsx` som den aktuelle sandhedskilde for v3-importen.
2. Behold audit-scriptet som fast kontrol efter fremtidige importer eller manuelle rettelser i workbooken.
3. Gennemgå versionsforskellene i CSV'en særskilt, især Spilledag 19, hvis vi vil rydde op i historiske dublet-/manual-review-problemer.
4. Brug ikke repo-kopien under `docs/statistik/examples` som autoritativ kilde for de seneste spilledage.
