import SwiftData
import SwiftUI

/// Første skærm: store hurtigvalg + indstillinger.
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GameDay.createdAt, order: .reverse) private var gameDays: [GameDay]

    @State private var path = NavigationPath()
    @State private var alertMessage: String?

    private enum HomeRoute: Hashable {
        case gameDay(UUID, openAddHand: Bool)
        case hand(gameDayId: UUID, handId: UUID)
        case standings
        case settings
        case allGameDays
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 18) {
                    Text("Hvad vil I lave?")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)

                    largeHomeButton(
                        title: "Tilføj spil",
                        systemImage: "plus.circle.fill",
                        prominent: true,
                        action: openAddHandFlow
                    )

                    largeHomeButton(
                        title: "Ny spilledag",
                        systemImage: "calendar.badge.plus",
                        prominent: true,
                        action: createGameDayAndOpen
                    )

                    largeHomeButton(
                        title: "Stilling",
                        systemImage: "list.number",
                        prominent: false,
                        action: { path.append(HomeRoute.standings) }
                    )

                    largeHomeButton(
                        title: "Seneste spil",
                        systemImage: "clock.arrow.circlepath",
                        prominent: false,
                        action: openLatestHand
                    )

                    NavigationLink(value: HomeRoute.allGameDays) {
                        Label("Alle spilledage", systemImage: "calendar")
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                    .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
            .navigationTitle("Whist 2.0")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        path.append(HomeRoute.settings)
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .symbolRenderingMode(.hierarchical)
                    }
                    .accessibilityLabel("Indstillinger")
                }
            }
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
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
                    StandingsPlaceholderView()
                case .settings:
                    AppSettingsView()
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
    }

    @ViewBuilder
    private func largeHomeButton(
        title: String,
        systemImage: String,
        prominent: Bool,
        action: @escaping () -> Void
    ) -> some View {
        if prominent {
            Button(action: action) {
                homeButtonLabel(title: title, systemImage: systemImage)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        } else {
            Button(action: action) {
                homeButtonLabel(title: title, systemImage: systemImage)
            }
            .buttonStyle(.bordered)
            .tint(.accentColor)
            .controlSize(.large)
        }
    }

    private func homeButtonLabel(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.title3.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 58)
            .multilineTextAlignment(.center)
            .labelStyle(.titleAndIcon)
            .imageScale(.large)
    }

    private func openAddHandFlow() {
        if let id = gameDays.first?.id {
            path.append(HomeRoute.gameDay(id, openAddHand: true))
        } else {
            let day = GameDay()
            modelContext.insert(day)
            try? modelContext.save()
            path.append(HomeRoute.gameDay(day.id, openAddHand: true))
        }
    }

    private func createGameDayAndOpen() {
        let day = GameDay()
        modelContext.insert(day)
        try? modelContext.save()
        path.append(HomeRoute.gameDay(day.id, openAddHand: false))
    }

    private func openLatestHand() {
        guard let pair = globalLatestHand else {
            alertMessage = "Der er ikke gemt nogen kamp endnu."
            return
        }
        path.append(HomeRoute.hand(gameDayId: pair.0.id, handId: pair.1.id))
    }

    private var globalLatestHand: (GameDay, RecordedHand)? {
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

    @ViewBuilder
    private func missingContent(title: String) -> some View {
        ContentUnavailableView(title, systemImage: "exclamationmark.triangle")
    }
}

// MARK: - Stilling (placeholder)

private struct StandingsPlaceholderView: View {
    var body: some View {
        ContentUnavailableView(
            "Stilling",
            systemImage: "list.number",
            description: Text("Samlet stilling og historik på tværs af spilledage — kommer senere.")
        )
        .navigationTitle("Stilling")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Indstillinger

private struct AppSettingsView: View {
    var body: some View {
        Form {
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
