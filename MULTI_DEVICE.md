# Flere telefoner og «aktivt spil» (Whist 2.0)

## Status i dag (2.0.1)

- **SwiftData** og `PendingHand` ligger **kun lokalt** på den enhed, der har oprettet kladde.
- Skærmen **«Aktivt spil»** læser den samme lokale `PendingHand` og er dermed et **orienterings-/læse**-lag for dem, der står med den telefon.
- **Alle kan i princippet indtaste** på den ene enhed; reglen *«kun én ad gangen»* og *«ikke nyt spil mens et aktivt findes»* håndhæves her ved, at der **højst én `PendingHand` pr. spilledag** findes, og at startsiden kun tilbyder **«Fortsæt aktivt spil»** (samme ark som ved melding/resultat), ikke et ekstra parallele kladde-flow.

## Det I mangler for rigtig fler-enheds-sync

For at **fire telefoner** ser den samme opdaterede melding i realtid, skal I vælge én (eller kombinere) af:

1. **CloudKit + SwiftData** (Apple): delt database eller synk af records; kræver Apple-id, tilstandsmaskine for konflikter og ofte **«hvem må skrive»** (rolle eller lease/lock i skyen).
2. **Egen backend** (REST/WebSocket): spilledag som «rum», klienter abonnerer; server tildeler **skrivelease** (fx 30 s) til én spiller ad gangen.
3. **Kort levetid QR / kode** + server: alle joiner samme session; samme lock-logik.

## Anbefalet produktlogik (når sync findes)

- **Visning**: alle kan se «Aktivt spil» (read-only).
- **Indtastning**: kun den der holder **aktiv lås** (eller alle med «anmod om tur») må ændre melding/resultat; server/CloudKit afviser andre writes.
- **Nyt spil**: tillad først når der **ikke** er pending *og* ingen «åben session» — matcher jeres ønske om ikke at starte nyt oven i et aktivt.

## Kontakt

Når I har valgt teknologi (CloudKit vs. egen server), kan meldings-JSON (`HandDraftPersistence`) genbruges som wire-format eller mappes til jeres API.
