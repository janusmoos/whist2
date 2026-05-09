import Foundation

/// Rangering og rækkefølge til stillingsskærme (højeste score først, delt plads tilladt).
enum StandingsPresentation: Sendable {

    struct Row: Identifiable, Equatable, Sendable {
        var id: Seat { seat }
        let seat: Seat
        let rank: Int
        let score: Int
    }

    /// Sorterer efter faldende score og tildeler konkurrencerang (`1,1,3,3` ved uafgjort).
    /// Ved samme score: alfabetisk på **navn** (ingen fast bordplads i rækkefølgen).
    static func rankedRows(scores: [Seat: Int]) -> [Row] {
        let seatsDesc = Seat.all.sorted { s1, s2 in
            let v1 = scores[s1] ?? 0
            let v2 = scores[s2] ?? 0
            if v1 != v2 { return v1 > v2 }
            return s1.playerDisplayName.localizedCaseInsensitiveCompare(s2.playerDisplayName) == .orderedAscending
        }
        var rows: [Row] = []
        var rank = 1
        for (i, seat) in seatsDesc.enumerated() {
            let sc = scores[seat] ?? 0
            if i > 0 {
                let prev = scores[seatsDesc[i - 1]] ?? 0
                if sc != prev {
                    rank = i + 1
                }
            }
            rows.append(Row(seat: seat, rank: rank, score: sc))
        }
        return rows
    }
}
