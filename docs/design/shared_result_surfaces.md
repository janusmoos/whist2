# Fælles resultat- og plakatdesign

Dette dokument beskriver de visninger, der skal behandles som samme designfamilie. Når en ændring laves ét sted, skal Codex vurdere om den også skal slå igennem de andre steder og spørge eksplicit, hvis der er lokale forskelle.

## Primære fælles komponenter

- `ActiveGameTrumpPoster` og `ActiveGameSolPoster` er grunddesignet for meldings-/resultatplakater.
- `ActiveGamePosterStyle` definerer fælles farver, radius og skrifttyper.
- `ActiveGamePosterScoreItem` bruges til scorebokse og kontraktmarkeringer.
- `ActiveGamePosterText` og `HandResumeCaption` er kilden til formuleringer i resumétekster for appens egne gemte spil.

## Relevante sider

- Forside: aktivt spil.
- Aktivt spil.
- Seneste spil.
- Nyt spil / spilledag efter gemt spil.
- Statistik > Spilledage > enkelt spilledag.
- Statistik > Spilledage > enkelt spil.

## Regel for fremtidige ændringer

Når der ændres i plakatens typografi, farver, borders, scorebokse, termometer, makker-/meldermarkering eller resumétekst, skal Codex først nævne hvilke af siderne ovenfor der påvirkes.

Hvis brugeren kun beder om en ændring på én side, skal Codex spørge om ændringen også skal slå igennem på de andre relevante sider, medmindre ændringen tydeligt er lokal.

## Lokale variabler

Lokale forskelle er tilladt, men skal være bevidste:

- Forside kan bruge kompakt layout og skjule resumétekst.
- Aktivt spil kan bruge nutidsform.
- Resultatsider bruger datid og scorebokse.
- Statistik-sider kan have historiske data, hvor alle oplysninger ikke altid findes; de skal stadig bruge samme panel-, score- og resuméudtryk.
