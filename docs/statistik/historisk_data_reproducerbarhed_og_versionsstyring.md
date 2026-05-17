# Reproducerbarhed af normalisering og versionsstyring (historiske data)

Når historisk whist-data flyttes til en **ny importkilde**, skal gamle normalizationregler stadig kunne **genskabes deterministisk** og bundles skal kunne udskilles med **semver + manifest**. Dokumentet beskriver hvordan jeres repo forbliver ”sandhedsarkiv”, og hvordan I undgår uopdagede drift‑ændringer.

---

## 1. Hvorfor reproducibility ikke er automatisk

- Samme `.xlsx` kan **ændres uden semver** ved små arkrettelser.
- Samme importer kan give forskellige resultater ved forskellige **Python**/bibliotheks‑versioner.
- Appens **Swift‑models** kan udvides uden at JSON forbliver kompatibel.

Konklusion: hver officiel datapakke MÅ have et **manifest** som knytter `(workbook_revision, importer_git_sha, tooling_versions)` til output‑checksummer.

---

## 2. Katalog over normaliseringsregler (begge spor)

Alle regler der påvirker `HistoricalWhistData` skal liste ét sted. Opdel eksplicit pr. spor:

### Spor **Legacy** (`v2` …)

- Primær dokumentation og referenceimplementation:  
  `docs/statistik/examples/v02/CODEX_HANDOFF_WHIST_IMPORT.md`
- Python‑prototype:  
  `docs/statistik/examples/v02/whist_import_audit_v2.py`
- Efterkoblede eller manuelle corrections:  
  `docs/statistik/historical_quality_corrections.md`,  
  `docs/statistik/session26_reimport_analysis.md`,  
  `docs/statistik/tools/`

**Regel‑typer:** ignorer‑arkliste, duplet ark‑navne (`22` vs `22b`), kolonne-/header‑detektion, kumulativ vs delta‑kolonnerav, navnenormaliserings­map, issue‑taxonomy (`score_sum_not_zero` osv.)

### Spor **Ny kilde** (Excel + manifest `…_naesten_2026` …)

Sandhedsarke (brugerkonfig maj 2026):

- `00_Regnskab_01`
- `SAMLET_alle regnskab_16-5-2026`

**Regel‑typer der skal skrives NU** (mens de er friske):

- Hvilke ark ignoreres (standardliste fra CODEX‑sektion udvid med nye regler ved behov).
- Hvordan første/metadata‑rækker springes på `SAMLET_*` ark.
- Kolonne til felt‑mapping inklusive duplikat kolonneoverskrifter (flere kolonner ved navn ”Thomas”; brug stabile indeks + header‑fingeraftryk).
- Melder-/makker-/giver‑string normalisering udvidelse (fx slash, `Peter+Christian`, trailing spaces).
- **Prioritet** ved konflikt: eksempelvis `expectedGameCount` fra `00_Regnskab_01` overstyrer automatisk ikke spilscores — men må udløse `expected_vs_imported_count_mismatch` i audit output.

Alle nye felter eller ændringer i normalization skal annoteres:

| Regel-id | Kilde ark | Tekstbeskrivning | Fra commit / dato |

---

## 3. Artefakter der skal opbevares sammen PR build

Minimal sæt (udvid efter jeres conventions):

| Artefakt | Beskrivelse |
|----------|-----------|
| `whist_historical_data_<SEMVER>.json` | Bundfil til Xcode |
| `import_manifest_<SEMVER>.json` | Fingeraftryk & metadata |
| `issues_<SEMVER>.csv` | Valideringsissues |
| Evt. `IMPORT_<SEMVER>_REPORT.md` | Menneskelig læsbar QA |

Eksempel på **manifest‑felter** (tilpas navne):

```json
{
  "bundleSemver": "3.0.0",
  "generatedAtUtc": "...",
  "sourceWorkbook": {
    "fileName": "Whist ... .xlsx",
    "sha256": "<checksum af hele filen før import>"
  },
  "truthSheets": ["00_Regnskab_01", "SAMLET_alle regnskab_16-5-2026"],
  "importerRepo": {...},
  "importerGitCommit": "...",
  "pythonVersion": "3.13.x",
  "openpyxlVersion": "...",
  "outputSha256": { "fullBundle": "..." }
}
```

`HistoricalWhistData.version` må gerne ligne `"3"` eller SemVer-streng konsistent med manifest — men **Git commit matcher manifest**, ikke kun JSON‑felt.

---

## 4. Bump‑regler og brud

Bump **minor** ved:

- nye spildage eller rækker som kun tilkommer workbook.

Bump **major** eller **explicit compatibility flagging** ved:

- ændret session‑opdeling (fx sammenfoldning eller split),

- ikke‑bagud‑kompatible id‑formats,

- ophævet semantisk betydning af felt.

Alle major‑spring skal dokumenteres i `IMPORT_<major>_CHANGELOG.md`.

---

## 5. Sikring af at legacy IKKE regresserer ved udvikling

1. Lad `whist_historical_data_v2.json` (eller navngiv dit legacy snapshot) forbliver bundlet til **golden tests**.

2. Udstil testdata side‑by‑side:

   ```
   XCTAssertEqual(summaryTotalPrimary, …)
   XCTAssertEqual(summaryTotalLegacy, …) // må ikke ændre sig ved kode refactor uden dokumenteret regeneration
   ```

3. Importmotor for ny spor kører i CI med **fixture `.xlsx` fragment** eller redigeret mikro workbook når muligt (hurtig regressionsdetekt).

---

## 6. Kobling til aktuel kodestruktur

`HistoricalDataJSONLoader` tager ét `resourceName` (default `whist_historical_data_v2`). En reproducer‑venlig udvidelse:

- enums `HistoricalDataPack` { case primary; case legacyV2Fixed }
- map til resource-navne + dokumenterede semver i manifest i bundle.

---

## 7. Åbne punkter hvor dokumentation IKKE må gætte sig frem – beslut før implementering

1. **`00_Regnskab_01` vs `SAMLET_alle …` konkret felt‑prioritet** – skal dokumenteres første gang begge parses i samme kørsel.
2. Ark med delte/forvirrende spillere eller dubletter **`31_*`‑varianter** – hvilket ark styrer samme spilledag‑nummer officielt ved ny spor?
3. Skal agg‑kolonner (streak/kr‑blokke) på samlet ark **importeres** eller blot **beregn på ny** i Swift (anbefalet: først ikke importere udover audit hvis målet er konsistens dynamisk)?

Når punkterne er lukket → flyt konklusioner ind i kolonne-/mapping‑listen i dette dokumentars søsterfil `excel_sandhedskilder_naesten_2026.md`.

---

## 8. Krydsreferences

| Emne | Fil |
|------|-----|
| Bruger-visible kilde‑valg og legacy opt‑in UX | `dual_source_histories_statistik_brugerflade.md` |
| Bekræftede ark i Excel | `excel_sandhedskilder_naesten_2026.md` |
| Legacy import v2 filosofi og JSON-form | `examples/v02/CODEX_HANDOFF_WHIST_IMPORT.md` |
