import SwiftData
import SwiftUI

// MARK: - Routing

private enum HandRoute: Hashable {
    case resultat
}

// MARK: - Draft (delt mellem Melding og Resultat)

@Observable
final class HandInputDraft {
    var kind: AddHandKind = .normal

    var bidder: Seat = .north
    var bidTricks: Int = 8

    /// Kun **almindelig**: trumf vælges i melding. Halve/VIP: trumf først i resultat.
    var normalSubtype: NormalBidSubtype = .alm
    /// `nil` indtil spilleren vælger trumf (alm.).
    var trumpAlm: Suit?

    /// Alm/halve/gode: vælg kulør for makker-es direkte (`nil` = ingen makker-es); sans/VIP bruger ikke feltet.
    var partnerAceSuit: Suit?

    var solType: SolType = .normal
    var solBidder: Seat = .north
    var goingWith: Set<Seat> = []

    var partner: Seat?
    var actualTricks: Int = 8
    /// Trumf efter spillet (halve, VIP). Alm bruger `trumpAlm` fra bud.
    var trumpAfterPlay: Suit?
    var vipLevel: VipLevel = .single
    /// Legacy felt til persistens; afledes nu af VIP (3.) + klør som trumf — se `vipTripleClubsDoubleActive`.
    var vip3IsClubs: Bool = true

    var isDuty: Bool = false
    var dutySeat: Seat = .south

    var solTricks: [Seat: Int] = Dictionary(uniqueKeysWithValues: Seat.all.map { ($0, 0) })

    func resolvedNormalGameType() -> NormalGameType {
        switch normalSubtype {
        case .alm, .sans, .halve, .gode:
            return normalSubtype.domainWithoutVip
        case .vip:
            return .vip(vipLevel)
        }
    }

    func effectiveTrumpForScoring() -> Suit? {
        if isDuty { return nil }
        let base = resolvedNormalGameType()
        switch base {
        case .gode:
            return .clubs
        case .almindelig:
            return trumpAlm
        case .sans:
            return nil
        case .halve:
            return trumpAfterPlay
        case .vip:
            /// Pointmotor (`ScoringEngine`) giver selv ×2 ved `.vip(.triple)` + `trumf == .clubs`.
            return trumpAfterPlay
        }
    }

    /// VIP i tredje med klør som valgt trumf → dobbelt point (×2) i beregningen.
    var vipTripleClubsDoubleActive: Bool {
        normalSubtype == .vip && vipLevel == .triple && trumpAfterPlay == .clubs
    }

    /// Alm/halve/gode — ikke sans/VIP.
    var requiresPartnerAceForBid: Bool {
        guard kind == .normal else { return false }
        switch normalSubtype {
        case .alm, .halve, .gode: return true
        case .sans, .vip: return false
        }
    }

    /// Kulører der ikke må vælges som makker-es (samme som trumf: alm = valgt trumf, gode = klør).
    var makkerEsExcludedSuits: Set<Suit> {
        guard kind == .normal, requiresPartnerAceForBid else { return [] }
        var out = Set<Suit>()
        if normalSubtype == .alm, let t = trumpAlm {
            out.insert(t)
        }
        if normalSubtype == .gode {
            out.insert(.clubs)
        }
        return out
    }

    /// Bruges til at gemme resultat-trinnet ved hver relevant ændring.
    var resultAutosaveToken: String {
        (try? HandDraftPersistence.encode(self, navigationStep: HandDraftPersistence.stepResultat)) ?? UUID().uuidString
    }

    var isBidStepValid: Bool {
        switch kind {
        case .normal:
            guard bidTricks >= 8, bidTricks <= 13 else { return false }
            if normalSubtype == .alm {
                guard trumpAlm != nil else { return false }
            }
            if requiresPartnerAceForBid {
                guard partnerAceSuit != nil else { return false }
            }
            return true
        case .sol:
            return true
        case .duty:
            return true
        }
    }

