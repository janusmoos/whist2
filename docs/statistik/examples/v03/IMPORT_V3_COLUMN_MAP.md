# Whist import v3 - kolonnemap

Oprettet: 2026-05-17

Denne fil beskriver den foreløbige faste mapping for `SAMLET_alle regnskab_16-5-2026` og auditmapping for `00_Regnskab_01`.

V3 skal bruge kolonneindeks og header-fingeraftryk, ikke kun headernavne, fordi samme headernavn gentages i flere statistikblokke.

## `SAMLET_alle regnskab_16-5-2026`

Dimensioner ved probe:

- Rækker: 755
- Kolonner: 77
- Header-række: 3
- Header SHA256: `81b3ab246b88c09f0d1b9ded92f1c3eec10fa612e3e76b3d6dd1f6f0bfcc4b77`

## Rækkezoner

| Række(r) | Rolle | Importbeslutning |
|---:|---|---|
| 1-2 | Gruppe-/formeloverskrifter | Audit/fingerprint kun |
| 3 | Felt-headers | Bruges til fingerprint og sanity check |
| 4-10 | Session 1-7 statusrækker uden spilnummer | Audit only |
| 11-755 | Spilrækker | Primær v3-import |

## Primær spilrække-mapping

Kolonnebogstaver er Excel-kolonner. Kolonneindeks er 1-baserede.

| JSON-/auditfelt | Kolonne | Indeks | Header række 3 | Beslutning |
|---|---:|---:|---|---|
| `sessionNumber` | A | 1 | `#` | Primær sessionsnøgle |
| `sourceGameMarker` / `gameNumberInSession` | B | 2 | `spil` | Primært spilnummer på rækken |
| `cumulativeScore.Thomas` | C | 3 | `Thomas` | Audit/reference, ikke playerResult delta |
| `cumulativeScore.Peter` | D | 4 | `Peter` | Audit/reference, ikke playerResult delta |
| `cumulativeScore.Janus` | E | 5 | `Janus` | Audit/reference, ikke playerResult delta |
| `cumulativeScore.Christian` | F | 6 | `Christian` | Audit/reference, ikke playerResult delta |
| `rawCheck` | G | 7 | `Tjek` | Audit only |
| `bidderRaw` | H | 8 | `Melder` | Normaliser til canonical player id eller issue |
| `partnerRaw` | I | 9 | `Makker` | Normaliser til canonical player id eller issue |
| `dealerRaw` | J | 10 | `giver` | Normaliser til canonical player id eller issue |
| `winningBidRaw` | K | 11 | `Vindende melding` | Rå feltværdi til game metadata |
| `gameTypeRaw` | N | 14 | `Type` | Normaliseres til game type, råværdi bevares |
| `gameFlag.vip` | O | 15 | `Vip` | Audit/metadata, ikke statistik først |
| `gameFlag.goodInThree` | P | 16 | `Gode i 3.` | Audit/metadata, ikke statistik først |
| `gameFlag.goesWith` | Q | 17 | `går med` | Audit/metadata, ikke statistik først |
| `gameFlag.selfPartner` | R | 18 | `selvmakker` | Audit/metadata, ikke statistik først |
| `gameFlag.grandSlam` | S | 19 | `Storslem` | Audit/metadata, ikke statistik først |
| `score.Thomas` | U | 21 | `Thomas` | PlayerResult score delta |
| `score.Peter` | V | 22 | `Peter` | PlayerResult score delta |
| `score.Janus` | W | 23 | `Janus` | PlayerResult score delta |
| `score.Christian` | X | 24 | `Christian` | PlayerResult score delta |
| `aloneRaw` | Z | 26 | `Alene?` | Audit/metadata |
| `date` | BC | 55 | `DATO` på række 1, blank på række 3 | Session date sanity check mod `00_Regnskab_01` |

## Statistikblokke der ikke importeres som sandhed i første pass

Disse blokke må bruges til audit, men må ikke danne appens primære statistik:

| Område | Kolonner | Beslutning |
|---|---|---|
| `MED MELDING` | AB-AE | Reberegn fra normaliserede spil senere |
| `vundet` / `tabt` | AH-AI | Audit only |
| `VINDERE` | AK-AQ | Audit only |
| `TABERE` | AS-AV | Audit only |
| `MAKKER` | AX-BB | Audit only |
| `STREAKS` / `WIN / RUNDER` | BD-BH | Audit only |
| `LOOSE / RUNDER` | BJ-BM | Audit only |
| `WIN / KR` | BO-BR | Audit only |
| `LOOSE / KR` | BT-BW | Audit only |
| `SPILLEDAGE` | BY | Dropdown/helper, ignore |

## `00_Regnskab_01` auditmapping

Dimensioner ved probe:

- Rækker: 48
- Kolonner: 14
- Sessionsmetadata: række 3-35

| Auditfelt | Kolonne | Indeks | Header | Beslutning |
|---|---:|---:|---|---|
| `sessionNumber` | A | 1 | blank | Audit sessionsnøgle |
| `auditOk` | B | 2 | `ok?` | Audit only |
| `date` | C | 3 | `Dato` | Session metadata/audit |
| `finalScore.Thomas` | D | 4 | `Thomas` på række 2 | Audit total |
| `finalScore.Peter` | E | 5 | `Peter` på række 2 | Audit total |
| `finalScore.Janus` | F | 6 | `Janus` på række 2 | Audit total |
| `finalScore.Christian` | G | 7 | `Christian` på række 2 | Audit total |
| `scoreSumCheck` | H | 8 | `Samlet sum` | Audit total skal normalt være 0 |
| `expectedGameCount` | I | 9 | `Antal spil` | Audit mod importeret spilantal |
| `largestWin` | J | 10 | `Største gevinst` | Audit only |
| `largestLoss` | K | 11 | `Største tab` | Audit only |
| `location` | L | 12 | blank | Session metadata |
| `sourceAccount` | M | 13 | `Regnskab` | Audit/source note |
| `notes` | N | 14 | blank | Audit/source note |

## Kendte forventede mismatch-klasser

| Issue | Beskrivelse |
|---|---|
| `individual_sheet_limited_source` | Session bruger individuel spilledagsfane, fordi samlet-arket kun har summary/status |
| `empty_source_sheet` | Session har fane, men ingen importerbare spilrækker |
| `expected_vs_imported_count_mismatch` | Antal spil i `00_Regnskab_01` matcher ikke importerede rækker |
| `date_mismatch` | Dato fra samlet-række matcher ikke sessionsdato fra `00_Regnskab_01` |
| `score_sum_not_zero` | U-X summerer ikke til 0 for en spilrække |
| `unknown_player_name` | Navnefelt kan ikke normaliseres til canonical player |
| `missing_required_game_field` | Primært felt som session eller spilnummer mangler på en spilrække |
| `session19_manual_review_required` | Session 19 har splitfaner, dublet-spilnumre og nul-delta-række, som ikke må resolves automatisk |
