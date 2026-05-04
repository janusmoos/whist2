import Foundation

/// Én gemt kamps bidrag til standings (afkoblet fra persistence — til test og genbrug).
struct HandScoreContribution: Equatable, Sendable {
    var handNumber: Int
    var playedAt: Date
    var scoresBySeat: [Seat: Int]
}

/// Akkumuleret standing for en spilledag.
struct GameDayStanding: Equatable, Sendable {
    /// Sum over alle kampe (lig med sidste steps `cumulative`, eller nul hvis ingen kampe).
    var totalsBySeat: [Seat: Int]
    /// Én post pr. kamp i kronologisk rækkefølge — kumulativ score efter den kamp.
    var steps: [StandingStep]
}

struct StandingStep: Equatable, Sendable, Identifiable {
    var id: Int { index }
    /// Løbenummer i `steps` (0 …).
    var index: Int
    /// Kampnummer til visning (#); falder tilbage til indeks+1 hvis `handNumber` mangler.
    var afterHandNumber: Int
    var cumulative: [Seat: Int]
}

enum GameDayScoreAggregation: Sendable {

    /// Sorterer kampe: primært `handNumber` (når begge ≥ 1), ellers `playedAt` stigende.
    static func orderedContributions(_ contributions: [HandScoreContribution]) -> [HandScoreContribution] {
        contributions.sorted { lhs, rhs in
            let ln = lhs.handNumber
            let rn = rhs.handNumber
            if ln >= 1, rn >= 1, ln != rn {
                return ln < rn
            }
            return lhs.playedAt < rhs.playedAt
        }
    }

    static func standing(from contributions: [HandScoreContribution]) -> GameDayStanding {
        let ordered = orderedContributions(contributions)
        guard !ordered.isEmpty else {
            return GameDayStanding(totalsBySeat: zeroScores(), steps: [])
        }

        var running = zeroScores()
        var steps: [StandingStep] = []

        for (idx, c) in ordered.enumerated() {
            running = merge(running, c.scoresBySeat)
            let displayNum = c.handNumber >= 1 ? c.handNumber : idx + 1
            steps.append(
                StandingStep(
                    index: idx,
                    afterHandNumber: displayNum,
                    cumulative: running
                )
            )
        }

        return GameDayStanding(totalsBySeat: running, steps: steps)
    }

    private static func zeroScores() -> [Seat: Int] {
        Dictionary(uniqueKeysWithValues: Seat.all.map { ($0, 0) })
    }

    private static func merge(_ a: [Seat: Int], _ b: [Seat: Int]) -> [Seat: Int] {
        var out: [Seat: Int] = [:]
        for s in Seat.all {
            out[s] = (a[s] ?? 0) + (b[s] ?? 0)
        }
        return out
    }
}
