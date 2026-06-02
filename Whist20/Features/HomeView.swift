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
                // #2 Seneste spil — Sea Green: frisk, energisk
                gridButton(
                    title: "Seneste spil",
                    systemImage: "clock.arrow.circlepath",
                    tint: paletteSeaGreen,
                    foreground: .white
                ) {
                    navigationPath.append(HomeRoute.senesteSpil)
                }

                // #3 Stilling — Soft Fawn: guld, 1. plads
                gridButton(
                    title: "Stilling",
                    systemImage: "list.number",
                    tint: paletteSoftFawn,
                    foreground: paletteOnyx
                ) {
                    onGoToStilling?()
                }

                // #4 Spilledage — Pine Teal: dybe optegnelser, historik
                gridButton(
                    title: "Spilledage",
                    systemImage: "calendar",
                    tint: palettePineTeal,
                    foreground: .white
                ) {
                    navigationPath.append(HomeRoute.allGameDays)
                }

                // #5 Statistik — Dry Sage: analytisk, jordnær
                gridButton(
                    title: "Statistik",
                    systemImage: "chart.bar.fill",
                    tint: paletteDrySage,
                    foreground: paletteOnyx
                ) {
                    onGoToStatistik?()
                }

                // #6 Scorecard — Onyx: seriøs opslagsside
                gridButton(
                    title: "Scorecard",
                    systemImage: "tablecells",
                    tint: paletteOnyx,
                    foreground: .white
                ) {
                    navigationPath.append(HomeRoute.scorecard)
                }

                // #7 Indstillinger — Dark Olive: neutral, sekundær
                gridButton(
                    title: "Indstillinger",
                    systemImage: "gearshape.fill",
                    tint: paletteDarkOlive,
                    foreground: .white
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
                    tint: paletteSeaGreen,
                    foreground: .white,
                    action: { navigationPath.append(HomeRoute.activeGame(gameDayId: day.id)) }
                )
            } else {
                return HeroConfig(
                    title: "Start nyt spil",
                    systemImage: "plus.circle.fill",
                    tint: paletteSeaGreen,
                    foreground: .white,
                    action: { navigationPath.append(HomeRoute.gameDay(day.id, openAddHand: true)) }
                )
            }
        } else {
            return HeroConfig(
                title: "Start ny spilledag",
                systemImage: "calendar.badge.plus",
                tint: paletteBurntOrange,
                foreground: .white,
                action: { navigationPath.append(HomeRoute.newGameDay) }
            )
        }
    }

    private func gridButton(
        title: String,
        systemImage: String,
        tint: Color,
        foreground: Color,
        borderColor: Color? = nil,
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
            .overlay {
                if let border = borderColor {
                    RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                        .strokeBorder(border, lineWidth: 1)
                }
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

    // Earthtone Forest palette + tilføjede nuancer
    private var paletteOnyx: Color        { Color(red: 18/255,  green: 22/255,  blue: 25/255)  } // #121619
    private var palettePineTeal: Color    { Color(red: 45/255,  green: 71/255,  blue: 57/255)  } // #2D4739
    private var paletteSeaGreen: Color    { Color(red: 9/255,   green: 129/255, blue: 74/255)  } // #09814A
    private var paletteDrySage: Color     { Color(red: 188/255, green: 179/255, blue: 130/255) } // #BCB382
    private var paletteSoftFawn: Color    { Color(red: 229/255, green: 198/255, blue: 135/255) } // #E5C687
    private var paletteBurntOrange: Color { Color(red: 201/255, green: 106/255, blue: 43/255)  } // #C96A2B (tilføjet)
    private var paletteDarkOlive: Color   { Color(red: 59/255,  green: 74/255,  blue: 48/255)  } // #3B4A30 (tilføjet)

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
        GameDay.activeDay(in: gameDays) ?? GameDay.focusForStandings(in: gameDays)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                appearancePanel
                backupPanel
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Indstillinger")
        .navigationBarTitleDisplayMode(.large)
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
                if backupInfo != nil { prepareShareFiles(for: day, showSuccess: false) }
            }
        }
    }

    // MARK: - Udseende

    private var appearancePanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            settingsHeader("Udseende")
            settingsDivider
            Picker("Tema", selection: $appAppearanceModeRaw) {
                ForEach(AppAppearanceMode.allCases) { mode in
                    Text(mode.title).tag(mode.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .posterCard
    }

    // MARK: - Backup

    private var backupPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            settingsHeader("Backup")
            if let day = backupGameDay {
                settingsDivider
                settingsRow(label: "Session", value: day.title)
                settingsDivider
                settingsRow(label: "Lokal kopi", value: backupStatusText)
                settingsDivider
                Text("Gemmes automatisk efter hvert spil. Filerne ligger i Filer > På min iPhone > Whist 2.0 > \(LocalGameBackupService.directoryName).")
                    .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 12))
                    .foregroundStyle(ActiveGamePosterStyle.darkInkColor.opacity(0.5))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                settingsDivider
                if shareFileURLs.isEmpty {
                    Button {
                        prepareShareFiles(for: day, showSuccess: true)
                    } label: {
                        settingsActionLabel("Klargør eksport", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.plain)
                } else {
                    ShareLink(items: shareFileURLs) {
                        settingsActionLabel("Eksporter session", systemImage: "square.and.arrow.up")
                    }
                }
            } else {
                settingsDivider
                Text("Når der findes en spilledag, kan den lokale backup eksporteres herfra.")
                    .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 13))
                    .foregroundStyle(ActiveGamePosterStyle.darkInkColor.opacity(0.55))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
            }
        }
        .posterCard
    }

    // MARK: - Helpers

    private func settingsHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.custom(ActiveGamePosterStyle.fontName, size: 13))
            .foregroundStyle(ActiveGamePosterStyle.sectionHeaderColor)
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 8)
    }

    private func settingsRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 14))
                .foregroundStyle(ActiveGamePosterStyle.darkInkColor)
            Spacer()
            Text(value)
                .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 13))
                .foregroundStyle(ActiveGamePosterStyle.darkInkColor.opacity(0.55))
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    private func settingsActionLabel(_ title: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(ActiveGamePosterStyle.selectedGreenColor)
            Text(title)
                .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 14).weight(.semibold))
                .foregroundStyle(ActiveGamePosterStyle.selectedGreenColor)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var settingsDivider: some View {
        Rectangle()
            .fill(ActiveGamePosterStyle.borderColor)
            .frame(height: 0.5)
            .padding(.horizontal, 8)
    }

    private var backupStatusText: String {
        guard let backupInfo else { return "Ingen fil endnu" }
        return backupInfo.modifiedAt.formatted(date: .abbreviated, time: .shortened)
    }

    private func refreshBackupInfo(for day: GameDay) {
        backupInfo = LocalGameBackupService.latestBackupInfo(for: day)
    }

    private func prepareShareFiles(for day: GameDay, showSuccess: Bool) {
        do {
            shareFileURLs = try LocalGameBackupService.shareFiles(for: day)
            refreshBackupInfo(for: day)
            if showSuccess { backupMessage = "Backup er klar til eksport." }
        } catch {
            shareFileURLs = []
            backupMessage = "Kun gemt i appen. Lokal backup kunne ikke skrives."
        }
    }
}

private extension View {
    var posterCard: some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ActiveGamePosterStyle.panelColor)
            .clipShape(RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                    .strokeBorder(ActiveGamePosterStyle.borderColor, lineWidth: 1)
            }
    }
}
