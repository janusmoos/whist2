import SwiftData
import SwiftUI

/// Oversigt over den senest afsluttede kamp og øvrige kampe samme spilledag — åbnes fra forsiden og bundmenuen.
/// Bruger tabelvisningen (`SenesteSpilDiscreteTable`): accordion med nyeste kamp udfoldet.
struct SenesteSpilView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GameDay.createdAt, order: .reverse) private var gameDays: [GameDay]

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
                if let pair = latestPair {
                    let ordered = handsNewestFirst(for: pair.gameDay)
                    let heroHand = ordered.first ?? pair.hand
                    let otherHands = Array(ordered.dropFirst())

                    SenesteSpilLatestHeroCard(hand: heroHand, gameDay: pair.gameDay)
                        .padding(.horizontal, 16)

                    if !otherHands.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Øvrige kampe samme dag")
                                .font(.headline)
                                .padding(.horizontal, 4)
                            SenesteSpilDiscreteTable(
                                gameDay: pair.gameDay,
                                hands: otherHands
                            )
                        }
                        .padding(.horizontal, 16)
                    }

                    Text("Viser kampe fra den spilledag, den seneste kamp tilhører.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
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
}