    var isResultStepValid: Bool {
        if kind == .duty { return true }
        if kind == .normal, isDuty { return true }
        switch kind {
        case .normal:
            guard partner != nil else { return false }
            guard actualTricks >= 0, actualTricks <= 13 else { return false }
            if normalSubtype == .alm, trumpAlm == nil { return false }
            if normalSubtype == .halve || normalSubtype == .vip, trumpAfterPlay == nil { return false }
            return normalScoresPreview != nil
        case .sol:
            return solScoresPreview != nil
        case .duty:
            return true
        }
    }

    private var normalScoresPreview: [Seat: Int]? {
        guard let p = partner, !isDuty, kind != .duty else { return nil }
        return ScoringEngine.scoreNormalHand(NormalHandScoreInput(
            gameType: resolvedNormalGameType(),
            bidTricks: bidTricks,
            actualTricks: actualTricks,
            bidder: bidder,
            partner: p,
            trumpSuit: effectiveTrumpForScoring()
        ))
    }

    private var solScoresPreview: [Seat: Int]? {
        ScoringEngine.scoreSolHand(SolHandScoreInput(
            solType: solType,
            bidder: solBidder,
            goingWith: goingWith,
            tricksBySeat: solTricks
        ))
    }

    func finalScores() -> [Seat: Int]? {
        if kind == .duty || isDuty {
            return ScoringEngine.dutyScores(dutyHolder: dutySeat)
        }
        switch kind {
        case .normal:
            guard let p = partner else { return nil }
            return ScoringEngine.scoreNormalHand(NormalHandScoreInput(
                gameType: resolvedNormalGameType(),
                bidTricks: bidTricks,
                actualTricks: actualTricks,
                bidder: bidder,
                partner: p,
                trumpSuit: effectiveTrumpForScoring()
            ))
        case .sol:
            return solScoresPreview
        case .duty:
            return ScoringEngine.dutyScores(dutyHolder: dutySeat)
        }
    }
}

enum AddHandKind: String, CaseIterable, Identifiable, Codable {
    case normal
    case sol
    case duty
    var id: String { rawValue }
    var title: String {
        switch self {
        case .normal: "Normal"
        case .sol: "Sol"
        case .duty: "Duestraf"
        }
    }
}

enum NormalBidSubtype: String, CaseIterable, Identifiable, Codable {
    case alm, sans, halve, gode, vip
    var id: String { rawValue }
    var title: String {
        switch self {
        case .alm: "Almindelige"
        case .sans: "Sans"
        case .halve: "Halve"
        case .gode: "Gode"
        case .vip: "VIP"
        }
    }
    var domainWithoutVip: NormalGameType {
        switch self {
        case .alm: .almindelig
        case .sans: .sans
        case .halve: .halve
        case .gode: .gode
        case .vip: .vip(.single)
        }
    }
}

// MARK: - Trin 1: Melding

