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
| 1 | Kortlæg statistik-input fra historiske data og SwiftData live spil | ☐ ikke startet |
| 2 | Beslut adapter/preparer-arkitektur for kombineret statistik | ☐ ikke startet |
| 3 | Udvid tests før større UI-ændringer | ☐ ikke startet |

**Sidst opdateret:** 2026-05-31

---

## Næste skridt – Codex (statistik + `docs/statistik/`)

_Udfyld og kryds af efter behov._

| # | Opgave | Status |
|---|--------|--------|
| 1 | | ☐ ikke startet / ☐ i gang / ☐ færdig |
| 2 | | |
| 3 | | |

**Sidst opdateret:** 2026-05-31

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
