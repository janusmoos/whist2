# Parallelt arbejde – Cursor og Codex

**Formål:** Ét sted i repo’et som **begge** værktøjer (og du) læser ved session-start: hvilke **branches**, hvilket **ejerskab** af mapper, og hvad der er **i gang / næste skridt** på hver side.

**Regel:** Opdater denne fil når I skifter fokus, merger til `main`, eller overtager en mappe — og **commit + push** så den anden part ser det efter `git pull`.

---

## Aktive branches (udfyld og hold ajour)

| Spor | Branch-navn | Primært ansvar |
|------|----------------|----------------|
| **Design / UI (Cursor)** | `design/visual-refresh` | SwiftUI, farver, typografi, layout i `Whist20/` |
| **Statistik / docs (Codex)** | `feature/statistics-historical-data` | Indhold og noter under `docs/statistik/`, evt. tilhørende kode på samme branch |
| **Fælles linje** | `main` | Merge via PR når noget er klart til alle |

*Ret tabellen hvis I omdøber branches.*

---

## Ejerskab (undgå konflikter)

| Område | Hvem må committe her? |
|--------|------------------------|
| `docs/statistik/` | **Kun Codex-sporet** (statistik-branchen), indtil I aftaler andet |
| `Whist20/**/*.swift`, assets, UI | **Kun design-sporet** (design-branchen), eller eksplicit koordineret |
| `docs/PARALLEL_WORK.md` | **Begge** — korte opdateringer når status ændrer sig |

**På design-maskinen:** commit **ikke** `docs/statistik/` ved en fejl. Ved støj fra lokal mappe: brug `.git/info/exclude` med linjen `docs/statistik/` (kun lokalt, pushet ikke). Se `TECHNICAL_HANDOFF.md`.

---

## Checkliste ved ny session

### Cursor (design)

- [ ] `git fetch origin && git checkout design/visual-refresh && git pull origin design/visual-refresh`
- [ ] Læs **Næste skridt – Cursor** nedenfor
- [ ] Rør ikke `docs/statistik/` i commits (medmindre I har merget Codex’ ændringer og I aftaler deling)

### Codex (statistik / funktioner)

- [ ] Åbn **samme repo-klon** (mappe med `Whist20.xcodeproj` og `.git`)
- [ ] `git fetch origin && git checkout feature/statistics-historical-data && git pull origin feature/statistics-historical-data`
- [ ] Læs **Næste skridt – Codex** nedenfor

### Før merge til `main`

- [ ] Den anden har ikke uløste ændringer i de samme filer (eller konflikter er forventet og aftalt)
- [ ] PR beskriver hvad der medtages (`docs/statistik/`, UI, osv.)

---

## Næste skridt – Cursor (design / UI)

_Udfyld og kryds af efter behov._

| # | Opgave | Status |
|---|--------|--------|
| 1 | | ☐ ikke startet / ☐ i gang / ☐ færdig |
| 2 | | |
| 3 | | |

**Sidst opdateret:** _dato + evt. initialer_

---

## Næste skridt – Codex (statistik + `docs/statistik/`)

_Udfyld og kryds af efter behov._

| # | Opgave | Status |
|---|--------|--------|
| 1 | | ☐ ikke startet / ☐ i gang / ☐ færdig |
| 2 | | |
| 3 | | |

**Sidst opdateret:** _dato + evt. initialer_

---

## Blokeringer og aftaler

_Kort notat hvis noget venter på den anden (fx “merge statistik-PR før nye UI-farver på tabellen”)._

- 

---

## Relaterede filer

- `TECHNICAL_HANDOFF.md` — arkitektur og git-opstart
- `docs/issues_local.txt` — samlet produkt-backlog
- `docs/issues.md` — GitHub-issues oversigt