private struct BidStepView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var draft: HandInputDraft
    @Binding var path: NavigationPath
    let gameDay: GameDay
    let onAnnuller: () -> Void

    var body: some View {
        Form {
            Section("Spiltype") {
                Picker("Type", selection: $draft.kind) {
                    ForEach(AddHandKind.allCases) { k in
                        Text(k.title).tag(k)
                    }
                }
                .pickerStyle(.segmented)
            }

            if draft.kind == .normal {
                normalBidSections
            } else if draft.kind == .sol {
                solBidSections
            }
        }
        .navigationTitle("Melding")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: draft.normalSubtype) { _, _ in
            if !draft.requiresPartnerAceForBid {
                draft.partnerAceSuit = nil
            } else if let ace = draft.partnerAceSuit, draft.makkerEsExcludedSuits.contains(ace) {
                draft.partnerAceSuit = nil
            }
        }
        .onChange(of: draft.trumpAlm) { _, _ in
            if let ace = draft.partnerAceSuit, draft.makkerEsExcludedSuits.contains(ace) {
                draft.partnerAceSuit = nil
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                DismissAddHandButton(gameDay: gameDay, onAnnuller: onAnnuller)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Næste") {
                    HandDraftPersistence.upsertPending(
                        context: modelContext,
                        gameDay: gameDay,
                        draft: draft,
                        navigationStep: HandDraftPersistence.stepResultat
                    )
                    path.append(HandRoute.resultat)
                }
                .disabled(!draft.isBidStepValid)
            }
        }
    }

    @ViewBuilder
    private var normalBidSections: some View {
        Section {
            MelderSeatButtonGrid(selectedSeat: $draft.bidder)
        }
        Section {
            HStack(spacing: 0) {
                NormalBidTricksWheelPicker(bidTricks: $draft.bidTricks)
                    .frame(maxWidth: .infinity)

                Picker("Spiltype", selection: $draft.normalSubtype) {
                    ForEach(NormalBidSubtype.allCases) { opt in
                        Text(opt.title).tag(opt)
                    }
                }
                .pickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .frame(height: 128)
                .clipped()
                .accessibilityLabel("Spiltype")
            }
            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
        }
        if draft.normalSubtype == .alm {
            Section("Trumf") {
                optionalSuitPicker(selection: $draft.trumpAlm)
            }
        }
        if draft.requiresPartnerAceForBid {
            Section("Makker-es") {
                optionalSuitPicker(selection: $draft.partnerAceSuit, excludedSuits: draft.makkerEsExcludedSuits)
            }
        }
    }

    @ViewBuilder
    private var solBidSections: some View {
        Section("Sol") {
            Picker("Sol-type", selection: $draft.solType) {
                ForEach(SolType.allCases, id: \.self) { t in
                    Text(solTypeTitle(t)).tag(t)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 128)
            .clipped()
            .accessibilityLabel("Sol-type")
        }
        Section {
            MelderSeatButtonGrid(selectedSeat: $draft.solBidder)
        }
        Section("Går med (valgfrit)") {
            ForEach(Seat.all.filter { $0 != draft.solBidder }, id: \.self) { seat in
                Toggle(seat.playerDisplayName, isOn: bindingGoingWith(seat))
            }
        }
    }

    private func solTypeTitle(_ t: SolType) -> String {
        switch t {
        case .normal: return "Sol"
        case .pure: return "Ren sol"
        case .halfDealer: return "Halv bordlægger"
        case .dealer: return "Bordlægger"
        }
    }

    private func bindingGoingWith(_ seat: Seat) -> Binding<Bool> {
        Binding(
            get: { draft.goingWith.contains(seat) },
            set: { newValue in
                if newValue { draft.goingWith.insert(seat) } else { draft.goingWith.remove(seat) }
            }
        )
    }
}

// MARK: - Trin 2: Resultat

private struct ResultStepView: View {
    @Environment(\.modelContext) private var modelContext

    @Bindable var draft: HandInputDraft
    let gameDay: GameDay
    @Binding var navigationPath: NavigationPath
    var dismissSheet: DismissAction
    @Binding var didCompleteSave: Bool

    var body: some View {
        Form {
            Section {
                MeldingStatusCard(
                    presentation: MeldingPresentation.from(
                        draft: draft,
                        navigationStepLabel: "Resultat — udfyld nedenfor og gem når spillet er færdigspillet"
                    )
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                .listRowBackground(Color.clear)
            }

            if draft.kind == .duty {
                dutyResultSections
            } else if draft.kind == .sol {
                solResultSections
            } else {
                normalResultSections
            }
        }
        .navigationTitle("Resultat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Tilbage") {
                    navigationPath.removeLast()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Gem") { save() }
                    .disabled(!draft.isResultStepValid)
            }
        }
        .onAppear {
            HandDraftPersistence.upsertPending(
                context: modelContext,
                gameDay: gameDay,
                draft: draft,
                navigationStep: HandDraftPersistence.stepResultat
            )
        }
        .onChange(of: draft.resultAutosaveToken) { _, _ in
            HandDraftPersistence.upsertPending(
                context: modelContext,
                gameDay: gameDay,
                draft: draft,
                navigationStep: HandDraftPersistence.stepResultat
            )
        }
    }

