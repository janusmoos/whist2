import SwiftData
import SwiftUI

/// Første skærm: kompakt 2×2 grid + aktivt spil, når der ligger en kladde.
struct HomeView: View {
    @Query(sort: \GameDay.createdAt, order: .reverse) private var gameDays: [GameDay]

    @Binding var navigationPath: NavigationPath

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

                    activeGameSection
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
                case .editGameDay(let id):
                    if let day = gameDays.first(where: { $0.id == id }) {
                        GameDayEditView(gameDay: day)
                    } else {
                        missingContent(title: "Spilledag findes ikke")
                    }
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
                    GameDaysView(navigationPath: $navigationPath)
                }
            }
        }
    }

    // MARK: - 2×2 Grid

    private var quickGrid: some View {
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        return LazyVGrid(columns: columns, spacing: 12) {
            gridButton(
                title: "Spilledage",
                systemImage: "calendar",
                tint: homeButtonBlue
            ) {
                navigationPath.append(HomeRoute.allGameDays)
            }

            gridButton(
                title: "Seneste spil",
                systemImage: "clock.arrow.circlepath",
                tint: homeButtonGreen
            ) {
                navigationPath.append(HomeRoute.senesteSpil)
            }

            gridButton(
                title: "Stilling",
                systemImage: "list.number",
                tint: homeButtonOrange
            ) {
                navigationPath.append(HomeRoute.standings)
            }

            gridButton(
                title: "Indstillinger",
                systemImage: "gearshape.fill",
                tint: homeButtonMuted
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
            VStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 27, weight: .semibold))
                    .frame(height: 30)
                Text(title)
                    .font(.custom(ActiveGamePosterStyle.fontName, size: 23))
                    .textCase(.uppercase)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 88)
            .padding(.vertical, 6)
            .foregroundStyle(tint)
            .background {
                RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                    .fill(ActiveGamePosterStyle.panelColor)
            }
            .overlay {
                RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                    .strokeBorder(ActiveGamePosterStyle.borderColor, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    // MARK: - Aktivt spil

    @ViewBuilder
    private var activeGameSection: some View {
        if let day = activeGameDay, hasActivePendingHand {
            activeGameBox(gameDay: day)
        }
    }

    /// Aktivt spil: samme plakatgrafik som fanen "Aktivt spil".
    private func activeGameBox(gameDay: GameDay) -> some View {
        let loaded = loadDraft(for: gameDay)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                    .symbolRenderingMode(.multicolor)
                Text("Aktivt spil")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }

            if let (draft, _) = loaded {
                let resumeLine = ActiveGamePosterText.resumeLine(for: draft)
                ActiveGameCardIllustration(draft: draft, isCompact: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ActiveGameResumePanel(resumeLine: resumeLine, colorScheme: colorScheme)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Helpers

    @Environment(\.colorScheme) private var colorScheme

    private var homeButtonBlue: Color { Color(red: 0.43, green: 0.56, blue: 0.75) }
    private var homeButtonGreen: Color { Color(red: 0.38, green: 0.66, blue: 0.53) }
    private var homeButtonOrange: Color { Color(red: 0.79, green: 0.53, blue: 0.21) }
    private var homeButtonMuted: Color { ActiveGamePosterStyle.darkInkColor.opacity(0.62) }

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
    @Query(sort: \GameDay.createdAt, order: .reverse) private var gameDays: [GameDay]
    @State private var backupInfo: LocalBackupInfo?
    @State private var shareFileURLs: [URL] = []
    @State private var backupMessage: String?

    private var backupGameDay: GameDay? {
        if let active = GameDay.activeDay(in: gameDays) {
            return active
        }
        return GameDay.focusForStandings(in: gameDays)
    }

    var body: some View {
        Form {
            Section("Opslagsværk") {
                NavigationLink(value: HomeRoute.scorecard) {
                    Label("Scorecard", systemImage: "tablecells")
                }
            }

            Section("Backup") {
                if let day = backupGameDay {
                    LabeledContent("Session") {
                        Text(day.title)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Lokal kopi") {
                        Text(backupStatusText)
                            .multilineTextAlignment(.trailing)
                    }
                    Text("Gemmes automatisk efter hvert spil. Filerne ligger i Filer > På min iPhone > Whist 2.0 > \(LocalGameBackupService.directoryName).")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    if shareFileURLs.isEmpty {
                        Button {
                            prepareShareFiles(for: day, showSuccess: true)
                        } label: {
                            Label("Klargør eksport", systemImage: "arrow.clockwise")
                        }
                    } else {
                        ShareLink(items: shareFileURLs) {
                            Label("Eksporter session", systemImage: "square.and.arrow.up")
                        }
                    }
                } else {
                    Text("Når der findes en spilledag, kan den lokale backup eksporteres herfra.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
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
        .alert("Backup", isPresented: Binding(
            get: { backupMessage != nil },
            set: { if !$0 { backupMessage = nil } }
        )) {
            Button("OK", role: .cancel) { backupMessage = nil }
        } message: {
            Text(backupMessage ?? "")
        }
        .onAppear {
            if let day = backupGameDay {
                refreshBackupInfo(for: day)
                if backupInfo != nil {
                    prepareShareFiles(for: day, showSuccess: false)
                }
            }
        }
    }

    private var backupStatusText: String {
        guard let backupInfo else {
            return "Ingen fil endnu"
        }
        return backupInfo.modifiedAt.formatted(date: .abbreviated, time: .shortened)
    }

    private func refreshBackupInfo(for day: GameDay) {
        backupInfo = LocalGameBackupService.latestBackupInfo(for: day)
    }

    private func prepareShareFiles(for day: GameDay, showSuccess: Bool) {
        do {
            shareFileURLs = try LocalGameBackupService.shareFiles(for: day)
            refreshBackupInfo(for: day)
            if showSuccess {
                backupMessage = "Backup er klar til eksport."
            }
        } catch {
            shareFileURLs = []
            backupMessage = "Kun gemt i appen. Lokal backup kunne ikke skrives."
        }
    }
}
