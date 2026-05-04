import SwiftData
import SwiftUI

/// Hub efter et gemt spil: hurtig tilføjelse, seneste spil, pladsholdere til statistik m.m.
struct GameDayStartView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var gameDay: GameDay
    /// Når sand, åbnes «Tilføj spil»-arket én gang ved første visning (fx fra forsiden).
    var presentAddHandSheetOnAppear: Bool = false

    @Query(sort: \GameDay.createdAt, order: .reverse) private var allGameDays: [GameDay]

    @State private var showAddHand = false
    @State private var sheetDismissNotice: String?
    @State private var didConsumePresentAddHand = false
    @State private var showResumeBlocked = false
    /// Hvilken af de kompakte kampe (ikke den fremhævede seneste) er udvidet med resumé.
    @State private var expandedOtherHandID: UUID?

    private var hasActivePendingHand: Bool {
        gameDay.pendingHand != nil
    }

    private var canStartOrContinueHand: Bool {
        gameDay.isActive || hasActivePendingHand
    }

    var body: some View {
        List {
            if !gameDay.isActive {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Spilledagen er afsluttet", systemImage: "moon.zzz.fill")
                            .font(.headline)
                        Text(
                            hasActivePendingHand
                                ? "Der ligger stadig et spil undervejs under «Aktivt spil». Genoptag spilledagen for at fortsætte — eller afslut den aktive spilkladde først."
                                : "Genoptag for at registrere nye kampe. Historik og pointfindes stadig nedenfor."
                        )
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        Button {
                            if gameDay.resumeIfAllowed(allDays: allGameDays, modelContext: modelContext) {
                                return
                            }
                            showResumeBlocked = true
                        } label: {
                            Label("Genoptag spilledag", systemImage: "arrow.uturn.backward.circle.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.vertical, 4)
                }
            }

            if canStartOrContinueHand {
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
            }

            if canStartOrContinueHand {
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
            }

            Section("Seneste spil") {
                if let hand = latestHand {
                    NavigationLink {
                        HandDetailView(hand: hand, gameDay: gameDay)
                    } label: {
                        FeaturedLatestHandCard(hand: hand)
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                    .listRowBackground(Color.clear)

                    ForEach(otherHandsChronological, id: \.id) { other in
                        CompactHandDayRow(
                            hand: other,
                            isExpanded: expandedOtherHandID == other.id,
                            onToggle: {
                                withAnimation(.easeInOut(duration: 0.22)) {
                                    if expandedOtherHandID == other.id {
                                        expandedOtherHandID = nil
                                    } else {
                                        expandedOtherHandID = other.id
                                    }
                                }
                            }
                        )
                        .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                        .listRowBackground(Color.clear)
                    }
                } else {
                    Text("Ingen gemte kampe endnu. Brug «Tilføj spil» når spilledagen er aktiv.")
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
                NavigationLink {
                    PointStandingView(gameDay: gameDay)
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "person.3.sequence")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                            .frame(width: 36)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Pointfordeling")
                                .font(.headline)
                            Text("Samlede point pr. spiller og udvikling over aftenen.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
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
            if presentAddHandSheetOnAppear, !didConsumePresentAddHand, canStartOrContinueHand {
                didConsumePresentAddHand = true
                showAddHand = true
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
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
        .alert("Kan ikke genoptage", isPresented: $showResumeBlocked) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(GameDaySessionDialogs.resumeBlocked)
        }
    }

    private var latestHand: RecordedHand? {
        gameDay.hands.max(by: { $0.playedAt < $1.playedAt })
    }

    /// Øvrige kampe samme dag (ikke den senest afsluttede): omvendt kronologisk (#n−1 … #1).
    private var otherHandsChronological: [RecordedHand] {
        guard let latest = latestHand else { return [] }
        return gameDay.hands
            .filter { $0.id != latest.id }
            .sorted { a, b in
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
                    Text("For at afslutte spilledagen skal I bruge «Afslut spilledag» på forsiden.")
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