    @ViewBuilder
    private var normalResultSections: some View {
        Section("Makker") {
            PartnerSeatButtonGrid(selectedPartner: $draft.partner)
            if let p = draft.partner {
                Text(
                    p == draft.bidder
                        ? "\(draft.bidder.playerDisplayName) meldte til sig selv (selvmakker)"
                        : "\(draft.bidder.playerDisplayName) meldte til \(p.playerDisplayName)"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }

        if draft.normalSubtype == .vip {
            Section("VIP-niveau") {
                Picker("Niveau", selection: $draft.vipLevel) {
                    Text("Første").tag(VipLevel.single)
                    Text("Anden").tag(VipLevel.double)
                    Text("Tredje").tag(VipLevel.triple)
                }
            }
        }

        Section {
            ActualTricksWheelPicker(actualTricks: $draft.actualTricks)
        }

        if draft.normalSubtype == .halve || draft.normalSubtype == .vip {
            Section("Trumf (efter spillet)") {
                optionalSuitPicker(selection: $draft.trumpAfterPlay)
            }
        }

        if draft.vipTripleClubsDoubleActive {
            Section {
                vipTripleClubsDoubleNotice
            }
            .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
            .listRowBackground(Color.clear)
        }

        if !draft.isDuty, let scores = draft.finalScores() {
            Section("Resultat") {
                ForEach(Seat.all, id: \.self) { seat in
                    HStack {
                        Text(seat.playerDisplayName)
                        Spacer()
                        Text("\(scores[seat] ?? 0)")
                            .monospacedDigit()
                    }
                }
            }
        }

        Section {
            Toggle("Duestraf (erstatter spillets point)", isOn: $draft.isDuty)
        }

        if draft.isDuty {
            Section("Duestraf") {
                Picker("Spiller med duty", selection: $draft.dutySeat) {
                    ForEach(Seat.all, id: \.self) { seat in
                        Text(seat.playerDisplayName).tag(seat)
                    }
                }
            }
        }
    }

    private var vipTripleClubsDoubleNotice: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Dobbelt point")
                .font(.subheadline.weight(.semibold))
            Text(
                "Du har valgt VIP i tredje og klør som trumf efter spillet. Kontraktholdets point beregnes som ved andre VIP-spil og ganges derefter med 2 — det følger reglen om, at klør i tredje VIP tæller dobbelt."
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.thinMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        }
    }

    @ViewBuilder
    private var solResultSections: some View {
        Section("Stik pr. spiller") {
            ForEach(Seat.all, id: \.self) { seat in
                Stepper("\(seat.playerDisplayName): \(draft.solTricks[seat] ?? 0)", value: bindingSolTricks(seat), in: 0 ... 13)
            }
        }
        if let scores = draft.finalScores() {
            Section("Resultat") {
                ForEach(Seat.all, id: \.self) { seat in
                    HStack {
                        Text(seat.playerDisplayName)
                        Spacer()
                        Text("\(scores[seat] ?? 0)")
                            .monospacedDigit()
                    }
                }
            }
        }
    }

    private var dutyResultSections: some View {
        Section("Duestraf") {
            Picker("Spiller med duty", selection: $draft.dutySeat) {
                ForEach(Seat.all, id: \.self) { seat in
                    Text(seat.playerDisplayName).tag(seat)
                }
            }
        }
    }

    private func bindingSolTricks(_ seat: Seat) -> Binding<Int> {
        Binding(
            get: { draft.solTricks[seat] ?? 0 },
            set: { newValue in
                var copy = draft.solTricks
                copy[seat] = newValue
                draft.solTricks = copy
            }
        )
    }

    private func solTypeTitle(_ t: SolType) -> String {
        switch t {
        case .normal: return "Sol"
        case .pure: return "Ren sol"
        case .halfDealer: return "Halv bordlægger"
        case .dealer: return "Bordlægger"
        }
    }

    private func persistBidderSeatRaw(draft: HandInputDraft, kind: String) -> Int {
        switch kind {
        case "sol":
            return draft.solBidder.rawValue
        case "duty":
            return draft.dutySeat.rawValue
        default:
            return draft.bidder.rawValue
        }
    }

    private func save() {
        guard let scores = draft.finalScores() else { return }
        let kind: String = {
            if draft.isDuty { return "duty" }
            switch draft.kind {
            case .normal: return "normal"
            case .sol: return "sol"
            case .duty: return "duty"
            }
        }()
        let json = HandScorePersistence.encodeScores(scores)
        let summary = HandScorePersistence.makeSummaryLine(kind: kind, scores: scores)
        let caption = HandResumeCaption.compactLine(from: draft)
        let bidderSeat = persistBidderSeatRaw(draft: draft, kind: kind)
        gameDay.migrateLegacyHandNumbersIfNeeded()
        let nextHandNumber = (gameDay.hands.map(\.handNumber).max() ?? 0) + 1
        let hand = RecordedHand(
            kindRaw: kind,
            summaryLine: summary,
            scoresBySeatJSON: json,
            resumeCaption: caption,
            bidderSeatRaw: bidderSeat,
            handNumber: nextHandNumber,
            gameDay: gameDay
        )
        modelContext.insert(hand)
        HandDraftPersistence.deletePending(context: modelContext, gameDay: gameDay)
        try? modelContext.save()
        didCompleteSave = true
        dismissSheet()
    }
}

// MARK: - Root (sheet)

struct AddHandView: View {
    @Environment(\.dismiss) private var dismissSheet
    @Environment(\.modelContext) private var modelContext

