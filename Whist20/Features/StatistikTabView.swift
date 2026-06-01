import Charts
import SwiftUI

@MainActor
final class HistoricalStatisticsStore: ObservableObject {
    enum State {
        case idle
        case loading
        case loaded(HistoricalStatisticsHubModel)
        case failure(Error)
    }

    @Published private(set) var state: State = .idle

    private let loader: HistoricalDataJSONLoader
    private var hasStartedLoading = false
    private var historicalData: HistoricalWhistData?
    private var liveUpdateTask: Task<Void, Never>?

    init(loader: HistoricalDataJSONLoader = HistoricalDataJSONLoader()) {
        self.loader = loader
    }

    deinit {
        liveUpdateTask?.cancel()
    }

    func loadIfNeeded(gameDays: [GameDay]) async {
        guard !hasStartedLoading else { return }
        hasStartedLoading = true
        state = .loading

        let loader = loader
        let liveSnapshots = LiveHistoricalStatisticsAdapter.snapshots(from: gameDays)
        let result = await Task.detached(priority: .userInitiated) {
            Result {
                let data = try loader.load()
                let model = HistoricalStatisticsPreparer.prepareHubModel(
                    historicalData: data,
                    liveSnapshots: liveSnapshots
                )
                return (data, model)
            }
        }.value

        switch result {
        case let .success((data, model)):
            historicalData = data
            state = .loaded(model)
        case let .failure(error):
            state = .failure(error)
        }
    }

    func gameDaysDidChange(_ gameDays: [GameDay]) {
        guard let historicalData else { return }
        let liveSnapshots = LiveHistoricalStatisticsAdapter.snapshots(from: gameDays)
        liveUpdateTask?.cancel()
        liveUpdateTask = Task { [historicalData] in
            try? await Task.sleep(nanoseconds: 150_000_000)
            guard !Task.isCancelled else { return }

            let model = await Task.detached(priority: .userInitiated) {
                HistoricalStatisticsPreparer.prepareHubModel(
                    historicalData: historicalData,
                    liveSnapshots: liveSnapshots
                )
            }.value

            guard !Task.isCancelled else { return }
            state = .loaded(model)
        }
    }
}

private struct GameDayStatisticsFingerprint: Equatable {
    var value: Int
}

struct StatistikTabView: View {
    @State private var selectedScope: HistoricalStatisticsScope = .current
    @State private var recentSessionLimit = 10
    @ObservedObject private var store: HistoricalStatisticsStore
    private let gameDays: [GameDay]

    private let recentSessionLimitOptions = [5, 10, 15, 20, 25, 50]
    private let plannedStatistics = [
        PlannedStatistic(
            title: "Spillerform",
            description: "Udvikling pr. spiller over de seneste spilledage, bedste/værste streaks og stabilitet."
        ),
        PlannedStatistic(
            title: "Meldinger og spiltype",
            description: "Succesrate fordelt på vip, sol, halve og trumf, med tydelig sample size."
        ),
        PlannedStatistic(
            title: "Makkerpar",
            description: "Point og winrate for faste og skiftende makkerpar, når historikken kan bære det."
        ),
        PlannedStatistic(
            title: "Rollefordeling",
            description: "Melder, makker, modspiller og giver-effekt, adskilt fra ren totalscore."
        ),
        PlannedStatistic(
            title: "Datakvalitet",
            description: "Synlige afvigelser, manglende rækker og importerede felter pr. spilledag."
        ),
    ]

    init(store: HistoricalStatisticsStore, gameDays: [GameDay]) {
        self.store = store
        self.gameDays = gameDays
    }

