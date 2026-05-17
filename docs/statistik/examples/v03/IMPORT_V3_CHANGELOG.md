# Whist import v3 - changelog

## 3.0.0-draft

Oprettet: 2026-05-17

### Added

- Dokumenteret v3 som nyt kildespor med `SAMLET_alle regnskab_16-5-2026` som primær spil-for-spil-kilde.
- Dokumenteret `00_Regnskab_01` som audit-/kontrolkilde, ikke som felt-overstyrende sandhed.
- Fastlagt at v2/legacy bevares immutable og skal kunne vælges eksplicit i appen.
- Tilføjet første faste kolonnemap for v3 med 1-baserede indeks, Excel-kolonner og header-fingeraftryk.
- Tilføjet manifest-template for reproducerbar import.
- Tilføjet read-only audit-script og første audit-output for workbooken.
- Tilføjet bekræftet navnenormalisering for stavevarianterne `Chrisitan`, `Jan`, `Janjusz`, `Jnaus`, `Peer`, `Janiz`, `Janjus` og `Jansicz`.
- Tilføjet bekræftet selvmakker-regel for `Selvmakker` og `Selv makker`, inkl. at `Melder = Selvmakker` får melder fra kolonne J.
- Tilføjet bekræftet split-regel for sammensatte `Melder`-værdier: første navn er melder, andet navn er makker.
- Tilføjet hybridregel for session 1-7: individuelle faner bruges som begrænset kilde for 1-4 og 6-7, mens session 5 er tom audit-kilde.
- Accepteret session 3 som 22 reelle spil; tomme formelrækker efter række 25 ignoreres.
- Accepteret session 4 som 29 reelle spil; `00_Regnskab_01` forventet 30 bevares kun som auditværdi.
- Accepteret session 8 som 50 reelle spil; `00_Regnskab_01` forventet 51 bevares kun som auditværdi.
- Tilføjet genereret `session19_combined_order.csv` med samlet rækkefølge for session 19 på tværs af 19a/19b/19c.
- Flagget session 19 som `session19_manual_review_required` i stedet for at resolve dublet-/nul-delta-rækker automatisk.
- Bekræftet `00_Regnskab_01` som sandhed for sessiondato/sted; samlet-arkets dato er audit-only.
- Besluttet at inkludere session 19 i v3-bundlen med `manualReviewRequired` flag.
- Tilføjet `whist_import_v3.py`, `whist_historical_data_v3.json`, `IMPORT_V3_REPORT.md` og `import_manifest_v3.generated.json`.
- Første v3-bundle indeholder 32 sessions, 903 spil og 3.612 playerResult-rækker.
- Tilføjet totalafstemning mellem `00_Regnskab_01` og `SAMLET_alle regnskab_16-5-2026`.
- Dokumenteret kendt midlertidig kontrolarksfejl for session 27: `00_Regnskab_01` har `Christian = -72`, mens primærkilden korrekt har `Christian = -76`.

### Changed

- Importstrategien skifter fra v2's spilledagsfaner til v3's samlede regnskabsark som primær kilde.
- Session 1-4 og 6-7 behandles som individuel begrænset kilde, fordi den nye primære samlearkskilde ikke indeholder spilrækker for 1-7.
- Audit-scriptet skelner nu mellem almindelige totalafvigelser (`control_total_mismatch`) og den snævre kendte session 27-fejl (`known_control_total_error`).

### Not Yet Implemented

- App-loader/facade med default primary v3 og eksplicit legacy v2-valg.
- Golden tests der sikrer, at v2 ikke ændres af v3-arbejdet.
