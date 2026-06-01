import SwiftData
import SwiftUI

/// Første skærm: kompakt 2×2 grid + aktivt spil, når der ligger en kladde.
struct HomeView: View {
    @Query(sort: \GameDay.createdAt, order: .reverse) private var gameDays: [GameDay]

    @Binding var navigationPath: NavigationPath
    var onGoToStilling: (() -> Void)?
    var onGoToStatistik: (() -> Void)?

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
            .background(Color(uiColor: .systemGroupedBackground))
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

    // MARK: - Gitter

    private var quickGrid: some View {
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        return VStack(spacing: 12) {
            heroButton

            LazyVGrid(columns: columns, spacing: 12) {
                // #2 Seneste spil — lime: frisk, legende, kig tilbage
                gridButton(
                    title: "Seneste spil",
                    systemImage: "clock.arrow.circlepath",
                    tint: paletteLime,
                    foreground: paletteNavy
                ) {
                    navigationPath.append(HomeRoute.senesteSpil)
                }

                // #3 Stilling — guld: 1. plads, konkurrence
                gridButton(
                    title: "Stilling",
                    systemImage: "list.number",
                    tint: paletteYellow,
                    foreground: paletteNavy
                ) {
                    onGoToStilling?()
                }

                // #4 Spilledage — mørk teal: historik, dybe optegnelser
                gridButton(
                    title: "Spilledage",
                    systemImage: "calendar",
                    tint: paletteDarkTeal,
                    foreground: .white
                ) {
                    navigationPath.append(HomeRoute.allGameDays)
                }

                // #5 Statistik — navy: analytisk, seriøs data
                gridButton(
                    title: "Statistik",
                    systemImage: "chart.bar.fill",
                    tint: paletteNavy,
                    foreground: .white
                ) {
                    onGoToStatistik?()
                }

                // #6 Scorecard — rød: vigtig opslagsside
                gridButton(
                    title: "Scorecard",
                    systemImage: "tablecells",
                    tint: paletteRed,
                    foreground: .white
                ) {
                    navigationPath.append(HomeRoute.scorecard)
                }

                // #7 Indstillinger — rav: neutral utility-varme
                gridButton(
                    title: "Indstillinger",
                    systemImage: "gearshape.fill",
                    tint: paletteAmber,
                    foreground: paletteNavy
                ) {
                    navigationPath.append(HomeRoute.settings)
                }
            }
        }
    }

    // MARK: - Hero-knap

    private var heroButton: some View {
        let cfg = heroConfig
        return Button(action: cfg.action) {
            HStack(spacing: 14) {
                Image(systemName: cfg.systemImage)
                    .font(.system(size: 26, weight: .regular))
                    .foregroundStyle(cfg.foreground.opacity(0.88))
                Text(cfg.title)
                    .font(.custom(ActiveGamePosterStyle.fontName, size: 22))
                    .textCase(.uppercase)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .foregroundStyle(cfg.foreground)
                Spacer()
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, minHeight: 96)
            .background(cfg.tint)
            .clipShape(RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(cfg.title)
    }

    private struct HeroConfig {
        var title: String
        var systemImage: String
        var tint: Color
        var foreground: Color
        var action: () -> Void
    }

    private var heroConfig: HeroConfig {
        if let day = activeGameDay {
            if hasActivePendingHand {
                return HeroConfig(
                    title: "Se aktive spil",
                    systemImage: "play.fill",
                    tint: paletteOrange,
                    foreground: .white,
                    action: { navigationPath.append(HomeRoute.activeGame(gameDayId: day.id)) }
                )
            } else {
                return HeroConfig(
                    title: "Start nyt spil",
                    systemImage: "plus.circle.fill",
                    tint: paletteOrange,
                    foreground: .white,
                    action: { navigationPath.append(HomeRoute.gameDay(day.id, openAddHand: true)) }
                )
            }
        } else {
            return HeroConfig(
                title: "Start ny spilledag",
                systemImage: "calendar.badge.plus",
                tint: paletteMidGreen,
                foreground: paletteDarkTeal,
                action: { navigationPath.append(HomeRoute.newGameDay) }
            )
        }
    }

    private func gridButton(
        title: String,
        systemImage: String,
        tint: Color,
        foreground: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                Image(systemName: systemImage)
                    .font(.system(size: 26, weight: .regular))
                    .foregroundStyle(foreground.opacity(0.88))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.top, 15)

                Spacer(minLength: 10)

                Text(title)
                    .font(.custom(ActiveGamePosterStyle.fontName, size: 19))
                    .textCase(.uppercase)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .foregroundStyle(foreground)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)
            }
            .frame(maxWidth: .infinity, minHeight: 96)
            .background(tint)
            .clipShape(RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous))
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
                    .foregroundStyle(ActiveGamePosterStyle.activeOrangeColor)
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
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                .fill(ActiveGamePosterStyle.panelSecondaryColor)
        }
        .overlay {
            RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                .strokeBorder(ActiveGamePosterStyle.borderColor, lineWidth: 1)
        }
    }

    // MARK: - Helpers

    @Environment(\.colorScheme) private var colorScheme

    // Tropica Summer (#011C40, #F2B90F, #F2A413, #F27B13, #D92B04) + grøn palette (#CCCC52, #8FB259, #192B33)
    private var paletteNavy: Color     { Color(red: 1/255,   green: 28/255,  blue: 64/255)  }
    private var paletteYellow: Color   { Color(red: 242/255, green: 185/255, blue: 15/255)  }
    private var paletteAmber: Color    { Color(red: 242/255, green: 164/255, blue: 19/255)  }
    private var paletteOrange: Color   { Color(red: 242/255, green: 123/255, blue: 19/255)  }
    private var paletteRed: Color      { Color(red: 217/255, green: 43/255,  blue: 4/255)   }
    private var paletteLime: Color     { Color(red: 204/255, green: 204/255, blue: 82/255)  }
    private var paletteMidGreen: Color { Color(red: 143/255, green: 178/255, blue: 89/255)  }
    private var paletteDarkTeal: Color { Color(red: 25/255,  green: 43/255,  blue: 51/255)  }

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
    @AppStorage("appAppearanceMode") private var appAppearanceModeRaw = AppAppearanceMode.auto.rawValue
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

            Section("Udseende") {
                Picker("Tema", selection: $appAppearanceModeRaw) {
                    ForEach(AppAppearanceMode.allCases) { mode in
                        Text(mode.title)
                            .tag(mode.rawValue)
                    }
                }
                .pickerStyle(.segmented)
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
                Text("Her kommer snart valg for navne, regler og mere.")
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
