import SwiftData
import SwiftUI

/// Rod-faner med fast bundmenu (altid synlig). Midterknappen er ikke en fane,
/// men en handling: «Nyt spil» åbner meldingen som ark; «Afslut spil» åbner
/// kladden samme sted (`AddHandView` restorer automatisk).
enum MainTab: Int, CaseIterable, Identifiable {
    case home
    case recentGames
    case activeGames
    case statistics

    var id: Int { rawValue }
}

// MARK: - Bundmenu

struct MainTabBar: View {
    @Binding var selectedTab: MainTab
    let hasActiveGameDay: Bool
    let hasActivePendingHand: Bool
    let onPlayTapped: () -> Void
    /// Ekstra tap på Forside når man allerede er der — nulstiller navigationssti.
    var onHomeTapped: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(alignment: .center, spacing: 0) {
                sideItem(tab: .home, title: "Forside", systemImage: "house.fill", enabled: true)
                sideItem(tab: .recentGames, title: "Seneste spil", systemImage: "clock.arrow.circlepath", enabled: true)
                centerItem
                sideItem(
                    tab: .activeGames,
                    title: "Aktivt spil",
                    systemImage: "rectangle.and.hand.point.up.left.fill",
                    enabled: hasActivePendingHand,
                    badge: hasActivePendingHand
                )
                sideItem(tab: .statistics, title: "Statistik", systemImage: "chart.bar.xaxis", enabled: true)
            }
            .padding(.horizontal, 4)
            .padding(.top, 8)
            .padding(.bottom, 10)
        }
        .background(.bar)
    }

    private func sideItem(
        tab: MainTab,
        title: String,
        systemImage: String,
        enabled: Bool,
        badge: Bool = false
    ) -> some View {
        let isSelected = selectedTab == tab
        let foreground: Color = {
            if !enabled { return .secondary.opacity(0.5) }
            return isSelected ? .accentColor : .secondary
        }()
        return Button {
            if tab == .home, selectedTab == .home {
                onHomeTapped?()
            }
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .overlay(alignment: .topTrailing) {
                        if badge {
                            Circle()
                                .fill(.orange)
                                .frame(width: 8, height: 8)
                                .offset(x: 6, y: -2)
                                .accessibilityHidden(true)
                        }
                    }
                Text(title)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(foreground)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var centerItem: some View {
        let title: String
        let icon: String
        let tint: Color
        if hasActivePendingHand {
            title = "Afslut spil"
            icon = "arrow.triangle.2.circlepath.circle.fill"
            tint = .orange
        } else {
            title = "Nyt spil"
            icon = "plus.circle.fill"
            tint = .accentColor
        }
        let enabled = hasActiveGameDay || hasActivePendingHand
        return Button(action: onPlayTapped) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .padding(.horizontal, 4)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(tint.opacity(enabled ? 0.15 : 0.07))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(tint.opacity(enabled ? 0.85 : 0.35), lineWidth: 1.75)
            }
            .foregroundStyle(enabled ? tint : tint.opacity(0.55))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(title)
        .accessibilityHint(
            hasActivePendingHand
                ? "Åbner det aktive spil for at afslutte det"
                : "Starter et nyt spil"
        )
    }
}

// MARK: - Aktive spil

struct ActiveSpilTabView: View {
    @Query(sort: \GameDay.createdAt, order: .reverse) private var gameDays: [GameDay]

    var openMeldingSheet: () -> Void = {}

    private var activeGameDay: GameDay? {
        GameDay.activeDay(in: gameDays)
    }

    private var hasActivePendingHand: Bool {
        activeGameDay?.pendingHand != nil
    }

    var body: some View {
        NavigationStack {
            Group {
                if let day = activeGameDay, hasActivePendingHand {
                    ActiveGameView(gameDay: day)
                } else {
                    ContentUnavailableView {
                        Label("Ingen aktivt spil", systemImage: "rectangle.and.hand.point.up.left")
                    } description: {
                        Text(
                            activeGameDay != nil
                                ? "Der er ingen spilkladde i gang. Start et nyt spil for at melde."
                                : "Der er ingen aktiv spilledag. Opret eller genoptag en spilledag fra forsiden."
                        )
                    } actions: {
                        if activeGameDay != nil {
                            Button {
                                openMeldingSheet()
                            } label: {
                                Label("Nyt spil", systemImage: "plus.circle.fill")
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                        }
                    }
                }
            }
            .navigationTitle("Aktivt spil")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Statistik

struct StatistikTabView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ContentUnavailableView(
                        "Statistik",
                        systemImage: "chart.bar.xaxis",
                        description: Text(
                            "Oversigt over spiltyper, makkerpar og tendenser — kommer senere."
                        )
                    )
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .navigationTitle("Statistik")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
