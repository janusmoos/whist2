# Distribution af Whist 2.0

Denne guide beskriver, hvordan du installerer appen på din egen iPhone og deler den med dine venner — uden App Store.

---

## 1. Installer på din egen iPhone

### Forudsætninger

- En Mac med **Xcode** installeret
- Et **Apple ID** (gratis konto er nok)
- Et USB-kabel (Lightning eller USB-C til din iPhone)

### Trin

1. **Åbn projektet** — dobbeltklik på `Whist20.xcodeproj`
2. **Tilføj din Apple-konto** (kun første gang)
   - Xcode → Settings → Accounts (⌘,)
   - Klik **+** og log ind med dit Apple ID
3. **Vælg Team** — klik på "Whist20" i sidebar → target "Whist20" → Signing & Capabilities
   - Slå "Automatically manage signing" til
   - Vælg dit Apple ID som Team
4. **Tilslut din iPhone** med kabel og lås den op
   - Tryk "Stol på denne computer" på telefonen
5. **Vælg din iPhone** i destination-dropdown'en øverst i Xcode
6. **Byg og kør** med ⌘R
7. **Stol på udvikleren** (kun første gang)
   - På iPhone: Indstillinger → Generelt → VPN og enhedshåndtering → tryk "Stol på"

> **Bemærk:** Med gratis Apple ID udløber appen efter **7 dage** — byg igen fra Xcode for at forny.

---

## 2. Del med venner

### Mulighed A: Tilslut deres telefon (gratis)

Den enkleste løsning, men kræver fysisk adgang til deres iPhone.

1. De tager deres iPhone med og tilslutter den til din Mac
2. I Xcode: vælg deres telefon som destination
3. Tryk ⌘R — appen installeres
4. De stoler på udvikleren (se trin 7 ovenfor)

**Ulempe:** Appen udløber efter 7 dage (gratis konto). De skal forbi igen.

### Mulighed B: AltStore PAL (EU — anbefalet)

Siden iOS 17.4 kan man i EU installere apps via alternative markedspladser. AltStore PAL er den mest udbredte.

#### Dine venner gør dette (én gang):

1. Gå til [altstore.io](https://altstore.io) på deres iPhone
2. Download og installer **AltStore PAL**
3. Opret eller log ind med deres Apple ID i AltStore

#### Du gør dette:

1. I Xcode: **Product → Archive**
2. Når archive er færdigt, åbnes Organizer automatisk
3. Vælg dit archive → **Distribute App**
4. Vælg **Custom → Development** (eller "Copy App")
5. Følg guiden og eksportér — du får en `.ipa`-fil
6. Send `.ipa`-filen til dine venner (AirDrop, iMessage, Google Drive osv.)

#### Dine venner installerer:

1. Åbn `.ipa`-filen på deres iPhone
2. Vælg "Åbn i AltStore"
3. AltStore installerer appen

**Pris:** €1,50/år pr. bruger for AltStore PAL.

### Mulighed C: TestFlight (bedst, men koster)

Den officielle Apple-løsning til beta-distribution.

1. Tilmeld dig **Apple Developer Program** — [developer.apple.com](https://developer.apple.com) — **749 kr/år**
2. I Xcode: **Product → Archive → Distribute App → App Store Connect**
3. Upload til App Store Connect
4. Opret en TestFlight-gruppe og tilføj dine venner via e-mail
5. De modtager en invitation og installerer via **TestFlight-appen**

**Fordele:** Ingen kabel, ingen sideloading, appen holder i 90 dage, op til 10.000 testere.

### Mulighed D: SideStore (gratis, mere teknisk)

Open source-alternativ der ikke kræver betalt udviklerkonto.

1. Dine venner installerer **SideStore** fra [sidestore.io](https://sidestore.io)
2. Du sender dem `.ipa`-filen (se eksportprocess under Mulighed B)
3. De åbner filen i SideStore

**Ulempe:** Appen skal geninstalleres hver 7. dag (gratis Apple ID-begrænsning).

---

## Oversigt

| Metode | Pris | Kabel nødvendigt | Holdbarhed | Nemmest for venner |
|--------|------|-------------------|------------|--------------------|
| Tilslut telefon | Gratis | Ja | 7 dage | ⭐⭐ |
| AltStore PAL (EU) | €1,50/år (bruger) | Nej | Varig | ⭐⭐⭐⭐ |
| TestFlight | 749 kr/år (udvikler) | Nej | 90 dage | ⭐⭐⭐⭐⭐ |
| SideStore | Gratis | Nej | 7 dage | ⭐⭐⭐ |