    var body: some View {
        NavigationStack {
            Group {
                switch store.state {
                case .idle, .loading:
                    ProgressView("Indlæser statistik...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                case let .loaded(model):
                    statisticsHub(model)
                case let .failure(error):
                    ContentUnavailableView {
                        Label("Statistik kunne ikke indlæses", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error.localizedDescription)
                    }
                    .padding()
                }
            }
            .navigationTitle("Statistik")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            await store.loadIfNeeded(gameDays: gameDays)
        }
        .onChange(of: gameDayStatisticsFingerprint) { _, _ in
            store.gameDaysDidChange(gameDays)
        }
    }

    private var gameDayStatisticsFingerprint: GameDayStatisticsFingerprint {
        var hasher = Hasher()
        for day in gameDays.sorted(by: { lhs, rhs in
                if lhs.createdAt != rhs.createdAt {
                    return lhs.createdAt < rhs.createdAt
                }
                return lhs.id.uuidString < rhs.id.uuidString
            }) {
            hasher.combine(day.id)
            hasher.combine(day.createdAt)
            hasher.combine(day.title)
            hasher.combine(day.endedAt)
            hasher.combine(day.seatOrderJSON)
            hasher.combine(day.pendingHand?.id)
            hasher.combine(day.pendingHand?.updatedAt)

            for hand in day.hands.sorted(by: { lhs, rhs in
                        if lhs.handNumber != rhs.handNumber {
                            return lhs.handNumber < rhs.handNumber
                        }
                        return lhs.playedAt < rhs.playedAt
                    }) {
                hasher.combine(hand.id)
                hasher.combine(hand.handNumber)
                hasher.combine(hand.playedAt)
                hasher.combine(hand.kindRaw)
                hasher.combine(hand.scoresBySeatJSON)
                hasher.combine(hand.bidderSeatRaw)
                hasher.combine(hand.partnerSeatRaw)
            }
        }
        return GameDayStatisticsFingerprint(value: hasher.finalize())
    }

    private func statisticsHub(_ model: HistoricalStatisticsHubModel) -> some View {
        let data = model.data
        let allSnapshot = model.allSnapshot
        let currentOverview = model.currentOverview

        return ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                overviewPosterPanel(snapshot: allSnapshot)

                VStack(spacing: 10) {
                    if let currentOverview {
                        NavigationLink {
                            AnyView(currentDayView(currentOverview))
                        } label: {
                            navigationCard(
                                title: "Nuværende spilledag",
                                subtitle: sessionSubtitle(currentOverview.session),
                                systemImage: "calendar",
                                metric: "\(currentOverview.gamesPlayed) spil"
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    NavigationLink {
                        AnyView(allSessionsView(model))
                    } label: {
                        navigationCard(
                            title: "Alle spilledage",
                            subtitle: "Dato, sted, resultater og spil-detaljer",
                            systemImage: "calendar.badge.clock",
                            metric: "\(allSnapshot.sessionCount)"
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        AnyView(playersOverviewView(model))
                    } label: {
                        navigationCard(
                            title: "Spillere",
                            subtitle: "Profiler, bedste/værste spil og meldinger",
                            systemImage: "person.3.sequence.fill",
                            metric: "\(data.players.count)"
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        AnyView(gameTypesOverviewView(model))
                    } label: {
                        navigationCard(
                            title: "Spiltyper",
                            subtitle: "Succes pr. type med tydelig sample size",
                            systemImage: "suit.club.fill",
                            metric: "\(model.gameTypeCount)"
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        AnyView(trendsOverviewView(model))
                    } label: {
                        navigationCard(
                            title: "Tendenser",
                            subtitle: "Udvikling over tid og seneste perioder",
                            systemImage: "chart.line.uptrend.xyaxis",
                            metric: "5-50"
                        )
                    }
                    .buttonStyle(.plain)
                }

                NavigationLink {
                    AnyView(dataQualityView(model))
                } label: {
                    navigationCard(
                        title: "Datagrundlag",
                        subtitle: "Importkvalitet, feltdækning og planlagte forbedringer",
                        systemImage: "checklist",
                        metric: "\(allSnapshot.issueCount)"
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .padding(.bottom, 12)
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private func overviewPosterPanel(snapshot: HistoricalStatisticsSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                posterMetricTile(title: "SPILLEDAGE", value: "\(snapshot.sessionCount)")
                posterMetricTile(title: "SPIL", value: "\(snapshot.gameCount)")
            }

            historicalSessionProgressChart(snapshot.timelinePoints)

            VStack(alignment: .leading, spacing: 10) {
                Text("STILLING")
                    .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 15))
                    .fontWidth(.compressed)
                    .fontWeight(.semibold)
                    .foregroundStyle(ActiveGamePosterStyle.darkInkColor.opacity(0.72))
                    .padding(.horizontal, 4)

                historicalStandingStrip(snapshot.playerSummaries)
            }
        }
    }

    private func posterMetricTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 13))
                .fontWidth(.compressed)
                .fontWeight(.semibold)
                .foregroundStyle(ActiveGamePosterStyle.darkInkColor.opacity(0.72))
            Text(value)
                .font(.custom(ActiveGamePosterStyle.fontName, size: 42))
                .fontWidth(.compressed)
                .monospacedDigit()
                .foregroundStyle(ActiveGamePosterStyle.darkInkColor)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                .fill(ActiveGamePosterStyle.panelColor)
        }
        .overlay {
            RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                .strokeBorder(ActiveGamePosterStyle.borderColor, lineWidth: 1)
        }
    }

    private func historicalSessionProgressChart(_ points: [HistoricalScoreTimelinePoint]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("STATUS")
                .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 15))
                .fontWidth(.compressed)
                .fontWeight(.semibold)
                .foregroundStyle(ActiveGamePosterStyle.darkInkColor.opacity(0.72))
                .padding(.horizontal, 4)

            HStack(spacing: 12) {
                HistoricalTimelineCanvas(
                    points: points,
                    xDomain: historicalChartXDomain(points),
                    yDomain: historicalChartYDomain(points),
                    colorForPlayer: { historicalPlayerLineColor(playerName: $0) }
                )
                .frame(height: 136)

                historicalChartLabelColumn(points)
            }
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                    .fill(ActiveGamePosterStyle.panelColor)
            }
            .overlay {
                RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                    .strokeBorder(ActiveGamePosterStyle.borderColor, lineWidth: 1)
            }
            .accessibilityLabel("Udvikling i samlet pointstilling pr. spilledag")
        }
    }

    private func historicalChartLabelColumn(_ points: [HistoricalScoreTimelinePoint]) -> some View {
        GeometryReader { geometry in
            let rows = historicalChartLabelRows(points, height: geometry.size.height)
            ZStack(alignment: .topLeading) {
                ForEach(rows) { row in
                    Text("\(row.point.playerName) \(scoreText(row.point.cumulativeScore))")
                        .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 11.5))
                        .fontWidth(.compressed)
                        .fontWeight(.semibold)
                        .foregroundStyle(historicalPlayerLineColor(playerName: row.point.playerName))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .frame(width: 96, height: 22, alignment: .leading)
                        .offset(y: row.y)
                }
            }
        }
        .frame(width: 96, height: 136)
    }

    private func latestHistoricalTimelinePoints(
        _ points: [HistoricalScoreTimelinePoint]
    ) -> [HistoricalScoreTimelinePoint] {
        let grouped = Dictionary(grouping: points, by: \.playerId)
        return grouped.values.compactMap { values in
            values.max { lhs, rhs in lhs.sessionIndex < rhs.sessionIndex }
        }
    }

    private func historicalChartXDomain(_ points: [HistoricalScoreTimelinePoint]) -> ClosedRange<Int> {
        let values = points.map(\.sessionIndex)
        let lower = values.min() ?? 0
        let upper = values.max() ?? lower
        return lower...upper
    }

    private func historicalChartYDomain(_ points: [HistoricalScoreTimelinePoint]) -> ClosedRange<Int> {
        let values = points.map(\.cumulativeScore) + [0]
        let lower = values.min() ?? 0
        let upper = values.max() ?? lower
        let span = max(1, upper - lower)
        let padding = max(20, Int(Double(span) * 0.12))
        return (lower - padding)...(upper + padding)
    }

    private func historicalChartLabelRows(
        _ points: [HistoricalScoreTimelinePoint],
        height: CGFloat
    ) -> [HistoricalChartLabelRow] {
        let labelHeight: CGFloat = 22
        let gap: CGFloat = 3
        let domain = historicalChartYDomain(points)
        let span = max(1, domain.upperBound - domain.lowerBound)
        var rows = latestHistoricalTimelinePoints(points)
            .map { point -> HistoricalChartLabelRow in
                let fraction = Double(domain.upperBound - point.cumulativeScore) / Double(span)
                let rawY = CGFloat(fraction) * height - labelHeight / 2
                return HistoricalChartLabelRow(
                    point: point,
                    y: min(max(rawY, 0), max(0, height - labelHeight))
                )
            }
            .sorted { $0.y < $1.y }

        for index in rows.indices.dropFirst() {
            let previousIndex = rows.index(before: index)
            rows[index].y = max(rows[index].y, rows[previousIndex].y + labelHeight + gap)
        }

        if let last = rows.last {
            let overflow = last.y + labelHeight - height
            if overflow > 0 {
                for index in rows.indices {
                    rows[index].y -= overflow
                }
            }
        }

        return rows.map { row in
            var output = row
            output.y = min(max(output.y, 0), max(0, height - labelHeight))
            return output
        }
    }

    private func historicalStandingStrip(_ summaries: [HistoricalPlayerScoreSummary]) -> some View {
        let ordered = summaries.sorted { lhs, rhs in
            lhs.player.displayOrder < rhs.player.displayOrder
        }

        return HStack(spacing: 8) {
            ForEach(ordered) { summary in
                VStack(spacing: 2) {
                    Text(summary.player.name.uppercased())
                        .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 11))
                        .fontWidth(.compressed)
                        .fontWeight(.semibold)
                        .foregroundStyle(ActiveGamePosterStyle.darkInkColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)

                    Text(scoreText(summary.totalScore))
                        .font(.custom(ActiveGamePosterStyle.fontName, size: 30))
                        .fontWidth(.compressed)
                        .monospacedDigit()
                        .foregroundStyle(scoreForeground(summary.totalScore))
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)
                }
                .padding(.top, 8)
                .padding(.horizontal, 5)
                .frame(maxWidth: .infinity)
                .frame(height: 70)
                .background {
                    RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                        .fill(ActiveGamePosterStyle.panelColor)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                        .strokeBorder(historicalPlayerLineColor(summary.player), lineWidth: 2)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(summary.player.name), \(scoreText(summary.totalScore)) point")
            }
        }
    }

    private func streakTile(
        title: String,
        primary: String,
        secondaryTitle: String,
        secondary: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 14))
                .fontWidth(.compressed)
                .fontWeight(.semibold)
                .foregroundStyle(ActiveGamePosterStyle.darkInkColor.opacity(0.72))
            Text(primary)
                .font(.custom(ActiveGamePosterStyle.fontName, size: 34))
                .fontWidth(.compressed)
                .monospacedDigit()
                .foregroundStyle(ActiveGamePosterStyle.darkInkColor)
                .lineLimit(1)
                .minimumScaleFactor(0.62)
            HStack(alignment: .firstTextBaseline) {
                Text(secondaryTitle)
                    .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 13))
                    .fontWidth(.compressed)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 6)
                Text(secondary)
                    .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 15))
                    .fontWidth(.compressed)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .foregroundStyle(secondary.hasPrefix("-") ? scoreForeground(-1) : scoreForeground(1))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                .fill(ActiveGamePosterStyle.panelColor)
        }
        .overlay {
            RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                .strokeBorder(ActiveGamePosterStyle.borderColor, lineWidth: 1)
        }
    }

    private func streakPrimaryText(_ streak: HistoricalPlayerScoreStreak?, fallback: String) -> String {
        guard let streak else { return fallback }
        return "\(streak.player.name) · \(streak.games) spil"
    }

    private func streakScoreText(_ streak: HistoricalPlayerScoreStreak?) -> String {
        guard let streak else { return "-" }
        return scoreText(streak.totalScore)
    }

    private func historicalPlayerLineColor(_ player: HistoricalPlayer) -> Color {
        historicalPlayerLineColor(displayOrder: player.displayOrder)
    }

    private func historicalPlayerLineColor(playerName: String) -> Color {
        switch playerName.lowercased() {
        case "thomas":
            return historicalPlayerLineColor(displayOrder: 1)
        case "peter":
            return historicalPlayerLineColor(displayOrder: 2)
        case "janus":
            return historicalPlayerLineColor(displayOrder: 3)
        case "christian":
            return historicalPlayerLineColor(displayOrder: 4)
        default:
            return ActiveGamePosterStyle.borderColor
        }
    }

    private func historicalPlayerLineColor(displayOrder: Int) -> Color {
        switch displayOrder {
        case 1:
            return Color(red: 0.44, green: 0.56, blue: 0.75)
        case 2:
            return Color(red: 0.44, green: 0.66, blue: 0.53)
        case 3:
            return Color(red: 0.79, green: 0.58, blue: 0.29)
        case 4:
            return Color(red: 0.61, green: 0.46, blue: 0.72)
        default:
            return ActiveGamePosterStyle.borderColor
        }
    }

    private func trendsContent(
        snapshot: HistoricalStatisticsSnapshot,
        trends: [HistoricalPlayerTrendSummary],
        gameTypeTrends: [HistoricalGameTypeTrendSummary]
    ) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tendenser")
                        .font(.largeTitle.weight(.bold))
                    Text("Form og udvikling for den valgte periode.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                scopeSection
                recentLimitPicker(snapshot)
                trendSummaryHeader(snapshot, trends: trends)
                trendPlayerCards(trends)
                gameTypeTrendSections(gameTypeTrends)
                scoreTimeline(snapshot.timelinePoints)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .padding(.bottom, 12)
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private func trendSummaryHeader(
        _ snapshot: HistoricalStatisticsSnapshot,
        trends: [HistoricalPlayerTrendSummary]
    ) -> some View {
        let leader = trends.first
        let latestLeader = trends.max { lhs, rhs in
            if lhs.latestSessionScore != rhs.latestSessionScore {
                return lhs.latestSessionScore < rhs.latestSessionScore
            }
            return lhs.periodScore < rhs.periodScore
        }

        return VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(scopeDescription(snapshot))
                    .font(.headline)
                Text("\(snapshot.sessionCount) spilledage · \(snapshot.gameCount) spil i perioden")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                statTile(title: "Formleder", value: leader.map { "\($0.player.name) \(scoreText($0.periodScore))" } ?? "-")
                statTile(title: "Seneste dag", value: latestLeader.map { "\($0.player.name) \(scoreText($0.latestSessionScore))" } ?? "-")
                statTile(title: "Spilledage", value: "\(snapshot.sessionCount)")
                statTile(title: "Afvigelser", value: "\(snapshot.issueCount)")
            }
        }
        .padding(16)
        .background(cardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private func trendPlayerCards(_ trends: [HistoricalPlayerTrendSummary]) -> some View {
        return VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Form pr. spiller")
                    .font(.headline)
                Text("Detaljer om konkrete spil ligger stadig under Spillere og Spilledage.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 10) {
                ForEach(Array(trends.enumerated()), id: \.element.id) { index, trend in
                    trendPlayerRow(trend, rank: index + 1)
                }
            }
        }
    }

    private func trendPlayerRow(_ trend: HistoricalPlayerTrendSummary, rank: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                rankBadge(rank)

                VStack(alignment: .leading, spacing: 2) {
                    Text(trend.player.name)
                        .font(.body.weight(.semibold))
                    Text("\(trend.sessionsPlayed) spilledage · snit \(averageText(trend.averageSessionScore)) pr. dag")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 10)

                Text(scoreText(trend.periodScore))
                    .font(.title3.weight(.bold).monospacedDigit())
                    .foregroundStyle(scoreForeground(trend.periodScore))
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                miniMetric(title: "Seneste dag", value: scoreText(trend.latestSessionScore))
                sessionMetric(title: "Bedste dag", session: trend.bestSession)
                sessionMetric(title: "Værste dag", session: trend.worstSession)
                miniMetric(title: "Snit/dag", value: averageText(trend.averageSessionScore))
            }
        }
        .padding(14)
        .background(cardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private func gameTypeTrendSections(_ summaries: [HistoricalGameTypeTrendSummary]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Spiltyper")
                    .font(.headline)
                Text("Gennemsnit pr. spiller og hvor ofte meldingen går hjem i den valgte periode.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if summaries.isEmpty {
                Text("Ingen spiltype-data i perioden.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(cardBackground)
            } else {
                VStack(spacing: 10) {
                    ForEach(summaries) { summary in
                        gameTypeTrendCard(summary)
                    }
                }
            }
        }
    }

    private func gameTypeTrendCard(_ summary: HistoricalGameTypeTrendSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(summary.gameType.capitalized)
                        .font(.body.weight(.semibold))
                    Text("\(summary.games) spil · \(summary.bidOutcomeGames) med melder/vinder-data")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(successRateText(summary.successRate))
                        .font(.subheadline.weight(.bold).monospacedDigit())
                    Text("\(summary.successfulBidGames) af \(summary.bidOutcomeGames) går hjem")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(summary.playerAverages) { average in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(average.player.name)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(signedAverageText(average.averageScore))
                            .font(.caption.weight(.bold).monospacedDigit())
                            .foregroundStyle(scoreForeground(average.averageScore))
                        Text("\(average.games) spil")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .background {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.primary.opacity(0.04))
                    }
                }
            }
        }
        .padding(14)
        .background(cardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private func navigationCard(title: String, subtitle: String, systemImage: String, metric: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(ActiveGamePosterStyle.selectedGreenColor)
                .frame(width: 56, height: 56)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(ActiveGamePosterStyle.panelColor)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(subtitle.isEmpty ? "-" : subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 12)

            Text(metric)
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(.secondary)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(cardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private func currentDayView(_ overview: HistoricalSessionOverview) -> some View {
        sessionDetailView(overview)
            .navigationTitle("Nuværende")
    }

    private func allSessionsView(_ model: HistoricalStatisticsHubModel) -> some View {
        let data = model.data
        let overviews = model.sessionOverviews
        let playerSessionScores = model.playerSessionScores

        return ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Alle spilledage")
                        .font(.largeTitle.weight(.bold))
                    Text("\(overviews.count) historiske spilledage. Detaljer ligger inde på hver dag.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                allSessionsHeatmap(
                    players: data.players,
                    overviews: overviews,
                    scoresByPlayerId: playerSessionScores
                )
                countDivergingChart(
                    title: "Dage med tab/gevinst",
                    emptyText: "Ingen dagsresultater at vise endnu.",
                    rows: allSessionDayOutcomeRows(players: data.players, scoresByPlayerId: playerSessionScores)
                )
                allSessionsRankDistributionChart(
                    players: data.players,
                    overviews: overviews
                )
                sessionOverviewList(overviews)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .padding(.bottom, 12)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Spilledage")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func allSessionsHeatmap(
        players: [HistoricalPlayer],
        overviews: [HistoricalSessionOverview],
        scoresByPlayerId: [String: [HistoricalPlayerSessionScore]]
    ) -> some View {
        let orderedPlayers = players.sorted { lhs, rhs in
            if lhs.displayOrder != rhs.displayOrder {
                return lhs.displayOrder < rhs.displayOrder
            }
            return lhs.name < rhs.name
        }
        let orderedSessions = overviews.sorted { lhs, rhs in lhs.sessionIndex < rhs.sessionIndex }
        let maxAbsScore = max(
            scoresByPlayerId.values.flatMap { $0.map { abs($0.score) } }.max() ?? 1,
            1
        )

        return VStack(alignment: .leading, spacing: 12) {
            Text("Dagsform")
                .font(.headline)

            if orderedSessions.isEmpty || orderedPlayers.isEmpty {
                Text("Ingen spilledage at vise endnu.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 7) {
                        Color.clear.frame(width: 74, height: 14)
                        ForEach(orderedPlayers) { player in
                            Text(player.name)
                                .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 12))
                                .fontWidth(.compressed)
                                .fontWeight(.semibold)
                                .foregroundStyle(ActiveGamePosterStyle.darkInkColor)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .frame(width: 74, height: 22, alignment: .leading)
                        }
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 7) {
                            HStack(spacing: 5) {
                                ForEach(orderedSessions) { overview in
                                    Text(overview.session.sessionNumber)
                                        .font(.caption2.weight(.semibold).monospacedDigit())
                                        .foregroundStyle(ActiveGamePosterStyle.darkInkColor.opacity(0.42))
                                        .frame(width: 22, height: 14)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.55)
                                }
                            }

                            ForEach(orderedPlayers) { player in
                                HStack(spacing: 5) {
                                    ForEach(orderedSessions) { overview in
                                        let score = sessionScore(
                                            playerId: player.id,
                                            sessionId: overview.session.id,
                                            scoresByPlayerId: scoresByPlayerId
                                        )
                                        heatmapCell(score: score, maxAbsScore: maxAbsScore)
                                            .accessibilityLabel(
                                                "\(player.name), spilledag \(overview.session.sessionNumber), \(scoreText(score)) point"
                                            )
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                .fill(ActiveGamePosterStyle.panelColor)
        }
        .overlay {
            RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                .strokeBorder(ActiveGamePosterStyle.borderColor, lineWidth: 1)
        }
    }

    private func heatmapCell(score: Int, maxAbsScore: Int) -> some View {
        let intensity = min(1, max(0.18, Double(abs(score)) / Double(maxAbsScore)))
        let fill: Color = {
            if score > 0 {
                return scoreForeground(1).opacity(0.32 + 0.60 * intensity)
            }
            if score < 0 {
                return scoreForeground(-1).opacity(0.34 + 0.58 * intensity)
            }
            return ActiveGamePosterStyle.borderColor.opacity(0.22)
        }()

        return RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(fill)
            .overlay {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(ActiveGamePosterStyle.borderColor.opacity(0.28), lineWidth: 0.7)
            }
            .frame(width: 22, height: 22)
    }

    private func sessionScore(
        playerId: String,
        sessionId: String,
        scoresByPlayerId: [String: [HistoricalPlayerSessionScore]]
    ) -> Int {
        scoresByPlayerId[playerId]?.first { $0.sessionId == sessionId }?.score ?? 0
    }

    private func allSessionDayOutcomeRows(
        players: [HistoricalPlayer],
        scoresByPlayerId: [String: [HistoricalPlayerSessionScore]]
    ) -> [SessionBidOutcomeRow] {
        players
            .sorted { lhs, rhs in
                if lhs.displayOrder != rhs.displayOrder {
                    return lhs.displayOrder < rhs.displayOrder
                }
                return lhs.name < rhs.name
            }
            .map { player in
                let scores = scoresByPlayerId[player.id] ?? []
                return SessionBidOutcomeRow(
                    player: player,
                    wins: scores.filter { $0.score > 0 }.count,
                    losses: scores.filter { $0.score < 0 }.count
                )
            }
    }

    private func allSessionsRankDistributionChart(
        players: [HistoricalPlayer],
        overviews: [HistoricalSessionOverview]
    ) -> some View {
        let rows = rankDistributionRows(players: players, overviews: overviews)
        let maxTotal = max(rows.map { $0.counts.values.reduce(0, +) }.max() ?? 1, 1)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Placeringer pr. spilledag")
                .font(.headline)

            VStack(spacing: 9) {
                ForEach(rows) { row in
                    HStack(spacing: 10) {
                        Text(row.player.name)
                            .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 12))
                            .fontWidth(.compressed)
                            .fontWeight(.semibold)
                            .foregroundStyle(ActiveGamePosterStyle.darkInkColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                            .frame(width: 74, alignment: .leading)

                        GeometryReader { geometry in
                            HStack(spacing: 2) {
                                ForEach(1...4, id: \.self) { rank in
                                    let count = row.counts[rank] ?? 0
                                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                                        .fill(rankColor(rank).opacity(count == 0 ? 0.16 : 0.82))
                                        .frame(width: max(count == 0 ? 2 : 7, geometry.size.width * CGFloat(count) / CGFloat(maxTotal)))
                                }
                            }
                        }
                        .frame(height: 16)

                        Text("\(row.counts.values.reduce(0, +))")
                            .font(.caption.weight(.bold).monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(width: 28, alignment: .trailing)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(rankDistributionAccessibility(row))
                }
            }

            HStack(spacing: 8) {
                ForEach(1...4, id: \.self) { rank in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(rankColor(rank))
                            .frame(width: 7, height: 7)
                        Text("\(rank).")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(16)
        .background(cardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                .strokeBorder(ActiveGamePosterStyle.borderColor, lineWidth: 1)
        }
    }

    private func rankDistributionRows(
        players: [HistoricalPlayer],
        overviews: [HistoricalSessionOverview]
    ) -> [SessionRankDistributionRow] {
        var countsByPlayerId = Dictionary(
            uniqueKeysWithValues: players.map { player in
                (player.id, SessionRankDistributionRow(player: player, counts: [:]))
            }
        )

        for overview in overviews {
            let rankedScores = overview.playerTotals.sorted { lhs, rhs in
                if lhs.score != rhs.score { return lhs.score > rhs.score }
                return lhs.player.displayOrder < rhs.player.displayOrder
            }
            for (index, score) in rankedScores.enumerated() {
                countsByPlayerId[score.player.id, default: SessionRankDistributionRow(player: score.player, counts: [:])]
                    .counts[index + 1, default: 0] += 1
            }
        }

        return countsByPlayerId.values.sorted { lhs, rhs in
            if lhs.player.displayOrder != rhs.player.displayOrder {
                return lhs.player.displayOrder < rhs.player.displayOrder
            }
            return lhs.player.name < rhs.player.name
        }
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1:
            return ActiveGamePosterStyle.positiveScoreColor
        case 2:
            return Color(red: 0.44, green: 0.56, blue: 0.75)
        case 3:
            return Color(red: 0.79, green: 0.58, blue: 0.29)
        default:
            return ActiveGamePosterStyle.negativeScoreColor
        }
    }

    private func rankDistributionAccessibility(_ row: SessionRankDistributionRow) -> String {
        "\(row.player.name): " + (1...4)
            .map { "\($0). plads \(row.counts[$0] ?? 0) dage" }
            .joined(separator: ", ")
    }

    private func playersOverviewView(_ model: HistoricalStatisticsHubModel) -> some View {
        let profiles = model.playerProfiles
        let summaries = model.playerSummaries
            .sorted { lhs, rhs in
                if lhs.player.displayOrder != rhs.player.displayOrder {
                    return lhs.player.displayOrder < rhs.player.displayOrder
                }
                return lhs.player.name < rhs.player.name
            }

        return ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Spillere")
                        .font(.largeTitle.weight(.bold))
                    Text("Overblik først. Tryk på en spiller for alle detaljer.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                playerLeaderboard(summaries, profiles: profiles)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .padding(.bottom, 12)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Spillere")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func gameTypesOverviewView(_ model: HistoricalStatisticsHubModel) -> some View {
        let data = model.data
        let overviews = model.gameTypeOverviews
        let trickDistribution = bidTrickDistribution(from: data)
        let solDistribution = solGameDistribution(from: data)
        let vipDistribution = vipGameDistribution(from: data)
        let trumpDistribution = trumpDistribution(from: data)

        return ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Spiltyper")
                        .font(.largeTitle.weight(.bold))
                }

                if overviews.isEmpty {
                    ContentUnavailableView("Ingen spiltyper", systemImage: "rectangle.stack.badge.play")
                } else {
                    gameTypePopularityChart(overviews)
                    gameTypeIconBarChart(overviews)
                    bidTrickDistributionChart(trickDistribution)
                    gameTypeSlicePieChart(
                        title: "Solspil",
                        emptyText: "Ingen registrerede solspil.",
                        slices: solDistribution
                    )
                    gameTypeSlicePieChart(
                        title: "VIP-spil",
                        emptyText: "Ingen registrerede VIP-spil.",
                        slices: vipDistribution
                    )
                    gameTypeSlicePieChart(
                        title: "Trumf og sans",
                        emptyText: "Ingen registrerede trumfer.",
                        slices: trumpDistribution
                    )

                    VStack(spacing: 10) {
                        ForEach(overviews) { overview in
                            NavigationLink {
                                gameTypeDetailView(overview)
                            } label: {
                                gameTypeRow(overview)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .padding(.bottom, 12)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Spiltyper")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func trendsOverviewView(_ model: HistoricalStatisticsHubModel) -> some View {
        let key = HistoricalStatisticsScopeCacheKey(scope: selectedScope, recentLimit: recentSessionLimit)
        let snapshot = model.snapshotsByScope[key] ?? model.allSnapshot
        let playerTrends = model.playerTrendSummariesByScope[key] ?? []
        let gameTypeTrends = model.gameTypeTrendSummariesByScope[key] ?? []

        return trendsContent(
            snapshot: snapshot,
            trends: playerTrends,
            gameTypeTrends: gameTypeTrends
        )
            .navigationTitle("Tendenser")
            .navigationBarTitleDisplayMode(.inline)
    }

    private func dataQualityView(_ model: HistoricalStatisticsHubModel) -> some View {
        let snapshot = model.allSnapshot

        return ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Datagrundlag")
                        .font(.largeTitle.weight(.bold))
                    Text("Her ligger importkvalitet og planlagte statistikspor.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                dataQualityChart(snapshot)
                dataQuality(snapshot)
                plannedStatisticsOverview
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .padding(.bottom, 12)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Datagrundlag")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var scopeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Spilledage")
                .font(.headline)
            Picker("Spilledage", selection: $selectedScope) {
                ForEach(HistoricalStatisticsScope.allCases) { scope in
                    Text(scope.title).tag(scope)
                }
            }
            .pickerStyle(.segmented)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Vælg spilledage til statistik")
    }

    @ViewBuilder
    private func recentLimitPicker(_ snapshot: HistoricalStatisticsSnapshot) -> some View {
        if snapshot.scope == .recent {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Antal spilledage")
                        .font(.subheadline.weight(.semibold))
                    Text("Vælg hvor langt tilbage den seneste periode går.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                Picker("Antal spilledage", selection: $recentSessionLimit) {
                    ForEach(recentSessionLimitOptions, id: \.self) { limit in
                        Text("\(limit)").tag(limit)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityLabel("Vælg antal seneste spilledage")
            }
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
            }
        }
    }

    private func summaryHeader(_ snapshot: HistoricalStatisticsSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Historisk data")
                    .font(.title2.weight(.bold))
                Text("\(scopeDescription(snapshot)) · \(snapshot.gameCount) spil · \(snapshot.playerResultCount) spillerresultater")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                statTile(title: "Spil", value: "\(snapshot.gameCount)")
                statTile(title: "Nulsum", value: "\(snapshot.zeroSumGameCount)")
                statTile(title: "Afvigelser", value: "\(snapshot.issueCount)")
                statTile(title: "Version", value: snapshot.dataVersion.replacingOccurrences(of: "whist_historical_data_", with: ""))
            }

            Text("Første statistikversion bruger kun pointdata. Spiltype, giver, melder og makker kommer senere med tydelig sample size.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private var plannedStatisticsOverview: some View {
        return VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Planlagte statistikfunktioner")
                    .font(.headline)
                Text("Næste versioner bør udvide fra ren pointvisning til forklarende statistik.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 10) {
                ForEach(plannedStatistics) { statistic in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "circle.dotted")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 18, height: 18)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(statistic.title)
                                .font(.subheadline.weight(.semibold))
                            Text(statistic.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private func playerLeaderboardChart(
        _ summaries: [HistoricalPlayerScoreSummary],
        subtitle: String = "Historisk nettoscore pr. spiller."
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Samlet stilling")
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Chart(summaries) { summary in
                BarMark(
                    x: .value("Point", summary.totalScore),
                    y: .value("Spiller", summary.player.name)
                )
                .foregroundStyle(scoreForeground(summary.totalScore))

                RuleMark(x: .value("Nul", 0))
                    .foregroundStyle(Color.secondary.opacity(0.45))
            }
            .frame(height: 220)
            .chartXAxisLabel("Point")
            .chartYAxisLabel("Spiller")
            .accessibilityLabel("Søjlediagram for samlet historisk score pr. spiller")
        }
        .padding(16)
        .background(cardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private func gameTypePopularityChart(_ overviews: [HistoricalGameTypeOverview]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spiltyper")
                .font(.headline)

            Chart(overviews) { overview in
                SectorMark(
                    angle: .value("Spil", overview.games),
                    innerRadius: .ratio(0.58),
                    angularInset: 1.5
                )
                .foregroundStyle(gameTypeChartColor(overview.title))
            }
            .frame(height: 230)
            .chartLegend(.hidden)
            .accessibilityLabel("Cirkeldiagram over mest populære spiltyper")

            chartLegend(overviews.map { GameTypeSlice(title: $0.title, count: $0.games) })
        }
        .padding(16)
        .background(cardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private func gameTypeIconBarChart(_ overviews: [HistoricalGameTypeOverview]) -> some View {
        let sorted = overviews.sorted { lhs, rhs in
            if lhs.games != rhs.games { return lhs.games < rhs.games }
            return lhs.title < rhs.title
        }
        let maxGames = max(sorted.map(\.games).max() ?? 1, 1)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Spiltyper efter antal")
                .font(.headline)

            VStack(spacing: 9) {
                ForEach(sorted) { overview in
                    HStack(spacing: 10) {
                        StatistikGameTypeIcon(kind: StatistikGameTypeIconKind(title: overview.title), color: ActiveGamePosterStyle.darkInkColor)
                            .frame(width: 26, height: 30)
                            .accessibilityHidden(true)

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.primary.opacity(0.06))
                                Capsule()
                                    .fill(gameTypeChartColor(overview.title))
                                    .frame(width: max(8, geometry.size.width * CGFloat(overview.games) / CGFloat(maxGames)))
                            }
                        }
                        .frame(height: 12)

                        Text("\(overview.games)")
                            .font(.caption.weight(.bold).monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(width: 34, alignment: .trailing)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(overview.title), \(overview.games) spil")
                }
            }
        }
        .padding(16)
        .background(cardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private func bidTrickDistributionChart(_ buckets: [HistoricalBidTrickBucket]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Meldte stik")
                .font(.headline)

            if buckets.isEmpty {
                Text("Ingen registrerede stikmeldinger.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Chart(buckets) { bucket in
                    BarMark(
                        x: .value("Stik", bucket.title),
                        y: .value("Spil", bucket.count)
                    )
                    .foregroundStyle(Color(red: 0.11, green: 0.14, blue: 0.18))
                    .cornerRadius(4)
                }
                .frame(height: 220)
                .chartXAxisLabel("Meldte stik")
                .chartYAxisLabel("Spil")
                .accessibilityLabel("Bjælkediagram over meldte stik i stikspil")
            }
        }
        .padding(16)
        .background(cardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private func gameTypeSlicePieChart(
        title: String,
        emptyText: String,
        slices: [GameTypeSlice]
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            if slices.isEmpty {
                Text(emptyText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Chart(slices) { slice in
                    SectorMark(
                        angle: .value("Spil", slice.count),
                        innerRadius: .ratio(0.58),
                        angularInset: 1.5
                    )
                    .foregroundStyle(gameTypeChartColor(slice.title))
                }
                .frame(height: 220)
                .chartLegend(.hidden)
                .accessibilityLabel("Lagkagediagram for \(title.lowercased())")

                if title == "Trumf og sans" {
                    trumpLegend(slices)
                } else {
                    chartLegend(slices)
                }
            }
        }
        .padding(16)
        .background(cardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private func chartLegend(_ slices: [GameTypeSlice]) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 118), spacing: 8, alignment: .leading)], alignment: .leading, spacing: 7) {
            ForEach(slices) { slice in
                HStack(spacing: 6) {
                    Circle()
                        .fill(gameTypeChartColor(slice.title))
                        .frame(width: 8, height: 8)
                    Text(slice.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)
                    Text("\(slice.count)")
                        .font(.caption2.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.top, 2)
    }

    private func trumpLegend(_ slices: [GameTypeSlice]) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 108), spacing: 8, alignment: .leading)], alignment: .leading, spacing: 7) {
            ForEach(slices) { slice in
                HStack(spacing: 6) {
                    trumpLegendIcon(slice.title)
                        .frame(width: 16, height: 16)
                    Text(slice.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)
                    Text("\(slice.count)")
                        .font(.caption2.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.top, 2)
    }

    @ViewBuilder
    private func trumpLegendIcon(_ title: String) -> some View {
        switch title.lowercased() {
        case "hjerter":
            Text(Suit.hearts.cardSymbol)
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(gameTypeChartColor(title))
        case "ruder":
            Text(Suit.diamonds.cardSymbol)
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(gameTypeChartColor(title))
        case "spar":
            Text(Suit.spades.cardSymbol)
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(gameTypeChartColor(title))
        case "klør":
            Text(Suit.clubs.cardSymbol)
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(gameTypeChartColor(title))
        case "sans":
            Image(systemName: "xmark.circle")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(gameTypeChartColor(title))
        default:
            Circle()
                .fill(gameTypeChartColor(title))
        }
    }

    private func gameTypeChartColor(_ title: String) -> Color {
        switch title.lowercased() {
        case "vip", "vip 1":
            return Color(red: 0.44, green: 0.56, blue: 0.75)
        case "vip 2":
            return Color(red: 0.50, green: 0.62, blue: 0.80)
        case "vip 3":
            return Color(red: 0.36, green: 0.47, blue: 0.67)
        case "halve":
            return Color(red: 0.44, green: 0.66, blue: 0.53)
        case "gode":
            return Color(red: 0.12, green: 0.16, blue: 0.21)
        case "almindelige":
            return Color(red: 0.79, green: 0.58, blue: 0.29)
        case "sans":
            return Color(red: 0.64, green: 0.65, blue: 0.64)
        case "sol":
            return Color(red: 0.91, green: 0.67, blue: 0.20)
        case "ren sol":
            return Color(red: 0.82, green: 0.52, blue: 0.13)
        case "halv bordlægger":
            return Color(red: 0.68, green: 0.48, blue: 0.76)
        case "bordlægger":
            return Color(red: 0.49, green: 0.33, blue: 0.62)
        case "duestraf", "ukendt", "vip ukendt":
            return Color.secondary.opacity(0.75)
        case "hjerter":
            return ActiveGamePosterStyle.negativeScoreColor
        case "ruder":
            return ActiveGamePosterStyle.negativeScoreColor
        case "spar":
            return Color(red: 0.08, green: 0.10, blue: 0.13)
        case "klør":
            return Color(red: 0.20, green: 0.21, blue: 0.22)
        default:
            return Color(red: 0.44, green: 0.56, blue: 0.75)
        }
    }

    private func dataQualityChart(_ snapshot: HistoricalStatisticsSnapshot) -> some View {
        let slices = [
            DataQualitySlice(title: "Nulsum", count: snapshot.zeroSumGameCount),
            DataQualitySlice(title: "Afvigelser", count: snapshot.nonZeroSumGameCount),
            DataQualitySlice(
                title: "Holdscore",
                count: snapshot.derivedIssueCounts[HistoricalDataQualityFlag.teamScoreMismatch.rawValue] ?? 0
            ),
        ].filter { $0.count > 0 }

        return VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Scorekvalitet")
                    .font(.headline)
                Text("Nulsum og afledte advarsler fra importen.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Chart(slices) { slice in
                SectorMark(
                    angle: .value("Spil", slice.count),
                    innerRadius: .ratio(0.58),
                    angularInset: 1.5
                )
                .foregroundStyle(by: .value("Status", slice.title))
            }
            .frame(height: 220)
            .chartLegend(position: .bottom, spacing: 8)
            .accessibilityLabel("Cirkeldiagram over scorekvalitet i historiske data")
        }
        .padding(16)
        .background(cardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private func playerLeaderboard(_ summaries: [HistoricalPlayerScoreSummary], profiles: [HistoricalPlayerProfile]) -> some View {
        let profilesByPlayerId = Dictionary(uniqueKeysWithValues: profiles.map { ($0.player.id, $0) })

        return VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Spillere")
                    .font(.headline)
                Text("Tryk på en spiller for bedste/værste dag, bedste/værste spil og meldingsstatistik.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 10) {
                ForEach(summaries) { summary in
                    if let profile = profilesByPlayerId[summary.player.id] {
                        NavigationLink {
                            playerProfileView(profile)
                        } label: {
                            playerRow(summary)
                        }
                        .buttonStyle(.plain)
                    } else {
                        playerRow(summary)
                    }
                }
            }
        }
    }

    private func sessionOverviewList(_ sessions: [HistoricalSessionOverview]) -> some View {
        let newestFirst = sessions.sorted { lhs, rhs in lhs.sessionIndex > rhs.sessionIndex }

        return VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Alle spilledage")
                    .font(.headline)
                Text("Seneste spilledag øverst. Tryk for resultater, bedste/værste spil og datagrundlag.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 10) {
                ForEach(newestFirst) { overview in
                    NavigationLink {
                        sessionDetailView(overview)
                    } label: {
                        sessionRow(overview)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func playerProfileView(_ profile: HistoricalPlayerProfile) -> some View {
        return ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.player.name)
                        .font(.largeTitle.weight(.bold))
                    Text("\(profile.summary.gamesPlayed) spil · \(scoreText(profile.summary.totalScore)) point · snit \(averageText(profile.summary.averageScore))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    sessionMetric(title: "Bedste dag", session: profile.bestDay)
                    sessionMetric(title: "Værste dag", session: profile.worstDay)
                    miniMetric(title: "Bedste spil", value: optionalScoreText(profile.bestGame?.selectedPlayerScore))
                    miniMetric(title: "Værste spil", value: optionalScoreText(profile.worstGame?.selectedPlayerScore))
                }

                playerSessionPerformanceSection(profile)

                if let bestGame = profile.bestGame {
                    gameDetailCard("Bedste spil", detail: bestGame, highlightedPlayerId: profile.player.id)
                }

                if let worstGame = profile.worstGame {
                    gameDetailCard("Værste spil", detail: worstGame, highlightedPlayerId: profile.player.id)
                }

                playerBidSection(profile)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Andre relevante nøgletal")
                        .font(.headline)
                    metricLine("Spil med brugbare metadata", "\(profile.gamesWithMetadata) af \(profile.summary.gamesPlayed)")
                    metricLine("Meldingssample", "\(profile.bidSampleSize) spil")
                    metricLine("Samlet score", scoreText(profile.summary.totalScore))
                    metricLine("Gennemsnit pr. spil", averageText(profile.summary.averageScore))
                }
                .padding(16)
                .background(cardBackground)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .padding(.bottom, 12)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(profile.player.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func playerSessionPerformanceSection(_ profile: HistoricalPlayerProfile) -> some View {
        let newestFirst = profile.sessionScores.sorted { lhs, rhs in lhs.sessionIndex > rhs.sessionIndex }

        return VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Gevinst/tab pr. spilledag")
                    .font(.headline)
                Text("Søjler over nul er gevinst, søjler under nul er tab. Listen under grafen viser seneste spilledag først.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Chart {
                ForEach(profile.sessionScores) { sessionScore in
                    BarMark(
                        x: .value("Spilledag", sessionScore.sessionIndex),
                        y: .value("Point", sessionScore.score)
                    )
                    .foregroundStyle(sessionScore.score >= 0 ? ActiveGamePosterStyle.positiveScoreColor : ActiveGamePosterStyle.negativeScoreColor)
                    .accessibilityLabel(sessionScore.sessionTitle)
                    .accessibilityValue(scoreText(sessionScore.score))
                }
                RuleMark(y: .value("Nul", 0))
                    .foregroundStyle(Color.secondary.opacity(0.45))
            }
            .frame(height: 220)
            .chartXAxisLabel("Spilledag")
            .chartYAxisLabel("Point")
            .accessibilityLabel("Søjlediagram for \(profile.player.name)s gevinst og tab pr. spilledag")

            VStack(spacing: 8) {
                ForEach(newestFirst) { sessionScore in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(sessionScore.sessionTitle)
                                .font(.subheadline.weight(.semibold))
                            Text("\(sessionScore.gamesInSession) spil")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: 12)

                        Text(scoreText(sessionScore.score))
                            .font(.subheadline.weight(.bold).monospacedDigit())
                            .foregroundStyle(scoreForeground(sessionScore.score))
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .background {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.primary.opacity(0.04))
                    }
                }
            }
        }
        .padding(16)
        .background(cardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private func playerBidSection(_ profile: HistoricalPlayerProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Meldinger")
                    .font(.headline)
                Text("Baseret på spil hvor spilleren er registreret som melder/vinder, og spiltypen er importeret.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let best = profile.mostSuccessfulBid {
                bidStatRow("Mest succesfuld", stat: best)
            } else {
                Text("Ingen brugbare meldingsdata for denne spiller endnu.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let worst = profile.leastSuccessfulBid, worst.id != profile.mostSuccessfulBid?.id {
                bidStatRow("Mindst succesfuld", stat: worst)
            }
        }
        .padding(16)
        .background(cardBackground)
    }

    private func sessionDetailView(_ overview: HistoricalSessionOverview) -> some View {
        let sessionStreaks = sessionScoreStreakSummary(from: overview.progressPoints)
        let bidOutcomes = sessionBidOutcomeRows(from: overview)

        return ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Spilledag \(overview.session.sessionNumber)")
                        .font(.largeTitle.weight(.bold))
                    Text(sessionDetailSubtitle(overview))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                sessionDevelopmentPanel(overview.progressPoints)
                sessionDailyResultPanel(overview.playerTotals)

                if let bestGame = overview.bestGame {
                    sessionOutcomeCard("Største gevinst", detail: bestGame, isWin: true)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    sessionStreakTile(
                        title: "Længste sejrsrække",
                        streak: sessionStreaks.longestWin,
                        fallback: "Ingen sejre"
                    )
                    sessionStreakTile(
                        title: "Længste tabsrække",
                        streak: sessionStreaks.longestLoss,
                        fallback: "Ingen tab"
                    )
                }

                sessionBidOutcomeChart(bidOutcomes)
                countDivergingChart(
                    title: "Tabte/vundne spil på dagen",
                    emptyText: "Ingen spilresultater på dagen.",
                    rows: sessionTotalOutcomeRows(from: overview)
                )
                sessionGameTypeIconBarChart(gameTypeSlices(from: overview.gameDetails))

                sessionGamesSection(overview.gameDetails)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .padding(.bottom, 12)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Spilledag \(overview.session.sessionNumber)")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sessionProgressChart(_ points: [HistoricalSessionProgressPoint]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Udvikling i løbet af dagen")
                .font(.headline)

            Chart(points) { point in
                LineMark(
                    x: .value("Spil", point.gameNumber),
                    y: .value("Point", point.cumulativeScore)
                )
                .foregroundStyle(by: .value("Spiller", point.player.name))
                .interpolationMethod(.linear)

                PointMark(
                    x: .value("Spil", point.gameNumber),
                    y: .value("Point", point.cumulativeScore)
                )
                .foregroundStyle(by: .value("Spiller", point.player.name))
                .symbolSize(18)
            }
            .frame(height: 240)
            .chartLegend(position: .bottom, alignment: .center, spacing: 8)
            .chartXAxisLabel("Spil")
            .chartYAxisLabel("Point")
            .accessibilityLabel("Linjediagram for spillerens samlede gevinst og tab i løbet af spilledagen")
        }
        .padding(16)
        .background(cardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private func sessionDevelopmentPanel(_ points: [HistoricalSessionProgressPoint]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            posterSectionTitle("UDVIKLING")

            HStack(spacing: 12) {
                HistoricalSessionTimelineCanvas(
                    points: points,
                    xDomain: sessionChartXDomain(points),
                    yDomain: sessionChartYDomain(points),
                    colorForPlayer: { historicalPlayerLineColor($0) }
                )
                .frame(height: 136)

                sessionChartLabelColumn(points)
            }
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                    .fill(ActiveGamePosterStyle.panelColor)
            }
            .overlay {
                RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                    .strokeBorder(ActiveGamePosterStyle.borderColor, lineWidth: 1)
            }
            .accessibilityLabel("Udvikling i pointstilling i løbet af spilledagen")
        }
    }

    private func sessionChartLabelColumn(_ points: [HistoricalSessionProgressPoint]) -> some View {
        GeometryReader { geometry in
            let rows = sessionChartLabelRows(points, height: geometry.size.height)
            ZStack(alignment: .topLeading) {
                ForEach(rows) { row in
                    Text("\(row.point.player.name) \(scoreText(row.point.cumulativeScore))")
                        .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 11.5))
                        .fontWidth(.compressed)
                        .fontWeight(.semibold)
                        .foregroundStyle(historicalPlayerLineColor(row.point.player))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .frame(width: 96, height: 22, alignment: .leading)
                        .offset(y: row.y)
                }
            }
        }
        .frame(width: 96, height: 136)
    }

    private func latestSessionProgressPoints(
        _ points: [HistoricalSessionProgressPoint]
    ) -> [HistoricalSessionProgressPoint] {
        let grouped = Dictionary(grouping: points, by: \.player.id)
        return grouped.values.compactMap { values in
            values.max { lhs, rhs in lhs.gameNumber < rhs.gameNumber }
        }
    }

    private func sessionChartXDomain(_ points: [HistoricalSessionProgressPoint]) -> ClosedRange<Int> {
        let values = points.map(\.gameNumber)
        let lower = values.min() ?? 0
        let upper = values.max() ?? lower
        return lower...upper
    }

    private func sessionChartYDomain(_ points: [HistoricalSessionProgressPoint]) -> ClosedRange<Int> {
        let values = points.map(\.cumulativeScore) + [0]
        let lower = values.min() ?? 0
        let upper = values.max() ?? lower
        let span = max(1, upper - lower)
        let padding = max(20, Int(Double(span) * 0.12))
        return (lower - padding)...(upper + padding)
    }

    private func sessionChartLabelRows(
        _ points: [HistoricalSessionProgressPoint],
        height: CGFloat
    ) -> [HistoricalSessionChartLabelRow] {
        let labelHeight: CGFloat = 22
        let gap: CGFloat = 3
        let domain = sessionChartYDomain(points)
        let span = max(1, domain.upperBound - domain.lowerBound)
        var rows = latestSessionProgressPoints(points)
            .map { point -> HistoricalSessionChartLabelRow in
                let fraction = Double(domain.upperBound - point.cumulativeScore) / Double(span)
                let rawY = CGFloat(fraction) * height - labelHeight / 2
                return HistoricalSessionChartLabelRow(
                    point: point,
                    y: min(max(rawY, 0), max(0, height - labelHeight))
                )
            }
            .sorted { $0.y < $1.y }

        for index in rows.indices.dropFirst() {
            let previousIndex = rows.index(before: index)
            rows[index].y = max(rows[index].y, rows[previousIndex].y + labelHeight + gap)
        }

        if let last = rows.last {
            let overflow = last.y + labelHeight - height
            if overflow > 0 {
                for index in rows.indices {
                    rows[index].y -= overflow
                }
            }
        }

        return rows.map { row in
            var output = row
            output.y = min(max(output.y, 0), max(0, height - labelHeight))
            return output
        }
    }

    private func sessionDailyResultPanel(_ scores: [HistoricalPlayerGameScore]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            posterSectionTitle("DAGENS RESULTAT")

            HStack(spacing: 8) {
                ForEach(scores.sorted { lhs, rhs in lhs.player.displayOrder < rhs.player.displayOrder }) { score in
                    VStack(spacing: 2) {
                        Text(score.player.name.uppercased())
                            .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 11))
                            .fontWidth(.compressed)
                            .fontWeight(.semibold)
                            .foregroundStyle(ActiveGamePosterStyle.darkInkColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.62)

                        Text(scoreText(score.score))
                            .font(.custom(ActiveGamePosterStyle.fontName, size: 30))
                            .fontWidth(.compressed)
                            .monospacedDigit()
                            .foregroundStyle(scoreForeground(score.score))
                            .lineLimit(1)
                            .minimumScaleFactor(0.58)
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 5)
                    .frame(maxWidth: .infinity)
                    .frame(height: 66)
                    .background {
                        RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                            .fill(ActiveGamePosterStyle.panelColor)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                            .strokeBorder(historicalPlayerLineColor(score.player), lineWidth: 2)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(score.player.name), \(scoreText(score.score)) point")
                }
            }
        }
    }

    private func posterSectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 15))
            .fontWidth(.compressed)
            .fontWeight(.semibold)
            .foregroundStyle(ActiveGamePosterStyle.darkInkColor.opacity(0.72))
            .padding(.horizontal, 4)
    }

    /// Kumulativ nettoscore efter hver spilledag — samme graftype som på en enkelt spilledag (`sessionProgressChart`), men med historisk akse.
    private func allSessionsProgressChart(_ points: [HistoricalScoreTimelinePoint]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Udvikling henover alle spilledage")
                .font(.headline)

            if points.isEmpty {
                Text("Ingen spilledage at vise endnu.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Chart(points) { point in
                    LineMark(
                        x: .value("Spilledag", point.sessionIndex),
                        y: .value("Point", point.cumulativeScore)
                    )
                    .foregroundStyle(by: .value("Spiller", point.playerName))
                    .interpolationMethod(.linear)

                    PointMark(
                        x: .value("Spilledag", point.sessionIndex),
                        y: .value("Point", point.cumulativeScore)
                    )
                    .foregroundStyle(by: .value("Spiller", point.playerName))
                    .symbolSize(18)
                }
                .frame(height: 240)
                .chartLegend(position: .bottom, alignment: .center, spacing: 8)
                .chartXAxisLabel("Spilledag")
                .chartYAxisLabel("Point")
                .accessibilityLabel("Linjediagram for kumulativ score henover alle spilledage")
            }
        }
        .padding(16)
        .background(cardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private func sessionResultStrip(_ scores: [HistoricalPlayerGameScore]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Samlet resultat")
                .font(.headline)

            HStack(spacing: 8) {
                ForEach(scores.sorted { lhs, rhs in lhs.player.displayOrder < rhs.player.displayOrder }) { score in
                    VStack(spacing: 2) {
                        Text(score.player.name)
                            .font(.caption2.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        Text(scoreText(score.score))
                            .font(.caption.weight(.bold).monospacedDigit())
                            .foregroundStyle(scoreForeground(score.score))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.primary.opacity(0.04))
                    }
                }
            }
        }
        .padding(16)
        .background(cardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private func sessionGameTypePieChart(_ details: [HistoricalGameScoreDetail]) -> some View {
        let slices = gameTypeSlices(from: details)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Mest populære spiltyper")
                .font(.headline)

            if slices.isEmpty {
                Text("Ingen registrerede spiltyper på dagen.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Chart(slices) { slice in
                    SectorMark(
                        angle: .value("Spil", slice.count),
                        innerRadius: .ratio(0.58),
                        angularInset: 1.5
                    )
                    .foregroundStyle(by: .value("Spiltype", slice.title))
                }
                .frame(height: 220)
                .chartLegend(position: .bottom, alignment: .center, spacing: 8)
                .accessibilityLabel("Lagkagediagram over mest populære spiltyper på spilledagen")
            }
        }
        .padding(16)
        .background(cardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private func sessionGameTypeIconBarChart(_ slices: [GameTypeSlice]) -> some View {
        let sorted = slices.sorted { lhs, rhs in
            if lhs.count != rhs.count { return lhs.count < rhs.count }
            return lhs.title < rhs.title
        }
        let maxCount = max(sorted.map(\.count).max() ?? 1, 1)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Spiltyper efter antal")
                .font(.headline)

            if sorted.isEmpty {
                Text("Ingen registrerede spiltyper på dagen.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 9) {
                    ForEach(sorted) { slice in
                        HStack(spacing: 10) {
                            StatistikGameTypeIcon(kind: StatistikGameTypeIconKind(title: slice.title), color: ActiveGamePosterStyle.darkInkColor)
                                .frame(width: 26, height: 30)
                                .accessibilityHidden(true)

                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.primary.opacity(0.06))
                                    Capsule()
                                        .fill(gameTypeChartColor(slice.title))
                                        .frame(width: max(8, geometry.size.width * CGFloat(slice.count) / CGFloat(maxCount)))
                                }
                            }
                            .frame(height: 12)

                            Text("\(slice.count)")
                                .font(.caption.weight(.bold).monospacedDigit())
                                .foregroundStyle(.secondary)
                                .frame(width: 34, alignment: .trailing)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(slice.title), \(slice.count) spil")
                    }
                }
            }
        }
        .padding(16)
        .background(cardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private func sessionBidOutcomeChart(_ rows: [SessionBidOutcomeRow]) -> some View {
        countDivergingChart(
            title: "Tabte/vundne spil på egne meldinger",
            emptyText: "Ingen vundne meldinger på dagen.",
            rows: rows
        )
    }

    private func countDivergingChart(
        title: String,
        emptyText: String,
        rows: [SessionBidOutcomeRow]
    ) -> some View {
        let maxCount = max(rows.map { max($0.wins, $0.losses) }.max() ?? 1, 1)

        return VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            if rows.allSatisfy({ $0.wins == 0 && $0.losses == 0 }) {
                Text(emptyText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 6) {
                    ForEach(rows) { row in
                        sessionBidOutcomeChartRow(row, maxCount: maxCount)
                    }
                }
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                .fill(ActiveGamePosterStyle.panelColor)
        }
        .overlay {
            RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                .strokeBorder(ActiveGamePosterStyle.borderColor, lineWidth: 1)
        }
    }

    private func sessionBidOutcomeChartRow(_ row: SessionBidOutcomeRow, maxCount: Int) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Text(row.player.name)
                .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 12))
                .fontWidth(.compressed)
                .fontWeight(.semibold)
                .foregroundStyle(ActiveGamePosterStyle.darkInkColor)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(width: 78, alignment: .leading)

            GeometryReader { geometry in
                let centerX = geometry.size.width * 0.5
                let valueLabelWidth: CGFloat = 22
                let valueLabelGap: CGFloat = 5
                let availableSideWidth = max(
                    18,
                    min(
                        centerX - valueLabelWidth - valueLabelGap,
                        geometry.size.width - centerX - valueLabelWidth - valueLabelGap
                    )
                )
                let winWidth = row.wins == 0 ? CGFloat(0) : max(8, availableSideWidth * CGFloat(row.wins) / CGFloat(maxCount))
                let lossWidth = row.losses == 0 ? CGFloat(0) : max(8, availableSideWidth * CGFloat(row.losses) / CGFloat(maxCount))
                let barHeight: CGFloat = 13
                let green = scoreForeground(1)
                let red = scoreForeground(-1)

                ZStack {
                    Rectangle()
                        .fill(ActiveGamePosterStyle.borderColor.opacity(0.48))
                        .frame(width: 1, height: 28)
                        .position(x: centerX, y: 18)

                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(red.opacity(row.losses == 0 ? 0.24 : 0.94))
                        .frame(width: lossWidth, height: barHeight)
                        .position(x: centerX - lossWidth / 2, y: 18)

                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(green.opacity(row.wins == 0 ? 0.24 : 0.94))
                        .frame(width: winWidth, height: barHeight)
                        .position(x: centerX + winWidth / 2, y: 18)

                    Text("\(row.losses)")
                        .font(.caption2.weight(.bold).monospacedDigit())
                        .foregroundStyle(red)
                        .frame(width: valueLabelWidth, alignment: .trailing)
                        .position(x: centerX - lossWidth - valueLabelGap - valueLabelWidth / 2, y: 18)

                    Text("\(row.wins)")
                        .font(.caption2.weight(.bold).monospacedDigit())
                        .foregroundStyle(green)
                        .frame(width: valueLabelWidth, alignment: .leading)
                        .position(x: centerX + winWidth + valueLabelGap + valueLabelWidth / 2, y: 18)
                }
            }
            .frame(height: 36)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(row.player.name): \(row.wins) vundne spil og \(row.losses) tabte spil på egne meldinger")
    }

    private func sessionStreakTile(
        title: String,
        streak: SessionPlayerScoreStreak?,
        fallback: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 14))
                .fontWidth(.compressed)
                .fontWeight(.semibold)
                .foregroundStyle(ActiveGamePosterStyle.darkInkColor.opacity(0.72))
            Text(streak.map { "\($0.player.name) · \($0.games) spil" } ?? fallback)
                .font(.custom(ActiveGamePosterStyle.fontName, size: 28))
                .fontWidth(.compressed)
                .foregroundStyle(ActiveGamePosterStyle.darkInkColor)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
            HStack(alignment: .firstTextBaseline) {
                Text("I alt")
                    .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 13))
                    .fontWidth(.compressed)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 6)
                Text(streak.map { scoreText($0.totalScore) } ?? "-")
                    .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 15))
                    .fontWidth(.compressed)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .foregroundStyle(scoreForeground(streak?.totalScore ?? 0))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                .fill(ActiveGamePosterStyle.panelColor)
        }
        .overlay {
            RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                .strokeBorder(ActiveGamePosterStyle.borderColor, lineWidth: 1)
        }
    }

    private func sessionOutcomeCard(_ title: String, detail: HistoricalGameScoreDetail, isWin: Bool) -> some View {
        let outcome = isWin ? outcomePlayers(for: detail, isWin: true) : outcomePlayers(for: detail, isWin: false)

        return NavigationLink {
            HistoricalGameDetailView(detail: detail, resumeText: gameResumeText(detail))
        } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("Spil \(detail.game.gameNumberInSession) · \(gameTypeText(detail.game))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(outcome.names)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                VStack(alignment: .trailing, spacing: 4) {
                    Text(scoreText(outcome.score))
                        .font(.title3.weight(.bold).monospacedDigit())
                        .foregroundStyle(scoreForeground(outcome.score))
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(16)
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
    }

    private func sessionGamesSection(_ details: [HistoricalGameScoreDetail]) -> some View {
        HistoricalSessionGamesTable(
            rows: details
                .sorted { lhs, rhs in lhs.game.gameNumberInSession > rhs.game.gameNumberInSession }
                .map { detail in
                    HistoricalSessionGameTableRow(
                        detail: detail,
                        gameTypeTitle: gameTypeText(detail.game),
                        resume: gameResumeText(detail)
                    )
                }
        )
    }

    private func sessionGameRow(_ detail: HistoricalGameScoreDetail) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Spil \(detail.game.gameNumberInSession)")
                            .font(.body.weight(.semibold))
                        if detail.hasQualityIssues {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(ActiveGamePosterStyle.activeOrangeColor)
                                .accessibilityLabel("Dataadvarsel")
                        }
                    }
                    Text(gameTypeText(detail.game))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }

            gameScoreStrip(detail, highlightedPlayerId: nil)
        }
        .padding(14)
        .background(cardBackground)
    }

    private func gameDetailView(_ detail: HistoricalGameScoreDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Spil \(detail.game.gameNumberInSession)")
                        .font(.largeTitle.weight(.bold))
                    Text(gameSubtitle(detail))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                gameScoreStrip(detail, highlightedPlayerId: nil)
                    .padding(16)
                    .background(cardBackground)

                if detail.hasQualityIssues {
                    gameQualityWarning(detail)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Resume")
                        .font(.headline)
                    Text(gameResumeText(detail))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(cardBackground)

            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .padding(.bottom, 12)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Spil \(detail.game.gameNumberInSession)")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sessionRow(_ overview: HistoricalSessionOverview) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Spilledag \(overview.session.sessionNumber)")
                    .font(.body.weight(.semibold))

                Text(formattedSessionDate(overview.session))
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                Text(formattedSessionLocation(overview.session))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 10)

            VStack(alignment: .trailing, spacing: 5) {
                Text("\(overview.gamesPlayed) spil")
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.secondary)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(14)
        .background(cardBackground)
    }

    private func gameDetailCard(_ title: String, detail: HistoricalGameScoreDetail, highlightedPlayerId: String?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(gameSubtitle(detail))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            gameScoreStrip(detail, highlightedPlayerId: highlightedPlayerId)

            VStack(alignment: .leading, spacing: 6) {
                metricLine("Dato", detail.session.date ?? "-")
                metricLine("Sted", detail.session.location ?? "-")
                metricLine("Melding", gameTypeText(detail.game))
                metricLine("Melder/vinder", playerListText(detail.game.bidderIds, fallback: detail.game.bidderId))
                metricLine("Makker", detail.game.partnerId ?? "-")
                metricLine("Giver", detail.game.dealerId ?? "-")
            }
        }
        .padding(16)
        .background(cardBackground)
    }

    private func gameQualityWarning(_ detail: HistoricalGameScoreDetail) -> some View {
        CollapsibleDataWarning(messages: detail.qualityFlags.map(qualityFlagText))
    }

    private func gameScoreStrip(_ detail: HistoricalGameScoreDetail, highlightedPlayerId: String?) -> some View {
        HStack(spacing: 8) {
            ForEach(detail.playerScores) { score in
                VStack(spacing: 2) {
                    Text(score.player.name)
                        .font(.caption2.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Text(scoreText(score.score))
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundStyle(scoreForeground(score.score))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(score.player.id == highlightedPlayerId ? Color.accentColor.opacity(0.16) : Color.primary.opacity(0.04))
                }
            }
        }
    }

    private func qualityFlagText(_ flag: String) -> String {
        if flag == HistoricalDataQualityFlag.teamScoreMismatch.rawValue {
            return "Holdscore stemmer ikke: et almindeligt makkerspil har ikke samme gevinst/tab på begge spillere på samme side. Sol og selvmakker er undtaget fra dette tjek."
        }
        if flag == HistoricalDataQualityFlag.correctedFromSourceNote.rawValue {
            return "Rettet fra kilde-note: regnearket indeholder en konkret note, og rettelsen får spillet til at summere til nul."
        }
        if flag == "score_sum_not_zero" {
            return "Resultatet summerer ikke til nul i den historiske kilde. Spillet vises, men bør læses som usikker historik."
        }
        if flag == "source_explicit_score_sum_not_zero" {
            return "Den eksplicitte scoreblok i regnearket summerer ikke til nul. Spillet kræver manuel kildeafklaring."
        }
        if flag == "missing_game_type" {
            return "Spiltypen mangler i den historiske kilde."
        }
        if flag == "missing_bidder_or_winner" {
            return "Melder eller vinder mangler i den historiske kilde."
        }
        if flag == "missing_dealer" {
            return "Giver mangler i den historiske kilde."
        }
        if flag == "missing_partner" {
            return "Makker mangler i den historiske kilde."
        }
        return flag.replacingOccurrences(of: "_", with: " ")
    }

    private func gameTypeRow(_ overview: HistoricalGameTypeOverview) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(overview.title)
                        .font(.body.weight(.semibold))
                    Text("\(overview.games) spil · \(overview.playerResultCount) spillerresultater")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                if let bestPlayer = overview.bestPlayer {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(bestPlayer.player.name)
                            .font(.caption.weight(.semibold))
                        Text(scoreText(bestPlayer.score))
                            .font(.caption.weight(.bold).monospacedDigit())
                            .foregroundStyle(scoreForeground(bestPlayer.score))
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }

            miniMetric(title: "Melder-data", value: "\(overview.gamesWithBidder)")
        }
        .padding(14)
        .background(cardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private func gameTypeDetailView(_ overview: HistoricalGameTypeOverview) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(overview.title)
                        .font(.largeTitle.weight(.bold))
                    Text("\(overview.games) historiske spil med denne spiltype.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    statTile(title: "Spil", value: "\(overview.games)")
                    statTile(title: "Resultater", value: "\(overview.playerResultCount)")
                    statTile(title: "Melder-data", value: "\(overview.gamesWithBidder)")
                }

                gameTypePlayerAverageChart(overview.playerAverages)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Spillere")
                        .font(.headline)

                    ForEach(overview.playerTotals.sorted { lhs, rhs in lhs.score > rhs.score }) { score in
                        HStack {
                            Text(score.player.name)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text(scoreText(score.score))
                                .font(.subheadline.weight(.bold).monospacedDigit())
                                .foregroundStyle(scoreForeground(score.score))
                        }
                    }
                }
                .padding(16)
                .background(cardBackground)

                gameTypeExpensiveGamesSection(overview)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Datadækning")
                        .font(.headline)
                    metricLine("Spil med type", "\(overview.games)")
                    metricLine("Spil med melder/vinder", "\(overview.gamesWithBidder)")
                    metricLine("Bemærkning", "Historikken har ufuldstændige metadata, så sammenligning skal læses med sample size.")
                }
                .padding(16)
                .background(cardBackground)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .padding(.bottom, 12)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(overview.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func gameTypePlayerAverageChart(_ averages: [HistoricalGameTypePlayerAverage]) -> some View {
        let ordered = averages.sorted { lhs, rhs in
            if lhs.player.displayOrder != rhs.player.displayOrder {
                return lhs.player.displayOrder < rhs.player.displayOrder
            }
            return lhs.player.name < rhs.player.name
        }
        let maxAbsAverage = max(ordered.map { abs($0.averageScore) }.max() ?? 1, 1)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Gennemsnit pr. spiller")
                .font(.headline)

            VStack(spacing: 8) {
                ForEach(ordered) { average in
                    HStack(spacing: 10) {
                        Text(average.player.name)
                            .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 12))
                            .fontWidth(.compressed)
                            .fontWeight(.semibold)
                            .foregroundStyle(ActiveGamePosterStyle.darkInkColor)
                            .lineLimit(1)
                            .frame(width: 72, alignment: .leading)

                        GeometryReader { geometry in
                            let centerX = geometry.size.width * 0.5
                            let sideWidth = max(8, centerX - 2)
                            let barWidth = average.averageScore == 0
                                ? CGFloat(0)
                                : max(8, sideWidth * CGFloat(abs(average.averageScore)) / CGFloat(maxAbsAverage))
                            let barColor = scoreForeground(average.averageScore)

                            ZStack {
                                Capsule()
                                    .fill(Color.primary.opacity(0.055))
                                    .frame(height: 12)

                                Rectangle()
                                    .fill(ActiveGamePosterStyle.borderColor.opacity(0.55))
                                    .frame(width: 1, height: 24)
                                    .position(x: centerX, y: 12)

                                if average.averageScore < 0 {
                                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                                        .fill(barColor.opacity(0.82))
                                        .frame(width: barWidth, height: 12)
                                        .position(x: centerX - barWidth / 2, y: 12)
                                } else if average.averageScore > 0 {
                                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                                        .fill(barColor.opacity(0.82))
                                        .frame(width: barWidth, height: 12)
                                        .position(x: centerX + barWidth / 2, y: 12)
                                }
                            }
                        }
                        .frame(height: 24)

                        Text(signedAverageText(average.averageScore))
                            .font(.caption.weight(.bold).monospacedDigit())
                            .foregroundStyle(scoreForeground(average.averageScore))
                            .frame(width: 46, alignment: .trailing)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(average.player.name), gennemsnit \(signedAverageText(average.averageScore)) over \(average.games) spil")
                }
            }
        }
        .padding(16)
        .background(cardBackground)
    }

    private func gameTypeExpensiveGamesSection(_ overview: HistoricalGameTypeOverview) -> some View {
        let games = mostExpensiveGames(in: overview)

        return VStack(alignment: .leading, spacing: 10) {
            Text("Dyreste spil")
                .font(.headline)

            if games.isEmpty {
                Text("Ingen spil at vise.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(games) { detail in
                    gameDetailCard("Spil \(detail.game.gameNumberInSession)", detail: detail, highlightedPlayerId: nil)
                }
            }
        }
    }

    private func mostExpensiveGames(in overview: HistoricalGameTypeOverview) -> [HistoricalGameScoreDetail] {
        let details = overview.gameDetails
        let maxAbsScore = details
            .map { detail in detail.playerScores.map { abs($0.score) }.max() ?? 0 }
            .max() ?? 0
        guard maxAbsScore > 0 else { return [] }
        return details
            .filter { detail in
                (detail.playerScores.map { abs($0.score) }.max() ?? 0) == maxAbsScore
            }
            .sorted { lhs, rhs in
                if lhs.session.sessionNumber != rhs.session.sessionNumber {
                    return lhs.session.sessionNumber < rhs.session.sessionNumber
                }
                return lhs.game.gameNumberInSession < rhs.game.gameNumberInSession
            }
    }

    private func scoreTimeline(_ points: [HistoricalScoreTimelinePoint]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Udvikling over tid")
                    .font(.headline)
                Text("Kumulativ score efter hver historisk spilledag.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Chart(points) { point in
                LineMark(
                    x: .value("Spilledag", point.sessionIndex),
                    y: .value("Point", point.cumulativeScore)
                )
                .foregroundStyle(by: .value("Spiller", point.playerName))
                .interpolationMethod(.linear)

                PointMark(
                    x: .value("Spilledag", point.sessionIndex),
                    y: .value("Point", point.cumulativeScore)
                )
                .foregroundStyle(by: .value("Spiller", point.playerName))
                .symbolSize(22)
            }
            .frame(height: 260)
            .chartLegend(position: .bottom, spacing: 8)
            .chartXAxisLabel("Spilledag")
            .chartYAxisLabel("Point")
            .accessibilityLabel("Linjediagram for historisk kumulativ score pr. spiller")
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private func playerRow(_ summary: HistoricalPlayerScoreSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(summary.player.name)
                        .font(.body.weight(.semibold))
                    Text("\(summary.gamesPlayed) spil · snit \(averageText(summary.averageScore))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 10)

                Text(scoreText(summary.totalScore))
                    .font(.title3.weight(.bold).monospacedDigit())
                    .foregroundStyle(scoreForeground(summary.totalScore))
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                miniMetric(title: "Bedste spil", value: optionalScoreText(summary.bestSingleGame))
                miniMetric(title: "Værste spil", value: optionalScoreText(summary.worstSingleGame))
                sessionMetric(title: "Bedste dag", session: summary.bestSession)
                sessionMetric(title: "Værste dag", session: summary.worstSession)
            }
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(summary.player.name), \(scoreText(summary.totalScore)) point, gennemsnit \(averageText(summary.averageScore))"
        )
    }

    private func dataQuality(_ snapshot: HistoricalStatisticsSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Datagrundlag")
                .font(.headline)
            Text("\(snapshot.zeroSumGameCount) af \(snapshot.gameCount) spil summerer til nul. \(snapshot.nonZeroSumGameCount) spil har scoreafvigelser og indgår stadig i pointstatistikken.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Kilde: bundled historikdatasæt \(snapshot.dataVersion), genereret \(snapshot.generatedAt).")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .tertiarySystemGroupedBackground))
        }
    }

    private func statTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.bold).monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.primary.opacity(0.045))
        }
    }

    private func miniMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.bold).monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        }
    }

    private func sessionMetric(title: String, session: HistoricalPlayerSessionScore?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(optionalScoreText(session?.score))
                .font(.caption.weight(.bold).monospacedDigit())
            if let session {
                Text(session.sessionTitle)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        }
    }

    private func rankBadge(_ rank: Int) -> some View {
        Text("\(rank)")
            .font(.subheadline.weight(.bold))
            .monospacedDigit()
            .foregroundStyle(rank == 1 ? Color(red: 0.45, green: 0.32, blue: 0.05) : .secondary)
            .frame(width: 32, height: 32)
            .background {
                Circle()
                    .fill(rank == 1 ? Color.yellow.opacity(0.35) : Color.secondary.opacity(0.12))
            }
            .accessibilityHidden(true)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(ActiveGamePosterStyle.panelColor)
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(ActiveGamePosterStyle.borderColor, lineWidth: 1)
            }
    }

    private func metricLine(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer(minLength: 12)
            Text(value)
                .font(.caption.weight(.semibold))
                .multilineTextAlignment(.trailing)
        }
    }

    private func bidStatRow(_ title: String, stat: HistoricalPlayerBidStatistic) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(stat.gameType.capitalized)
                    .font(.subheadline.weight(.semibold))
            }

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 2) {
                Text(scoreText(stat.totalScore))
                    .font(.subheadline.weight(.bold).monospacedDigit())
                    .foregroundStyle(scoreForeground(stat.totalScore))
                Text("\(stat.games) spil · snit \(averageText(stat.averageScore))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        }
    }

    private func sessionSubtitle(_ session: HistoricalSession) -> String {
        [formattedSessionDate(session), formattedSessionLocation(session)]
            .compactMap { value in
                value == "-" ? nil : value
            }
            .joined(separator: " · ")
    }

    private func sessionDetailSubtitle(_ overview: HistoricalSessionOverview) -> String {
        [
            formattedSessionDate(overview.session),
            formattedSessionLocation(overview.session),
            "\(overview.gamesPlayed) spil",
        ]
        .filter { !$0.isEmpty && $0 != "-" }
        .joined(separator: " · ")
    }

    private func formattedSessionDate(_ session: HistoricalSession) -> String {
        guard let date = session.date, !date.isEmpty else {
            return "-"
        }

        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.dateFormat = "yyyy-MM-dd"

        guard let parsedDate = parser.date(from: date) else {
            return date
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "da_DK")
        formatter.dateFormat = "d. MMMM yyyy"
        return formatter.string(from: parsedDate)
    }

    private func formattedSessionLocation(_ session: HistoricalSession) -> String {
        guard let location = session.location?.trimmingCharacters(in: .whitespacesAndNewlines), !location.isEmpty else {
            return "-"
        }
        return location
    }

    private func gameSubtitle(_ detail: HistoricalGameScoreDetail) -> String {
        let session = "Spilledag \(detail.session.sessionNumber)"
        let game = "spil \(detail.game.gameNumberInSession)"
        let place = detail.session.location.map { "· \($0)" } ?? ""
        let date = detail.session.date.map { "· \($0)" } ?? ""
        return "\(session), \(game) \(date) \(place)"
    }

    private func gameResumeText(_ detail: HistoricalGameScoreDetail) -> String {
        let gameType = gameTypeText(detail.game)
        let bidder = playerNameText(detail.game.bidderId, scores: detail.playerScores)
        let bidText = historicalBidText(for: detail.game, gameType: gameType)

        if isHistoricalSolGame(gameType) {
            return "Spil #\(detail.game.gameNumberInSession): \(historicalSolResumeText(detail, gameType: gameType, bidder: bidder))"
        }

        if gameType == "Duestraf" {
            let holder = bidder == "-" ? playerNameText(detail.game.winnerId, scores: detail.playerScores) : bidder
            return "Spil #\(detail.game.gameNumberInSession): Duestraf til \(holder)"
        }

        var narrative: String
        if bidder != "-" {
            narrative = "\(bidder) meldte \(bidText)"
        } else {
            narrative = "Der blev meldt \(bidText)"
        }

        if let actual = inferredActualTricks(for: detail, gameType: gameType),
           let bid = detail.game.bidTricks,
           bidder != "-" {
            narrative = historicalStorslemCoreIfNeeded(narrative, actual: actual)
            narrative += historicalTrickOutcomeSpoken(
                bid: bid,
                actual: actual,
                bidder: bidder,
                partner: playerNameText(detail.game.partnerId, scores: detail.playerScores)
            )
        }

        return "Spil #\(detail.game.gameNumberInSession): \(narrative)"
    }

    private func historicalBidText(for game: HistoricalGame, gameType: String) -> String {
        let bid = game.bidTricks.map { "\($0) " } ?? ""

        switch gameType {
        case "Almindelige":
            var text = "\(bid)almindelige"
            if let trump = trumpTitle(for: game), trump != "Sans" {
                text += " med \(suitSymbol(for: trump)) som trumf"
            }
            return text
        case "Sans":
            return "\(bid)sans uden trumf"
        case "Gode":
            return "\(bid)♣ (gode)"
        case "Halve":
            var text = "\(bid)halve"
            if let trump = trumpTitle(for: game), trump != "Sans" {
                text += " med \(suitSymbol(for: trump)) som trumf"
            }
            return text
        case "VIP":
            var text = "\(bid)\(vipLevelTitle(for: game))"
            if let trump = trumpTitle(for: game), trump != "Sans" {
                text += " med \(suitSymbol(for: trump)) som trumf"
            }
            return text
        default:
            return "\(bid)\(gameType.lowercased())"
        }
    }

    private func historicalSolResumeText(
        _ detail: HistoricalGameScoreDetail,
        gameType: String,
        bidder: String
    ) -> String {
        let melder = bidder == "-" ? "Der" : bidder
        var sentence = bidder == "-"
            ? "Der blev meldt \(gameType.lowercased())"
            : "\(melder) meldte \(gameType.lowercased())"

        let allies = historicalSolAllies(for: detail)
        if !allies.isEmpty {
            sentence += " og \(danishNameList(allies)) gik med"
        }

        let participants = uniqueHistoricalNames([bidder].filter { $0 != "-" } + allies)
        guard !participants.isEmpty else { return sentence }

        let scoresByName = Dictionary(uniqueKeysWithValues: detail.playerScores.map { ($0.player.name, $0.score) })
        let home = participants.filter { (scoresByName[$0] ?? 0) > 0 }
        let down = participants.filter { (scoresByName[$0] ?? 0) < 0 }

        if down.isEmpty {
            return sentence + (participants.count == 1 ? " – han gik hjem" : " – de gik alle hjem")
        }
        if home.isEmpty {
            return sentence + (participants.count == 1 ? " – han gik ned" : " – de gik alle ned")
        }

        return sentence + " – \(danishNameList(home)) gik hjem, men \(danishNameList(down)) gik ned"
    }

    private func historicalSolAllies(for detail: HistoricalGameScoreDetail) -> [String] {
        let bidder = playerNameText(detail.game.bidderId, scores: detail.playerScores)
        var allies: [String] = []

        let partner = playerNameText(detail.game.partnerId, scores: detail.playerScores)
        if partner != "-", partner != bidder {
            allies.append(partner)
        }

        let additionalBidders = detail.game.bidderIds
            .map { playerNameText($0, scores: detail.playerScores) }
            .filter { $0 != "-" && $0 != bidder }
        allies.append(contentsOf: additionalBidders)

        return uniqueHistoricalNames(allies)
    }

    private func isHistoricalSolGame(_ gameType: String) -> Bool {
        ["Sol", "Ren sol", "Halv bordlægger", "Bordlægger"].contains(gameType)
    }

    private func inferredActualTricks(
        for detail: HistoricalGameScoreDetail,
        gameType: String
    ) -> Int? {
        guard let bid = detail.game.bidTricks, (8...13).contains(bid) else { return nil }
        guard let bidderId = detail.game.bidderId else { return nil }
        guard let bidderScore = detail.playerScores.first(where: { $0.player.id == bidderId })?.score else { return nil }
        let base = historicalBasePoints(for: bid)
        let multiplier = historicalMultiplier(for: detail.game, gameType: gameType)
        guard base > 0, multiplier > 0 else { return nil }

        return (0...13).first { actual in
            historicalContractScore(bid: bid, actual: actual, base: base, multiplier: multiplier) == bidderScore
        }
    }

    private func historicalContractScore(bid: Int, actual: Int, base: Int, multiplier: Int) -> Int {
        let difference = actual - bid
        if difference >= 0 {
            var total = (base * (difference + 1) + base) * multiplier
            if actual == 13 {
                total *= 2
            }
            return total
        }

        var total = base * abs(difference) * multiplier
        if actual == 0 {
            total *= 2
        }
        return -total
    }

    private func historicalBasePoints(for bid: Int) -> Int {
        switch bid {
        case 8: return 1
        case 9: return 2
        case 10: return 4
        case 11: return 8
        case 12: return 16
        case 13: return 32
        default: return 0
        }
    }

    private func historicalMultiplier(for game: HistoricalGame, gameType: String) -> Int {
        switch gameType {
        case "Almindelige":
            return 1
        case "Sans", "Halve", "Gode":
            return 2
        case "VIP":
            switch vipLevelTitle(for: game) {
            case "VIP 1": return 2
            case "VIP 2": return 4
            case "VIP 3": return 8
            default: return 2
            }
        default:
            return 0
        }
    }

    private func historicalStorslemCoreIfNeeded(_ core: String, actual: Int) -> String {
        guard actual == 13 || actual == 0 else { return core }
        return "\(core) – STORSLEM"
    }

    private func historicalTrickOutcomeSpoken(
        bid: Int,
        actual: Int,
        bidder: String,
        partner: String
    ) -> String {
        let delta = actual - bid
        if delta == 0 {
            if partner != "-", partner != bidder {
                return ", og sammen med \(partner) ramte han buddet præcis på stikkene"
            }
            return ", og ramte buddet præcis på stikkene"
        }

        let paren = delta > 0 ? "(+\(delta))" : "(\(delta))"
        if partner != "-", partner != bidder {
            return ", og sammen med \(partner) tog han \(actual) stik \(paren)"
        }
        return ", og tog \(actual) stik \(paren)"
    }

    private func danishNameList(_ names: [String]) -> String {
        let trimmed = names.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        switch trimmed.count {
        case 0:
            return ""
        case 1:
            return trimmed[0]
        case 2:
            return "\(trimmed[0]) og \(trimmed[1])"
        default:
            let head = trimmed.dropLast().joined(separator: ", ")
            return "\(head) og \(trimmed.last!)"
        }
    }

    private func uniqueHistoricalNames(_ names: [String]) -> [String] {
        var seen = Set<String>()
        var output: [String] = []
        for name in names where !seen.contains(name) {
            output.append(name)
            seen.insert(name)
        }
        return output
    }

    private func gameTypeText(_ game: HistoricalGame) -> String {
        if let canonical = canonicalGameType(for: game) {
            return canonical
        }
        if let raw = game.gameTypeRaw, !raw.isEmpty {
            return raw
        }
        if let normalized = game.gameTypeNormalized, !normalized.isEmpty {
            return normalized.capitalized
        }
        return "-"
    }

    private func canonicalGameType(for game: HistoricalGame) -> String? {
        HistoricalGameTypeClassifier.canonicalGameType(for: game)
    }

    private func bidTrickDistribution(from data: HistoricalWhistData) -> [HistoricalBidTrickBucket] {
        let grouped = Dictionary(grouping: data.games.compactMap { game -> Int? in
            guard
                canonicalGameType(for: game) == "Almindelige",
                let bidTricks = game.bidTricks,
                (1...13).contains(bidTricks)
            else {
                return nil
            }
            return bidTricks
        }) { $0 }

        return grouped
            .map { tricks, values in HistoricalBidTrickBucket(tricks: tricks, count: values.count) }
            .sorted { $0.tricks < $1.tricks }
    }

    private func solGameDistribution(from data: HistoricalWhistData) -> [GameTypeSlice] {
        let order = ["Sol", "Ren sol", "Halv bordlægger", "Bordlægger"]
        return distribution(from: data.games.compactMap { game in
            guard let type = canonicalGameType(for: game), order.contains(type) else { return nil }
            return type
        }, order: order)
    }

    private func vipGameDistribution(from data: HistoricalWhistData) -> [GameTypeSlice] {
        let order = ["VIP 1", "VIP 2", "VIP 3", "VIP ukendt"]
        return distribution(from: data.games.compactMap { game in
            guard canonicalGameType(for: game) == "VIP" else { return nil }
            return vipLevelTitle(for: game)
        }, order: order)
    }

    private func trumpDistribution(from data: HistoricalWhistData) -> [GameTypeSlice] {
        let order = ["Hjerter", "Ruder", "Spar", "Klør", "Sans"]
        return distribution(from: data.games.compactMap { trumpTitle(for: $0) }, order: order)
    }

    private func distribution(from values: [String], order: [String]) -> [GameTypeSlice] {
        let grouped = Dictionary(grouping: values) { $0 }
        return grouped
            .map { title, values in GameTypeSlice(title: title, count: values.count) }
            .sorted { lhs, rhs in
                let lhsIndex = order.firstIndex(of: lhs.title) ?? Int.max
                let rhsIndex = order.firstIndex(of: rhs.title) ?? Int.max
                if lhsIndex != rhsIndex { return lhsIndex < rhsIndex }
                if lhs.count != rhs.count { return lhs.count > rhs.count }
                return lhs.title < rhs.title
            }
    }

    private func vipLevelTitle(for game: HistoricalGame) -> String {
        let raw = normalizedText(game.gameTypeRaw)
        let normalized = normalizedText(game.gameTypeNormalized)
        let text = "\(raw) \(normalized)"

        if text.contains("vip i 3") || text.contains("vip 3") || text.contains("3. /") || text.contains("/ 3") {
            return "VIP 3"
        }
        if text.contains("vip i 2") || text.contains("vip 2") || text.contains("2. vip") || text.contains("2 vip") || text.contains("/ 2") {
            return "VIP 2"
        }
        if text.contains("vip i 1") || text.contains("vip 1") || text.contains("vip i første") || text.contains("/ 1") {
            return "VIP 1"
        }

        return "VIP ukendt"
    }

    private func trumpTitle(for game: HistoricalGame) -> String? {
        guard let canonical = canonicalGameType(for: game) else { return nil }
        if canonical == "Sans" { return "Sans" }
        if canonical == "Gode" { return "Klør" }
        if ["Sol", "Ren sol", "Halv bordlægger", "Bordlægger", "Duestraf"].contains(canonical) {
            return nil
        }

        let text = normalizedText(game.gameTypeRaw)
        if text.contains("hjerte") || text.contains("hjerter") || text.contains("♥") {
            return "Hjerter"
        }
        if text.contains("ruder") || text.contains("♦") {
            return "Ruder"
        }
        if text.contains("spar") || text.contains("♠") {
            return "Spar"
        }
        if text.contains("klør") || text.contains("kloer") || text.contains("♣") {
            return "Klør"
        }

        return nil
    }

    private func suitSymbol(for title: String) -> String {
        switch title {
        case "Hjerter": return "♥"
        case "Ruder": return "♦"
        case "Spar": return "♠"
        case "Klør": return "♣"
        default: return title
        }
    }

    private func normalizedText(_ value: String?) -> String {
        (value ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: ".", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
    }

    private func playerListText(_ players: [String], fallback: String?) -> String {
        if !players.isEmpty {
            return players.joined(separator: ", ")
        }
        return fallback ?? "-"
    }

    private func playerNameListText(
        _ players: [String],
        fallback: String?,
        scores: [HistoricalPlayerGameScore]
    ) -> String {
        let playerIds = players.isEmpty ? fallback.map { [$0] } ?? [] : players
        let names = playerIds
            .map { playerNameText($0, scores: scores) }
            .filter { $0 != "-" }
        return names.isEmpty ? "-" : names.joined(separator: ", ")
    }

    private func playerNameText(_ playerId: String?, scores: [HistoricalPlayerGameScore]) -> String {
        guard let playerId, !playerId.isEmpty else { return "-" }
        return scores.first { $0.player.id == playerId }?.player.name ?? playerId
    }

    private func gameTypeSlices(from details: [HistoricalGameScoreDetail]) -> [GameTypeSlice] {
        let grouped = Dictionary(grouping: details) { detail in
            gameTypeText(detail.game)
        }

        return grouped
            .filter { !$0.key.isEmpty && $0.key != "-" }
            .map { title, details in
                GameTypeSlice(title: title, count: details.count)
            }
            .sorted { lhs, rhs in
                if lhs.count != rhs.count {
                    return lhs.count > rhs.count
                }
                return lhs.title < rhs.title
            }
    }

    private func sessionBidOutcomeRows(from overview: HistoricalSessionOverview) -> [SessionBidOutcomeRow] {
        var outcomesByPlayerId = Dictionary(
            uniqueKeysWithValues: overview.playerTotals.map {
                ($0.player.id, SessionBidOutcomeRow(player: $0.player, wins: 0, losses: 0))
            }
        )

        for detail in overview.gameDetails {
            let bidderIds = normalizedPlayerIds(detail.game.bidderIds, fallback: detail.game.bidderId)
            guard !bidderIds.isEmpty else { continue }

            for bidderId in bidderIds {
                guard let score = detail.playerScores.first(where: { $0.player.id == bidderId }) else { continue }
                outcomesByPlayerId[bidderId, default: SessionBidOutcomeRow(player: score.player, wins: 0, losses: 0)]
                    .record(score.score)
            }
        }

        return outcomesByPlayerId.values.sorted { lhs, rhs in
            if lhs.player.displayOrder != rhs.player.displayOrder {
                return lhs.player.displayOrder < rhs.player.displayOrder
            }
            return lhs.player.name < rhs.player.name
        }
    }

    private func sessionTotalOutcomeRows(from overview: HistoricalSessionOverview) -> [SessionBidOutcomeRow] {
        var outcomesByPlayerId = Dictionary(
            uniqueKeysWithValues: overview.playerTotals.map {
                ($0.player.id, SessionBidOutcomeRow(player: $0.player, wins: 0, losses: 0))
            }
        )

        for point in overview.progressPoints {
            outcomesByPlayerId[point.player.id, default: SessionBidOutcomeRow(player: point.player, wins: 0, losses: 0)]
                .record(point.gameScore)
        }

        return outcomesByPlayerId.values.sorted { lhs, rhs in
            if lhs.player.displayOrder != rhs.player.displayOrder {
                return lhs.player.displayOrder < rhs.player.displayOrder
            }
            return lhs.player.name < rhs.player.name
        }
    }

    private func sessionScoreStreakSummary(
        from points: [HistoricalSessionProgressPoint]
    ) -> SessionScoreStreakSummary {
        let grouped = Dictionary(grouping: points, by: \.player.id)
        var allStreaks: [SessionPlayerScoreStreak] = []

        for playerPoints in grouped.values {
            let ordered = playerPoints.sorted { lhs, rhs in lhs.gameNumber < rhs.gameNumber }
            var activeKind: HistoricalScoreStreakKind?
            var activeGames = 0
            var activeTotal = 0
            var activePlayer: HistoricalPlayer?

            func finishActiveStreak() {
                guard let kind = activeKind, activeGames > 0, let player = activePlayer else {
                    activeKind = nil
                    activeGames = 0
                    activeTotal = 0
                    activePlayer = nil
                    return
                }
                allStreaks.append(
                    SessionPlayerScoreStreak(
                        player: player,
                        kind: kind,
                        games: activeGames,
                        totalScore: activeTotal
                    )
                )
                activeKind = nil
                activeGames = 0
                activeTotal = 0
                activePlayer = nil
            }

            for point in ordered {
                let kind: HistoricalScoreStreakKind?
                if point.gameScore > 0 {
                    kind = .win
                } else if point.gameScore < 0 {
                    kind = .loss
                } else {
                    kind = nil
                }

                guard let kind else {
                    finishActiveStreak()
                    continue
                }

                if activeKind != kind {
                    finishActiveStreak()
                    activeKind = kind
                    activeGames = 0
                    activeTotal = 0
                    activePlayer = point.player
                }

                activeGames += 1
                activeTotal += point.gameScore
            }

            finishActiveStreak()
        }

        let winStreaks = allStreaks.filter { $0.kind == .win }
        let lossStreaks = allStreaks.filter { $0.kind == .loss }
        return SessionScoreStreakSummary(
            longestWin: bestSessionStreak(from: winStreaks, prefersHigherTotal: true),
            longestLoss: bestSessionStreak(from: lossStreaks, prefersHigherTotal: false)
        )
    }

    private func bestSessionStreak(
        from streaks: [SessionPlayerScoreStreak],
        prefersHigherTotal: Bool
    ) -> SessionPlayerScoreStreak? {
        streaks.max { lhs, rhs in
            if lhs.games != rhs.games {
                return lhs.games < rhs.games
            }
            if lhs.totalScore != rhs.totalScore {
                return prefersHigherTotal ? lhs.totalScore < rhs.totalScore : lhs.totalScore > rhs.totalScore
            }
            return lhs.player.displayOrder > rhs.player.displayOrder
        }
    }

    private func normalizedPlayerIds(_ ids: [String], fallback: String?) -> [String] {
        let normalizedIds = ids
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if !normalizedIds.isEmpty {
            return normalizedIds
        }
        guard let fallback = fallback?.trimmingCharacters(in: .whitespacesAndNewlines), !fallback.isEmpty else {
            return []
        }
        return [fallback]
    }

    private func outcomePlayers(for detail: HistoricalGameScoreDetail, isWin: Bool) -> (names: String, score: Int) {
        let scores = detail.playerScores.map(\.score)
        let targetScore = isWin ? scores.max() : scores.min()
        guard let targetScore else {
            return ("-", 0)
        }
        let names = detail.playerScores
            .filter { $0.score == targetScore }
            .map(\.player.name)
            .joined(separator: ", ")
        return (names.isEmpty ? "-" : names, targetScore)
    }

    private func scoreText(_ value: Int) -> String {
        if value > 0 { return "+\(value)" }
        return "\(value)"
    }

    private func optionalScoreText(_ value: Int?) -> String {
        guard let value else { return "-" }
        return scoreText(value)
    }

    private func averageText(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(2)))
    }

    private func signedAverageText(_ value: Double) -> String {
        let formatted = averageText(value)
        if value > 0 {
            return "+\(formatted)"
        }
        return formatted
    }

    private func successRateText(_ value: Double?) -> String {
        guard let value else { return "-" }
        return value.formatted(.percent.precision(.fractionLength(0)))
    }

    private func scoreForeground(_ value: Int) -> Color {
        scoreForeground(Double(value))
    }

    private func scoreForeground(_ value: Double) -> Color {
        switch value {
        case let x where x > 0:
            return ActiveGamePosterStyle.positiveScoreColor
        case let x where x < 0:
            return ActiveGamePosterStyle.negativeScoreColor
        default:
            return Color.secondary
        }
    }

    private func scopeDescription(_ snapshot: HistoricalStatisticsSnapshot) -> String {
        switch snapshot.scope {
        case .current:
            return "Nuværende spilledag"
        case .recent:
            return "Seneste \(snapshot.sessionCount) spilledage"
        case .all:
            return "Alle \(snapshot.sessionCount) spilledage"
        }
    }

}

