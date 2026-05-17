# Spilledag 26 – analyse og korrigeret reimport

Genereret: 2026-05-10T19:41:08

## Konklusion

Spilledag 26 blev tidligere importeret fra forskellen mellem kolonne B:E-rækkerne. Regnearket indeholder imidlertid en eksplicit per-spil-scoreblok i kolonne S:V (`T j`, `P j`, `J j`, `C j`). Den blok er brugt som korrigeret kilde, når den summerer til nul.

Spil 3 (`Sang`) var derfor forkert importeret som `Thomas -92, Peter +84, Janus +84, Christian -76`. Den korrigerede reimport bruger `Thomas -80, Peter +80, Janus +80, Christian -80`.

## Korrigerede spil

| Spil | Type | Før | Efter |
|---:|---|---|---|
| 2 | Sol | Thomas +20, Peter +4, Janus -12, Christian -12 | Thomas +12, Peter -4, Janus -4, Christian -4 |
| 3 | Sang | Thomas -92, Peter +84, Janus +84, Christian -76 | Thomas -80, Peter +80, Janus +80, Christian -80 |
| 4 | Sol | Thomas +12, Peter -4, Janus -4, Christian -4 | Thomas -12, Peter +4, Janus +4, Christian +4 |
| 5 | 10 Alm | Thomas +8, Peter -8, Janus -8, Christian +8 | Thomas -8, Peter +8, Janus +8, Christian -8 |
| 6 | Sol | Thomas -4, Peter +12, Janus -4, Christian -4 | Thomas +4, Peter -12, Janus +4, Christian +4 |
| 7 | Halv bordlæggrer | Thomas -16, Peter +48, Janus -16, Christian -16 | Thomas +16, Peter -48, Janus +16, Christian +16 |
| 8 | 9 vip 1. Ruder til hjerter | Thomas +16, Peter -16, Janus +16, Christian -16 | Thomas -16, Peter +16, Janus -16, Christian +16 |
| 9 | Sol | Thomas +4, Peter +4, Janus -12, Christian +4 | Thomas -4, Peter -4, Janus +12, Christian -4 |
| 10 | 10 Alm | Thomas -8, Peter +8, Janus -8, Christian +8 | Thomas +8, Peter -8, Janus +8, Christian -8 |
| 11 | Ren sol | Thomas +8, Peter -24, Janus +8, Christian +8 | Thomas -8, Peter +24, Janus -8, Christian -8 |
| 12 | Sol | Thomas +12, Peter -4, Janus -4, Christian -4 | Thomas -12, Peter +4, Janus +4, Christian +4 |
| 13 | 9 vip 2 | Thomas +32, Peter -32, Janus +32, Christian -32 | Thomas -32, Peter +32, Janus -32, Christian +32 |
| 14 | Ren sol | Thomas -48, Peter +16, Janus +16, Christian +16 | Thomas +48, Peter -16, Janus -16, Christian -16 |
| 15 | Sol | Thomas +4, Peter -12, Janus +4, Christian +4 | Thomas -4, Peter +12, Janus -4, Christian -4 |
| 16 | Sol | Thomas +4, Peter +4, Janus +4, Christian -12 | Thomas -4, Peter -4, Janus -4, Christian +12 |
| 17 | 9 vip i 3 | Thomas +64, Peter +64, Janus -64, Christian -64 | Thomas -64, Peter -64, Janus +64, Christian +64 |
| 18 | 9 Alm | Thomas -4, Peter +4, Janus +4, Christian -4 | Thomas +4, Peter -4, Janus -4, Christian +4 |
| 19 | Sol | Thomas +4, Peter +4, Janus -12, Christian +4 | Thomas -4, Peter -4, Janus +12, Christian -4 |
| 20 | 9 vip i 2 | Thomas +24, Peter -24, Janus -24, Christian +24 | Thomas -24, Peter +24, Janus +24, Christian -24 |
| 21 | 9 vip i 1 | Thomas +48, Peter -48, Janus -48, Christian +48 | Thomas -48, Peter +48, Janus +48, Christian -48 |
| 22 | Ren sol | Thomas +24, Peter -8, Janus -8, Christian -8 | Thomas -24, Peter +8, Janus +8, Christian +8 |
| 23 | 9 vip i 2 | Thomas -48, Peter +16, Janus +16, Christian +16 | Thomas +48, Peter -16, Janus -16, Christian -16 |
| 25 | 9 vip i 2 | Thomas +32, Peter -32, Janus -32, Christian +32 | Thomas -32, Peter +32, Janus +32, Christian -32 |
| 26 | 9 vip i 2 | Thomas +32, Peter -32, Janus +32, Christian -32 | Thomas -32, Peter +32, Janus -32, Christian +32 |
| 27 | 10. Halve | Thomas +8, Peter +8, Janus -8, Christian -8 | Thomas -8, Peter -8, Janus +8, Christian +8 |
| 28 | 9 halve | Thomas -8, Peter +8, Janus -8, Christian +8 | Thomas +8, Peter -8, Janus +8, Christian -8 |
| 29 | 10 sans | Thomas +56, Peter -56, Janus -56, Christian +56 | Thomas -56, Peter +56, Janus +56, Christian -56 |

