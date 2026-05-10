# Historiske datakvalitetsrettelser

Genereret: 2026-05-10T20:08:11

## Automatiske rettelser

Kun spil med en konkret regnearksnote og en entydig nulsum-korrektion er rettet. Øvrige ubalancer bevares som datakvalitetsadvarsler i appen.

| Spilledag | Spil | Spiller | Før | Efter | Resultat efter rettelse | Kilde-note |
|---:|---:|---|---:|---:|---|---|
| 2 | 13 | Janus | -104 | -4 | Thomas +4, Peter +4, Janus -4, Christian -4 | Regnearksnoten siger: Her ryger jeg 100 kroner for langt ned. |
| 2 | 14 | Christian | -20 | +20 | Thomas -20, Peter -20, Janus +20, Christian +20 | Regnearksnoten siger: Hvem vinder 20 i stedet for at miste dem? Tror det er Christian... |

## Bevidst ikke rettet automatisk

- Spilledag 1, 3 og 4 har historiske ubalancer uden nok metadata til at afgøre, hvilken spiller der skal justeres.
- Spilledag 25, spil 3-7 summerer til nul, men resultatet matcher ikke almindelig makkerlogik. Her kan fejlen ligge i resultat, makker, melder/vinder eller spiltype.
- Spilledag 26, spil 24 har en eksplicit scoreblok, der selv summerer forkert. Den kræver manuel kildeafklaring.
