import Charts
import SwiftData
import SwiftUI

/// Samlet pointfordeling og udvikling over spilledagen.
struct PointStandingView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var gameDay: GameDay

    private var standing: GameDayStanding {
        let contribs = gameDay.hands.map(\.scoreContribution)
        return GameDayScoreAggregation.standing(from: contribs)
    }

    private var orderedSeats: [Seat] {
        gameDay.seatOrder
    }

    /// Nyeste kamp øverst (samme som «Seneste spil» / spilledagsliste).
    private var forløbStepsNewestFirst: [StandingStep] {
        Array(standing.steps.reversed())
    }

    var body: some View {
        List {
            Section {
                if gameDay.hands.isEmpty {
                    Text("Ingen gemte kampe endnu. Når I gemmer spil, vises summer og grafen her.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    totalsGrid
                }
            } header: {
                Text("Samlet")
            }

            if standing.steps.count >= 2 {
                Section {
                    standingChart
                        .frame(height: 220)
                        .padding(.vertical, 4)
                } header: {
                    Text("Udvikling")
                } footer: {
                    Text("Kumulativ score efter hver kamp. Grafen kræver mindst to kampe.")
                        .font(.footnote)
                }
            }

            if !standing.steps.isEmpty {
                Section {
                    ForEach(forløbStepsNewestFirst) { step in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Efter kamp #\(step.afterHandNumber)")
                                .font(.subheadline.weight(.semibold))
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                                ForEach(orderedSeats, id: \.self) { seat in
                                    let value = step.cumulative[seat] ?? 0
                                    Text("\(seat.playerDisplayName) \(scoreText(value))")
                                        .font(.caption2.weight(.semibold))
                                        .multilineTextAlignment(.center)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 4)
                                        .background {
                                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                .fill(chipBackground(for: value))
                                        }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Forløb")
                }
            }
        }
        .navigationTitle("Pointfordeling")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            gameDay.migrateLegacyHandNumbersIfNeeded()
            try? modelContext.save()
        }
    }

    private var totalsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            ForEach(orderedSeats, id: \.self) { seat in
                let value = standing.totalsBySeat[seat] ?? 0
                Text("\(seat.playerDisplayName)\n\(scoreText(value))")
                    .font(.body.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.75)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 6)
                    .background {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(chipBackground(for: value))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(seat.playerDisplayName), \(scoreText(value)) point i alt")
            }
        }
    }

    private var standingChart: some View {
        Chart {
            ForEach(orderedSeats, id: \.self) { seat in
                ForEach(standing.steps) { step in
                    LineMark(
                        x: .value("Kamp", step.afterHandNumber),
                        y: .value("Point", step.cumulative[seat] ?? 0)
                    )
                    .foregroundStyle(by: .value("Spiller", seat.playerDisplayName))
                    .interpolationMethod(.linear)
                }
            }
        }
        .chartLegend(position: .bottom, spacing: 8)
        .chartXAxisLabel("Kamp #")
        .chartYAxisLabel("Point")
        .accessibilityLabel("Linjediagram for kumulativ score pr. spiller")
    }

    private func scoreText(_ value: Int) -> String {
        if value > 0 { return "+\(value)" }
        return "\(value)"
    }

    private func chipBackground(for value: Int) -> Color {
        switch value {
        case let x where x > 0:
            return Color.green.opacity(0.32)
        case let x where x < 0:
            return Color.red.opacity(0.32)
        default:
            return Color.secondary.opacity(0.12)
        }
    }
}
