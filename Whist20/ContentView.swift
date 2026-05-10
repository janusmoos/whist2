import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GameDay.createdAt, order: .reverse) private var gameDays: [GameDay]

    @State private var selectedTab: MainTab = .home
    /// Delt med `HomeView`, så navigation bevares når I skifter fane og kommer tilbage til forsiden.
    @State private var homeNavigationPath = NavigationPath()
    @State private var showAddHandSheet = false
    @State private var addHandAlertMessage: String?
    @State private var toastMessage: String?
    @State private var toastWorkItem: DispatchWorkItem?
    /// Reserverer plads til den faste bundmenu (`MainTabBar`). Måles ved layout — `safeAreaInset` alene gav ofte skjult bund på indlejrede navigationer.
    @State private var mainTabBarOverlapHeight: CGFloat = 62

    private var activeGameDay: GameDay? {
        GameDay.activeDay(in: gameDays)
    }

    private var hasActivePendingHand: Bool {
        activeGameDay?.pendingHand != nil
    }

    var body: some View {
        Group {
            switch selectedTab {
            case .home:
                HomeView(navigationPath: $homeNavigationPath)
            case .recentGames:
                NavigationStack {
                    SenesteSpilView()
                        .navigationTitle("Seneste spil")
                        .navigationBarTitleDisplayMode(.large)
                }
            case .activeGames:
                ActiveSpilTabView(openMeldingSheet: openMeldingSheet)
            case .statistics:
                StatistikTabView()
            }
        }
        .padding(.bottom, mainTabBarOverlapHeight)
        .overlay(alignment: .bottom) {
            MainTabBar(
                selectedTab: $selectedTab,
                hasActiveGameDay: activeGameDay != nil,
                hasActivePendingHand: hasActivePendingHand,
                onPlayTapped: openMeldingSheet,
                onHomeTapped: { homeNavigationPath = NavigationPath() }
            )
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: MainTabBarMeasuredHeightKey.self,
                        value: proxy.size.height
                    )
                }
            )
        }
        .onPreferenceChange(MainTabBarMeasuredHeightKey.self) { height in
            if height > 1 {
                mainTabBarOverlapHeight = height
            }
        }
        .sheet(isPresented: $showAddHandSheet) {
            if let day = activeGameDay {
                AddHandView(
                    gameDay: day,
                    onDismissSaveNotice: { message in showToast(message) },
                    onSaved: { gameDayId in navigateToGameDayAfterSave(gameDayId) }
                )
            }
        }
        .alert("Bemærk", isPresented: Binding(
            get: { addHandAlertMessage != nil },
            set: { if !$0 { addHandAlertMessage = nil } }
        )) {
            Button("OK", role: .cancel) { addHandAlertMessage = nil }
        } message: {
            Text(addHandAlertMessage ?? "")
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
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onTapGesture { dismissToast() }
                    .accessibilityAddTraits(.isStaticText)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: toastMessage != nil)
        .onAppear {
            GameDayEndedAtMigration.runIfNeeded(modelContext: modelContext)
        }
    }

    /// «Nyt spil»/«Afslut spil» fra bundmenuen: åbner meldingen direkte. Kræver aktiv spilledag.
    private func openMeldingSheet() {
        guard activeGameDay != nil else {
            addHandAlertMessage =
                "Der er ingen aktiv spilledag. Opret en ny spilledag, eller genoptag en afsluttet under «Alle spilledage» på forsiden."
            return
        }
        showAddHandSheet = true
    }

    private func showToast(_ message: String) {
        toastWorkItem?.cancel()
        withAnimation { toastMessage = message }
        let item = DispatchWorkItem { [self] in
            withAnimation { self.toastMessage = nil }
        }
        toastWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: item)
    }

    private func dismissToast() {
        toastWorkItem?.cancel()
        withAnimation { toastMessage = nil }
    }

    /// Efter gem: nulstil forsidenavigation, skub spilledagsoversigten (der viser tabellen).
    private func navigateToGameDayAfterSave(_ gameDayId: UUID) {
        homeNavigationPath = NavigationPath()
        homeNavigationPath.append(HomeRoute.gameDay(gameDayId, openAddHand: false))
        selectedTab = .home
    }
}

/// Bruges til at matche indholdets bund-padding med den faktiske højde af `MainTabBar` i `ContentView`.
private enum MainTabBarMeasuredHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    let schema = Schema([GameDay.self, RecordedHand.self, PendingHand.self])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [configuration])
    return ContentView()
        .modelContainer(container)
}
