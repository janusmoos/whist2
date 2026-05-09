# Teknisk handoff – Whist 2.0

Dokument til nye coding-agents (eller mennesker). Opdater det, når arkitektur eller vigtige beslutninger ændrer sig.

**Vigtigt (GitHub-klon):** I repoet `janusmoos/whist2` ligger Xcode-projektet i **repo-roden** (`Whist20.xcodeproj`, mappe `Whist20/`). Der er **ingen** undermappe `whist 2.0/` i den officielle klon.

---

## Projekt og repo

- **Primær app:** SwiftUI iOS-app **Whist 2.0** (target **Whist20**).
- **Åbn i Xcode:** `Whist20.xcodeproj` i **repo-roden** (se også `README.md`).
- **Git:** `origin` → `git@github.com:janusmoos/whist2.git` (typisk branch `main`).
- **Legacy / andre træk:** Ældre eksperimentelle mapper findes evt. lokalt uden for dette repo — **rediger kun denne klon** medmindre opgaven eksplicit siger andet.

---

## Opstartstjek: GitHub, mappe og parallel udvikling (Cursor + Codex)

**Formål:** Sikre at Codex (eller en anden agent/IDE) arbejder mod **det rigtige repo**, i **den rigtige mappe**, og på en måde der **tåler samtidig udvikling i Cursor**.

Udfør disse punkter **før** du retter kode eller kører builds.

### 1. Korrekt GitHub-repo og remote

- **Kanonisk repo:** `janusmoos/whist2`
- **SSH:** `git@github.com:janusmoos/whist2.git`
- **HTTPS:** `https://github.com/janusmoos/whist2.git`

**Tjek (kør i repo-roden — den mappe der indeholder `Whist20.xcodeproj` og `.git`):**

```bash
git rev-parse --show-toplevel
git remote -v
git status -sb
```

Forvent at `origin` peger på `janusmoos/whist2` (fetch/push).  
**Hvis du får `fatal: not a git repository`:** du er ikke i klonen — åbn den rigtige mappe (fx `whist2-repo`), ikke en overmappe uden `.git`.

### 2. Åbn den rigtige mappe i værktøjet

- **Korrekt rod:** mappen der indeholder **`Whist20.xcodeproj`**, **`Whist20/`** og **`.git`** (ét og samme sted).
- Codex/Cursor “peger på GitHub” ved at **åbne den lokale git-klon** — ikke et tomt sandbox-workspace og ikke en mappe uden `.git`.
- Eksempel på sti (din maskine): `/Users/moos/Documents/_Cursor/whist2-repo` — **tilpas hvis din klon ligger et andet sted.**

### 3. Synk før arbejde

```bash
git fetch origin
git pull --rebase origin main   # eller den branch teamet bruger som hovedlinje
```

### 4. Branch så Cursor og Codex ikke træder hinanden over tæerne

| Gør | Undgå |
|-----|--------|
| Kortlivet branch pr. opgave (`feature/...`, `fix/...`) | To værktøjer der committer løst på samme branch uden pull/push mellem |
| Commit og **push** ofte til din branch | Store, umergede lokale ændringer i uger |
| Flet via PR eller eksplicit merge når færdigt | At antage at værktøjer “deler filer” uden git — de deler **repo via GitHub** |

Regel: **én sandhed = GitHub**; Cursor og Codex er to arbejdsstationer mod samme remote.

### 5. Mini-checkliste før første commit i en session

- [ ] `git rev-parse --show-toplevel` viser en mappe med `Whist20.xcodeproj`
- [ ] `git remote -v` viser `janusmoos/whist2`
- [ ] `git pull` (eller rebase) er kørt på den branch jeg bygger videre på
- [ ] Jeg arbejder på en **egen branch** hvis nogen anden kan røre samme kode i Cursor samme dag
- [ ] Efter ændringer: `git push` så andre kan hente

### 6. Backlog og koordinering

- **Produkt-backlog:** `docs/issues_local.txt` (opdateres efter behov).
- **Cursor + Codex samtidig:** `docs/PARALLEL_WORK.md` — branches, ejerskab af mapper (fx `docs/statistik/`), og næste skridt pr. værktøj.
- GitHub-issues: `docs/issues.md` og `gh issue list -R janusmoos/whist2`.

