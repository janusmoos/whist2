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
        List {
            if let pair = latestPair {
                Section {
                    SenesteSpilDiscreteTable(
                        gameDay: pair.gameDay,
                        hands: handsNewestFirst(for: pair.gameDay)
                    )
                    .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 10, trailing: 12))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } header: {
                    Text(pair.gameDay.title)
                } footer: {
                    Text("Viser kampe fra den spilledag, den seneste kamp tilhører.")
                        .font(.footnote)
                }
            } else {
                Section {
                    ContentUnavailableView(
                        "Ingen gemte kampe",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Når I har gemt en kamp, vises den her med resumé og point.")
                    )
                }
            }
        }
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
