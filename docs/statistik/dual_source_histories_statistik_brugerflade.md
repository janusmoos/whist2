# To kilder til historisk statistik: brutto-krav, udvalgte data og tilbagekobling til legacy

Denne tekst beskriver **produktfeltet og princippet** bag at have en **primær ny kilde** og en **bevaret legacy-kilde**, som kun må bruges ved eksplicit ønske. Den erstatter ikke kodeimplementering; den fastlægger beslutningsrammen så ingen senere måned utilsigtet ødelægger mulighed for sammenligning eller tilbagevenden.

---

## 1. Mål og rammer

1. **Standard i app:** Statistik udregnes fra den **aktuelle aftalte databundle** (fremtidig `v_next` eller `v3`; i denne repo findes bundle-navne som `whist_historical_data_v2`).
2. **Legacy-kilden** (bundlet eller logisk ækvivalent til `…_v2` + dokumenterede corrections) forbliver **immutable** på versionsniveau: den ændres ikke bagudrettet ved nye forsøg; opdateringer sker ved at udgive en **ny semver** eller et nyt resource-navn.
3. Legacy er **ikke** standard og må **kun** eksponeres, når brugeren aktivt aktiverer det (jf. §3).
4. Brugeren skal **altid kunne vende tilbage** til samme stadie som før aktiveringen af legacy (uden data-tab af den aktive kilde).

---

## 2. Begrebsliste

| Begreb | Forklaring |
|--------|-----------|
| **Aktiv kilde** | Den datapakke importeren/UI bruger til at vise statistik på et givent tidspunkt. |
| **Primær bundle** | Produktbundlet ”rigtigt” udtryk af aktiv kilde til slutbrugere (uden debug). |
| **Legacy-bundle** | Ældre fastfrosset datapakke (eks. generation fra per-fane importer + dokumenterede rettelser). |
| **Kildeskift** | Bruger (eller kun udviklerrutine som du beder om) aktiverer en anden fastlagt datapakke. |
| **Genskabelighed** | Evnen til at regenerere samme bundle fra pinned kilde-kode og kilde‑Excel med samme checksum (jf. reproducibility-doc). |

---

## 3. Adgang til legacy: ”kun hvis eksplicit bedt om det”

Krav kan opfyldes med **flere konkrete mønstre** (vælg ét og dokumentér det i Xcode / release notes):

### Anbefalet: skjult eller udvikler-trigger

1. **Ingen toggle i vanilla Indstillinger** for slutbrugere.
2. **Eksplicit opt-in**, fx:
   - en skjult handlingssekvens (fx tryk‑hold på statistiktitlen N gange og bekræft),
   - eller kun synlig toggles i `_DEBUG`/`#if DEBUG` builds,
   - eller kun i Enterprise/TestFlight‑profilen.

Formålet er at undgå, at ”tilfældige” brugerfejl tolkning af statistik sammenholder med dokumentation eller support‑sager.

### Hvis toggle skal være synlig til dig alene på enhed

- Brug fx **kun synlig ved at indtaste en kode** eller **kun når icloud-debug-flag er sat**.
- Alle stier der kan vælge legacy skal skrive **persistens-flag** eller logge aktiv kilde‑id (kun lokalt!), så fejlrapporter vedhæfter aktiv kilde.

---

## 4. Persistens og tilbagekobling i app‑laget

Minimal logik der bør dokumenteres/implementeres:

| Data | Handling |
|------|----------|
| `activeHistoricalResourceName` eller `HistoricalDataSourceId` enum | Gemmes i `UserDefaults`/Keychain-afhængig af sensitivitet. |
| Første kørsel efter upgrade | Migrér eksisterende brugerkonfig til default `primary`; legacy vises ikke. |
| Ved skift Legacy → Aktiv primær | Fjern eller overskrive kun **valg‑flag**, ikke selve bundles (bundfiler er stabile assets). |

**Vigtigt:** Statistikberegninen skal ikke blande datasæt på tværs af spil-ID’er på én graf. Enten/ind eller tydelig advarsel ved sammenstillingsmodus senere versionsmulighed).

---

## 5. Udtryk til bruger i UI (forslag)

Når aktiv kilde er primær bundle:

> Historisk statistik bygger på **dato‑mærket** dataset [vis `generatedAt` / version fra JSON].

Ved aktiv legacy‑kilde:

> Aktiv dataset: **Lagret historik v2**. Dette matcher den tidligere importmetode. Skift til ny kilde via [skjult sti eller debug].

---

## 6. Acceptance-kriterier (for implementering eller review)

1. Fra clean install finder bruger **kun** ny primær bundle (hvad dén nu hedder ved release).
2. Legacy-bundle findes stadig inde i applikationsbundelen som separat `.json`-resource (eller lignende), men **`HistoricalDataJSONLoader`** læses med resource-navne afledt af aktiv‑kilde-flag.
3. Vælg legacy → luk app → åbn → **stadig legacy** til valgte flag nulstilles.
4. Nulstil til primær bundle → ingen rester af blandet cache i hukommelse (reload af `HistoricalWhistData` fra ønsket loader).
5. Statistik‑UI kan vise aktiv **version-/generatedAt‑streng** så dokumentation kan matches til git‑commit/import‑manifest.

---

## 7. Relaterede dokumenter

- `historisk_data_reproducerbarhed_og_versionsstyring.md` — hvordan regler peges tilbage til git/import‑motor.
- `excel_sandhedskilder_naesten_2026.md` — hvilke faner Excel der er sandhed for ny kilde.
