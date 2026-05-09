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

## GitHub issues (hurtige kommandoer)

```bash
# Liste issues
gh issue list -R janusmoos/whist2

# Se et issue (fx #1)
gh issue view 1 -R janusmoos/whist2 --web

# Start arbejde på et issue (lav branch og gå i gang)
git checkout -b issue-1-sol-wheel

# (Når du er klar) lav PR der lukker issue
gh pr create -R janusmoos/whist2 --title "Issue #1: Sol-type som wheel" --body "Closes #1"
```

Se også:
- `TECHNICAL_HANDOFF.md` (arkitektur, opstartstjek for Cursor/Codex, filer og kommandoer)
- `VERSIONING.md` (marketing-version vs build-nummer, og foreslåede git-tags)
- `MULTI_DEVICE.md` (overblik over fler-enheds-sync og anbefalet retning)