private struct CollapsibleDataWarning: View {
    var messages: [String]

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.snappy(duration: 0.18)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(ActiveGamePosterStyle.activeOrangeColor)
                    Text("Advarsel om data")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isExpanded ? "Skjul advarsel om data" : "Vis advarsel om data")

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(messages.enumerated()), id: \.offset) { _, message in
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(ActiveGamePosterStyle.activeOrangeColor.opacity(0.14))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(ActiveGamePosterStyle.activeOrangeColor.opacity(0.32), lineWidth: 1)
        }
    }
}

private struct HistoricalGameDetailView: View {
    var detail: HistoricalGameScoreDetail
    var resumeText: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                pageHeader
                historicalGamePoster

                if detail.hasQualityIssues {
                    CollapsibleDataWarning(messages: detail.qualityFlags.map(qualityFlagText))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .padding(.bottom, 12)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Spil \(detail.game.gameNumberInSession)")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var pageHeader: some View {
        VStack(alignment: .center, spacing: 4) {
            Text("SPIL #\(detail.game.gameNumberInSession)")
                .font(.custom(ActiveGamePosterStyle.fontName, size: 42))
                .fontWidth(.compressed)
                .foregroundStyle(ActiveGamePosterStyle.darkInkColor)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(gameSubtitle)
                .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 15))
                .fontWidth(.compressed)
                .fontWeight(.semibold)
                .foregroundStyle(ActiveGamePosterStyle.darkInkColor.opacity(0.66))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.78)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 2)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
            .fill(ActiveGamePosterStyle.panelColor)
            .overlay {
                RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                    .strokeBorder(ActiveGamePosterStyle.borderColor, lineWidth: 1)
            }
    }

    private var historicalGamePoster: some View {
        VStack(alignment: .leading, spacing: 10) {
            historicalTopPanel
            gameScoreStrip(highlightedPlayerId: nil)
            historicalDetailTiles

            VStack(alignment: .leading, spacing: 8) {
                SuitColoredInlineText.build(resumeText, colorScheme: .light, suitFontSize: 12)
                    .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 14))
                    .fontWidth(.compressed)
                    .lineSpacing(2)
                    .foregroundStyle(ActiveGamePosterStyle.darkInkColor.opacity(0.80))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground)
        }
    }

    private var historicalTopPanel: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: -2) {
                Text(bidderNameText.uppercased())
                    .font(.custom(ActiveGamePosterStyle.fontName, size: 35))
                    .fontWidth(.compressed)
                    .foregroundStyle(ActiveGamePosterStyle.darkInkColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.58)

                Text("MELDTE")
                    .font(.custom(ActiveGamePosterStyle.fontName, size: 35))
                    .fontWidth(.compressed)
                    .foregroundStyle(bidderScore >= 0 ? scoreForeground(1) : scoreForeground(-1))
                    .lineLimit(1)
                    .minimumScaleFactor(0.58)

                Text(posterGameTypeTitle)
                    .font(.custom(ActiveGamePosterStyle.fontName, size: 35))
                    .fontWidth(.compressed)
                    .foregroundStyle(ActiveGamePosterStyle.darkInkColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.48)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            posterPrimaryValue
                .frame(width: 112, height: 128)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(cardBackground)
    }

    @ViewBuilder
    private var posterPrimaryValue: some View {
        if isSolGame {
            StatistikGameTypeIcon(kind: StatistikGameTypeIconKind(title: gameTypeText), color: ActiveGamePosterStyle.darkInkColor)
                .frame(width: 96, height: 96)
        } else if let bid = detail.game.bidTricks {
            Text("\(bid)")
                .font(.custom(ActiveGamePosterStyle.fontName, size: 120))
                .fontWidth(.compressed)
                .monospacedDigit()
                .foregroundStyle(ActiveGamePosterStyle.darkInkColor)
                .lineLimit(1)
                .minimumScaleFactor(0.45)
        } else {
            StatistikGameTypeIcon(kind: StatistikGameTypeIconKind(title: gameTypeText), color: ActiveGamePosterStyle.darkInkColor)
                .frame(width: 84, height: 84)
        }
    }

    @ViewBuilder
    private var historicalDetailTiles: some View {
        if !isSolGame {
            HStack(spacing: 10) {
                historicalInfoTile(title: "TRUMF") {
                    trumpTileIcon
                }

                historicalInfoTile(title: "MAKKER") {
                    partnerTileIcon
                }
            }
        }
    }

    private func historicalInfoTile<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.custom(ActiveGamePosterStyle.fontName, size: 32))
                .fontWidth(.compressed)
                .foregroundStyle(ActiveGamePosterStyle.darkInkColor)
                .lineLimit(1)
                .minimumScaleFactor(0.58)

            Spacer(minLength: 0)
            content()
                .frame(height: 70)
            Spacer(minLength: 0)
        }
        .padding(.top, 12)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
        .frame(height: 150)
        .background(cardBackground)
    }

    @ViewBuilder
    private var trumpTileIcon: some View {
        if let suit = trumpSuit {
            Text(suit.cardSymbol)
                .font(.system(size: 66, weight: .black))
                .foregroundStyle(suitColor(suit))
        } else {
            Image(systemName: "xmark.circle")
                .font(.system(size: 55, weight: .semibold))
                .foregroundStyle(ActiveGamePosterStyle.darkInkColor)
        }
    }

    @ViewBuilder
    private var partnerTileIcon: some View {
        if let suit = partnerAceSuit {
            Text(suit.cardSymbol)
                .font(.system(size: 66, weight: .black))
                .foregroundStyle(suitColor(suit))
        } else if let partner = detail.game.partnerId, !partner.isEmpty {
            Text(playerNameText(partner))
                .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 18).weight(.semibold))
                .fontWidth(.compressed)
                .foregroundStyle(ActiveGamePosterStyle.darkInkColor)
                .lineLimit(1)
                .minimumScaleFactor(0.58)
        } else {
            Text("-")
                .font(.custom(ActiveGamePosterStyle.fontName, size: 48))
                .fontWidth(.compressed)
                .foregroundStyle(.secondary)
        }
    }

    private var gameSubtitle: String {
        let session = "Spilledag \(detail.session.sessionNumber)"
        let place = detail.session.location.map { "· \($0)" } ?? ""
        let date = detail.session.date.map { "· \($0)" } ?? ""
        return "\(session) \(date) \(place)"
    }

    private var bidderNameText: String {
        playerNameText(detail.game.bidderId)
    }

    private var bidderScore: Int {
        guard let bidderId = detail.game.bidderId else { return 0 }
        return detail.playerScores.first { $0.player.id == bidderId }?.score ?? 0
    }

    private var isSolGame: Bool {
        ["Sol", "Ren sol", "Halv bordlægger", "Bordlægger"].contains(gameTypeText)
    }

    private var posterGameTypeTitle: String {
        switch gameTypeText {
        case "Almindelige": return "ALM"
        case "Halv bordlægger": return "1/2 BORD"
        case "Bordlægger": return "BORD"
        default: return gameTypeText.uppercased()
        }
    }

    private var trumpSuit: Suit? {
        switch trumpTitle {
        case "Hjerter": return .hearts
        case "Ruder": return .diamonds
        case "Spar": return .spades
        case "Klør": return .clubs
        default: return nil
        }
    }

    private var partnerAceSuit: Suit? {
        let text = [detail.game.gameTypeRaw, detail.game.gameTypeNormalized]
            .compactMap { $0 }
            .joined(separator: " ")
            .lowercased()
        if text.contains("hjerte") || text.contains("♥") { return .hearts }
        if text.contains("ruder") || text.contains("♦") { return .diamonds }
        if text.contains("spar") || text.contains("♠") { return .spades }
        if text.contains("klør") || text.contains("kloer") || text.contains("♣") { return .clubs }
        return nil
    }

    private var trumpTitle: String? {
        switch gameTypeText {
        case "Sans": return "Sans"
        case "Gode": return "Klør"
        case "Sol", "Ren sol", "Halv bordlægger", "Bordlægger", "Duestraf":
            return nil
        default:
            let text = [detail.game.gameTypeRaw, detail.game.gameTypeNormalized]
                .compactMap { $0 }
                .joined(separator: " ")
                .lowercased()
            if text.contains("hjerte") || text.contains("♥") { return "Hjerter" }
            if text.contains("ruder") || text.contains("♦") { return "Ruder" }
            if text.contains("spar") || text.contains("♠") { return "Spar" }
            if text.contains("klør") || text.contains("kloer") || text.contains("♣") { return "Klør" }
            return nil
        }
    }

    private func suitColor(_ suit: Suit) -> Color {
        switch suit {
        case .hearts:
            return ActiveGamePosterStyle.negativeScoreColor
        case .diamonds:
            return ActiveGamePosterStyle.negativeScoreColor
        case .spades:
            return Color(red: 0.08, green: 0.10, blue: 0.13)
        case .clubs:
            return Color(red: 0.20, green: 0.21, blue: 0.22)
        }
    }

    private var gameTypeText: String {
        if let raw = detail.game.gameTypeRaw, !raw.isEmpty {
            return raw
        }
        if let normalized = detail.game.gameTypeNormalized, !normalized.isEmpty {
            return normalized.capitalized
        }
        return "-"
    }

    private func gameDetailCard(_ title: String, highlightedPlayerId: String?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(gameSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            gameScoreStrip(highlightedPlayerId: highlightedPlayerId)

            VStack(alignment: .leading, spacing: 6) {
                metricLine("Dato", detail.session.date ?? "-")
                metricLine("Sted", detail.session.location ?? "-")
                metricLine("Melding", gameTypeText)
                metricLine("Melder/vinder", playerListText(detail.game.bidderIds, fallback: detail.game.bidderId))
                metricLine("Makker", detail.game.partnerId ?? "-")
                metricLine("Giver", detail.game.dealerId ?? "-")
            }
        }
        .padding(16)
        .background(cardBackground)
    }

    private func gameScoreStrip(highlightedPlayerId: String?) -> some View {
        HStack(spacing: 8) {
            ForEach(detail.playerScores) { score in
                VStack(spacing: 2) {
                    Text(score.player.name)
                        .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 11).weight(.semibold))
                        .fontWidth(.compressed)
                        .foregroundStyle(ActiveGamePosterStyle.darkInkColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Text(scoreText(score.score))
                        .font(.custom(ActiveGamePosterStyle.fontName, size: 30))
                        .fontWidth(.compressed)
                        .monospacedDigit()
                        .foregroundStyle(scoreForeground(score.score))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background {
                    RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                        .fill(ActiveGamePosterStyle.panelColor)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                        .strokeBorder(score.player.id == highlightedPlayerId ? ActiveGamePosterStyle.contractMarkerColor : ActiveGamePosterStyle.borderColor, lineWidth: score.player.id == highlightedPlayerId ? 2 : 1)
                }
            }
        }
    }

    private func metricLine(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer(minLength: 12)
            Text(value)
                .font(.caption.weight(.semibold))
                .multilineTextAlignment(.trailing)
        }
    }

    private func playerListText(_ players: [String], fallback: String?) -> String {
        if !players.isEmpty {
            return players.joined(separator: ", ")
        }
        return fallback ?? "-"
    }

    private func playerNameListText(_ players: [String], fallback: String?) -> String {
        let playerIds = players.isEmpty ? fallback.map { [$0] } ?? [] : players
        let names = playerIds
            .map(playerNameText)
            .filter { $0 != "-" }
        return names.isEmpty ? "-" : names.joined(separator: ", ")
    }

    private func playerNameText(_ playerId: String?) -> String {
        guard let playerId, !playerId.isEmpty else { return "-" }
        return detail.playerScores.first { $0.player.id == playerId }?.player.name ?? playerId
    }

    private func qualityFlagText(_ flag: String) -> String {
        if flag == HistoricalDataQualityFlag.teamScoreMismatch.rawValue {
            return "Holdscore stemmer ikke: et almindeligt makkerspil har ikke samme gevinst/tab på begge spillere på samme side. Sol og selvmakker er undtaget fra dette tjek."
        }
        if flag == HistoricalDataQualityFlag.correctedFromSourceNote.rawValue {
            return "Rettet fra kilde-note: spillet er korrigeret manuelt ud fra en note i originalmaterialet."
        }
        return flag.replacingOccurrences(of: "_", with: " ")
    }

    private func scoreText(_ value: Int) -> String {
        if value > 0 { return "+\(value)" }
        return "\(value)"
    }

    private func scoreForeground(_ value: Int) -> Color {
        switch value {
        case let x where x > 0:
            return ActiveGamePosterStyle.positiveScoreColor
        case let x where x < 0:
            return ActiveGamePosterStyle.negativeScoreColor
        default:
            return Color.secondary
        }
    }
}

