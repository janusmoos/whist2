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
    @State private var toastMessage: String?
    @State private var toastWorkItem: DispatchWorkItem?
    @State private var didConsumePresentAddHand = false
    @State private var showResumeBlocked = false
    /// Hvilken af de kompakte kampe (ikke den fremhævede seneste) er udvidet med resumé.
    @State private var expandedOtherHandID: UUID?
    @State private var senesteSpilVisning: SenesteSpilOversigtVisning = .table

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
                    VStack(alignment: .leading, spacing: 10) {
                        Button {
                            showAddHand = true
                        } label: {
                            Label(
                                "Tilføj spil",
                                systemImage: "plus.circle.fill"
                            )
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .buttonStyle(.borderedProminent)

                        // Aktivitetsstatus: diskret række når der ikke er en kladde.
                        if hasActivePendingHand {
                            NavigationLink {
                                ActiveGameView(gameDay: gameDay)
                            } label: {
                                Label("Fortsæt aktivt spil", systemImage: "arrow.triangle.2.circlepath.circle.fill")
                                    .font(.subheadline.weight(.semibold))
                            }
                        } else {
                            HStack(spacing: 10) {
                                Image(systemName: "rectangle.and.hand.point.up.left.filled")
                                    .foregroundStyle(.tertiary)
                                    .frame(width: 20)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Ingen kladde i gang")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                    Text("Et påbegyndt spil dukker op her som «Aktivt spil».")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                                Spacer(minLength: 0)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Aktivt spil: ingen kladde")
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Seneste spil") {
                if latestHand != nil {
                    if senesteSpilVisning == .cards {
                        if let hand = latestHand {
                            NavigationLink(value: HomeRoute.hand(gameDayId: gameDay.id, handId: hand.id)) {
                                FeaturedLatestHandCard(hand: hand, gameDay: gameDay)
                            }
                            .buttonStyle(.plain)
                            .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                            .listRowBackground(Color.clear)

                            ForEach(otherHandsChronological, id: \.id) { other in
                                CompactHandDayRow(
                                    hand: other,
                                    gameDay: gameDay,
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
                        }
                    } else {
                        SenesteSpilDiscreteTable(gameDay: gameDay, hands: handsNewestFirst)
                            .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 10, trailing: 12))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
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
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial.opacity(0.85))
                    .background(Color.primary.opacity(0.7))
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
                Menu {
                    Picker("Visning", selection: $senesteSpilVisning) {
                        ForEach(SenesteSpilOversigtVisning.allCases) { mode in
                            Text(mode.menuTitle).tag(mode)
                        }
                    }
                } label: {
                    Image(systemName: "square.grid.2x2")
                }
                .accessibilityLabel("Visning af seneste spil")

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

    /// Seneste kamp først, derefter ældre (samme orden som kortvisningen).
    private var handsNewestFirst: [RecordedHand] {
        guard let latest = latestHand else { return [] }
        return [latest] + otherHandsChronological
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
