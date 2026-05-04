import SwiftData
import SwiftUI

/// Hub efter et gemt spil: hurtig tilføjelse, seneste spil, pladsholdere til statistik m.m.
struct GameDayStartView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var gameDay: GameDay
    /// Når sand, åbnes «Tilføj spil»-arket én gang ved første visning (fx fra forsiden).
    var presentAddHandSheetOnAppear: Bool = false

    @State private var showAddHand = false
    @State private var sheetDismissNotice: String?
    @State private var didConsumePresentAddHand = false

    private var hasActivePendingHand: Bool {
        gameDay.pendingHand != nil
    }

    var body: some View {
        List {
            Section {
                Button {
                    showAddHand = true
                } label: {
                    Label(
                        hasActivePendingHand ? "Fortsæt aktivt spil" : "Tilføj spil",
                        systemImage: hasActivePendingHand ? "arrow.triangle.2.circlepath.circle.fill" : "plus.circle.fill"
                    )
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .buttonStyle(.borderedProminent)
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            }

            Section {
                NavigationLink {
                    ActiveGameView(gameDay: gameDay)
                } label: {
                    Label("Aktivt spil", systemImage: "rectangle.and.hand.point.up.left.filled")
                }
                if !hasActivePendingHand {
                    Text("Når et spil er påbegyndt uden at være gemt, vises meldingen under «Aktivt spil».")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Seneste spil") {
                if let hand = latestHand {
                    NavigationLink {
                        HandDetailView(hand: hand, gameDay: gameDay)
                    } label: {
                        LatestHandResumeLabel(hand: hand)
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 4, bottom: 6, trailing: 12))
                } else {
                    Text("Ingen gemte kampe endnu. Brug knappen ovenfor når I har spillet.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                dummyCard(
                    title: "Statistik",
                    systemImage: "chart.bar.xaxis",
                    message: "Oversigt over spiltyper, makkerpar og tendenser — kommer senere."
                )
            }

            Section {
                dummyCard(
                    title: "Pointfordeling",
                    systemImage: "person.3.sequence",
                    message: "Samlede point pr. spiller og udvikling over aftenen — kommer senere."
                )
            }

            Section {
                NavigationLink {
                    GameDaySettingsAndHandsView(gameDay: gameDay)
                } label: {
                    Label("Spilledag & alle kampe", systemImage: "list.bullet.rectangle")
                }
            }
        }
        .navigationTitle(gameDay.title)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showAddHand) {
            AddHandView(gameDay: gameDay) { message in
                sheetDismissNotice = message
            }
        }
        .alert("Aktivt spil", isPresented: Binding(
            get: { sheetDismissNotice != nil },
            set: { if !$0 { sheetDismissNotice = nil } }
        )) {
            Button("OK", role: .cancel) { sheetDismissNotice = nil }
        } message: {
            Text(sheetDismissNotice ?? "")
        }
        .onAppear {
            gameDay.migrateLegacyHandNumbersIfNeeded()
            try? modelContext.save()
            if presentAddHandSheetOnAppear, !didConsumePresentAddHand {
                didConsumePresentAddHand = true
                showAddHand = true
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddHand = true
                } label: {
                    Image(systemName: hasActivePendingHand ? "arrow.triangle.2.circlepath" : "plus")
                }
                .accessibilityLabel(hasActivePendingHand ? "Fortsæt aktivt spil" : "Tilføj spil")
            }
        }
    }

    private var latestHand: RecordedHand? {
        gameDay.hands.max(by: { $0.playedAt < $1.playedAt })
    }

    @ViewBuilder
    private func dummyCard(title: String, systemImage: String, message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(.tertiary)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Stik over/under (badge)

private struct TrickDeltaBadge: View {
    let delta: Int

    var body: some View {
        Text(label)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(foregroundColor)
            .frame(width: 30, height: 30)
            .background {
                Circle()
                    .fill(fillColor)
            }
            .overlay {
                Circle()
                    .strokeBorder(borderColor, lineWidth: 1)
            }
            .accessibilityHidden(true)
    }

    private var label: String {
        if delta > 0 { return "+\(delta)" }
        if delta < 0 { return "\(delta)" }
        return "0"
    }

    private var fillColor: Color {
        switch delta {
        case let x where x > 0:
            return Color.green.opacity(0.38)
        case let x where x < 0:
            return Color.red.opacity(0.38)
        default:
            return Color.secondary.opacity(0.2)
        }
    }

    private var borderColor: Color {
        switch delta {
        case let x where x > 0:
            return Color.green.opacity(0.55)
        case let x where x < 0:
            return Color.red.opacity(0.55)
        default:
            return Color.secondary.opacity(0.35)
        }
    }

    private var foregroundColor: Color {
        switch delta {
        case let x where x > 0:
            return Color(red: 0.05, green: 0.45, blue: 0.18)
        case let x where x < 0:
            return Color(red: 0.55, green: 0.08, blue: 0.1)
        default:
            return Color.secondary
        }
    }
}

// MARK: - Seneste spil (resume med nummer + spiller-knapper)

private struct LatestHandResumeLabel: View {
    let hand: RecordedHand

    private var scores: [Seat: Int] {
        HandScorePersistence.decodeScores(hand.scoresBySeatJSON)
    }

    /// Fast pladsorden: nord → øst → syd → vest (rå værdi), uafhængigt af JSON-nøgler.
    private var orderedSeats: [Seat] {
        Seat.all.sorted { $0.rawValue < $1.rawValue }
    }

    private var captionParts: HandResumeCaption.CaptionDisplayParts {
        HandResumeCaption.displayParts(for: hand)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            handNumberStrip
            VStack(alignment: .leading, spacing: 6) {
                playerScoreGrid
                HStack(alignment: .center, spacing: 8) {
                    Text(captionParts.narrative)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineSpacing(1)
                        .lineLimit(5)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if let delta = captionParts.trickDelta {
                        TrickDeltaBadge(delta: delta)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(captionAccessibilityLabel)
            }
            .padding(.leading, 10)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minHeight: 76)
    }

    private var captionAccessibilityLabel: String {
        var parts = [captionParts.narrative]
        if let d = captionParts.trickDelta {
            if d == 0 {
                parts.append("Lige på budet.")
            } else if d > 0 {
                parts.append("\(d) stik over budet.")
            } else {
                parts.append("\(-d) stik under budet.")
            }
        }
        return parts.joined(separator: " ")
    }

    private var handNumberStrip: some View {
        Text(hand.handNumber > 0 ? "#\(hand.handNumber)" : "—")
            .font(.title3.weight(.bold).monospacedDigit())
            .foregroundStyle(.secondary)
            .frame(width: 48)
            .frame(minHeight: 76, maxHeight: .infinity)
            .padding(.trailing, 2)
            .overlay(alignment: .trailing) {
                Rectangle()
                    .fill(Color.secondary.opacity(0.28))
                    .frame(width: 1)
            }
    }

    private var bidderSeat: Seat? {
        guard hand.bidderSeatRaw >= 0, let s = Seat(rawValue: hand.bidderSeatRaw) else { return nil }
        guard hand.kindRaw == "normal" || hand.kindRaw == "sol" else { return nil }
        return s
    }

    private var playerScoreGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
            ForEach(orderedSeats, id: \.self) { seat in
                let value = scores[seat] ?? 0
                let isBidder = bidderSeat == seat
                Text("\(seat.playerDisplayName) \(scoreText(value))")
                    .font(isBidder ? .caption2.weight(.bold) : .caption2.weight(.semibold))
                    .textCase(isBidder ? .uppercase : nil)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 4)
                    .background {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(chipBackground(for: value))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                    }
                    .accessibilityLabel(
                        isBidder
                            ? "\(seat.playerDisplayName), melder, \(scoreText(value)) point"
                            : "\(seat.playerDisplayName), \(scoreText(value)) point"
                    )
            }
        }
    }

    private func scoreText(_ value: Int) -> String {
        if value > 0 { return "+\(value)" }
        return "\(value)"
    }

    private func chipBackground(for value: Int) -> Color {
        switch value {
        case let x where x > 0:
            return Color.green.opacity(0.32)
        case let x where x < 0:
            return Color.red.opacity(0.32)
        default:
            return Color.secondary.opacity(0.12)
        }
    }
}

