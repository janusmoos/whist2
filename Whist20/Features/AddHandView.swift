import SwiftData
import SwiftUI

// MARK: - Routing

private enum HandRoute: Hashable {
    /// Kun normale spil med undertype halve: trumf før resultat.
    case halveTrumf
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

    /// Resultat for sol: kun melder + «går med» tastes ind; resten udledes.
    var solTrickInputSeats: [Seat] {
        guard kind == .sol else { return [] }
        var out: [Seat] = [solBidder]
        for s in goingWith.sorted(by: { $0.rawValue < $1.rawValue }) where s != solBidder {
            out.append(s)
        }
        return out
    }

    /// Fordeler rest-stik på modstanderne så summen over fire pladser er 13 (kun kontraktsiden redigeres i UI).
    func syncSolOpponentTricksFromContractSide() {
        guard kind == .sol else { return }
        var copy = solTricks
        let contractList = [solBidder] + goingWith.filter { $0 != solBidder }.sorted { $0.rawValue < $1.rawValue }
        let contractSet = Set(contractList)
        let opponents = Seat.all.filter { !contractSet.contains($0) }
        let contractSum = contractList.reduce(0) { $0 + (copy[$1] ?? 0) }
        let remaining = 13 - contractSum
        if opponents.isEmpty {
            solTricks = copy
            return
        }
        if remaining < 0 {
            solTricks = copy
            return
        }
        let n = opponents.count
        let base = remaining / n
        let extras = remaining % n
        for (index, seat) in opponents.enumerated() {
            copy[seat] = base + (index < extras ? 1 : 0)
        }
        solTricks = copy
    }

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
            guard solContractTricksValid else { return false }
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

