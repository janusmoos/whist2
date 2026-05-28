# Regler for kortillustrationer

Dette dokument er den levende sandhed for, hvordan Whist20 illustrerer spiltyper og meldinger med konkrete kortgrafikker.

Kortkilden er:

`docs/skins/Card-graphics/Single Cards (One Per FIle)/`

Kun kort, der faktisk bruges i appen, importeres til `Whist20/Assets.xcassets`. Nye kort importeres først, når en regel nedenfor har valgt dem til en konkret UI-situation.

## Importprincipper

- Importer kun enkeltkort, der bruges i appen.
- Brug stabile asset-navne i appen: `card_spade_1`, `card_heart_12_queen`, osv.
- Bevar original-SVG'erne i `docs/skins/...` som kilde.
- UI-regler skal pege på ønsket kortmotiv, ikke direkte på filnavne, indtil kortet faktisk importeres.
- Når en regel besluttes eller ændres, skal dette dokument opdateres samme gang som appkoden.

## Kendte kortnavne i kildemappen

Kildemappen bruger engelske kulører:

- `SPADE-*` = Spar
- `HEART-*` = Hjerter
- `DIAMOND-*` = Ruder
- `CLUB-*` = Klør
- `JOKER-*` = Joker

Tal/rang følger filnavnet:

- `1` = es
- `2` til `10` = tal-kort
- `11-JACK` = knægt
- `12-QUEEN` = dame
- `13-KING` = konge

## Primære spiltyper

| Spiltype | App-kilde | Eksisterende regel | Illustration | Status |
| --- | --- | --- | --- | --- |
| Almindelige | `NormalGameType.almindelig` / `NormalSubtype.alm` | Bud 8-13, valgt trumf, evt. makker-es | Kortillustrationens kulør følger valgt trumf. | Besluttet |
| Sans | `NormalGameType.sans` / `NormalSubtype.sans` | Bud 8-13, uden trumf, valgt makker-es | Kortlignende grafik uden kulør. | Besluttet |
| Halve | `NormalGameType.halve` / `NormalSubtype.halve` | Bud 8-13, trumf vælges før resultat, evt. makker-es | Når trumf er valgt: kortillustrationens kulør følger trumf. Før trumf: kortlignende grafik med tekst om Halve. | Besluttet |
| Gode | `NormalGameType.gode` / `NormalSubtype.gode` | Bud 8-13, fast klør/gode-logik, evt. makker-es | Kortillustrationens kulør følger trumf; for Gode er trumf klør. | Besluttet |
| VIP i første | `NormalGameType.vip(.single)` | VIP-niveau 1, trumf efter spil | Når trumf er valgt: kortillustrationens kulør følger trumf. Før trumf: kortlignende grafik med tekst om VIP i første. | Besluttet |
| VIP i anden | `NormalGameType.vip(.double)` | VIP-niveau 2, trumf efter spil | Når trumf er valgt: kortillustrationens kulør følger trumf. Før trumf: kortlignende grafik med tekst om VIP i anden. | Besluttet |
| VIP i tredje | `NormalGameType.vip(.triple)` | VIP-niveau 3, trumf efter spil; klør giver ekstra dobbeltregel i pointmotor | Når trumf er valgt: kortillustrationens kulør følger trumf. Før trumf: kortlignende grafik med tekst om VIP i tredje. | Besluttet |

## Sol-varianter

| Spiltype | App-kilde | Eksisterende regel | Illustration | Status |
| --- | --- | --- | --- | --- |
| Sol | `SolType.normal` | Solspiller må tage maks. 1 stik | Sol-grafik i midten, suppleret med grafik/tekst der siger Sol. | Besluttet |
| Ren sol | `SolType.pure` | Solspiller må tage 0 stik | Sol-grafik i midten, suppleret med grafik/tekst der siger Ren sol. | Besluttet |
| Halv bordlægger | `SolType.halfDealer` | 0 stik, højere pointværdi | Sol-grafik i midten, suppleret med grafik/tekst der siger Halv bordlægger. | Besluttet |
| Bordlægger | `SolType.dealer` | 0 stik, højeste pointværdi | Sol-grafik i midten, suppleret med grafik/tekst der siger Bordlægger. | Besluttet |

## Meldingselementer og varianter

