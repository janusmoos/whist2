import SwiftData
import SwiftUI

/// Første skærm: kompakt 2×2 grid + live-boks med aktivt / seneste spil.
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GameDay.createdAt, order: .reverse) private var gameDays: [GameDay]

    @Binding var navigationPath: NavigationPath
    @State private var alertMessage: String?
    @State private var showEndGameDayConfirm = false

    private var activeGameDay: GameDay? {
        GameDay.activeDay(in: gameDays)
    }

    private var hasActivePendingHand: Bool {
        activeGameDay?.pendingHand != nil
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: 20) {
                    quickGrid
                        .padding(.top, 8)

                    liveStatusBox
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
            .navigationTitle("Whist 2.0")
            .navigationBarTitleDisplayMode(.large)
            .environment(\.homeNavigationPath, $navigationPath)
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .senesteSpil:
                    SenesteSpilView()
                case .activeGame(let gameDayId):
                    if let day = gameDays.first(where: { $0.id == gameDayId }) {
                        ActiveGameView(gameDay: day)
                    } else {
                        missingContent(title: "Spilledag findes ikke")
                    }
                case .newGameDay:
                    NewGameDayView(path: $navigationPath)
                case .gameDay(let id, let openAdd):
                    if let day = gameDays.first(where: { $0.id == id }) {
                        GameDayStartView(gameDay: day, presentAddHandSheetOnAppear: openAdd)
                    } else {
                        missingContent(title: "Spilledag findes ikke")
                    }
                case .hand(let dayId, let handId):
                    if let day = gameDays.first(where: { $0.id == dayId }),
                       let hand = day.hands.first(where: { $0.id == handId }) {
                        HandDetailView(hand: hand, gameDay: day)
                    } else {
                        missingContent(title: "Kamp findes ikke")
                    }
                case .standings:
                    StandingsView()
                case .settings:
                    AppSettingsView()
                case .scorecard:
                    ScorecardView()
                case .allGameDays:
                    GameDaysView()
                }
            }
        }
        .alert("Bemærk", isPresented: Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) {
            Button("OK", role: .cancel) { alertMessage = nil }
        } message: {
            Text(alertMessage ?? "")
        }
        .alert("Afslut spilledag?", isPresented: $showEndGameDayConfirm) {
            Button("Annuller", role: .cancel) {}
            Button("Afslut", role: .destructive) {
                if let day = activeGameDay {
                    day.close(modelContext: modelContext)
                }
            }
        } message: {
            Text(
                GameDaySessionDialogs.endGameDayMessage(
                    hasPendingHand: activeGameDay?.pendingHand != nil
                )
            )
        }
    }

    // MARK: - 2×2 Grid

    private var quickGrid: some View {
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        return LazyVGrid(columns: columns, spacing: 12) {
            if activeGameDay != nil {
                gridButton(
                    title: "Afslut spilledag",
                    systemImage: "flag.checkered",
                    tint: .orange
                ) {
                    showEndGameDayConfirm = true
                }
            } else {
                gridButton(
                    title: "Ny spilledag",
                    systemImage: "calendar.badge.plus",
                    tint: .accentColor
                ) {
                    navigationPath.append(HomeRoute.newGameDay)
                }
            }

            gridButton(
                title: "Alle spilledage",
                systemImage: "calendar",
                tint: .accentColor
            ) {
                navigationPath.append(HomeRoute.allGameDays)
            }

            gridButton(
                title: "Stilling",
                systemImage: "list.number",
                tint: .accentColor
            ) {
                navigationPath.append(HomeRoute.standings)
            }

            gridButton(
                title: "Indstillinger",
                systemImage: "gearshape.fill",
                tint: .secondary
            ) {
                navigationPath.append(HomeRoute.settings)
            }
        }
    }

    private func gridButton(
        title: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .imageScale(.large)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .foregroundStyle(tint)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(tint.opacity(0.1))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(tint.opacity(0.25), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    // MARK: - Live-boks: aktivt spil eller seneste afsluttede

    @ViewBuilder
    private var liveStatusBox: some View {
        if let day = activeGameDay, hasActivePendingHand {
            activeGameBox(gameDay: day)
        } else if let (day, _) = latestFinishedPair {
            recentGamesBox(gameDay: day)
        } else {
            emptyStatusBox
        }
    }

    /// Aktivt spil: resumé-tekst fra kladden.
    private func activeGameBox(gameDay: GameDay) -> some View {
        let loaded = loadDraft(for: gameDay)
        return VStack(alignment: .leading, spacing: 10) {
            Label("Aktivt spil", systemImage: "circle.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(.orange)
                .symbolRenderingMode(.multicolor)
            if let (draft, step) = loaded {
                let resumeLine = HandResumeCaption.presentTenseLine(from: draft)
                SuitColoredInlineText.build(resumeLine, colorScheme: colorScheme)
                    .font(.subheadline.weight(.semibold))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Text(gameDay.title)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.orange.opacity(0.3), lineWidth: 1.5)
        }
    }

    /// Seneste afsluttede kamp: tile-layout à la MeldingStatusCard.
    private func recentGamesBox(gameDay: GameDay) -> some View {
        guard let (_, hand) = latestFinishedPair else {
            return AnyView(EmptyView())
        }
        let scores = HandScorePersistence.decodeScores(hand.scoresBySeatJSON)
        let seats = gameDay.seatOrder
        let bidderName: String? = Seat(rawValue: hand.bidderSeatRaw)?.playerDisplayName
        let partnerName: String? = {
            guard hand.kindRaw == "normal", hand.partnerSeatRaw >= 0 else { return nil }
            return Seat(rawValue: hand.partnerSeatRaw)?.playerDisplayName
        }()
        let parsed = parseResumeDetails(hand)

        return AnyView(
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Seneste spil")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Spacer()
                    Text("#\(hand.handNumber)")
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.tertiary)
                }

                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        if let name = bidderName {
                            infoTile(label: "Melder", value: name)
                        }
                        infoTile(label: "Type", value: parsed.typeLabel)
                    }

                    if hand.kindRaw != "duty" {
                        let hasTrump = parsed.trump != nil
                        let hasBid = parsed.bidTricks != nil
                        let hasPartner = partnerName != nil
                        let hasStik = parsed.stikText != nil

                        if hasTrump || hasBid || hasPartner || hasStik {
                            HStack(spacing: 8) {
                                if let p = partnerName {
                                    infoTile(label: "Makker", value: p)
                                }
                                if let bid = parsed.bidTricks {
                                    infoTile(label: "Meldt", value: "\(bid) stik")
                                }
                            }
                        }

                        if hasTrump || hasStik {
                            HStack(spacing: 8) {
                                if let trump = parsed.trump {
                                    infoTile(label: "Trumf", value: trump)
                                }
                                if let stik = parsed.stikText {
                                    infoTile(label: "Stik", value: stik)
                                }
                            }
                        }
                    }
                }

                HStack(spacing: 6) {
                    ForEach(seats, id: \.self) { seat in
                        let v = scores[seat] ?? 0
                        HStack(spacing: 3) {
                            Text(String(seat.playerDisplayName.prefix(1)))
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text(v > 0 ? "+\(v)" : "\(v)")
                                .font(.subheadline.weight(.bold).monospacedDigit())
                                .foregroundStyle(v > 0 ? .green : v < 0 ? .red : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, 2)

                Text(gameDay.title)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.thinMaterial)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            }
        )
    }

    private func infoTile(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.thinMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private struct ResumeDetails {
        var typeLabel: String
        var bidTricks: Int?
        var trump: String?
        var stikText: String?
    }

    private func parseResumeDetails(_ hand: RecordedHand) -> ResumeDetails {
        let caption = hand.resumeCaption
        var details = ResumeDetails(typeLabel: "—")

        switch hand.kindRaw {
        case "duty":
            details.typeLabel = "Duestraf"
            return details
        case "sol":
            details.typeLabel = parseSolType(caption)
            return details
        default:
            break
        }

        details.typeLabel = parseNormalType(caption)
        details.bidTricks = parseBidTricks(caption)
        details.trump = parseTrump(caption)

        if let range = caption.range(of: "||") {
            let code = String(caption[range.upperBound...]).trimmingCharacters(in: .whitespaces)
            if let delta = Int(code.hasPrefix("+") ? String(code.dropFirst()) : code),
               let bid = details.bidTricks {
                let actual = bid + delta
                let sign = delta > 0 ? "+\(delta)" : delta < 0 ? "\(delta)" : "±0"
                details.stikText = "\(actual) (\(sign))"
            }
        }

        return details
    }

    private func parseNormalType(_ caption: String) -> String {
        let lower = caption.lowercased()
        if lower.contains("vip tredje") || lower.contains("vip 3") { return "VIP i 3." }
        if lower.contains("vip anden") || lower.contains("vip 2") { return "VIP i 2." }
        if lower.contains("vip første") || lower.contains("vip 1") || lower.contains("vip") { return "VIP i 1." }
        if lower.contains("(gode)") { return "Gode" }
        if lower.contains("halve") { return "Halve" }
        if lower.contains("sans") { return "Sans" }
        if lower.contains("almindelige") { return "Almindelig" }
        return "Normal"
    }

    private func parseSolType(_ caption: String) -> String {
        let lower = caption.lowercased()
        if lower.contains("bordlægger") && !lower.contains("halv") { return "Hel bordlægger" }
        if lower.contains("halv bordlægger") || lower.contains("halv-bordlægger") { return "Halv bordlægger" }
        if lower.contains("ren sol") || lower.contains("ren-sol") { return "Ren sol" }
        return "Sol"
    }

    private func parseBidTricks(_ caption: String) -> Int? {
        guard let range = caption.range(of: "meldte ", options: [.backwards, .caseInsensitive]) else { return nil }
        let after = caption[range.upperBound...].trimmingCharacters(in: .whitespaces)
        return after.split(separator: " ").first.flatMap { Int($0) }
    }

    private func parseTrump(_ caption: String) -> String? {
        let suitSymbols: [(symbol: String, name: String)] = [
            ("♠", "Spar"), ("♥", "Hjerter"), ("♦", "Ruder"), ("♣", "Klør"),
        ]
        if caption.lowercased().contains("sans") { return nil }
        if caption.lowercased().contains("(gode)") { return "♣" }
        guard let range = caption.range(of: "som trumf", options: .caseInsensitive) else { return nil }
        let before = caption[..<range.lowerBound]
        for (symbol, _) in suitSymbols {
            if before.contains(symbol) { return symbol }
        }
        return nil
    }

    private var emptyStatusBox: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.title2)
                .foregroundStyle(.tertiary)
            Text("Opret en spilledag for at komme i gang.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 16)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        }
    }

    // MARK: - Helpers

    @Environment(\.colorScheme) private var colorScheme

    private var latestFinishedPair: (gameDay: GameDay, hand: RecordedHand)? {
        var best: (GameDay, RecordedHand)?
        for day in gameDays {
            for hand in day.hands {
                guard let cur = best else {
                    best = (day, hand)
                    continue
                }
                if hand.playedAt > cur.1.playedAt {
                    best = (day, hand)
                }
            }
        }
        return best
    }

    private func loadDraft(for gameDay: GameDay) -> (draft: HandInputDraft, stepRaw: String?)? {
        guard let json = gameDay.pendingHand?.draftJSON,
              let snap = try? HandDraftPersistence.decode(json) else { return nil }
        let d = HandInputDraft()
        HandDraftPersistence.apply(snap, to: d)
        return (d, snap.navigationStep)
    }

    @ViewBuilder
    private func missingContent(title: String) -> some View {
        ContentUnavailableView(title, systemImage: "exclamationmark.triangle")
    }
}

// MARK: - Indstillinger

private struct AppSettingsView: View {
    var body: some View {
        Form {
            Section("Opslagsværk") {
                NavigationLink(value: HomeRoute.scorecard) {
                    Label("Scorecard", systemImage: "tablecells")
                }
            }

            Section {
                Text("Her kommer snart valg for navne, regler, tema og mere.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Indstillinger")
        .navigationBarTitleDisplayMode(.inline)
    }
}