private struct PlannedStatistic: Identifiable {
    var id: String { title }
    var title: String
    var description: String
}

private struct HistoricalChartLabelRow: Identifiable {
    var id: String { point.playerId }
    var point: HistoricalScoreTimelinePoint
    var y: CGFloat
}

private struct HistoricalSessionChartLabelRow: Identifiable {
    var id: String { point.player.id }
    var point: HistoricalSessionProgressPoint
    var y: CGFloat
}

private struct HistoricalTimelineCanvas: View {
    let points: [HistoricalScoreTimelinePoint]
    let xDomain: ClosedRange<Int>
    let yDomain: ClosedRange<Int>
    let colorForPlayer: (String) -> Color

    var body: some View {
        Canvas { context, size in
            let xSpan = max(1, xDomain.upperBound - xDomain.lowerBound)
            let ySpan = max(1, yDomain.upperBound - yDomain.lowerBound)
            let plotRect = CGRect(
                x: 2,
                y: 8,
                width: max(1, size.width - 4),
                height: max(1, size.height - 16)
            )

            let yForScore: (Int) -> CGFloat = { score in
                let fraction = CGFloat(Double(yDomain.upperBound - score) / Double(ySpan))
                return plotRect.minY + fraction * plotRect.height
            }

            if yDomain.contains(0) {
                var zeroPath = Path()
                let y = yForScore(0)
                zeroPath.move(to: CGPoint(x: plotRect.minX, y: y))
                zeroPath.addLine(to: CGPoint(x: plotRect.maxX, y: y))
                context.stroke(
                    zeroPath,
                    with: .color(.secondary.opacity(0.22)),
                    style: StrokeStyle(lineWidth: 1, lineCap: .round)
                )
            }

            let grouped = Dictionary(grouping: points, by: \.playerId)
            for values in grouped.values {
                let ordered = values.sorted { lhs, rhs in
                    lhs.sessionIndex < rhs.sessionIndex
                }
                guard let first = ordered.first else { continue }

                var path = Path()
                for (index, point) in ordered.enumerated() {
                    let xFraction = CGFloat(Double(point.sessionIndex - xDomain.lowerBound) / Double(xSpan))
                    let coordinate = CGPoint(
                        x: plotRect.minX + xFraction * plotRect.width,
                        y: yForScore(point.cumulativeScore)
                    )
                    if index == 0 {
                        path.move(to: coordinate)
                    } else {
                        path.addLine(to: coordinate)
                    }
                }

                context.stroke(
                    path,
                    with: .color(colorForPlayer(first.playerName).opacity(0.78)),
                    style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round)
                )
            }
        }
        .accessibilityHidden(true)
    }
}

