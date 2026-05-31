import SwiftData
import SwiftUI

/// Hub efter et gemt spil: hurtig tilføjelse, seneste spil, pladsholdere til statistik m.m.
struct GameDayStartView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Bindable var gameDay: GameDay
    /// Når sand, åbnes «Tilføj spil»-arket én gang ved første visning (fx fra forsiden).
    var presentAddHandSheetOnAppear: Bool = false

    @Query(sort: \GameDay.createdAt, order: .reverse) private var allGameDays: [GameDay]

    @State private var showAddHand = false
    @State private var toastMessage: String?
    @State private var toastWorkItem: DispatchWorkItem?
    @State private var didConsumePresentAddHand = false
    @State private var showResumeBlocked = false

    private var hasActivePendingHand: Bool {
        gameDay.pendingHand != nil
    }

    private var canStartOrContinueHand: Bool {
        gameDay.isActive || hasActivePendingHand
    }

    var body: some View {
        Group {
            if gameDay.isActive {
                activeGameDayContent
            } else {
                finishedGameDayContent
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddHand) {
            AddHandView(
                gameDay: gameDay,
                onDismissSaveNotice: { message in showBriefToast(message) },
                onSaved: { _, backupMessage in
                    if backupMessage != "Lokal backup gemt" {
                        showBriefToast(backupMessage)
                    }
                }
            )
        }
        .overlay(alignment: .top) {
            if let msg = toastMessage {
                Text(msg)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(ActiveGamePosterStyle.toastForegroundColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background {
                        if reduceTransparency {
                            ActiveGamePosterStyle.toastBackgroundColor
                        } else {
                            Rectangle()
                                .fill(.ultraThinMaterial.opacity(0.85))
                                .background(Color.primary.opacity(0.7))
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onTapGesture { dismissBriefToast() }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: toastMessage != nil)
        .onAppear {
            gameDay.migrateLegacyHandNumbersIfNeeded()
            try? modelContext.save()
            if presentAddHandSheetOnAppear, !didConsumePresentAddHand, canStartOrContinueHand {
                didConsumePresentAddHand = true
                showAddHand = true
            }
        }
        .toolbar {
            if gameDay.isActive {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("Nyt spil")
                            .font(.headline.weight(.semibold))
                        Text("Spilledag: \(gameDay.title)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Nyt spil, spilledag \(gameDay.title)")
                }

                ToolbarItemGroup(placement: .primaryAction) {
                    if canStartOrContinueHand {
                        Button {
                            showAddHand = true
                        } label: {
                            Image(systemName: hasActivePendingHand ? "arrow.triangle.2.circlepath" : "plus")
                        }
                        .accessibilityLabel(hasActivePendingHand ? "Fortsæt aktivt spil" : "Tilføj spil")
                    }
                }
            }
        }
        .alert("Kan ikke genoptage", isPresented: $showResumeBlocked) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(GameDaySessionDialogs.resumeBlocked)
        }
    }

    private var activeGameDayContent: some View {
        List {
            Section("Seneste spil") {
                if let hand = latestHand {
                    VStack(alignment: .leading, spacing: 10) {
                        RecordedHandCardIllustration(hand: hand, isCompact: true)
                        ActiveGameResumePanel(
                            resumeLine: ActiveGamePosterText.resultResumeLine(for: hand),
                            colorScheme: colorScheme
                        )
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                    .listRowBackground(Color.clear)
                } else {
                    Text("Ingen gemte kampe endnu. Brug «Tilføj spil» når spilledagen er aktiv.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var finishedGameDayContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                FinishedGameDayHeader(gameDay: gameDay)

                FinishedGameDayStatisticsArea(
                    gameDay: gameDay,
                    hands: handsNewestFirst
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 28)
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private var latestHand: RecordedHand? {
        gameDay.hands.max(by: { $0.playedAt < $1.playedAt })
    }

    private var handsNewestFirst: [RecordedHand] {
        gameDay.hands.sorted { a, b in
            if a.handNumber > 0, b.handNumber > 0, a.handNumber != b.handNumber {
                return a.handNumber > b.handNumber
            }
            return a.playedAt > b.playedAt
        }
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

    private func showBriefToast(_ message: String) {
        toastWorkItem?.cancel()
        withAnimation { toastMessage = message }
        let item = DispatchWorkItem { [self] in
            withAnimation { self.toastMessage = nil }
        }
        toastWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: item)
    }

    private func dismissBriefToast() {
        toastWorkItem?.cancel()
        withAnimation { toastMessage = nil }
    }
}

// MARK: - Afsluttet spilledag

private struct FinishedGameDayHeader: View {
    var gameDay: GameDay

    private var trimmedNotes: String {
        gameDay.notes.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(spacing: 10) {
            Text(gameDay.title.uppercased())
                .font(.custom(ActiveGamePosterStyle.fontName, size: 42))
                .fontWidth(.compressed)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.62)
                .frame(maxWidth: .infinity)

            Text(dateLine)
                .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 20))
                .fontWidth(.compressed)
                .fontWeight(.semibold)
                .foregroundStyle(ActiveGamePosterStyle.darkInkColor.opacity(0.78))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            if !trimmedNotes.isEmpty {
                Text(trimmedNotes)
                    .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 17))
                    .fontWidth(.compressed)
                    .fontWeight(.regular)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 2)
            }
        }
        .padding(.horizontal, 6)
        .padding(.bottom, 4)
        .accessibilityElement(children: .combine)
    }

    private var dateLine: String {
        let date = gameDay.createdAt.formatted(date: .long, time: .omitted)
        if let ended = gameDay.endedAt {
            let endedDate = ended.formatted(date: .abbreviated, time: .shortened)
            return "\(date) · afsluttet \(endedDate)"
        }
        return date
    }
}

private struct FinishedGameDayStatisticsArea: View {
    var gameDay: GameDay
    var hands: [RecordedHand]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SenesteSpilDaySummarySection(
                standing: gameDay.scoreStanding,
                seats: gameDay.seatOrder,
                title: "Samlet resultat"
            )

            totalGamesTile

            VStack(alignment: .leading, spacing: 12) {
                Text("Alle spil")
                    .font(.title2.weight(.bold))
                    .padding(.horizontal, 4)

                if hands.isEmpty {
                    Text("Ingen gemte kampe.")
                        .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 16))
                        .fontWidth(.compressed)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background {
                            RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                                .fill(ActiveGamePosterStyle.panelColor)
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                                .strokeBorder(ActiveGamePosterStyle.borderColor, lineWidth: 1)
                        }
                } else {
                    SenesteSpilDiscreteTable(gameDay: gameDay, hands: hands)
                }
            }
        }
        .padding(.top, 2)
    }

    private var totalGamesTile: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("SAMLET ANTAL SPIL")
                    .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 15))
                    .fontWidth(.compressed)
                    .fontWeight(.semibold)
                    .foregroundStyle(ActiveGamePosterStyle.darkInkColor.opacity(0.72))
                    .lineLimit(1)
                Text("Afsluttet spilledag")
                    .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 14))
                    .fontWidth(.compressed)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Text("\(hands.count)")
                .font(.custom(ActiveGamePosterStyle.fontName, size: 52))
                .fontWidth(.compressed)
                .monospacedDigit()
                .foregroundStyle(ActiveGamePosterStyle.darkInkColor)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                .fill(ActiveGamePosterStyle.panelColor)
        }
        .overlay {
            RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                .strokeBorder(ActiveGamePosterStyle.borderColor, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Samlet antal spil, \(hands.count)")
    }
}

