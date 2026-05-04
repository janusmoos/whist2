import SwiftData
import SwiftUI

/// Oversigt over den senest afsluttede kamp og øvrige kampe samme spilledag — åbnes fra forsiden.
struct SenesteSpilView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GameDay.createdAt, order: .reverse) private var gameDays: [GameDay]

    @State private var expandedOtherHandID: UUID?

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

    private func otherHandsChronological(gameDay: GameDay, latest: RecordedHand) -> [RecordedHand] {
        gameDay.hands
            .filter { $0.id != latest.id }
            .sorted { a, b in
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
                    NavigationLink {
                        HandDetailView(hand: pair.hand, gameDay: pair.gameDay)
                    } label: {
                        FeaturedLatestHandCard(hand: pair.hand)
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                    .listRowBackground(Color.clear)

                    ForEach(otherHandsChronological(gameDay: pair.gameDay, latest: pair.hand), id: \.id) { other in
                        CompactHandDayRow(
                            hand: other,
                            isExpanded: expandedOtherHandID == other.id,
                            onToggle: {
                                withAnimation(.easeInOut(duration: 0.22)) {
                                    if expandedOtherHandID == other.id {
                                        expandedOtherHandID = nil
                                    } else {
                                        expandedOtherHandID = other.id
                                    }
                                }
                            }
                        )
                        .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                        .listRowBackground(Color.clear)
                    }
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
