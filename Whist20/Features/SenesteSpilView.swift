import Charts
import SwiftData
import SwiftUI

/// Oversigt over den senest afsluttede kamp og øvrige kampe samme spilledag — åbnes fra forsiden og bundmenuen.
/// Bruger tabelvisningen (`SenesteSpilDiscreteTable`): accordion med nyeste kamp udfoldet.
struct SenesteSpilView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GameDay.createdAt, order: .reverse) private var gameDays: [GameDay]

    var onOpenActiveGame: (() -> Void)?

    private var activeGameDay: GameDay? {
        GameDay.activeDay(in: gameDays)
    }

    private var hasActivePendingHand: Bool {
        activeGameDay?.pendingHand != nil
    }

    private var latestPair: (gameDay: GameDay, hand: RecordedHand)? {
        var best: (GameDay, RecordedHand)?
        for day in gameDays {
            for hand in day.hands {
                guard let cur = best else {
                    best = (day, hand)
                    continue
                }
                if hand.playedAt > cur.1.playedAt {
                    best = (day, hand)
                }
            }
        }
        return best
    }

    private func handsNewestFirst(for gameDay: GameDay) -> [RecordedHand] {
        gameDay.hands.sorted { a, b in
            if a.handNumber > 0, b.handNumber > 0, a.handNumber != b.handNumber {
                return a.handNumber > b.handNumber
            }
            return a.playedAt > b.playedAt
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if hasActivePendingHand {
                    activeGameLinkBox
                        .padding(.horizontal, 16)
                }

                if let pair = latestPair {
                    let ordered = handsNewestFirst(for: pair.gameDay)
                    let heroHand = ordered.first ?? pair.hand
                    let otherHands = Array(ordered.dropFirst())

                    SenesteSpilLatestHeroCard(hand: heroHand, gameDay: pair.gameDay)
                        .padding(.horizontal, 16)

                    if !otherHands.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Alle dagens spil")
                                .font(.title2.weight(.bold))
                                .padding(.horizontal, 4)
                            SenesteSpilDiscreteTable(
                                gameDay: pair.gameDay,
                                hands: otherHands
                            )
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 18)
                    }

                    SenesteSpilDaySummarySection(
                        standing: pair.gameDay.scoreStanding,
                        seats: pair.gameDay.seatOrder
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                } else {
                    ContentUnavailableView(
                        "Ingen gemte kampe",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Når I har gemt en kamp, vises den her med resumé og point.")
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 48)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Seneste spil")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            if let day = latestPair?.gameDay {
                day.migrateLegacyHandNumbersIfNeeded()
                try? modelContext.save()
            }
        }
    }

    private var activeGameLinkBox: some View {
        Button {
            onOpenActiveGame?()
        } label: {
            HStack(spacing: 12) {
                ActiveGamePlayCardIcon(color: ActiveGamePosterStyle.textOnWarmAccentColor, lineWidth: 1.8)

                VStack(alignment: .leading, spacing: 0) {
                    Text("Se meldingen i det aktive spil")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(ActiveGamePosterStyle.textOnWarmAccentColor)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ActiveGamePosterStyle.textOnWarmAccentColor.opacity(0.82))
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(ActiveGamePosterStyle.activeOrangeColor)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(ActiveGamePosterStyle.activeOrangeColor.opacity(0.88), lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Se meldingen i det aktive spil")
        .accessibilityHint("Åbner fanen Aktivt spil")
    }
}

struct SenesteSpilDaySummarySection: View {
    var standing: GameDayStanding
    var seats: [Seat]
    var title: String = "Status"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            progressSection
            standingsSection
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var standingsSection: some View {
        HStack(spacing: 8) {
            ForEach(seats, id: \.self) { seat in
                let score = standing.totalsBySeat[seat] ?? 0
                VStack(spacing: 2) {
                    Text(seat.playerDisplayName.uppercased())
                        .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 11))
                        .fontWidth(.compressed)
                        .fontWeight(.semibold)
                        .foregroundStyle(ActiveGamePosterStyle.darkInkColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)

                    Text(scoreText(score))
                        .font(.custom(ActiveGamePosterStyle.fontName, size: 36))
                        .fontWidth(.compressed)
                        .monospacedDigit()
                        .foregroundStyle(scoreColor(score))
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)
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
                        .strokeBorder(playerPalette(for: seat).line, lineWidth: 2)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(seat.playerDisplayName), \(scoreText(score)) point")
            }
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2.weight(.bold))
                .padding(.horizontal, 4)

            VStack(alignment: .leading, spacing: 10) {
                if chartPoints.isEmpty {
                    Text("Ingen udvikling at vise endnu.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 20)
                } else {
                    HStack(spacing: chartLabelGap) {
                        Chart {
                            RuleMark(y: .value("Nul", 0))
                                .foregroundStyle(Color.secondary.opacity(0.22))
                                .lineStyle(StrokeStyle(lineWidth: 1, lineCap: .round))

                            ForEach(chartPoints) { point in
                                LineMark(
                                    x: .value("Spil", Double(point.handNumber)),
                                    y: .value("Point", Double(point.score)),
                                    series: .value("Spiller", point.seat.playerDisplayName)
                                )
                                .foregroundStyle(playerPalette(for: point.seat).line.opacity(0.78))
                                .lineStyle(StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                                .interpolationMethod(.catmullRom)
                            }
                        }
                        .chartXScale(domain: chartXDomain)
                        .chartYScale(domain: chartYDomain)
                        .chartXAxis(.hidden)
                        .chartYAxis(.hidden)
                        .chartLegend(.hidden)
                        .chartPlotStyle { plot in
                            plot
                                .padding(.horizontal, 2)
                                .padding(.vertical, 8)
                        }

                        chartLabelColumn
                    }
                    .frame(height: 136)
                    .accessibilityLabel("Udvikling i dagens pointstilling")
                }
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
        }
    }

    private var chartPoints: [RecentDayChartPoint] {
        standing.steps.flatMap { step in
            seats.map { seat in
                RecentDayChartPoint(
                    stepIndex: step.index,
                    handNumber: step.afterHandNumber,
                    seat: seat,
                    score: step.cumulative[seat] ?? 0
                )
            }
        }
    }

    private var lastChartPoints: [RecentDayChartPoint] {
        guard let lastStep = standing.steps.last else { return [] }
        return seats.map { seat in
            RecentDayChartPoint(
                stepIndex: lastStep.index,
                handNumber: lastStep.afterHandNumber,
                seat: seat,
                score: lastStep.cumulative[seat] ?? 0
            )
        }
    }

    private var chartLabelPlacements: [RecentDayChartLabelPlacement] {
        let groups = Dictionary(grouping: lastChartPoints, by: \.score)
        let rawPlacements = groups
            .map { score, points in
                let groupSeats = seats.compactMap { seat in
                    points.contains { $0.seat == seat } ? seat : nil
                }
                return RecentDayChartLabelPlacement(
                    seats: groupSeats,
                    actualScore: score,
                    displayScore: Double(score)
                )
            }
            .sorted { $0.actualScore < $1.actualScore }

        var adjusted: [RecentDayChartLabelPlacement] = []
        var previousDisplayScore: Double?
        for placement in rawPlacements {
            var output = placement
            if let previousDisplayScore {
                output.displayScore = max(output.displayScore, previousDisplayScore + chartLabelMinimumGap)
            }
            adjusted.append(output)
            previousDisplayScore = output.displayScore
        }
        return adjusted
    }

    private var chartLabelColumn: some View {
        GeometryReader { geometry in
            let rows = chartLabelRows(height: geometry.size.height)
            ZStack(alignment: .topLeading) {
                ForEach(rows) { row in
                    HStack(spacing: 4) {
                        ForEach(row.placement.seats, id: \.self) { seat in
                            Text(labelName(for: seat, abbreviated: row.placement.seats.count > 1))
                                .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 12))
                                .fontWidth(.compressed)
                                .fontWeight(.semibold)
                                .foregroundStyle(playerPalette(for: seat).line)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                    }
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background {
                        Capsule(style: .continuous)
                            .fill(ActiveGamePosterStyle.panelColor.opacity(0.92))
                    }
                    .frame(width: chartLabelColumnWidth, height: chartLabelHeight, alignment: .leading)
                    .offset(y: row.y)
                    .accessibilityHidden(true)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(width: chartLabelColumnWidth)
    }

    private var chartXDomain: ClosedRange<Double> {
        let handNumbers = standing.steps.map { Double($0.afterHandNumber) }
        let lower = handNumbers.min() ?? 0
        let upper = handNumbers.max() ?? lower
        return lower...upper
    }

    private var chartYDomain: ClosedRange<Double> {
        let lineScores = chartPoints.map { Double($0.score) }
        let labelScores = chartLabelPlacements.map(\.displayScore)
        let values = lineScores + labelScores + [0]
        let lower = values.min() ?? 0
        let upper = values.max() ?? lower
        let span = max(1, upper - lower)
        let padding = max(16, span * 0.14)
        return (lower - padding)...(upper + padding)
    }

    private var chartLabelMinimumGap: Double {
        let scores = chartPoints.map(\.score)
        let lower = scores.min() ?? 0
        let upper = scores.max() ?? lower
        let span = max(1, upper - lower)
        return max(10, Double(span) * 0.065)
    }

    private var chartLabelColumnWidth: CGFloat {
        82
    }

    private var chartLabelGap: CGFloat {
        12
    }

    private var chartLabelHeight: CGFloat {
        24
    }

    private func scoreText(_ value: Int) -> String {
        value > 0 ? "+\(value)" : "\(value)"
    }

    private func scoreColor(_ value: Int) -> Color {
        if value > 0 { return ActiveGamePosterStyle.positiveScoreColor }
        if value < 0 { return ActiveGamePosterStyle.negativeScoreColor }
        return .secondary
    }

    private func labelName(for seat: Seat, abbreviated: Bool) -> String {
        abbreviated ? String(seat.playerDisplayName.prefix(1)) : seat.playerDisplayName
    }

    private func chartLabelYPosition(for score: Double, height: CGFloat) -> CGFloat {
        let domain = chartYDomain
        let span = max(1, domain.upperBound - domain.lowerBound)
        let fraction = (domain.upperBound - score) / span
        let rawY = CGFloat(fraction) * height - chartLabelHeight / 2
        return min(
            max(rawY, 0),
            max(0, height - chartLabelHeight)
        )
    }

    private func chartLabelRows(height: CGFloat) -> [RecentDayChartLabelRow] {
        let gap: CGFloat = 4
        var rows = chartLabelPlacements
            .map {
                RecentDayChartLabelRow(
                    placement: $0,
                    y: chartLabelYPosition(for: Double($0.actualScore), height: height)
                )
            }
            .sorted { $0.y < $1.y }

        guard !rows.isEmpty else { return [] }

        for index in rows.indices.dropFirst() {
            let minimumY = rows[rows.index(before: index)].y + chartLabelHeight + gap
            rows[index].y = max(rows[index].y, minimumY)
        }

        if let last = rows.last {
            let overflow = last.y + chartLabelHeight - height
            if overflow > 0 {
                for index in rows.indices {
                    rows[index].y -= overflow
                }
            }
        }

        if rows.count > 1 {
            for index in rows.indices.dropLast().reversed() {
                let nextIndex = rows.index(after: index)
                let maximumY = rows[nextIndex].y - chartLabelHeight - gap
                rows[index].y = min(rows[index].y, maximumY)
            }
        }

        if let first = rows.first, first.y < 0 {
            let underflow = -first.y
            for index in rows.indices {
                rows[index].y += underflow
            }
        }

        return rows.map { row in
            var output = row
            output.y = min(max(output.y, 0), max(0, height - chartLabelHeight))
            return output
        }
    }

    private func playerPalette(for seat: Seat) -> RecentPlayerPalette {
        switch seat {
        case .south:
            return RecentPlayerPalette(line: Color(hex: 0x6F8FBF), background: Color(hex: 0xE8EEF7))
        case .east:
            return RecentPlayerPalette(line: Color(hex: 0x6FA987), background: Color(hex: 0xE7F1EB))
        case .west:
            return RecentPlayerPalette(line: Color(hex: 0xC9944A), background: Color(hex: 0xF5EBDD))
        case .north:
            return RecentPlayerPalette(line: Color(hex: 0x9B75B8), background: Color(hex: 0xEFE8F4))
        }
    }
}

private struct RecentDayChartPoint: Identifiable {
    var id: String { "\(seat.rawValue)-\(stepIndex)" }
    var stepIndex: Int
    var handNumber: Int
    var seat: Seat
    var score: Int
}

private struct RecentDayChartLabelPlacement: Identifiable {
    var id: String { seats.map(\.rawValue).map(String.init).joined(separator: "-") }
    var seats: [Seat]
    var actualScore: Int
    var displayScore: Double
}

private struct RecentDayChartLabelRow: Identifiable {
    var id: String { placement.id }
    var placement: RecentDayChartLabelPlacement
    var y: CGFloat
}

private struct RecentPlayerPalette {
    var line: Color
    var background: Color
}

private extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0
        )
    }
}