// MARK: - Spilledag, bord og fuld kamp-liste (sekundær skærm)

private struct GameDaySettingsAndHandsView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var gameDay: GameDay

    @Query(sort: \GameDay.createdAt, order: .reverse) private var allGameDays: [GameDay]

    @State private var showResumeBlocked = false

    var body: some View {
        Form {
            Section("Spilledag") {
                TextField("Titel", text: $gameDay.title)
                TextField("Noter", text: $gameDay.notes, axis: .vertical)
                    .lineLimit(3...10)
                LabeledContent("Oprettet") {
                    Text(gameDay.createdAt.formatted(date: .long, time: .shortened))
                }
                if gameDay.isActive {
                    Text("For at afslutte spilledagen skal I bruge «Afslut spilledag» øverst på Spilledage.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    if let ended = gameDay.endedAt {
                        LabeledContent("Afsluttet") {
                            Text(ended.formatted(date: .abbreviated, time: .shortened))
                        }
                    }
                    Button("Genoptag spilledag") {
                        if gameDay.resumeIfAllowed(allDays: allGameDays, modelContext: modelContext) {
                            return
                        }
                        showResumeBlocked = true
                    }
                }
            }

            Section("Bord") {
                Text("Fast plads → navn. Samlede point finder du under «Pointfordeling» på spilledagsoversigten.")
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
                    NavigationLink(value: HomeRoute.hand(gameDayId: gameDay.id, handId: hand.id)) {
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
        .alert("Kan ikke genoptage", isPresented: $showResumeBlocked) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(GameDaySessionDialogs.resumeBlocked)
        }
    }

    private func handListTitleLine(_ hand: RecordedHand) -> String {
        let narrative = hand.displayResumeNarrative
        if hand.handNumber > 0 {
            return "#\(hand.handNumber) \(narrative)"
        }
        return narrative
    }

    /// Omvendt kronologisk: seneste kamp øverst (#n, #n−1, …).
    private var sortedHands: [RecordedHand] {
        gameDay.hands.sorted { a, b in
            if a.handNumber > 0, b.handNumber > 0, a.handNumber != b.handNumber {
                return a.handNumber > b.handNumber
            }
            return a.playedAt > b.playedAt
        }
    }

    private func deleteHands(at offsets: IndexSet) {
        let list = sortedHands
        for index in offsets {
            modelContext.delete(list[index])
        }
        try? modelContext.save()
    }
}
