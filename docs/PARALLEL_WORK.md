# Parallelt arbejde – Cursor og Codex

**Formål:** Ét sted i repo’et som **begge** værktøjer (og du) læser ved session-start: hvilke **branches**, hvilket **ejerskab** af mapper, og hvad der er **i gang / næste skridt** på hver side.

For overordnede branch- og arkitekturbeslutninger, se også `docs/architecture/branch_and_architecture_decisions.md`. Den fil er den levende beslutningslog for parkerede spor, merge-strategi og arkitekturretning.

**Regel:** Opdater denne fil når I skifter fokus, merger til `main`, eller overtager en mappe — og **commit + push** så den anden part ser det efter `git pull`.

---

## Aktive branches (udfyld og hold ajour)

| Spor | Branch-navn | Primært ansvar |
|------|----------------|----------------|
| **Fælles linje** | `main` | Aktuel sandhed for app, statistik, performance og Dark Mode |
| **Live statistik (Codex)** | `codex/live-statistics-integration` | Aktivt spor: integrere data fra live spil i hele statistik-modulet |
| **Web/live-overblik (Codex/Cursor)** | `codex/web-live-overblik-plan` | Aktiv planbranch: rammer, performancekrav og næste udviklingsplan for web/live-overblik |
| **Performance-reference** | `codex/performance-refactor-plan` | Parkeret snapshot, ikke aktiv udviklingsgren |
| **Design-reference** | `codex/design-experiments` | Parkeret snapshot, ikke aktiv udviklingsgren |
| **Dark Mode-reference** | `codex/dark-mode` | Merged til `main`; kan slettes senere |
| **Historisk statistik-reference** | `feature/statistics-historical-data` | Parkeret historisk gren; merge ikke direkte |
| **Datakvalitet-reference** | `codex/fix-historical-quality-notes` | Parkeret historisk gren; merge ikke direkte |

*Ret tabellen når branches oprettes, merges, parkeres eller slettes. Opdater samtidig `docs/architecture/branch_and_architecture_decisions.md`.*

---

## Ejerskab (undgå konflikter)

| Område | Hvem må committe her? |
|--------|------------------------|
| `docs/statistik/` | Koordineres eksplicit, især hvis ændringer berører v3-data/audit |
| `Whist20/**/*.swift`, assets, UI | Koordineres eksplicit, især ved Dark Mode, performance eller navigation |
| `docs/PARALLEL_WORK.md` | **Begge** — korte opdateringer når status ændrer sig |
| `docs/architecture/branch_and_architecture_decisions.md` | **Begge** — opdateres ved arkitektur- og branchbeslutninger |

Ved støj fra lokale mapper: brug `.git/info/exclude` lokalt. Se `TECHNICAL_HANDOFF.md`.

---

## Checkliste ved ny session

### Cursor (design)

- [ ] `git fetch origin && git checkout main && git pull --rebase origin main`
- [ ] Læs **Næste skridt – Cursor** nedenfor
- [ ] Opret kortlivet branch fra `main`, hvis arbejdet ikke er en helt simpel dokumentationsopdatering

### Codex (statistik / funktioner)

- [ ] Åbn **samme repo-klon** (mappe med `Whist20.xcodeproj` og `.git`)
- [ ] `git fetch origin && git checkout codex/live-statistics-integration && git pull --rebase origin codex/live-statistics-integration`
- [ ] Læs **Næste skridt – Codex** nedenfor
- [ ] Sammenlign med `main`, hvis branchen har levet længe: `git fetch origin && git log --oneline --left-right --cherry-pick origin/main...HEAD`

### Før merge til `main`

- [ ] Den anden har ikke uløste ændringer i de samme filer (eller konflikter er forventet og aftalt)
- [ ] PR eller mergebesked beskriver hvad der medtages (`docs/statistik/`, UI, osv.)
- [ ] `docs/architecture/branch_and_architecture_decisions.md` er opdateret, hvis arbejdet ændrer branch- eller arkitekturstatus

---

## Næste skridt – Cursor (design / UI)

_Udfyld og kryds af efter behov._

| # | Opgave | Status |
|---|--------|--------|
| 1 | Læs `docs/statistik/web_live_overblik_og_statistik_plan.md` før web/live-arbejde | ☑ færdig |
| 2 | Lav første web/live-commit: `schemaVersion`, `web/README.md`, `.env.example` | ☑ færdig |
| 3 | Forbedr web-overblik med stabil scoreboard-UI og stale/error states | ☑ færdig |
| 4 | Performance-sikring: fingerprint + SyncPriority i LiveSessionSync | ☑ færdig |
| 5 | Deploy til Vercel + smoke-test (Fase D) | ☑ færdig |
| 6 | **Manuel:** sæt `LiveSessionAPISecret` i plist lokalt og test fra simulator | ☐ ikke startet |
| 7 | Fase E: tilføj `completedHands` i payload v2 og session-detalje-route | ☐ ikke startet |

**Sidst opdateret:** 2026-06-02

---

## Næste skridt – Codex (statistik + `docs/statistik/`)

_Udfyld og kryds af efter behov._

| # | Opgave | Status |
|---|--------|--------|
| 1 | Opret planbranch for web/live-overblik | ☑ færdig |
| 2 | Skriv grundigt arkitektur- og handoff-dokument | ☑ færdig |
| 3 | Hold app/web-kode uændret indtil planen er læst i Cursor | ☑ færdig |

**Sidst opdateret:** 2026-06-02

---

## Blokeringer og aftaler

_Kort notat hvis noget venter på den anden (fx “merge statistik-PR før nye UI-farver på tabellen”)._

- 

---

## Relaterede filer

- `TECHNICAL_HANDOFF.md` — arkitektur og git-opstart
- `docs/architecture/branch_and_architecture_decisions.md` — branch- og arkitekturbeslutninger
- `docs/issues_local.txt` — samlet produkt-backlog
- `docs/issues.md` — GitHub-issues oversigt