| Element | Hvor ses det | Illustration | Status |
| --- | --- | --- | --- |
| Bud 8 | Almindelige, Sans, Halve, Gode, VIP | Skal besluttes: tal som kort, badge eller tekst? | Afventer |
| Bud 9 | Almindelige, Sans, Halve, Gode, VIP | Skal besluttes | Afventer |
| Bud 10 | Almindelige, Sans, Halve, Gode, VIP | Skal besluttes | Afventer |
| Bud 11 | Almindelige, Sans, Halve, Gode, VIP | Skal besluttes | Afventer |
| Bud 12 | Almindelige, Sans, Halve, Gode, VIP | Skal besluttes | Afventer |
| Bud 13 | Almindelige, Sans, Halve, Gode, VIP | Skal besluttes | Afventer |
| Trumf: Spar | Almindelige, Halve, VIP | Kortillustration bruger spar som kulør. | Besluttet |
| Trumf: Hjerter | Almindelige, Halve, VIP | Kortillustration bruger hjerter som kulør. | Besluttet |
| Trumf: Ruder | Almindelige, Halve, VIP | Kortillustration bruger ruder som kulør. | Besluttet |
| Trumf: Klør | Almindelige, Halve, Gode, VIP | Kortillustration bruger klør som kulør. | Besluttet |
| Makker-es | Almindelige, Halve, Gode | Skal besluttes: vis es i valgt kulør? | Afventer |
| Selvmakker | Almindelige, Halve, Gode, historiske VIP-varianter | Skal besluttes | Afventer |
| Duestraf / duefejl | Historiske data og fejltilstande | Skal besluttes | Afventer |
| Storslem | Historiske data/metadata | Skal besluttes | Afventer |

## Foreløbige designspørgsmål

Beslut disse før første implementering:

1. Skal budtallet 8-13 vises som et fysisk kort, som tekst oven på kortet, eller som et separat badge?
2. Hvilken endelig sol-grafik skal bruges: SwiftUI-sol, asset, joker/andet kort eller specialillustration?
3. Skal `VIP i første/anden/tredje` have hvert sit motiv, eller samme motiv med niveau-badge?
4. Når trumf mangler i Halve/VIP, skal grafikken ligne en kortbagside, et blankt kort eller et særligt “venter på trumf”-kort?
5. Skal de endelige kortillustrationer bruge de importerede SVG-kort, eller skal appen tegne stiliserede kort i SwiftUI?
6. Skal `selvmakker` markeres med et separat ikon/kort, eller kun med tekst?
7. Efter `Aktivt spil`: hvor må kortillustrationer bruges næste gang: Forside, Melding, Seneste spil, Statistik eller Scorecard?

## Første afprøvning: Aktivt spil

Første implementering laves på siden `Aktivt spil`.

Prototype-regler:

- Kendt trumf i Almindelige, Gode, Halve og VIP: vis plakatgrafik med melder, spiltype, budtal, trumf og makker-es.
- Det store budtal og stik-termometeret farves efter trumfens kulør.
- Stik-termometeret viser meldte stik som andel af 13 stik. 13 er fuld højde i topblokken.
- På gemte normale resultater viser termometeret også det faktiske stikresultat: stik over meldingen markeres som grønt felt over meldingsniveauet, og stik under meldingen markeres som rødt felt mellem faktisk niveau og meldingsniveau.
- Stik-termometeret skal starte helt ved bunden af topblokken og kunne gå helt til toppen.
- Alle hovedtekster inde i grafikboksene bruger samme typografiske størrelse. `MELDER` vises som outline-tekst. Resuméboksen bruger sin egen mindre tekststørrelse.
- Plakatteksten bruger Google Fonts-displayfonten `Anton`, fordi `Oswald` ikke var tung nok til plakatretningen. Kun fontfilen `Anton-Regular.ttf` er registreret i appen.
- Stik-tallet i topblokken skal være omtrent lige så højt som de tre tekstlinjer i samme boks og centreres over makker-boksen nedenunder.
- Stik-tallet skal kunne vises tocifret uden at blive mindre; topboksens venstre tekstkolonne må give plads før tallet skaleres ned.
- Borderfarven skal være en lys brun, kun lidt mørkere end boksenes baggrund.
- Resuméteksten vises i en plakatboks med samme baggrund og border som de andre bokse. Den bruger `Archivo` regular i komprimeret bredde, mindre størrelse og med visuelt lettere farve/intensitet.
- Resumétekst bruger de samme Unicode-kulørikoner som de store plakatbokse (`♠ ♥ ♦ ♣`) og de samme faste kulørfarver: rød `Color(red: 0.72, green: 0.05, blue: 0.10)` og sort `Color(red: 0.10, green: 0.12, blue: 0.16)`.
- Grafikboksene bruger bløde hjørner og 1 px brun border.
- Resuméteksten er mindre, visuelt lettere, og slutter med pris pr. stik, fx `(20 kr/stik)`.
- Gode: behandles som klør-trumf.
- Sans: brug samme plakatlayout som trumfspil, men uden kulør. Topblokkens tal er neutral sort. Termometeret bruger samme fyld-design som trumfspil, men med neutral lysegrå i stedet for trumffarve. `TRUMF`-boksen viser SF Symbol `xmark.circle` som “ingen trumf”-ikon i en lidt lettere vægt. I kompakte visninger er ikonet lidt mindre, så der er mere luft i bunden af boksen. `MAKKER`-boksen viser det valgte makker-es.
- De to nederste plakatbokse (`TRUMF` og `MAKKER`) skal altid være lige store inden for samme visning, også når deres indhold har forskellig intrinsic størrelse.
- Indholdet i de to nederste plakatbokse skal flugte: titlerne har samme skriftstørrelse og samme faste titel-slot, og ikoner/neutral markering ligger i samme faste symbol-slot.
- Plakatkomponenten skal reservere sin fulde samlede højde i layoutet, så topboks, nederste bokse og resuméboks aldrig kan tegne oven i hinanden. Hovedlayoutet bruger SwiftUIs `Grid`, hvor topboksen spænder over to kolonner, og `TRUMF`/`MAKKER` er anden række med fast højde. Kompakt variant har egne tekstmål, fordi Anton-fonten visuelt fylder meget i højden. `GeometryReader` må ikke bruges som layoutmotor i plakatens hovedrækker.
- Sol: brug samme plakatfamilie som de øvrige spil. Topboksen viser melder, `MELDER`, solvariant og stor sol-grafik. Der vises ikke nederste `TYPE`/`KRAV`-bokse for solspil. `Halv bordlægger` vises som `½ bordlægger` i meldings-/resultatbokse, med let reduceret plakatfontstørrelse så navnet visuelt matcher de øvrige soltyper bedre. Solikonet tegnes i SwiftUI efter inspirationen: åben solring for Sol, åben kraftigere solring for Ren sol, halvt udfyldt sol for Halv bordlægger og fuldt udfyldt sol for Bordlægger. Cirklen i solikonerne er forholdsvis lille, og strålerne er lidt længere, så ikonet virker lettere og skarpere. Soltopboksen skal have samme højde som topboksen i de andre plakattyper. Hvis en eller flere spillere går med på solmeldingen, vises en fuldbredde-boks under topboksen med samme plakattypografi, fx `Thomas går med` eller `Thomas og Janus går med`.
- Resultatsider med gemte spil viser en pointlinje lige under øverste plakatboks: fire lige store bokse, én pr. spiller. Navnet vises småt, semibold og med lidt ekstra top-padding, mens pointtallet er markant. Positive point er grønne, negative point er røde, og nul er neutralt.
- På resultater markeres kontraktsiden i pointlinjen med en diskret mørkebrun border på 2 px. Melderens border er solid, og makker/solspillere der `går med` får dashed border. Der bruges ikke ekstra tekst, topstreg eller notifikationsikon. Den øverste resultatboks bruger samme neutrale 1 px plakatborder som de øvrige plakatbokse.
- Resultatsider med gemte spil bruger datid i øverste plakatboks (`MELDTE`) først efter resultatet er gemt. Aktive kladder bruger fortsat nutid (`MELDER`). Øverste boks på gemte resultater har neutral plakatborder; `MELDTE` farves grøn/rød efter melderens resultat. Resuméboksen for gemte resultater starter med `Spil #<nummer>:`.
- På gemte resultater er `MELDTE` ikke outline; teksten farves efter melderens resultat med samme grøn/rød som resultat-borderen. På aktive meldinger/kladder er `MELDER` fortsat outline.
- På gemte normale resultatplakater vises forskellen mellem meldte og faktiske stik som et lille badge ved siden af det store stik-tal i topboksen, fx `+2` eller `-1`. Badget vises kun når forskellen ikke er nul. Positiv forskel bruger fælles resultatgrøn `Color(red: 0.10, green: 0.48, blue: 0.23)`, og negativ forskel bruger fælles resultatrød `Color(red: 0.72, green: 0.05, blue: 0.10)`.
- Det store stik-tal i topboksen er neutralt mørkt, også når trumfen er rød. Trumffarven bruges i termometeret og i trumf-/makkerikonerne.
- Storslem markeres tydeligt ved almindelige/normalspil, når en af siderne får alle 13 stik, uanset hvor mange stik der blev meldt. I appens normale resultatinput betyder det, at kontraktsiden har `13` stik eller `0` stik. Hvis melder taber storslem, starter resuméteksten med `STORSLEM!` lige efter spilnummeret, fx `Spil #24: STORSLEM! Peter meldte ...`. Hvis melder vinder med 13 stik, nævnes storslem i stedet som en ekstra sætning til sidst, fx `Storslem til Thomas og Janus`. Resultatplakaten bevarer den oprindelige spiltype i topboksens tredje linje (`ALM`, `VIP 2`, osv.). Hvis melder taber storslem, vises et rødt, let transparent corner ribbon i øverste højre hjørne af topboksen. Hvis melder vinder med 13 stik, får tabernes pointbokse i stedet et rødt corner ribbon.
- Halve/VIP uden trumf endnu: brug samme plakatlayout som de øvrige normale spil, så aktivt spil ikke falder tilbage til gammelt design. Topboksen viser melder, spiltype og budtal; `TRUMF`-boksen viser teksten `VÆLGES` som neutral ventemarkering, mens `MAKKER`-boksen viser det valgte makker-es.
- VIP-melding kræver valg af makker-es allerede i meldingsregistreringen. Det valgte es omtales som `til <kulør>` i resuméteksten. VIP er den eneste spiltype, hvor den senere valgte trumf gerne må være samme kulør som makker-es; Halve blokerer fortsat samme kulør.
- I prototypen importeres ingen SVG-kort endnu; vi afprøver først informationsarkitektur og layout med SwiftUI-tegnet kortgrafik. Når retningen er godkendt, importerer vi kun de konkrete SVG-kort, der bliver brugt.
- Forsiden genbruger samme plakatgrafik og resuméboks under de fire hovedknapper, både når der findes et aktivt spil med kladde, og når den viser seneste afsluttede spil. Forsiden må ikke have sin egen separate aktive-/seneste-spil-stil.
- Forsidens plakatvariant må komprimeres, så de væsentlige forsideinformationer kan ses uden scroll. Første komprimering er lavere `TRUMF`/`MAKKER`-bokse med samme grunddesign.
- `Nyt spil`-siden bruger samme kompakte plakatvariant til seneste gemte spil, efterfulgt af den kompakte scorelinje. Resuméteksten udelades her for at give plads til sidens øvrige elementer.
- `Seneste spil`-siden bruger samme plakatkomponent til den fremhævede seneste kamp. Den gamle øverste chip-linje over plakaten vises ikke længere. Under `Øvrige kampe samme dag` bruger den kompakte scoreliste den sekundære `Archivo`-font i en mindre størrelse; melderens pointtal vises ekstra fedt, mens alle pointtal har samme skriftstørrelse. Pointfarver genbruger altid de fælles resultatfarver: grøn `Color(red: 0.10, green: 0.48, blue: 0.23)` og rød `Color(red: 0.72, green: 0.05, blue: 0.10)`. Når en øvrig kamp foldes ud med chevron, vises kun resuméteksten og dato, ikke resultat-plakatdesignet. Resuméet i denne fold-ud-visning starter ikke med `Spil #<nummer>:`.
- `Seneste spil`-siden viser nederst en spilledagsoversigt med overskriften `Status`. Først vises et minimalt linjediagram uden akser, tal, grid, datapunktmarkører eller indbygget legend; eneste hjælpelinje er en meget diskret 0-linje. Hver spillerlinje har et lille, læsbart navn ved linjens seneste niveau. Diagrammet og labelkolonnen er separate views i samme række, så linjerne aldrig tegnes ind under navnene, og navnene ikke kan klippes af chartets plotområde. Labelkolonnen har fast venstrekant og minimumsafstand mellem labelrækker; spillere med samme slutpoint står på samme labelrække ved siden af hinanden, eventuelt forkortet. Under diagrammet vises fire pointbokse inspireret af resultatplakatens pointlinje: små spillernavne, store pointtal, fælles plakatbaggrund, 2 px spillerfarvet border og plus/minus i de fælles resultatfarver. Spillerfarverne er defineret i `docs/design/color_system.md`.
- Spilledagssiden viser kun det seneste gemte spil i `Seneste spil`-sektionen. Listen over tidligere spil og den store tilføj/kladde-boks vises ikke længere på denne side; tilføjelse af spil sker via toolbar-knappen.
- Grunddesignet skal styres ét sted med lokale varianter pr. side. Side-specifikke valg må være parametre som kompakthed, om resumé vises, og om scorelinje vises; de må ikke være kopier af plakatlayoutet.