    @State private var draft = HandInputDraft()
    @State private var path = NavigationPath()
    @State private var didRestoreFromPending = false
    @State private var userCancelledSheet = false
    @State private var didCompleteSave = false

    let gameDay: GameDay
    /// Kaldes når arket lukkes uden «Annuller» og uden fuld «Gem» — typisk træk-ned.
    var onDismissSaveNotice: ((String) -> Void)?

    init(gameDay: GameDay, onDismissSaveNotice: ((String) -> Void)? = nil) {
        self.gameDay = gameDay
        self.onDismissSaveNotice = onDismissSaveNotice
    }

    var body: some View {
        NavigationStack(path: $path) {
            BidStepView(draft: draft, path: $path, gameDay: gameDay, onAnnuller: { userCancelledSheet = true })
                .navigationDestination(for: HandRoute.self) { route in
                    switch route {
                    case .resultat:
                        ResultStepView(
                            draft: draft,
                            gameDay: gameDay,
                            navigationPath: $path,
                            dismissSheet: dismissSheet,
                            didCompleteSave: $didCompleteSave
                        )
                    }
                }
        }
        .onAppear {
            guard !didRestoreFromPending else { return }
            didRestoreFromPending = true
            restorePendingIfNeeded()
        }
        .onDisappear {
            handleInteractiveSheetDismiss()
        }
    }

    private func handleInteractiveSheetDismiss() {
        if didCompleteSave {
            didCompleteSave = false
            return
        }
        if userCancelledSheet {
            userCancelledSheet = false
            return
        }
        let step = path.isEmpty ? HandDraftPersistence.stepMelding : HandDraftPersistence.stepResultat
        HandDraftPersistence.upsertPending(
            context: modelContext,
            gameDay: gameDay,
            draft: draft,
            navigationStep: step
        )
        onDismissSaveNotice?(buildDismissUserMessage())
    }