// MARK: - Spilledag, bord og fuld kamp-liste (sekundær skærm)

private struct GameDaySettingsAndHandsView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var gameDay: GameDay

    var body: some View {
        Form {
            Section("Spilledag") {
                TextField("Titel", text: $gameDay.title)
                LabeledContent("Oprettet") {
                    Text(gameDay.createdAt.formatted(date: .long, time: .shortened))
                }
            }

            Section("Bord") {
                Text("Fast plads → navn. Point pr. kamp lægges sammen her senere.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                ForEach(Seat.all, id: \.self) { seat in
                    LabeledContent(seat.compassLabel) {
                        Text(seat.playerDisplayName)
                            .fontWeight(.medium)
                    }
                }
            }

            Section("Alle kampe") {
                if sortedHands.isEmpty {
                    Text("Ingen gemte kampe endnu.")
                        .foregroundStyle(.secondary)
                }
                ForEach(sortedHands, id: \.id) { hand in
                    NavigationLink {
                        HandDetailView(hand: hand, gameDay: gameDay)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(handListTitleLine(hand))
                                .font(.subheadline)
                                .lineLimit(4)
                            Text(hand.playedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete(perform: deleteHands)
            }
        }
        .navigationTitle("Spilledag")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            gameDay.migrateLegacyHandNumbersIfNeeded()
            try? modelContext.save()
        }
    }

    private func handListTitleLine(_ hand: RecordedHand) -> String {
        if hand.handNumber > 0 {
            return "#\(hand.handNumber) \(hand.summaryLine)"
        }
        return hand.summaryLine
    }

    private var sortedHands: [RecordedHand] {
        gameDay.hands.sorted { $0.playedAt > $1.playedAt }
    }

    private func deleteHands(at offsets: IndexSet) {
        let list = sortedHands
        for index in offsets {
            modelContext.delete(list[index])
        }
        try? modelContext.save()
    }
}
