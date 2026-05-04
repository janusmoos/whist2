# Snapshots – Whist 2.0

Her ligger **komplette kopier** af Xcode-projektet på bestemte tidspunkter, så du kan åbne en ældre mappe og fortsætte udvikling derfra uden git.

## Navnekonvention

Hver snapshot-mappe hedder:

`Whist20-<MARKETING_VERSION>-<YYYY-MM-DD>`

Fx `Whist20-2.0.0-2026-05-03`.

## Sådan går du tilbage og arbejder videre

1. **Luk** evt. åbent Whist20-projekt i Xcode.
2. Find den ønskede mappe under `Snapshots/`.
3. Dobbeltklik **`Whist20.xcodeproj`** i netop den mappe (eller **File → Open** i Xcode og peg på den snapshot-mappe).

Det er en **selvstændig kopi**; ændringer her påvirker ikke hovedmappen og omvendt, medmindre du kopierer filer manuelt.

## Nyt snapshot (fremover)

Fra projektroden (`whist 2.0/`):

```bash
./Scripts/make-snapshot.sh
```

Scriptet læser `MARKETING_VERSION` fra `Whist20.xcodeproj` og bruger dagens dato. Valgfrit første argument: fast dato til test, fx `./Scripts/make-snapshot.sh 2026-05-03`.

## Indhold

Hvert snapshot er en `rsync`-kopi af projektet uden:

- `Snapshots/` (undgår rekursion),
- `.DS_Store`,
- `xcuserdata` (maskinspecifik Xcode-data).

Vil du have brugerdata med i et snapshot, kan du tilføje det manuelt bagefter.

## Samme dato to gange

Scriptet fejler, hvis destinationsmappen findes. Til endnu et snapshot samme dag kan du fx midlertidigt sætte marketing-version i Xcode eller omdøbe den eksisterende snapshot-mappe manuelt.

## Tip

Overvej **git** i hovedmappen til daglig historik; snapshots er et supplement til veldefinerede «arkiver» du kan åbne år senere.

I `.gitignore` er kun mapperne `Snapshots/Whist20-*` udeladt fra git (store kopier); **`Snapshots/README.md`** kan gerne committes.
