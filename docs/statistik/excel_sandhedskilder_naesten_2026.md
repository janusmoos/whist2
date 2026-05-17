# Excel-arbejdsbog: sandhedskilder for ny historisk import (maj 2026)

## Fil og versionsstempel

- **Fil:** `Whist – resultater – samlet (2024)_AKTIV_forenkling af data.xlsx`
- **Kontrolleret lokalt:** arklisten er læst fra `xl/workbook.xml` (maj 2026-udgaven med arknavne som nedenfor).

Arkbogen indeholder i alt **56 faner**. De to faner du har udpeget som sandhedskilder for den **nye** pipeline er begge til stede:

| Ark | Status i filen |
|-----|----------------|
| `00_Regnskab_01` | Findes |
| `SAMLET_alle regnskab_16-5-2026` | Findes |

Der findes også et ældre aggregeringsark **`SAMLET_alle regnskab`** (uden dato-suffiks). Det er **ikke** udpeget til den nye pipeline; det bør ikke blandas uden eksplicit beslutning, da to samletfaner nemt divergerer over tid.

## Rollefordeling mellem de to sandhedsark

Formålet skal dokumenteres ved implementering. Anbefalet tolkning (kan justeres ved team-beslutning):

### `00_Regnskab_01`

Typisk rolle:

- Session-/spil-/regnskabsmetadata på **makroniveau** (forventede antal spil pr. spilledag, måske dato eller reference til faner osv.—afhænger af læsevenlig layout i arket).

Brug ved import:

- **Validering:** afstem importeret spilliste mod forventede tællere, hvor arket eksplicit angiver dem.
- **Sessionmapping:** hjælp til konsistent navngivelse af `sessionNumber`/`sourceSheetName` i output-JSON.

### `SAMLET_alle regnskab_16-5-2026`

Typisk rolle:

- **Den mest kompakte ”flade” liste** af spillinjer og afledte kolonner (melder, giver, spiltype, kumulative scorer, streaks mv.), som blev analyseret i CSV-eskperimentet.

Brug ved import:

- Primær eller sekundær **spil‑for‑spil** sandhed ved den nye import: en række pr. officielt spil, med kolonneindeks/fast mapping i import-specifikationen.

**Vigtigt:** Kombinationen af to sandhedskilder kræver en **konflikt-/prioritetsliste** i importdokumentet (se `historisk_data_reproducerbarhed_og_versionsstyring.md`). Fx: hvis `00_Regnskab_01`s forventede antal spil ikke stemmer med antal spillinjer på `SAMLET_alle regnskab_16-5-2026`, skal importeren klassificere mismatchet og logge det i audit (ikke kun stille falde tilbage på én kolonne).

## Andre relevante faner i samme workbook (uden at være sandhedskilder)

Arbejdsbogen indeholder mange spilledagsfaner (fx `01_21-06-2016`, … , `31_…`) samt dubletter/forsøg (fx `_26_30-11-2024 …`, variationer på `31_22-11-2025`). De er **potentielle** kilder til manuel eller halv-automatisk fejlfinding, men må ikke importeres ”for sjov” ved siden af de to udpegede ark, medmindre I udvider sandhedsmodellen.

**Observation:** arknavne viser spilledage ud over det, der traditionelt lå i første bundled JSON‑import (fx `27_28-03-2025_Dyrhaven` … `31_22-11-2025_…`). Det er den forventede **gevinst** ved at definere ny kilde ud fra aktuel Excel-version fremfor at fastholde kun et gammelt snapshot.

Faner udtrykkeligt uønskede til sandhed tidligere (jf. overlappende docs som `examples/v02/CODEX_HANDOFF_WHIST_IMPORT.md`): `STATISTIK_*`, `TEST_*`, `Claude Cache`, `_skabelon`, mange `d_*` og diagram/cache-faner. **Bevar denne liste** i importkonfigurationen som `ignoreSheets` eller tilsvarende.

## Næste tekniske skridt oven på denne gennemgang

1. Læse **begge** ark i python/Swift-script og udskrive én rapport: kolonnenavne/indekser pr. ark, første/ sidste datablok og antal databrækkende rækker.
2. Oprette et **feltkort**: hvilken JSON-struktur hver importeret kolonne fylder (`HistoricalGame`, `HistoricalPlayerResult`, udvidelser eller nye strukturer ved behov).
3. Afstem totals med `HistoricalAuditSummary` og issues som i v2 (eller `auditSummary`/issues i en ny semver).

Se også: `dual_source_histories_statistik_brugerflade.md` og `historisk_data_reproducerbarhed_og_versionsstyring.md`.
