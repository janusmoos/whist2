import SwiftData
import SwiftUI

/// Første skærm: store hurtigvalg + indstillinger.
struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GameDay.createdAt, order: .reverse) private var gameDays: [GameDay]

    @State private var path = NavigationPath()
    @State private var alertMessage: String?
    @State private var showEndGameDayConfirm = false

    private var activeGameDay: GameDay? {
        GameDay.activeDay(in: gameDays)
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

                    if let day = activeGameDay {
                        Button {
                            path.append(HomeRoute.activeGame(gameDayId: day.id))
                        } label: {
                            homeButtonLabel(
                                title: "Aktivt spil",
                                systemImage: "rectangle.and.hand.point.up.left.filled"
                            )
                        }
                        .buttonStyle(.bordered)
                        .tint(.accentColor)
                        .controlSize(.large)
                        .overlay(alignment: .topTrailing) {
                            if day.pendingHand != nil {
                                Circle()
                                    .fill(.orange)
                                    .frame(width: 10, height: 10)
                                    .padding(.trailing, 8)
                                    .padding(.top, 10)
                                    .accessibilityHidden(true)
                            }
                        }
                        .accessibilityLabel(
                            day.pendingHand != nil
                                ? "Aktivt spil, kladde i gang"
                                : "Aktivt spil"
                        )
                    }

                    if activeGameDay != nil {
                        Button {
                            showEndGameDayConfirm = true
                        } label: {
                            homeButtonLabel(title: "Afslut spilledag", systemImage: "flag.checkered")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                        .controlSize(.large)
                    } else {
                        largeHomeButton(
                            title: "Ny spilledag",
                            systemImage: "calendar.badge.plus",
                            prominent: true,
                            action: { path.append(HomeRoute.newGameDay) }
                        )
                    }

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
            .environment(\.homeNavigationPath, $path)
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
                case .senesteSpil:
                    SenesteSpilView()
                case .activeGame(let gameDayId):
                    if let day = gameDays.first(where: { $0.id == gameDayId }) {
                        ActiveGameView(gameDay: day)
                    } else {
                        missingContent(title: "Spilledag findes ikke")
                    }
                case .newGameDay:
                    NewGameDayView(path: $path)
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
        guard let id = GameDay.activeDay(in: gameDays)?.id else {
            alertMessage = "Der er ingen aktiv spilledag. Opret en ny spilledag, eller genoptag en afsluttet under «Alle spilledage»."
            return
        }
        path.append(HomeRoute.gameDay(id, openAddHand: true))
    }

    private func openLatestHand() {
        path.append(HomeRoute.senesteSpil)
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