    private var solContractTricksValid: Bool {
        guard kind == .sol else { return true }
        let sum = solTrickInputSeats.reduce(0) { $0 + (solTricks[$1] ?? 0) }
        return sum <= 13
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
        .onChange(of: draft.normalSubtype) { _, newSubtype in
            if newSubtype != .halve && newSubtype != .vip {
                draft.trumpAfterPlay = nil
            }
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
                    if draft.kind == .normal && draft.normalSubtype == .halve {
                        HandDraftPersistence.upsertPending(
                            context: modelContext,
                            gameDay: gameDay,
                            draft: draft,
                            navigationStep: HandDraftPersistence.stepHalveTrumf
                        )
                        path.append(HandRoute.halveTrumf)
                    } else {
                        HandDraftPersistence.upsertPending(
                            context: modelContext,
                            gameDay: gameDay,
                            draft: draft,
                            navigationStep: HandDraftPersistence.stepResultat
                        )
                        path.append(HandRoute.resultat)
                    }
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
        Section {
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
        Section("Går med") {
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

// MARK: - Trin 1b: Halve — trumf (før resultat)

private struct HalveTrumpStepView: View {
    @Environment(\.modelContext) private var modelContext

    @Bindable var draft: HandInputDraft
    @Binding var path: NavigationPath
    let gameDay: GameDay

    var body: some View {
        Form {
            Section {
                MeldingStatusCard(
                    presentation: MeldingPresentation.from(
                        draft: draft,
                        navigationStepLabel: nil
                    )
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                .listRowBackground(Color.clear)
            }

            Section {
                Text("Vælg trumf for halve-spillet. Den bruges i pointberegning og vises på Aktivt spil med det samme.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                optionalSuitPicker(selection: $draft.trumpAfterPlay, excludedSuits: draft.makkerEsExcludedSuits)
            } header: {
                Text("Trumf")
            }
        }
        .navigationTitle("Trumf (halve)")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: draft.trumpAfterPlay) { _, newTrump in
            if let ace = draft.partnerAceSuit, let t = newTrump, ace == t {
                draft.partnerAceSuit = nil
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Tilbage") {
                    path.removeLast()
                }
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
                .disabled(draft.trumpAfterPlay == nil)
            }
        }
        .onAppear {
            HandDraftPersistence.upsertPending(
                context: modelContext,
                gameDay: gameDay,
                draft: draft,
                navigationStep: HandDraftPersistence.stepHalveTrumf
            )
        }
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
            if draft.kind == .sol {
                draft.syncSolOpponentTricksFromContractSide()
            }
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

        /// Halve: trumf vælges på forrige skærm (`HalveTrumpStepView`).
        if draft.normalSubtype == .vip {
            Section("Trumf") {
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
                "Du har valgt VIP i tredje og klør som trumf ved halve. Kontraktholdets point beregnes som ved andre VIP-spil og ganges derefter med 2 — det følger reglen om, at klør i tredje VIP tæller dobbelt."
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
        Section("Stik (melder og medspillere)") {
            ForEach(draft.solTrickInputSeats, id: \.self) { seat in
                Stepper("\(seat.playerDisplayName): \(draft.solTricks[seat] ?? 0)", value: bindingSolTricksContract(seat), in: 0 ... 13)
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

    private func bindingSolTricksContract(_ seat: Seat) -> Binding<Int> {
        Binding(
            get: { draft.solTricks[seat] ?? 0 },
            set: { newValue in
                var copy = draft.solTricks
                copy[seat] = newValue
                draft.solTricks = copy
                draft.syncSolOpponentTricksFromContractSide()
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

    private func persistPartnerSeatRaw(draft: HandInputDraft, kind: String) -> Int {
        guard kind == "normal", let p = draft.partner else { return -1 }
        return p.rawValue
    }

    private func persistSolAlliesJSON(draft: HandInputDraft, kind: String) -> String {
        guard kind == "sol" else { return "[]" }
        let arr = draft.goingWith.map(\.rawValue).sorted()
        guard let data = try? JSONEncoder().encode(arr),
              let str = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return str
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
        let caption = HandResumeCaption.compactLine(from: draft)
        let bidderSeat = persistBidderSeatRaw(draft: draft, kind: kind)
        let partnerSeat = persistPartnerSeatRaw(draft: draft, kind: kind)
        let solAlliesJSON = persistSolAlliesJSON(draft: draft, kind: kind)
        gameDay.migrateLegacyHandNumbersIfNeeded()
        let nextHandNumber = (gameDay.hands.map(\.handNumber).max() ?? 0) + 1
        let hand = RecordedHand(
            kindRaw: kind,
            summaryLine: "",
            scoresBySeatJSON: json,
            resumeCaption: caption,
            bidderSeatRaw: bidderSeat,
            partnerSeatRaw: partnerSeat,
            solAlliesSeatsJSON: solAlliesJSON,
            handNumber: nextHandNumber,
            gameDay: gameDay
        )
        hand.summaryLine = hand.displayResumeNarrative
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
                    case .halveTrumf:
                        HalveTrumpStepView(draft: draft, path: $path, gameDay: gameDay)
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
        let stepFromPending: String? = {
            guard let p = gameDay.pendingHand,
                  let snap = try? HandDraftPersistence.decode(p.draftJSON) else { return nil }
            return snap.navigationStep
        }()
        let step = stepFromPending
            ?? (path.isEmpty ? HandDraftPersistence.stepMelding : HandDraftPersistence.stepResultat)
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
        if draft.kind == .normal, draft.normalSubtype == .halve, draft.trumpAfterPlay == nil {
            return "Kladde gemt. Vælg trumf for halve under «Fortsæt aktivt spil» — den vises også på Aktivt spil, når den er valgt."
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
        } else if snap.navigationStep == HandDraftPersistence.stepHalveTrumf {
            DispatchQueue.main.async {
                path.append(HandRoute.halveTrumf)
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
    TrumpSuitPicker(selection: selection)
}

private struct TrumpSuitPicker: View {
    @Binding var selection: Suit
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack {
            Spacer()
            ForEach(Suit.allCases, id: \.self) { suit in
                Button {
                    selection = suit
                } label: {
                    Text(suit.cardSymbol)
                        .font(.title2)
                        .foregroundStyle(suit.playingCardForegroundColor(colorScheme: colorScheme))
                        .frame(width: 44, height: 44)
                        .background(selection == suit ? Color.accentColor.opacity(0.25) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.borderless)
            }
            Spacer()
        }
    }
}

/// Vælg kulør; ingen forvalg. Tryk samme kulør igen for at fjerne valget (`nil`). Udelukkede kulører er inaktive.
private func optionalSuitPicker(selection: Binding<Suit?>, excludedSuits: Set<Suit> = []) -> some View {
    OptionalSuitPicker(selection: selection, excludedSuits: excludedSuits)
}

private struct OptionalSuitPicker: View {
    @Binding var selection: Suit?
    var excludedSuits: Set<Suit> = []
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack {
            Spacer()
            ForEach(Suit.allCases, id: \.self) { suit in
                let excluded = excludedSuits.contains(suit)
                Button {
                    guard !excluded else { return }
                    if selection == suit {
                        selection = nil
                    } else {
                        selection = suit
                    }
                } label: {
                    Text(suit.cardSymbol)
                        .font(.title2)
                        .foregroundStyle(symbolColor(suit: suit, excluded: excluded))
                        .frame(width: 44, height: 44)
                        .background(selection == suit && !excluded ? Color.accentColor.opacity(0.25) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.borderless)
                .disabled(excluded)
            }
            Spacer()
        }
    }

    private func symbolColor(suit: Suit, excluded: Bool) -> Color {
        if excluded { return Color.secondary.opacity(0.35) }
        return suit.playingCardForegroundColor(colorScheme: colorScheme)
    }
}

// MARK: - Kort resume til «Seneste spil»

enum HandResumeCaption {
    /// Kort status under «Aktivt spil» (kladde) — samme rå trin som i `PendingHand`.
    static func pendingNavigationStepHint(navigationStepRaw: String?) -> String? {
        guard let s = navigationStepRaw else { return nil }
        switch s {
        case HandDraftPersistence.stepMelding:
            return "Trin: melding (indtastning)"
        case HandDraftPersistence.stepResultat:
            return "Trin: resultat (indtastning)"
        case HandDraftPersistence.stepHalveTrumf:
            return "Trin: trumf for halve (indtastning)"
        default:
            return nil
        }
    }

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
        /// Fuld talesprogssætning (inkl. stikudfald for normale bud med `||`-kode i `resumeCaption`).
        var narrative: String
        /// Forældet — alt vises i `narrative`; bevares som `nil` fra `displayParts`.
        var trickDelta: Int?
    }

    /// Én sammenhængende fortælling: kulør som symboler, evt. «gik med» fra JSON, stikudfald som talesprog.
    static func displayParts(for hand: RecordedHand) -> CaptionDisplayParts {
        let trimmed = hand.resumeCaption.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = trimmed.isEmpty ? legacyFallback(for: hand) : trimmed

        let (narrativeRaw, parsedDelta): (String, Int?) = {
            if let range = base.range(of: "||") {
                let nar = String(base[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                let code = String(base[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                return (nar, parseDeltaToken(code))
            }
            return (base, nil)
        }()

        var narrative = substituteSuitNamesWithSymbols(in: narrativeRaw)
        narrative = applyLegacyResumeWordFixes(narrative)
        narrative = appendSolGoingWithToNarrative(narrative, hand: hand)
        narrative = prependNormalBidderIfNeeded(narrative, hand: hand)
        if let d = parsedDelta {
            let bid = parseBidTricksAfterMeldte(in: narrative)
            narrative += trickOutcomeSpoken(delta: d, bidTricks: bid, hand: hand)
        }
        narrative = stripUnwantedResumePhrases(narrative)
        return CaptionDisplayParts(narrative: narrative, trickDelta: nil)
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

    /// Fjerner formuleringer der ikke må bruges i halve-resume (fx «efter spillet») og retter ældre ordlyd.
    private static func stripUnwantedResumePhrases(_ text: String) -> String {
        var s = text
        let banned = [" efter spillet", " bagefter", " efter spil"]
        for b in banned {
            s = s.replacingOccurrences(of: b, with: "", options: .caseInsensitive)
        }
        while s.contains("  ") {
            s = s.replacingOccurrences(of: "  ", with: " ")
        }
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func applyLegacyResumeWordFixes(_ text: String) -> String {
        var t = text.replacingOccurrences(of: "bordlægger-sol", with: "bordlægger", options: .caseInsensitive)
        t = t.replacingOccurrences(of: " (fast trumf)", with: "")
        return t
    }

    /// Ældre kampe uden «… meldte …» i teksten — tilføj melder ud fra `bidderSeatRaw`.
    private static func prependNormalBidderIfNeeded(_ narrative: String, hand: RecordedHand) -> String {
        guard hand.kindRaw == "normal",
              hand.bidderSeatRaw >= 0,
              let bidder = Seat(rawValue: hand.bidderSeatRaw) else {
            return narrative
        }
        let trimmed = narrative.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return narrative }
        let name = bidder.playerDisplayName
        let prefix = "\(name) meldte "
        if trimmed.hasPrefix(prefix) { return narrative }
        if trimmed.lowercased().hasPrefix("\(name.lowercased()) meldte ") { return narrative }
        return prefix + trimmed
    }

    /// Melder og makker som navne til stikudfald (normal); ellers melder alene.
    private static func contractSideNames(for hand: RecordedHand) -> String {
        guard hand.kindRaw == "normal" else {
            if let s = Seat(rawValue: hand.bidderSeatRaw) { return s.playerDisplayName }
            return "Spillerne"
        }
        guard let bidder = Seat(rawValue: hand.bidderSeatRaw) else { return "Spillerne" }
        guard hand.partnerSeatRaw >= 0, let partner = Seat(rawValue: hand.partnerSeatRaw) else {
            return bidder.playerDisplayName
        }
        if bidder == partner {
            return bidder.playerDisplayName
        }
        return "\(bidder.playerDisplayName) og \(partner.playerDisplayName)"
    }

    /// Første heltal efter sidste «meldte » i normal-resumé (meldt antal stik).
    private static func parseBidTricksAfterMeldte(in narrative: String) -> Int? {
        guard let range = narrative.range(of: "meldte ", options: [.backwards, .caseInsensitive]) else { return nil }
        let after = narrative[range.upperBound...].trimmingCharacters(in: .whitespaces)
        return after.split(separator: " ").first.flatMap { Int($0) }
    }

    /// Stikudfald: `… tog 10 stik (+2)` / `… tog 6 stik (-2)` (kun normale spil med `||` i gemt tekst).
    private static func trickOutcomeSpoken(delta: Int, bidTricks: Int?, hand: RecordedHand) -> String {
        let who = contractSideNames(for: hand)
        guard let bid = bidTricks else {
            return trickOutcomeSpokenLegacy(delta: delta, who: who)
        }
        if delta == 0 {
            return ", og \(who) ramte buddet præcis på stikkene"
        }
        let actual = bid + delta
        let paren = delta > 0 ? "(+\(delta))" : "(\(delta))"
        return ", og \(who) tog \(actual) stik \(paren)"
    }

    private static func trickOutcomeSpokenLegacy(delta: Int, who: String) -> String {
        switch delta {
        case 0:
            return ", og \(who) ramte buddet præcis på stikkene"
        case 1:
            return ", og \(who) tog ét stik for meget"
        case let x where x > 1:
            return ", og \(who) tog \(x) stik for meget"
        case -1:
            return ", og \(who) tog ét stik for lidt"
        case let x where x < -1:
            return ", og \(who) tog \(-x) stik for lidt"
        default:
            return ""
        }
    }

    // MARK: - Normal (talesprog)

    private static func normalLineSpoken(_ d: HandInputDraft) -> String {
        let bid = d.bidTricks
        let melder = d.bidder.playerDisplayName
        let core: String
        switch d.normalSubtype {
        case .alm:
            var s = "\(bid) almindelige"
            if let t = d.trumpAlm {
                s += " med \(t.cardSymbol) som trumf"
            }
            if let ace = d.partnerAceSuit {
                s += " og \(ace.cardSymbol) som makker-es"
            }
            core = s
        case .sans:
            core = "\(bid) sans uden trumf"
        case .gode:
            core = "\(bid) gode i \(Suit.clubs.cardSymbol)"
        case .halve:
            var s = "\(bid) halve"
            if let ace = d.partnerAceSuit {
                s += " til \(ace.cardSymbol)"
            }
            if let tr = d.trumpAfterPlay {
                s += " med \(tr.cardSymbol) som trumf"
            }
            core = s
        case .vip:
            var s = "\(bid) VIP \(vipOrdinalDanish(d.vipLevel))"
            if let tr = d.trumpAfterPlay {
                s += " med \(tr.cardSymbol) som trumf"
            }
            core = s
        }
        /// `||` + kode parses til stikudfald i visning.
        return "\(melder) meldte \(core)||\(deltaToken(bid: d.bidTricks, actual: d.actualTricks))"
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
        var sentence = "\(d.solBidder.playerDisplayName) meldte \(solTypeSpoken(d.solType))"
        let allies = d.goingWith.sorted { $0.rawValue < $1.rawValue }
        if !allies.isEmpty {
            let names = allies.map(\.playerDisplayName).joined(separator: ", ")
            sentence += ", og \(names) gik med"
        }
        sentence += solOutcomeSpoken(from: d)
        return sentence
    }

    private static func solOutcomeSpoken(from d: HandInputDraft) -> String {
        let bidderTricks = d.solTricks[d.solBidder] ?? 0
        let limit = d.solType.maxAllowedTricks
        if bidderTricks <= limit {
            return ", og melderen holdt solen"
        }
        return ", og melderen overskred solens grænse"
    }

    /// Tilføjer «gik med» fra gemt JSON når det ikke allerede står i teksten (ældre resuméer).
    private static func appendSolGoingWithToNarrative(_ narrative: String, hand: RecordedHand) -> String {
        guard hand.kindRaw == "sol" else { return narrative }
        let allies = solAlliesSeats(from: hand)
        guard !allies.isEmpty else { return narrative }
        if narrative.range(of: "gik med", options: .caseInsensitive) != nil
            || narrative.range(of: "går med", options: .caseInsensitive) != nil {
            return narrative
        }
        let names = allies.map(\.playerDisplayName).joined(separator: ", ")
        if narrative.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "\(names) gik med"
        }
        return "\(narrative), og \(names) gik med"
    }

    private static func solAlliesSeats(from hand: RecordedHand) -> [Seat] {
        guard hand.kindRaw == "sol" else { return [] }
        guard let data = hand.solAlliesSeatsJSON.data(using: .utf8),
              let rawInts = try? JSONDecoder().decode([Int].self, from: data) else {
            return []
        }
        return rawInts.compactMap { Seat(rawValue: $0) }.sorted { $0.rawValue < $1.rawValue }
    }

    private static func solTypeSpoken(_ t: SolType) -> String {
        switch t {
        case .normal: return "sol"
        case .pure: return "ren sol"
        case .halfDealer: return "halv bordlægger"
        case .dealer: return "bordlægger"
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

