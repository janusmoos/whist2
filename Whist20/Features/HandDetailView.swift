import SwiftData
import SwiftUI

struct HandDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    let hand: RecordedHand
    /// Bruges til migration af `handNumber` på ældre gemte kampe.
    var gameDay: GameDay? = nil

    private var scores: [Seat: Int] {
        HandScorePersistence.decodeScores(hand.scoresBySeatJSON)
    }

    private var navigationTitleText: String {
        hand.handNumber > 0 ? "Kamp #\(hand.handNumber)" : "Kamp"
    }

    var body: some View {
        List {
            Section {
                SuitColoredInlineText.build(hand.displayResumeNarrative, colorScheme: colorScheme)
                    .font(.body)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                Text(hand.playedAt.formatted(date: .abbreviated, time: .shortened))
                    .foregroundStyle(.secondary)
            }

            Section("Point") {
                ForEach(Seat.all, id: \.self) { seat in
                    HStack {
                        Text(seat.playerDisplayName)
                        Spacer()
                        Text("\(scores[seat] ?? 0)")
                            .monospacedDigit()
                            .fontWeight(.medium)
                    }
                }
                let sum = scores.values.reduce(0, +)
                HStack {
                    Text("Sum")
                        .fontWeight(.semibold)
                    Spacer()
                    Text("\(sum)")
                        .monospacedDigit()
                        .foregroundStyle(sum == 0 ? Color.secondary : Color.red)
                }
            }
        }
        .navigationTitle(navigationTitleText)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            gameDay?.migrateLegacyHandNumbersIfNeeded()
            try? modelContext.save()
        }
    }
}