private struct HistoricalSessionTimelineCanvas: View {
    let points: [HistoricalSessionProgressPoint]
    let xDomain: ClosedRange<Int>
    let yDomain: ClosedRange<Int>
    let colorForPlayer: (HistoricalPlayer) -> Color

    var body: some View {
        Canvas { context, size in
            let xSpan = max(1, xDomain.upperBound - xDomain.lowerBound)
            let ySpan = max(1, yDomain.upperBound - yDomain.lowerBound)
            let plotRect = CGRect(
                x: 2,
                y: 8,
                width: max(1, size.width - 4),
                height: max(1, size.height - 16)
            )

            let yForScore: (Int) -> CGFloat = { score in
                let fraction = CGFloat(Double(yDomain.upperBound - score) / Double(ySpan))
                return plotRect.minY + fraction * plotRect.height
            }

            if yDomain.contains(0) {
                var zeroPath = Path()
                let y = yForScore(0)
                zeroPath.move(to: CGPoint(x: plotRect.minX, y: y))
                zeroPath.addLine(to: CGPoint(x: plotRect.maxX, y: y))
                context.stroke(
                    zeroPath,
                    with: .color(.secondary.opacity(0.20)),
                    style: StrokeStyle(lineWidth: 1, lineCap: .round)
                )
            }

            let grouped = Dictionary(grouping: points, by: \.player.id)
            for values in grouped.values {
                let ordered = values.sorted { lhs, rhs in
                    lhs.gameNumber < rhs.gameNumber
                }
                guard let first = ordered.first else { continue }

                var path = Path()
                for (index, point) in ordered.enumerated() {
                    let xFraction = CGFloat(Double(point.gameNumber - xDomain.lowerBound) / Double(xSpan))
                    let coordinate = CGPoint(
                        x: plotRect.minX + xFraction * plotRect.width,
                        y: yForScore(point.cumulativeScore)
                    )
                    if index == 0 {
                        path.move(to: coordinate)
                    } else {
                        path.addLine(to: coordinate)
                    }
                }

                context.stroke(
                    path,
                    with: .color(colorForPlayer(first.player).opacity(0.78)),
                    style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round)
                )
            }
        }
        .accessibilityHidden(true)
    }
}

