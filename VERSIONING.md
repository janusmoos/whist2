# Versionspolitik – Whist 2.0

Projektet bruger **to tal**, som Xcode også skelner mellem:

| Felt | Xcode-nøgle | Betydning |
|------|-------------|-----------|
| **Marketing version** | `MARKETING_VERSION` | Det brugerne ser (App Store, Om appen). Semantisk versioning: **MAJOR.MINOR.PATCH**. |
| **Build-nummer** | `CURRENT_PROJECT_VERSION` | Entydigt monotont heltal pr. upload til App Store Connect (og pr. TestFlight-build). |

**Aktuel marketing-version i Xcode-projektet:** **2.0.1** (minor: meldings-UI, aktivt-spil-visning, dokumentation for flere enheder).

Startværdier i dette repo var oprindeligt: **2.0.0** (marketing) og **1** (build), så 2.0-linjen er tydeligt adskilt fra Whist 0.6 / 1.0.

---

## Hvornår øges **MAJOR** (fx 2.0.0 → 3.0.0)

- Brydende ændringer for brugerdata (fx ny database-model **uden** migration fra 2.x).
- Skift af bundle-id / “ny app” i butikken, hvis I bevidst starter forfra uden opdateringssti.
- Større omskrivning, hvor I kommunikerer “helt ny produktgeneration” udadtil.

---

## Hvornår øges **MINOR** (fx 2.0.0 → 2.1.0)

- Nye **funktioner** eller større flows (fx første scoreboard, import fra legacy, iCloud).
- Nye skærme, der udvider produktet mærkbart.
- Mindre breaking ændringer i interne API’er, som **ikke** kræver ny major for brugerne.

Nulstil ikke build-nummer ved minor (fortsæt blot +1 på build ved hver upload).

---

## Hvornår øges **PATCH** (fx 2.0.0 → 2.0.1)

- Fejlrettelser og små justeringer uden nye features.
- Performance, crash-fixes, tekst-/UI-rettelser.
- Sikkerheds- eller kompatibilitetsfixes (fx til ny iOS), når funktionssættet er uændret.

---

## Hvornår øges **build-nummer** (`CURRENT_PROJECT_VERSION`)

- **Altid** ved hver build, der uploades til **TestFlight** eller **App Store** (1 → 2 → 3 …).
- Valgfrit internt: I kan også bump’e ved hver CI-artefakt, hvis I vil skelne builds uden at ændre marketing-version.

Regel: Build skal **aldrig** genbruges for et givet bundle-id i App Store Connect.

---

## Praktisk workflow

1. Udvikling på samme marketing-version (fx 2.0.0) med stigende build, indtil I udgiver.
2. Ved release til brugere: sæt marketing-version efter reglerne ovenfor; build fortsætter eller sættes højere end sidste upload.
3. Hold **Whist20**- og **Whist20Tests**-targets synkroniseret (samme `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION`), medmindre I bevidst afviger.

---

## Relation til git

- **Git tags** kan følge marketing-version: `v2.0.0`, `v2.1.0`.
- Tag **inkluder build** kun hvis I har brug for det (fx `v2.0.0-b42`); ellers er build historik nok i App Store Connect / CI.