Angiv gerne **issue eller backlog-punkt** i commit-besked eller PR.

---

## Arkitektur (kort)

| Lag | Indhold |
|-----|--------|
| **App-entry** | `Whist20/Whist20App.swift` — `ModelContainer` med **egen store-sti** (`Application Support/Whist20/game.store`); ved skema-fejl slettes lokale store-filer én gang og der retries. |
| **Persistence** | **SwiftData** — modeller under `Whist20/Persistence/` (`GameDay`, `RecordedHand`, `PendingHand`). Én **pending hand** pr. spilledag. |
| **Domæne** | `Whist20/Domain/` — bl.a. `ScoringEngine`, `WhistGameTypes`, `Seat`, `GameDayScoreAggregation`, `MeldingPresentation`, `StandingsPresentation`. |
| **Features (UI)** | `Whist20/Features/` — `HomeView`, `MainTabShell`, `AddHandView`, `SenesteSpilView`, `ActiveGameView`, `ScorecardView`, osv. |
| **Navigation** | `Whist20/ContentView.swift` — faner, `NavigationPath`, sheet til `AddHandView`, toast, bundmenu via `safeAreaInset`. |

**Bundmenu:** `MainTab` i `Whist20/Features/MainTabShell.swift`.

**Multi-device:** Se `MULTI_DEVICE.md` — ingen reel realtidssync mellem telefoner uden CloudKit/backend.

---

## Beslutninger der bør respekteres

1. **Én aktiv spilledag / én pending** — håndhæves via data og UI.
2. **Spillerrækkefølge** — `GameDay.seatOrderJSON` + `Seat`, dealer-rotation.
3. **Præsentation** — resumé m.m. samles i domæne/præsentationslag.
4. **Versionering** — `VERSIONING.md`.
5. **SwiftUI/iOS** — se evt. `.cursor/rules/` i workspace for projektregler.

---

## Uløste eller delvist uløste problemer

Se backlog-fil (lokal) og `docs/issues.md`. Tekniske spor: multi-device sync, pending efter gem, bundmenu-navigation, halve+trumf-flow, resumé-sprog, redigering fra seneste spil, import/backup — detaljer i tidligere noter eller issues.

---

## Relevante filer (alle under `Whist20/` eller `Whist20Tests/`)

| Område | Filer |
|--------|--------|
| Rod-UI + tabs | `Whist20/ContentView.swift`, `Whist20/Features/MainTabShell.swift`, `HomeView.swift`, … |
| Melding/resultat | `Whist20/Features/AddHandView.swift`, `Whist20/Persistence/HandDraftPersistence.swift`, `PendingHand.swift` |
| Seneste spil | `Whist20/Features/SenesteSpil*.swift`, `HandDetailView.swift` |
| Aktivt spil | `Whist20/Features/ActiveGameView.swift` |
| Domæne | `Whist20/Domain/*.swift` |
| Tests | `Whist20Tests/*` |

**Dokumentation i repo-roden:** `README.md`, `MULTI_DEVICE.md`, `VERSIONING.md`, `DISTRIBUTION.md`, `docs/issues.md`.

---

## Kommandoer (kør i repo-roden)

```bash
open "Whist20.xcodeproj"

xcodebuild \
  -project "Whist20.xcodeproj" \
  -scheme "Whist20" \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  test

./Scripts/make-snapshot.sh
gh issue list -R janusmoos/whist2
```

---

## Næste skridt (forslag)

1. Byg i Xcode, kør tests.
2. Prioritér bugs fra backlog / issues.
3. Parallel udvikling: følg **Opstartstjek** ovenfor; tag releases efter `VERSIONING.md`.

---

## Første filer for en ny agent

1. Udfør **«Opstartstjek»** (især `git rev-parse --show-toplevel` og `git remote -v`).
2. Læs **`TECHNICAL_HANDOFF.md`** (denne fil) og **`Whist20/ContentView.swift`**.
3. Læs **`MULTI_DEVICE.md`** hvis opgaven berører flere enheder.