private struct DataQualitySlice: Identifiable {
    var id: String { title }
    var title: String
    var count: Int
}

private struct GameTypeSlice: Identifiable {
    var id: String { title }
    var title: String
    var count: Int
}

private struct SessionPlayerScoreStreak: Identifiable {
    var id: String { "\(player.id)-\(kind)-\(games)-\(totalScore)" }
    var player: HistoricalPlayer
    var kind: HistoricalScoreStreakKind
    var games: Int
    var totalScore: Int
}

private struct SessionScoreStreakSummary {
    var longestWin: SessionPlayerScoreStreak?
    var longestLoss: SessionPlayerScoreStreak?
}

private struct SessionBidOutcomeRow: Identifiable {
    var id: String { player.id }
    var player: HistoricalPlayer
    var wins: Int
    var losses: Int

    mutating func record(_ score: Int) {
        if score > 0 {
            wins += 1
        } else if score < 0 {
            losses += 1
        }
    }
}

private struct SessionRankDistributionRow: Identifiable {
    var id: String { player.id }
    var player: HistoricalPlayer
    var counts: [Int: Int]
}

private struct HistoricalSessionGameTableRow: Identifiable {
    var id: String { detail.id }
    var detail: HistoricalGameScoreDetail
    var gameTypeTitle: String
    var resume: String
}