## Ikke automatisk korrigeret

| Spil | Type | Importeret | Regneark S:V | Årsag |
|---:|---|---|---|---|
| 24 | 9 gode | Thomas +8, Peter -8, Janus +8, Christian -8 | Thomas -8, Peter +8, Janus -8, Christian -8 | S:V summerer ikke til nul |

## Andre holdscore-afvigelser i historikken

De øvrige makkerspil med ulige holdscore er ikke automatisk ændret. Ved opslag i regnearket findes samme afvigelse i kildeblokken, så de er markeret som datakvalitet/regelfortolkning snarere end en sikker importfejl.

| Spilledag | Spil | Type | Resultat efter reimport | Vurdering |
|---:|---:|---|---|---|
| 19a | 22 | 9 halve | Thomas +96, Peter +72, Janus -104, Christian -64 | Kilde-/regelafklaring; ikke sikker importfejl |
| 19b | 1 | 9 gode | Thomas -50, Peter +34, Janus +170, Christian -154 | Kilde-/regelafklaring; ikke sikker importfejl |
| 19c | 10 | 10 alm | Thomas +8, Peter -8, Janus -8, Christian +8 | Kilde-/regelafklaring; ikke sikker importfejl |
| 20 | 9 | 10 vip i 3 | Thomas -24, Peter -24, Janus +72, Christian -24 | Kilde-/regelafklaring; ikke sikker importfejl |
| 21 | 9 | 8 vip i 3. | Thomas -24, Peter -24, Janus +24, Christian +24 | Kilde-/regelafklaring; ikke sikker importfejl |
| 22 | 10 | 8 gode | Thomas -6, Peter -6, Janus +6, Christian +6 | Kilde-/regelafklaring; ikke sikker importfejl |
| 22 | 25 | 8 i 2 | Thomas +16, Peter -16, Janus +16, Christian -16 | Kilde-/regelafklaring; ikke sikker importfejl |
| 22 | 34 | 10 alm (duefejl | Thomas -72, Peter +24, Janus +24, Christian +24 | Kilde-/regelafklaring; ikke sikker importfejl |
| 25 | 3 | 9 gode | Thomas -4, Peter +20, Janus -4, Christian -12 | Kilde-/regelafklaring; ikke sikker importfejl |
| 25 | 4 | 10 gode | Thomas +28, Peter -12, Janus +28, Christian -44 | Kilde-/regelafklaring; ikke sikker importfejl |
| 25 | 5 | 9 gode | Thomas +40, Peter +0, Janus +16, Christian -56 | Kilde-/regelafklaring; ikke sikker importfejl |
| 25 | 6 | 9 vip i 1. Hjerte til spar | Thomas +56, Peter -16, Janus +0, Christian -40 | Kilde-/regelafklaring; ikke sikker importfejl |
| 25 | 7 | 9 vip i 3. Hjerte til spar | Thomas +88, Peter -48, Janus +32, Christian -72 | Kilde-/regelafklaring; ikke sikker importfejl |
| 25 | 20 | 10 vip1 | Thomas +24, Peter -24, Janus +24, Christian -24 | Kilde-/regelafklaring; ikke sikker importfejl |
| 26 | 18 | 9 Alm | Thomas +4, Peter -4, Janus -4, Christian +4 | Kilde-/regelafklaring; ikke sikker importfejl |