    private func buildDismissUserMessage() -> String {
        if path.isEmpty {
            if !draft.isBidStepValid {
                return "Kladde gemt som aktivt spil. Meldingen er ikke færdig — udfyld alle felter under «Fortsæt aktivt spil»."
            }
            return "Kladde gemt som aktivt spil. Melding er ikke færdigregistreret før du trykker «Næste». Fortsæt via «Fortsæt aktivt spil»."
        }
        if !draft.isResultStepValid {
            return "Resultatkladde gemt som aktivt spil. Spillet er ikke gemt før felterne er gyldige og du trykker «Gem»."
        }
        return "Kladde gemt. Husk at trykke «Gem» for at registrere kampen, eller fortsæt senere under «Fortsæt aktivt spil»."
    }

    private func restorePendingIfNeeded() {
        guard let json = gameDay.pendingHand?.draftJSON else { return }
        guard let snap = try? HandDraftPersistence.decode(json) else { return }
        HandDraftPersistence.apply(snap, to: draft)
        if snap.navigationStep == HandDraftPersistence.stepResultat {
            DispatchQueue.main.async {
                path.append(HandRoute.resultat)
            }
        }
        /// `stepMelding`: genskab kun udkastet; brugeren forbliver på meldingstrinnet.
    }
}

// MARK: - Delt UI

private struct DismissAddHandButton: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let gameDay: GameDay
    let onAnnuller: () -> Void

    var body: some View {
        Button("Annuller") {
            onAnnuller()
            HandDraftPersistence.deletePending(context: modelContext, gameDay: gameDay)
            dismiss()
        }
    }
}