private struct HistoricalSessionGamesTable: View {
    @Environment(\.colorScheme) private var colorScheme

    let rows: [HistoricalSessionGameTableRow]

    @State private var expandedGameID: String?

    private let gameNumberColumnWidth: CGFloat = 44
    private let gameTypeIconColumnWidth: CGFloat = 28
    private let metaForeground = Color.secondary.opacity(0.72)

    private var players: [HistoricalPlayer] {
        let allPlayers = rows.flatMap { $0.detail.playerScores.map(\.player) }
        return Dictionary(grouping: allPlayers, by: \.id)
            .compactMap { $0.value.first }
            .sorted { lhs, rhs in lhs.displayOrder < rhs.displayOrder }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Alle spil")
                .font(.headline)

            VStack(alignment: .leading, spacing: 0) {
                headerRow
                ForEach(rows) { row in
                    accordionRow(row)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background {
                RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                    .fill(ActiveGamePosterStyle.panelColor)
            }
            .overlay {
                RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                    .strokeBorder(ActiveGamePosterStyle.borderColor, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous))
            .onChange(of: rows.map(\.id)) { _, ids in
                if let id = expandedGameID, !ids.contains(id) {
                    expandedGameID = nil
                }
            }
        }
    }

    private var headerRow: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(" ")
                .frame(width: gameNumberColumnWidth, alignment: .leading)
            Color.clear
                .frame(width: gameTypeIconColumnWidth, height: 1)
            ForEach(players) { player in
                Text(String(player.name.prefix(1)).uppercased())
                    .font(tableNumberFont)
                    .fontWidth(.compressed)
                    .fontWeight(.black)
                    .foregroundStyle(ActiveGamePosterStyle.darkInkColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .accessibilityLabel(player.name)
            }
            Color.clear.frame(width: 13, height: 1)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
    }

    private func accordionRow(_ row: HistoricalSessionGameTableRow) -> some View {
        let isExpanded = expandedGameID == row.id

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.22)) {
                    expandedGameID = isExpanded ? nil : row.id
                }
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    scoreRow(row)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .frame(width: 13)
                        .accessibilityHidden(true)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                resumeBox(row)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint(isExpanded ? "Skjul resumé" : "Vis resumé for spillet")
    }

    private func scoreRow(_ row: HistoricalSessionGameTableRow) -> some View {
        let scoresByPlayerId = Dictionary(uniqueKeysWithValues: row.detail.playerScores.map { ($0.player.id, $0.score) })
        return HStack(alignment: .center, spacing: 8) {
            Text("#\(row.detail.game.gameNumberInSession)")
                .font(tableNumberFont)
                .fontWidth(.compressed)
                .monospacedDigit()
                .foregroundStyle(metaForeground)
                .frame(width: gameNumberColumnWidth, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            StatistikGameTypeIcon(kind: StatistikGameTypeIconKind(title: row.gameTypeTitle), color: metaForeground)
                .frame(width: gameTypeIconColumnWidth, height: 24)
                .accessibilityLabel(row.gameTypeTitle)

            ForEach(players) { player in
                let value = scoresByPlayerId[player.id] ?? 0
                let isBidder = isBidder(player, in: row.detail.game)
                Text(scoreCell(value))
                    .font(tableNumberFont)
                    .fontWidth(.compressed)
                    .fontWeight(isBidder ? .black : .regular)
                    .monospacedDigit()
                    .foregroundStyle(scoreForeground(value))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }
        }
    }

    private func resumeBox(_ row: HistoricalSessionGameTableRow) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SuitColoredInlineText.build(row.resume, colorScheme: colorScheme, suitFontSize: 13)
                .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 15))
                .fontWidth(.compressed)
                .lineSpacing(2)
                .opacity(0.82)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
        .padding(.bottom, 8)
    }

    private var tableNumberFont: Font {
        .custom(ActiveGamePosterStyle.resumeFontName, size: 16)
    }

    private func isBidder(_ player: HistoricalPlayer, in game: HistoricalGame) -> Bool {
        if game.bidderId == player.id { return true }
        return game.bidderIds.contains(player.id)
    }

    private func scoreCell(_ value: Int) -> String {
        if value > 0 { return "+\(value)" }
        return "\(value)"
    }

    private func scoreForeground(_ value: Int) -> Color {
        if value > 0 { return ActiveGamePosterStyle.positiveScoreColor }
        if value < 0 { return ActiveGamePosterStyle.negativeScoreColor }
        return Color.secondary
    }
}

