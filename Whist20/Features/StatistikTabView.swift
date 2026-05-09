import Charts
import SwiftUI

struct StatistikTabView: View {
    @State private var selectedScope: HistoricalStatisticsScope = .current
    @State private var recentSessionLimit = 10

    private let dataResult: Result<HistoricalWhistData, Error>
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

    init(loader: HistoricalDataJSONLoader = HistoricalDataJSONLoader()) {
        dataResult = Result { try loader.load() }
    }

    var body: some View {
        NavigationStack {
            Group {
                switch dataResult {
                case let .success(data):
                    statisticsHub(data)
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
    }

    private func statisticsHub(_ data: HistoricalWhistData) -> some View {
        let allSnapshot = HistoricalStatisticsEngine.snapshot(from: data, scope: .all)
        let currentData = HistoricalStatisticsEngine.scopedData(from: data, scope: .current)
        let currentOverview = HistoricalStatisticsEngine.sessionOverviews(from: currentData).last
        let playerProfiles = HistoricalStatisticsEngine.playerProfiles(from: data)
        let gameTypes = gameTypeOverviews(from: data)

        return ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Statistikoversigt")
                        .font(.title2.weight(.bold))
                    Text("\(allSnapshot.sessionCount) spilledage · \(allSnapshot.gameCount) historiske spil · \(playerProfiles.count) spillere")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 10) {
                    if let currentOverview {
                        NavigationLink {
                            currentDayView(currentOverview)
                        } label: {
                            navigationCard(
                                title: "Nuværende spilledag",
                                subtitle: sessionSubtitle(currentOverview.session),
                                systemImage: "calendar.badge.clock",
                                metric: "\(currentOverview.gamesPlayed) spil"
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    NavigationLink {
                        allSessionsView(data)
                    } label: {
                        navigationCard(
                            title: "Alle spilledage",
                            subtitle: "Dato, sted, resultater og spil-detaljer",
                            systemImage: "calendar",
                            metric: "\(allSnapshot.sessionCount)"
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        playersOverviewView(data)
                    } label: {
                        navigationCard(
                            title: "Spillere",
                            subtitle: "Profiler, bedste/værste spil og meldinger",
                            systemImage: "person.3",
                            metric: "\(playerProfiles.count)"
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        gameTypesOverviewView(data)
                    } label: {
                        navigationCard(
                            title: "Spiltyper",
                            subtitle: "Succes pr. type med tydelig sample size",
                            systemImage: "rectangle.stack.badge.play",
                            metric: "\(gameTypes.count)"
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        trendsOverviewView(data)
                    } label: {
                        navigationCard(
                            title: "Tendenser",
                            subtitle: "Udvikling over tid og seneste perioder",
                            systemImage: "chart.xyaxis.line",
                            metric: "5-50"
                        )
                    }
                    .buttonStyle(.plain)
                }

                NavigationLink {
                    dataQualityView(data)
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

    private func trendsContent(data: HistoricalWhistData, snapshot: HistoricalStatisticsSnapshot) -> some View {
        let trends = HistoricalStatisticsEngine.playerTrendSummaries(from: data)

        return ScrollView {
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

    private func navigationCard(title: String, subtitle: String, systemImage: String, metric: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 34, height: 34)
                .background {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.accentColor.opacity(0.12))
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

    private func allSessionsView(_ data: HistoricalWhistData) -> some View {
        let overviews = HistoricalStatisticsEngine.sessionOverviews(from: data)

        return ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Alle spilledage")
                        .font(.largeTitle.weight(.bold))
                    Text("\(overviews.count) historiske spilledage. Detaljer ligger inde på hver dag.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

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

    private func playersOverviewView(_ data: HistoricalWhistData) -> some View {
        let snapshot = HistoricalStatisticsEngine.snapshot(from: data, scope: .all)
        let profiles = HistoricalStatisticsEngine.playerProfiles(from: data)

        return ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Spillere")
                        .font(.largeTitle.weight(.bold))
                    Text("Overblik først. Tryk på en spiller for alle detaljer.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                playerLeaderboard(snapshot.playerSummaries, profiles: profiles)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .padding(.bottom, 12)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Spillere")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func gameTypesOverviewView(_ data: HistoricalWhistData) -> some View {
        let overviews = gameTypeOverviews(from: data)

        return ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Spiltyper")
                        .font(.largeTitle.weight(.bold))
                    Text("Kun spil med importeret spiltype indgår. Sample size vises på hver række.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if overviews.isEmpty {
                    ContentUnavailableView("Ingen spiltyper", systemImage: "rectangle.stack.badge.play")
                } else {
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

    private func trendsOverviewView(_ data: HistoricalWhistData) -> some View {
        let scopedData = HistoricalStatisticsEngine.scopedData(
            from: data,
            scope: selectedScope,
            recentSessionLimit: recentSessionLimit
        )
        let snapshot = HistoricalStatisticsEngine.snapshot(
            from: data,
            scope: selectedScope,
            recentSessionLimit: recentSessionLimit
        )

        return trendsContent(data: scopedData, snapshot: snapshot)
            .navigationTitle("Tendenser")
            .navigationBarTitleDisplayMode(.inline)
    }

    private func dataQualityView(_ data: HistoricalWhistData) -> some View {
        let snapshot = HistoricalStatisticsEngine.snapshot(from: data, scope: .all)

        return ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Datagrundlag")
                        .font(.largeTitle.weight(.bold))
                    Text("Her ligger importkvalitet og planlagte statistikspor.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

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
                ForEach(Array(summaries.enumerated()), id: \.element.id) { index, summary in
                    if let profile = profilesByPlayerId[summary.player.id] {
                        NavigationLink {
                            playerProfileView(profile)
                        } label: {
                            playerRow(summary, rank: index + 1)
                        }
                        .buttonStyle(.plain)
                    } else {
                        playerRow(summary, rank: index + 1)
                    }
                }
            }
        }
    }

    private func sessionOverviewList(_ sessions: [HistoricalSessionOverview]) -> some View {
        let newestFirst = sessions.sorted { lhs, rhs in lhs.sessionIndex > rhs.sessionIndex }

        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Alle spilledage")
                    .font(.headline)
                Text("Dato, sted, antal spil og bedste/værste spil pr. spilledag.")
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
        ScrollView {
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
                    .foregroundStyle(sessionScore.score >= 0 ? Color.green : Color.red)
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
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Spilledag \(overview.session.sessionNumber)")
                        .font(.largeTitle.weight(.bold))
                    Text(sessionSubtitle(overview.session))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    statTile(title: "Spil", value: "\(overview.gamesPlayed)")
                    statTile(title: "Afvigelser", value: "\(overview.issueCount)")
                    statTile(title: "Spiltype", value: "\(overview.gamesWithType)")
                    statTile(title: "Makker", value: "\(overview.gamesWithPartner)")
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Resultat")
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

                if let bestGame = overview.bestGame {
                    gameDetailCard("Bedste spil", detail: bestGame, highlightedPlayerId: nil)
                }

                if let worstGame = overview.worstGame {
                    gameDetailCard("Værste spil", detail: worstGame, highlightedPlayerId: nil)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Datagrundlag")
                        .font(.headline)
                    metricLine("Kildeark", overview.session.sourceSheetName)
                    metricLine("Forventede spil", overview.session.expectedGameCount.map(String.init) ?? "-")
                    metricLine("Importerede spil", "\(overview.session.importedGameCount)")
                    metricLine("Status", overview.session.qualityStatus)
                }
                .padding(16)
                .background(cardBackground)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .padding(.bottom, 12)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Spilledag \(overview.session.sessionNumber)")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sessionRow(_ overview: HistoricalSessionOverview) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Spilledag \(overview.session.sessionNumber)")
                        .font(.body.weight(.semibold))
                    Text(sessionSubtitle(overview.session))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 10)

                Text("\(overview.gamesPlayed) spil")
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                miniMetric(title: "Bedste spil", value: optionalScoreText(overview.bestGame?.playerScores.map(\.score).max()))
                miniMetric(title: "Værste spil", value: optionalScoreText(overview.worstGame?.playerScores.map(\.score).min()))
                miniMetric(title: "Spiltype-data", value: "\(overview.gamesWithType)")
                miniMetric(title: "Afvigelser", value: "\(overview.issueCount)")
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

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                miniMetric(title: "Snit pr. resultat", value: averageText(overview.averageScore))
                miniMetric(title: "Melder-data", value: "\(overview.gamesWithBidder)")
            }
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
                    statTile(title: "Snit", value: averageText(overview.averageScore))
                }

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

                if let bestGame = overview.bestGame {
                    gameDetailCard("Bedste spil", detail: bestGame, highlightedPlayerId: nil)
                }

                if let worstGame = overview.worstGame {
                    gameDetailCard("Værste spil", detail: worstGame, highlightedPlayerId: nil)
                }

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

    private func playerRow(_ summary: HistoricalPlayerScoreSummary, rank: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                rankBadge(rank)

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
                miniMetric(title: "Bedste", value: optionalScoreText(summary.bestSingleGame))
                miniMetric(title: "Værste", value: optionalScoreText(summary.worstSingleGame))
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
            "Rang \(rank), \(summary.player.name), \(scoreText(summary.totalScore)) point, gennemsnit \(averageText(summary.averageScore))"
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
            .fill(Color(uiColor: .secondarySystemGroupedBackground))
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
        [session.date, session.location]
            .compactMap { value in
                guard let value, !value.isEmpty else { return nil }
                return value
            }
            .joined(separator: " · ")
    }

    private func gameSubtitle(_ detail: HistoricalGameScoreDetail) -> String {
        let session = "Spilledag \(detail.session.sessionNumber)"
        let game = "spil \(detail.game.gameNumberInSession)"
        let place = detail.session.location.map { "· \($0)" } ?? ""
        let date = detail.session.date.map { "· \($0)" } ?? ""
        return "\(session), \(game) \(date) \(place)"
    }

    private func gameTypeText(_ game: HistoricalGame) -> String {
        if let raw = game.gameTypeRaw, !raw.isEmpty {
            return raw
        }
        if let normalized = game.gameTypeNormalized, !normalized.isEmpty {
            return normalized.capitalized
        }
        return "-"
    }

    private func playerListText(_ players: [String], fallback: String?) -> String {
        if !players.isEmpty {
            return players.joined(separator: ", ")
        }
        return fallback ?? "-"
    }

    private func gameTypeOverviews(from data: HistoricalWhistData) -> [HistoricalGameTypeOverview] {
        let gamesByType = Dictionary(grouping: data.games) { game in
            game.gameTypeNormalized?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        }
        let playersById = Dictionary(uniqueKeysWithValues: data.players.map { ($0.id, $0) })
        let allGameDetails = Dictionary(uniqueKeysWithValues: data.games.compactMap { game -> (String, HistoricalGameScoreDetail)? in
            let sessionsById = Dictionary(uniqueKeysWithValues: data.sessions.map { ($0.id, $0) })
            let results = data.playerResults.filter { $0.gameId == game.id }
            guard let session = sessionsById[game.sessionId] else { return nil }
            let scores = results.compactMap { result -> HistoricalPlayerGameScore? in
                guard let player = playersById[result.playerId] else { return nil }
                return HistoricalPlayerGameScore(player: player, score: result.score)
            }
            return (
                game.id,
                HistoricalGameScoreDetail(
                    game: game,
                    session: session,
                    playerScores: scores,
                    selectedPlayerScore: nil
                )
            )
        })

        return gamesByType
            .filter { !$0.key.isEmpty }
            .map { type, games in
                let gameIds = Set(games.map(\.id))
                let playerScores = data.playerResults
                    .filter { gameIds.contains($0.gameId) }
                    .reduce(into: [String: Int]()) { totals, result in
                        totals[result.playerId, default: 0] += result.score
                    }
                    .compactMap { playerId, score -> HistoricalPlayerGameScore? in
                        guard let player = playersById[playerId] else { return nil }
                        return HistoricalPlayerGameScore(player: player, score: score)
                    }
                let details = games.compactMap { allGameDetails[$0.id] }
                let playerResultCount = data.playerResults.filter { gameIds.contains($0.gameId) }.count
                let totalScore = playerScores.map(\.score).reduce(0, +)

                return HistoricalGameTypeOverview(
                    gameType: type,
                    games: games.count,
                    playerResultCount: playerResultCount,
                    averageScore: playerResultCount > 0 ? Double(totalScore) / Double(playerResultCount) : 0,
                    gamesWithBidder: games.filter { $0.bidderId != nil || !$0.bidderIds.isEmpty }.count,
                    playerTotals: playerScores,
                    bestGame: details.max { lhs, rhs in
                        (lhs.playerScores.map(\.score).max() ?? 0) < (rhs.playerScores.map(\.score).max() ?? 0)
                    },
                    worstGame: details.min { lhs, rhs in
                        (lhs.playerScores.map(\.score).min() ?? 0) < (rhs.playerScores.map(\.score).min() ?? 0)
                    }
                )
            }
            .sorted { lhs, rhs in
                if lhs.games != rhs.games {
                    return lhs.games > rhs.games
                }
                return lhs.title < rhs.title
            }
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

    private func scoreForeground(_ value: Int) -> Color {
        switch value {
        case let x where x > 0:
            return Color(red: 0.05, green: 0.45, blue: 0.18)
        case let x where x < 0:
            return Color(red: 0.55, green: 0.08, blue: 0.1)
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

private struct PlannedStatistic: Identifiable {
    var id: String { title }
    var title: String
    var description: String
}

private struct HistoricalGameTypeOverview: Identifiable {
    var id: String { gameType }
    var gameType: String
    var games: Int
    var playerResultCount: Int
    var averageScore: Double
    var gamesWithBidder: Int
    var playerTotals: [HistoricalPlayerGameScore]
    var bestGame: HistoricalGameScoreDetail?
    var worstGame: HistoricalGameScoreDetail?

    var title: String {
        gameType.capitalized
    }

    var bestPlayer: HistoricalPlayerGameScore? {
        playerTotals.max { lhs, rhs in lhs.score < rhs.score }
    }
}