private func trumpPicker(selection: Binding<Suit>) -> some View {
    HStack {
        Spacer()
        ForEach(Suit.allCases, id: \.self) { suit in
            Button {
                selection.wrappedValue = suit
            } label: {
                Text(suit.cardSymbol)
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .background(selection.wrappedValue == suit ? Color.accentColor.opacity(0.25) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.borderless)
        }
        Spacer()
    }
}

/// Vælg kulør; ingen forvalg. Tryk samme kulør igen for at fjerne valget (`nil`). Udelukkede kulører er inaktive.
private func optionalSuitPicker(selection: Binding<Suit?>, excludedSuits: Set<Suit> = []) -> some View {
    HStack {
        Spacer()
        ForEach(Suit.allCases, id: \.self) { suit in
            let excluded = excludedSuits.contains(suit)
            Button {
                guard !excluded else { return }
                if selection.wrappedValue == suit {
                    selection.wrappedValue = nil
                } else {
                    selection.wrappedValue = suit
                }
            } label: {
                Text(suit.cardSymbol)
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .background(selection.wrappedValue == suit && !excluded ? Color.accentColor.opacity(0.25) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.borderless)
            .disabled(excluded)
            .foregroundStyle(excluded ? Color.secondary.opacity(0.35) : Color.primary)
        }
        Spacer()
    }
}

// MARK: - Kort resume til «Seneste spil»

enum HandResumeCaption {
    /// Talesprog + kulør-ikoner (♠♥♦♣), gemmes i `RecordedHand.resumeCaption`.
    static func compactLine(from draft: HandInputDraft) -> String {
        if draft.kind == .duty {
            return "Duestraf til \(draft.dutySeat.playerDisplayName)"
        }
        if draft.isDuty {
            return "Duestraf til \(draft.dutySeat.playerDisplayName)"
        }
        switch draft.kind {
        case .normal:
            return normalLineSpoken(draft)
        case .sol:
            return solLineSpoken(draft)
        case .duty:
            return "Duestraf til \(draft.dutySeat.playerDisplayName)"
        }
    }

    struct CaptionDisplayParts: Sendable {
        var narrative: String
        /// Stik over/under bud (`nil` for ældre tekster uden `||`-kode, sol, duestraf).
        var trickDelta: Int?
    }

    /// Del resume op i fortælling + evt. stik-delta (kodet efter `||` i `resumeCaption`).
    static func displayParts(for hand: RecordedHand) -> CaptionDisplayParts {
        let trimmed = hand.resumeCaption.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = trimmed.isEmpty ? legacyFallback(for: hand) : trimmed
        if let range = base.range(of: "||") {
            let nar = String(base[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            let code = String(base[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            if let delta = parseDeltaToken(code) {
                return CaptionDisplayParts(
                    narrative: substituteSuitNamesWithSymbols(in: nar),
                    trickDelta: delta
                )
            }
        }
        return CaptionDisplayParts(
            narrative: substituteSuitNamesWithSymbols(in: base),
            trickDelta: nil
        )
    }

    /// Kun fortællingstekst (fx til enkel visning uden badge).
    static func displayResumeLine(for hand: RecordedHand) -> String {
        displayParts(for: hand).narrative
    }

    private static func parseDeltaToken(_ code: String) -> Int? {
        if let v = Int(code) { return v }
        if code.hasPrefix("+") { return Int(code.dropFirst()) }
        return nil
    }

    static func legacyFallback(for hand: RecordedHand) -> String {
        if let idx = hand.summaryLine.firstIndex(of: ":") {
            return String(hand.summaryLine[..<idx]).trimmingCharacters(in: .whitespaces)
        }
        return "Spil"
    }

    // MARK: - Normal (talesprog)

    private static func normalLineSpoken(_ d: HandInputDraft) -> String {
        let bid = d.bidTricks
        var sentence: String
        switch d.normalSubtype {
        case .alm:
            sentence = "\(bid) almindelige"
            if let t = d.trumpAlm {
                sentence += " med \(t.cardSymbol) som trumf"
            }
            if let ace = d.partnerAceSuit {
                sentence += " og \(ace.cardSymbol) som makker-es"
            }
        case .sans:
            sentence = "\(bid) sans uden trumf"
        case .gode:
            sentence = "\(bid) gode i \(Suit.clubs.cardSymbol) (fast trumf)"
        case .halve:
            sentence = "\(bid) halve"
            if let ace = d.partnerAceSuit {
                sentence += " til \(ace.cardSymbol)"
            }
            if let tr = d.trumpAfterPlay {
                sentence += " med \(tr.cardSymbol) som trumf"
            }
        case .vip:
            sentence = "\(bid) VIP \(vipOrdinalDanish(d.vipLevel))"
            if let tr = d.trumpAfterPlay {
                sentence += " med \(tr.cardSymbol) som trumf"
            }
        }
        /// `||` + kode vises som cirkel under «Seneste spil» (fx `||+2`, `||-1`, `||0`).
        return "\(sentence)||\(deltaToken(bid: d.bidTricks, actual: d.actualTricks))"
    }

    private static func vipOrdinalDanish(_ level: VipLevel) -> String {
        switch level {
        case .single: return "i første"
        case .double: return "i anden"
        case .triple: return "i tredje"
        }
    }

    private static func deltaToken(bid: Int, actual: Int) -> String {
        let delta = actual - bid
        if delta > 0 { return "+\(delta)" }
        if delta < 0 { return "\(delta)" }
        return "0"
    }

    // MARK: - Sol

    private static func solLineSpoken(_ d: HandInputDraft) -> String {
        "\(d.solBidder.playerDisplayName) meldte \(solTypeSpoken(d.solType))"
    }

    private static func solTypeSpoken(_ t: SolType) -> String {
        switch t {
        case .normal: return "sol"
        case .pure: return "ren sol"
        case .halfDealer: return "halv bordlægger"
        case .dealer: return "bordlægger-sol"
        }
    }

    // MARK: - Ældre tekst → ikoner

    private static func substituteSuitNamesWithSymbols(in text: String) -> String {
        var s = text
        let pairs: [(String, String)] = [
            ("almindeligt", "almindelige"),
            ("Hjerter", "♥"), ("hjerter", "♥"),
            ("Ruder", "♦"), ("ruder", "♦"),
            ("Spar", "♠"), ("spar", "♠"),
            ("Klør", "♣"), ("klør", "♣"),
        ]
        for (word, sym) in pairs {
            s = s.replacingOccurrences(of: word, with: sym)
        }
        return s
    }
}