private enum StatistikGameTypeIconKind: Equatable {
    case almindelige
    case halve
    case gode
    case sans
    case vip(Int?)
    case sol(StatistikSolIconKind)
    case duty
    case unknown

    init(title: String) {
        switch title.lowercased() {
        case "almindelige":
            self = .almindelige
        case "halve":
            self = .halve
        case "gode":
            self = .gode
        case "sans":
            self = .sans
        case "vip":
            self = .vip(nil)
        case "vip 1":
            self = .vip(1)
        case "vip 2":
            self = .vip(2)
        case "vip 3":
            self = .vip(3)
        case "sol":
            self = .sol(.normal)
        case "ren sol":
            self = .sol(.pure)
        case "halv bordlægger":
            self = .sol(.halfDealer)
        case "bordlægger":
            self = .sol(.dealer)
        case "duestraf":
            self = .duty
        default:
            self = .unknown
        }
    }
}

private enum StatistikSolIconKind {
    case normal
    case pure
    case halfDealer
    case dealer
}

private struct StatistikGameTypeIcon: View {
    var kind: StatistikGameTypeIconKind
    var color: Color

    var body: some View {
        switch kind {
        case .sol(let solType):
            StatistikSolIcon(kind: solType, color: color)
        default:
            card
        }
    }

    private var card: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .strokeBorder(color, lineWidth: 1.8)
            cardContent
                .foregroundStyle(color)
                .padding(2)
        }
        .aspectRatio(0.72, contentMode: .fit)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var cardContent: some View {
        switch kind {
        case .almindelige:
            EmptyView()
        case .halve:
            HStack(spacing: 0) {
                Color.clear
                color
            }
        case .gode:
            Text(Suit.clubs.cardSymbol)
                .font(.system(size: 13, weight: .black))
        case .sans:
            Image(systemName: "xmark.circle")
                .font(.system(size: 12, weight: .semibold))
        case .vip(let level):
            Text(level.map { "V\($0)" } ?? "V")
                .font(.system(size: 9.5, weight: .black, design: .rounded))
                .minimumScaleFactor(0.65)
        case .duty:
            Image(systemName: "exclamationmark")
                .font(.system(size: 11, weight: .black))
        case .unknown:
            Text("?")
                .font(.system(size: 11, weight: .black, design: .rounded))
        case .sol:
            EmptyView()
        }
    }
}

private struct StatistikSolIcon: View {
    var kind: StatistikSolIconKind
    var color: Color

    var body: some View {
        ZStack {
            ForEach(0..<rayCount, id: \.self) { index in
                Capsule()
                    .fill(color)
                    .frame(width: 2.1, height: rayLength)
                    .offset(y: -rayOffset)
                    .rotationEffect(.degrees(Double(index) / Double(rayCount) * 360))
            }
            disc
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var disc: some View {
        switch kind {
        case .normal:
            Circle()
                .stroke(color, lineWidth: 2)
                .frame(width: discSize, height: discSize)
        case .pure:
            Circle()
                .stroke(color, lineWidth: 2.2)
                .frame(width: discSize, height: discSize)
        case .halfDealer:
            Circle()
                .stroke(color, lineWidth: 2.1)
                .background {
                    HStack(spacing: 0) {
                        Color.clear
                        color
                    }
                    .clipShape(Circle())
                }
                .frame(width: discSize, height: discSize)
        case .dealer:
            Circle()
                .fill(color)
                .frame(width: discSize, height: discSize)
        }
    }

    private var rayCount: Int {
        switch kind {
        case .normal: return 6
        case .pure: return 8
        case .halfDealer, .dealer: return 12
        }
    }

    private var rayLength: CGFloat {
        kind == .normal ? 4.8 : 5.5
    }

    private var rayOffset: CGFloat {
        kind == .normal ? 9.5 : 10.2
    }

    private var discSize: CGFloat {
        switch kind {
        case .normal: return 10
        case .pure: return 10.5
        case .halfDealer, .dealer: return 11
        }
    }
}

private struct HistoricalBidTrickBucket: Identifiable {
    var id: Int { tricks }
    var tricks: Int
    var count: Int

    var title: String {
        "\(tricks)"
    }
}
