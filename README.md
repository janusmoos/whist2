# Whist 2.0 (iOS)

Dette er den primære (“mainline”) version af Whist-appen.

## Åbn i Xcode

- Åbn: `Whist20.xcodeproj`

```bash
open "Whist20.xcodeproj"
```

## Kør tests (Simulator)

```bash
xcodebuild \
  -project "Whist20.xcodeproj" \
  -scheme "Whist20" \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  test
```

Hvis du har en anden simulator tilgængelig, kan du skifte `name=...` i destination.

## Snapshots (arkivkopier)

Snapshots ligger i `Snapshots/` og kan laves sådan:

```bash
./Scripts/make-snapshot.sh
```

Se også:
- `VERSIONING.md` (marketing-version vs build-nummer, og foreslåede git-tags)
- `MULTI_DEVICE.md` (overblik over fler-enheds-sync og anbefalet retning)

