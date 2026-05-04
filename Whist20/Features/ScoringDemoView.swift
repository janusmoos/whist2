import SwiftUI

/// Viser faste scenarier med `ScoringEngine`, så du kan se logikken i appen uden unit tests.
struct ScoringDemoView: View {

    private struct DemoRow: Identifiable {
        let id: UUID
        let title: String
        let subtitle: String
        let scores: [Seat: Int]

        init(title: String, subtitle: String, scores: [Seat: Int]) {
            self.id = UUID()
            self.title = title
            self.subtitle = subtitle
            self.scores = scores
        }
    }

    private let demoRows: [DemoRow] = {
        var list: [DemoRow] = []

        if let s = ScoringEngine.scoreNormalHand(NormalHandScoreInput(
            gameType: .almindelig,
            bidTricks: 8,
            actualTricks: 8,
            bidder: .north,
            partner: .east,
            trumpSuit: nil
        )) {
            list.append(DemoRow(
                title: "Almindelige, 8 præcis",
                subtitle: "Christian melder, Peter makker",
                scores: s
            ))
        }

        if let s = ScoringEngine.scoreNormalHand(NormalHandScoreInput(
            gameType: .sans,
            bidTricks: 9,
            actualTricks: 10,
            bidder: .north,
            partner: .east,
            trumpSuit: nil
        )) {
            list.append(DemoRow(
                title: "Sans, 9 meldt, 10 taget",
                subtitle: "Som i dokumentationen (12 pr. kontraktspiller)",
                scores: s
            ))
        }

        if let s = ScoringEngine.scoreNormalHand(NormalHandScoreInput(
            gameType: .almindelig,
            bidTricks: 8,
            actualTricks: 8,
            bidder: .north,
            partner: .north,
            trumpSuit: nil
        )) {
            list.append(DemoRow(
                title: "Selvmakker, 8 præcis",
                subtitle: "Christian alene på holdet (selvmakker)",
                scores: s
            ))
        }

        list.append(DemoRow(
            title: "Duestraf",
            subtitle: "Thomas har duty",
            scores: ScoringEngine.dutyScores(dutyHolder: .south)
        ))

        if let s = ScoringEngine.scoreSolHand(SolHandScoreInput(
            solType: .normal,
            bidder: .north,
            goingWith: [],
            tricksBySeat: [.north: 0, .east: 5, .south: 4, .west: 4]
        )) {
            list.append(DemoRow(
                title: "Sol (normal), Christian vinder alene",
                subtitle: "0 stik til Christian",
                scores: s
            ))
        }

        return list
    }()

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                Text("Tallene kommer direkte fra domænelaget – samme regler som Whist 0.6.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                ForEach(demoRows) { row in
                    demoCard(row)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Point-demo")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func demoCard(_ row: DemoRow) -> some View {
        let sum = row.scores.values.reduce(0, +)
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(row.title)
                    .font(.headline)
                Text(row.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(Seat.all, id: \.self) { seat in
                HStack {
                    Text(seat.playerDisplayName)
                    Spacer()
                    Text("\(row.scores[seat] ?? 0)")
                        .monospacedDigit()
                        .fontWeight(.medium)
                }
            }

            Divider()

            HStack {
                Text("Sum")
                    .fontWeight(.semibold)
                Spacer()
                Text("\(sum)")
                    .monospacedDigit()
                    .foregroundStyle(sum == 0 ? Color.secondary : Color.red)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

#Preview {
    NavigationStack {
        ScoringDemoView()
    }
}
