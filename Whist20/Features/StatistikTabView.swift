import Charts
import SwiftUI

struct StatistikTabView: View {
    @State private var selectedScope: HistoricalStatisticsScope = .all

    private let dataResult: Result<HistoricalWhistData, Error>

    init(loader: HistoricalDataJSONLoader = HistoricalDataJSONLoader()) {
        dataResult = Result { try loader.load() }
    }

    var body: some View {
        NavigationStack {
            Group {
                switch dataResult {
                case let .success(data):
                    let snapshot = HistoricalStatisticsEngine.snapshot(from: data, scope: selectedScope)
                    statisticsContent(snapshot)
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

    private func statisticsContent(_ snapshot: HistoricalStatisticsSnapshot) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                scopePicker
                summaryHeader(snapshot)
                playerLeaderboard(snapshot.playerSummaries)
                scoreTimeline(snapshot.timelinePoints)
                dataQuality(snapshot)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .padding(.bottom, 12)
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private var scopePicker: some View {
        Picker("Periode", selection: $selectedScope) {
            ForEach(HistoricalStatisticsScope.allCases) { scope in
                Text(scope.title).tag(scope)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Vælg statistikperiode")
    }

    private func summaryHeader(_ snapshot: HistoricalStatisticsSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Historisk data")
                    .font(.title2.weight(.bold))
                Text("\(snapshot.scope.title) · \(snapshot.sessionCount) spilledage · \(snapshot.gameCount) spil · \(snapshot.playerResultCount) spillerresultater")
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

    private func playerLeaderboard(_ summaries: [HistoricalPlayerScoreSummary]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Samlet stilling")
                .font(.headline)

            VStack(spacing: 10) {
                ForEach(Array(summaries.enumerated()), id: \.element.id) { index, summary in
                    playerRow(summary, rank: index + 1)
                }
            }
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
}