## Beslutningslog

| Dato | Beslutning | Påvirker |
| --- | --- | --- |
| 2026-05-18 | Dokument oprettet. Alle illustrationer afventer valg. | Designbranch `codex/design-experiments` |
| 2026-05-18 | Kortkulør følger trumf for Almindelige, Gode, Halve og VIP. Sans bruger kulørløs kortgrafik. Solspil bruger sol-grafik med varianttekst. Halve/VIP uden trumf bruger ventende kortgrafik. Første afprøvning sker på `Aktivt spil`. | `Aktivt spil` |
| 2026-05-18 | `Aktivt spil` bruger plakatlayout for normale spil med kendt trumf: melder/spiltype/budtal i topblok, stik-termometer i trumffarve, og underblokke for trumf og makker-es. | `ActiveGameView` |
| 2026-05-18 | Plakatlayout justeret: `MELDER` er outline, termometer går kant-til-kant i topblokken, grafikbokse har 1 px brun border og radius, plakattekst har fælles størrelse, og resumétekst viser pris pr. stik. | `ActiveGameView` |
| 2026-05-18 | Plakatteksten i `Aktivt spil` afprøver Google Fonts-fonten `Barlow Condensed Black` / weight 900. Fontfilen og OFL-licensen ligger i `Whist20/Resources/Fonts/`. | `ActiveGameView`, `AppInfoAdditions.plist` |
| 2026-05-18 | Plakatteksten skiftet fra Barlow Condensed til Google Fonts-fonten `Oswald` i tungeste vægt. Den ydre grå resumeboks omkring plakatgrafikken fjernes, stik-tallet gøres større, og topboksens tre tekstlinjer trækkes tættere sammen. | `ActiveGameView`, `AppInfoAdditions.plist` |
| 2026-05-18 | Oswald forkastet som for let. Plakatteksten skiftet til Google Fonts-fonten `Anton`, som har mere vægt og smallere displayform. | `ActiveGameView`, `AppInfoAdditions.plist` |
| 2026-05-18 | Stik-tallet forstørret og centreret over makker-boksen. `TRUMF` og `MAKKER` gøres lidt større. Den lysegrå hjælpetekst under resuméet fjernes, og borderfarven lysnes markant. | `ActiveGameView` |
| 2026-05-18 | Tocifrede stik-tal må ikke trunceres til ellipsis. Tallet bevarer sin store størrelse og får naturlig bredde; venstre tekstkolonne i topboksen gøres smallere. | `ActiveGameView` |
| 2026-05-18 | Topboksens tre tekstlinjer trækkes en anelse tættere sammen, `MELDER` får lidt mere bogstavafstand, og resuméteksten lægges i en matchende plakatboks med mindre og visuelt lettere tekst. | `ActiveGameView` |
| 2026-05-22 | Forsiden genbruger plakatillustrationen og resuméboksen fra `Aktivt spil` under de fire knapper, så aktivt spil kun har én visuel regel på tværs af appen. | `HomeView`, `ActiveGameView` |
| 2026-05-22 | Forsidevarianten af plakatillustrationen gøres mere kompakt ved at gøre `TRUMF`- og `MAKKER`-boksene lavere, med mindre intern afstand og mindre kulørsymboler. | `HomeView`, `ActiveGameView` |
| 2026-05-22 | `Nyt spil`-siden skifter som standard til kortvisning og viser seneste gemte spil med samme kompakte plakatdesign plus scorelinje. | `GameDayStartView`, `ActiveGameView` |
| 2026-05-22 | Sans dækkes af samme plakatdesign: neutral sort tal, neutral lysegrå fyldt termometer, `SANS` som spiltype, `xmark.circle` som ingen-trumf-ikon i `TRUMF`-boksen og neutral `MAKKER`-boks. | `ActiveGameView`, gemte/aktive plakatvisninger |
| 2026-05-22 | Plakatlayoutet må ikke bruge `GeometryReader` som hoved-layoutmotor. Topboks, mellemrum og nederste panelrække reserveres med faste højder, så kortene ikke kan overlappe i SwiftUIs layoutflow. | `ActiveGameView` |
| 2026-05-22 | Plakatlayoutet omlagt fra stak-baseret rækkeopbygning til `Grid` med topcellen over to kolonner og nederste kort som separat række. Kompakt variant får egne font- og panelmål for at undgå at Anton-tekst visuelt kolliderer med nederste kort. | `ActiveGameView` |
| 2026-05-22 | Nederste `TRUMF`/`MAKKER`-kort bruger faste titel- og symbol-slots, så tekst og ikon flugter på tværs af de to kort og ikke bliver klippet af kortmasken. | `ActiveGameView` |
| 2026-05-22 | Solspil får egen plakatvariant: kun topkort med melder, solvariant og stor sol. `TYPE`/`KRAV`-boksene bruges ikke til sol. Reglen gælder både aktiv kladde og gemte solspil, når de vises med plakatkomponenten. | `ActiveGameView` |
| 2026-05-22 | Solikonerne skifter fra SF Symbols til SwiftUI-tegnede specialikoner inspireret af fire kort: Sol har en enklere åben ring med seks stråler, Ren sol har åben ring med otte stråler, Halv bordlægger har halvt udfyldt sol med tolv stråler, og Bordlægger har fuldt udfyldt sol med tolv stråler. Strålerne ligger tæt på cirklen, og ikonerne skaleres i et fast ikonfelt, så solboksen matcher topboksens størrelse i de øvrige spiltyper. | `ActiveGameView` |
| 2026-05-22 | På meldingssiden vises solvarianten som selve `Spiltype`, så Sol, Ren sol, Halv bordlægger og Bordlægger ikke alle reduceres til `Sol`. | `MeldingPresentation` |
| 2026-05-22 | `Seneste spil`-siden skifter fra gammelt hero-layout til den fælles plakatkomponent. Den fremhævede seneste kamp bruger fuld plakat, og udfoldede øvrige kampe bruger kompakt plakat. | `SenesteSpilComponents`, `SenesteSpilDiscreteTable` |
| 2026-05-22 | Solplakaten viser en ekstra fuldbredde-boks under topboksen, når solmeldingen har spillere der går med. Boksen bruger samme plakatfont og navneliste på dansk. | `ActiveGameView` |
| 2026-05-22 | Forsidens fallback for `Seneste spil` skifter fra gammelt tile-dashboard til den fælles kompakte plakatkomponent og resuméboks. | `HomeView` |
| 2026-05-22 | Resuméboksen skifter fra Anton til Google Fonts-fonten `Archivo` regular med komprimeret bredde, størrelse 18, line spacing 2 og opacity 0.82. Kun den variable Archivo-fontfil og OFL-licensen importeres. | `ActiveGameView`, `AppInfoAdditions.plist` |
| 2026-05-22 | Gemte spilplakater får en pointlinje lige under topboksen med fire lige store spillerbokse. Linjen vises på resultatsider, men ikke på aktive kladder uden resultat. | `ActiveGameView` |
| 2026-05-23 | Normale resultatplakater får et lille grønt/rødt delta-badge ved det store stik-tal, når faktisk antal stik afviger fra meldingen. | `ActiveGameView` |
| 2026-05-23 | Storslem flyttes ud af spiltype-linjen. Ved tabt storslem for melder starter resuméet med `STORSLEM!` og topboksen får rødt ribbon. Ved vundet 13-stik-storslem nævnes storslem sidst i resuméet som `Storslem til ...`, og tabernes pointbokse får ribbon. | `ActiveGameView`, `RecordedHand` |
| 2026-05-23 | `Seneste spil` får nederst en dagsoversigt med `Status`: minimalistisk udviklingsdiagram øverst og stillingsbokse nedenunder. Diskrete spillerfarver dokumenteres særskilt i `docs/design/color_system.md`. | `SenesteSpilView`, `docs/design/color_system.md` |
