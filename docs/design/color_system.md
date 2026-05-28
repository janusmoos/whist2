# Whist20 farvesystem

Dette dokument er den levende reference for faste farver i Whist20. Når en farve ændres i appen, skal denne fil opdateres samtidig med koden.

Den visuelle palette findes også som grafik:

`docs/design/whist20_color_palette.svg`

## Plakatfarver

| Navn | Hex | Brug |
| --- | --- | --- |
| Plakatbaggrund | `#EDE8E0` | Baggrund i meldings-, resultat- og resumébokse. |
| Plakatborder | `#B3A38F` | Neutral border omkring plakatbokse og tabeller i plakatstil. |
| Mørk tekst/kulør | `#1A1F29` | Sort spar/klør, store stik-tal, mørke ikoner og primær plakattekst. |
| Kontraktmarkering | `#524538` | Diskret mørkebrun border på melder/makker-pointbokse. |
| Resultatrød | `#B80D1A` | Negative point, tabt melding, røde kulører og røde ribbons/badges. |
| Resultatgrøn | `#1A7A3B` | Positive point, vundet melding og grønne badges/borders. |
| Sans-neutral | `#B8B8B8` | Neutral sans-termometerfarve. |
| Aktiv orange | `#EB8C0D` | Aktiv-prik, orange handlinger og enkelte navigationsmarkører. |

## Forsideknapper

Forsidens navigationsknapper bruger samme plakatbaggrund og plakatborder som resultat- og meldingsbokse. Ikoner og knaptekst bruger dæmpede accentfarver, der ligger tæt på spillerfarverne, så forsiden hænger sammen med `Status`-diagrammet uden at ligne et kontrolpanel fra system-UI.

| Knap | Hex | Brug |
| --- | --- | --- |
| Spilledage | `#6E8FBF` | Blå accent til kalenderindgang. |
| Seneste spil | `#61A887` | Grøn accent til historikindgang. |
| Stilling | `#C98736` | Okker accent til pointoversigt. |
| Indstillinger | `#1A1F29` med reduceret opacity | Neutral mørk accent til indstillinger. |

## Bundnavigation

Bundnavigationen bruger en pilleformet plakatflade med hævet kort-stack som central handling. Midterkortet er en handling, ikke en fane: `Nyt spil` eller `Afslut spil`, afhængigt af om der ligger en aktiv kladde.

| Navn | Hex | Brug |
| --- | --- | --- |
| Bundbar-flade | `#EDE8E0` ved ca. 94% opacity | Pilleformet bundnavigation. |
| Valgt ikon / nyt spil | `#1A5745` | Valgt fane og plus på midterkortet. |
| Inaktivt ikon | `#1A1F29` ved ca. 56% opacity | Ikke-valgte sideikoner. |
| Aktivt spil-prik / afslut spil | `#ED8C0D` | Badge ved aktiv kladde og midterkortets fortsæt/afslut-tilstand. |
| Kortbaggrund bag midterkort | `#D6D9C9` | De forskudte bagkort bag den centrale handling. |

## Spillerfarver

Spillerfarverne bruges til diskrete udviklingslinjer og som 2 px border på stillingsboksene på `Seneste spil`. Stillingsboksene bruger fortsat den fælles plakatbaggrund. Spillerfarverne skal ikke erstatte resultatfarverne for plus/minus-point.

| Spiller | Sæde | Linje | Baggrund | Brug |
| --- | --- | --- | --- | --- |
| Thomas | `south` | `#6F8FBF` | `#E8EEF7` | Blågrå udviklingslinje og border. |
| Peter | `east` | `#6FA987` | `#E7F1EB` | Dæmpet grøn udviklingslinje og border. |
| Janus | `west` | `#C9944A` | `#F5EBDD` | Varm okker udviklingslinje og border. |
| Christian | `north` | `#9B75B8` | `#EFE8F4` | Dæmpet lilla udviklingslinje og border. |

## Regler

- Plus- og minuspoint bruger altid `Resultatgrøn` og `Resultatrød`, også når spillerbokse eller diagrammer har egne spillerfarver.
- Kulørikoner bruger `Resultatrød` for hjerter/ruder og `Mørk tekst/kulør` for spar/klør. I koden styres alle kulørfarver via `Suit.color(context:colorScheme:)` i `SuitPlayingCardStyle.swift`; nye lokale forskelle skal tilføjes som en ny `SuitColorContext`, ikke som lokale `switch`-statements.
- Store stik-tal i resultatplakater bruger `Mørk tekst/kulør`, ikke trumffarven. Trumffarven må stadig bruges i termometeret og kulørbokse.
- Plakatbokse bruger som udgangspunkt `Plakatbaggrund` og `Plakatborder`.
- Melder/makker-markering i pointbokse bruger `Kontraktmarkering`, så rollen er tydelig uden at dominere resultatfarverne.
- Nye diagrammer skal være mere diskrete end resultatplakaten: brug spillerlinjer med lavere visuel vægt og undgå stærke flader. Stillingsbokse bruger plakatbaggrund og spillerfarvet border.
- Hvis en ny farve får semantisk betydning, skal den tilføjes her med navn, hex og brug.
