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
        ZStack(alignment: .bottom) {
            tabBarPill

            centerItem
                .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 188)
        .background {
            Color.clear
        }
    }

    private var tabBarPill: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(tabBarFill)
                .overlay {
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .strokeBorder(ActiveGamePosterStyle.highlightBorderColor.opacity(0.78), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.11), radius: 18, x: 0, y: 8)

            HStack(alignment: .center, spacing: 0) {
                sideItem(tab: .home, title: "Forside", systemImage: "house", enabled: true)
                sideItem(tab: .recentGames, title: "Seneste spil", systemImage: "clock", enabled: true)
                Color.clear
                    .frame(width: 76)
                    .accessibilityHidden(true)
                sideItem(
                    tab: .activeGames,
                    title: "Aktivt spil",
                    systemImage: nil,
                    enabled: hasActivePendingHand,
                    badge: false
                )
                sideItem(tab: .statistics, title: "Statistik", systemImage: "chart.bar", enabled: true)
            }
            .padding(.horizontal, 15)
        }
        .frame(height: 66)
        .padding(.horizontal, 10)
        .padding(.bottom, 3)
    }

    private func sideItem(
        tab: MainTab,
        title: String,
        systemImage: String?,
        enabled: Bool,
        badge: Bool = false
    ) -> some View {
        let isSelected = selectedTab == tab
        let foreground: Color = {
            if !enabled { return tabIconMuted.opacity(0.42) }
            return isSelected ? tabIconSelected : tabIconMuted
        }()
        return Button {
            if tab == .home, selectedTab == .home {
                onHomeTapped?()
            }
            selectedTab = tab
        } label: {
            sideIcon(systemImage: systemImage, tab: tab, isSelected: isSelected, enabled: enabled, badge: badge)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .foregroundStyle(foreground)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    @ViewBuilder
    private func sideIcon(
        systemImage: String?,
        tab: MainTab,
        isSelected: Bool,
        enabled: Bool,
        badge: Bool
    ) -> some View {
        if tab == .activeGames {
            activeGameTabIcon(isSelected: isSelected, enabled: enabled, badge: badge)
        } else if let systemImage {
            Image(systemName: systemImage)
                .font(.system(size: 23, weight: isSelected ? .semibold : .regular))
                .symbolVariant(isSelected ? .fill : .none)
                .frame(width: 34, height: 34)
        }
    }

    private func activeGameTabIcon(isSelected: Bool, enabled: Bool, badge: Bool) -> some View {
        let color = enabled ? activeBadgeColor : tabIconMuted.opacity(0.50)
        return ZStack {
            ActiveGamePlayCardIcon(
                color: color.opacity(enabled ? 1 : 0.60),
                lineWidth: isSelected ? 2 : 1.6
            )
            if badge {
                Circle()
                    .fill(activeBadgeColor)
                    .frame(width: 8, height: 8)
                    .offset(x: 16, y: -14)
                    .accessibilityHidden(true)
            }
        }
        .frame(width: 36, height: 36)
    }

    private var centerItem: some View {
        let title: String
        let icon: String
        let tint: Color
        if hasActivePendingHand {
            title = "Afslut spil"
            icon = "play.fill"
            tint = activeBadgeColor
        } else {
            title = "Nyt spil"
            icon = "plus"
            tint = centerActionColor
        }
        let enabled = hasActiveGameDay || hasActivePendingHand
        return Button(action: onPlayTapped) {
            ZStack {
                centerBackCard(rotation: -8, x: -8.5, y: 10)
                centerBackCard(rotation: 7, x: 8.5, y: 10)
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(ActiveGamePosterStyle.panelColor)
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(ActiveGamePosterStyle.highlightBorderColor.opacity(0.96), lineWidth: 2.2)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(ActiveGamePosterStyle.borderColor.opacity(enabled ? 0.58 : 0.32), lineWidth: 1)
                            .padding(5)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(ActiveGamePosterStyle.borderColor.opacity(enabled ? 0.30 : 0.16), lineWidth: 0.8)
                    }
                    .frame(width: 49, height: 75)
                    .shadow(color: .black.opacity(enabled ? 0.16 : 0.06), radius: 12, x: 0, y: 6)

                Image(systemName: icon)
                    .font(.system(size: hasActivePendingHand ? 23 : 30, weight: .heavy))
                    .foregroundStyle(enabled ? tint : tabIconMuted.opacity(0.35))
                    .offset(y: -2)
            }
            .frame(width: 82, height: 88)
            .foregroundStyle(enabled ? tint : tabIconMuted.opacity(0.46))
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

    private func centerBackCard(rotation: Double, x: CGFloat, y: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(ActiveGamePosterStyle.tabBackCardColor.opacity(0.74))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(ActiveGamePosterStyle.highlightBorderColor.opacity(0.78), lineWidth: 1.8)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(ActiveGamePosterStyle.borderColor.opacity(0.56), lineWidth: 0.9)
                    .padding(4.5)
            }
            .frame(width: 42, height: 66)
            .rotationEffect(.degrees(rotation))
            .offset(x: x, y: y)
            .shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 5)
            .accessibilityHidden(true)
    }

    private var tabBarFill: Color {
        ActiveGamePosterStyle.panelColor.opacity(0.94)
    }

    private var tabIconSelected: Color {
        ActiveGamePosterStyle.selectedGreenColor
    }

    private var tabIconMuted: Color {
        ActiveGamePosterStyle.darkInkColor.opacity(0.56)
    }

    private var centerActionColor: Color {
        ActiveGamePosterStyle.selectedGreenColor
    }

    private var activeBadgeColor: Color {
        ActiveGamePosterStyle.activeOrangeColor
    }
}

struct ActiveGamePlayCardIcon: View {
    var color: Color
    var lineWidth: CGFloat = 1.6

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(color.opacity(0.95), lineWidth: lineWidth)
                .frame(width: 22, height: 34)

            Image(systemName: "play.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(color)
        }
        .frame(width: 36, height: 36)
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
