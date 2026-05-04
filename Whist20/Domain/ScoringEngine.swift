import Foundation

// MARK: - Input

struct NormalHandScoreInput: Hashable, Sendable {
    var gameType: NormalGameType
    /// Melding 8 ... 13
    var bidTricks: Int
    /// Stik til kontraktholder-holdet (0 ... 13)
    var actualTricks: Int
    var bidder: Seat
    /// Ved selvmakker er `partner == bidder`.
    var partner: Seat
    /// Trumf; bruges til VIP i tredje + klør (×2), som i legacy.
    var trumpSuit: Suit?
}

struct SolHandScoreInput: Hashable, Sendable {
    var solType: SolType
    var bidder: Seat
    /// Medspillere der "går med" (uden melder).
    var goingWith: Set<Seat>
    var tricksBySeat: [Seat: Int]
}

// MARK: - Engine

/// Ren pointberegning – samme formler som `PointCalculationService` i Whist 0.6 (inkl. stor slem ×2 for alle typer, sol-loop, duestraf).
enum ScoringEngine: Sendable {

    private static let basePointsByBid: [Int: Int] = [
        8: 1, 9: 2, 10: 4, 11: 8, 12: 16, 13: 32,
    ]

    private static let storslemMultiplier = 2
    private static let klørVip3Multiplier = 2

    // MARK: Duestraf (shortcut i legacy `GameInputViewModel`)

    static func dutyScores(dutyHolder: Seat) -> [Seat: Int] {
        var scores = zeroScores()
        for seat in Seat.all {
            scores[seat] = seat == dutyHolder ? -72 : 24
        }
        return scores
    }

    // MARK: Normalt spil

    static func scoreNormalHand(_ input: NormalHandScoreInput) -> [Seat: Int]? {
        guard (8 ... 13).contains(input.bidTricks),
              (0 ... 13).contains(input.actualTricks) else { return nil }

        let perContractSidePlayer = calculateBasePoints(
            bidTricks: input.bidTricks,
            actualTricks: input.actualTricks,
            gameType: input.gameType,
            suit: input.trumpSuit
        )

        if input.partner == input.bidder {
            return selfPartnerScores(basePoints: perContractSidePlayer, bidder: input.bidder)
        }

        return standardPartnershipScores(
            basePoints: perContractSidePlayer,
            bidder: input.bidder,
            partner: input.partner
        )
    }

    // MARK: Sol (samme loop som legacy `calculateSolGamePoints`)

    static func scoreSolHand(_ input: SolHandScoreInput) -> [Seat: Int]? {
        var scores = zeroScores()
        let all = Set(Seat.all)
        let going = input.goingWith.union([input.bidder])
        let modstandere = all.subtracting(going)

        let ppo = input.solType.pointsPerOpponent

        if let t = input.tricksBySeat[input.bidder], t <= input.solType.maxAllowedTricks {
            scores[input.bidder] = ppo * modstandere.count
        } else {
            scores[input.bidder] = -ppo * modstandere.count
        }

        for player in input.goingWith {
            if let tricks = input.tricksBySeat[player], tricks <= input.solType.maxAllowedTricks {
                scores[player] = ppo * modstandere.count
            } else {
                scores[player] = -ppo * modstandere.count
            }
        }

        for modstander in modstandere {
            var modstanderPoint = 0
            modstanderPoint += (scores[input.bidder] ?? 0) > 0 ? -ppo : ppo
            for medspiller in input.goingWith {
                modstanderPoint += (scores[medspiller] ?? 0) > 0 ? -ppo : ppo
            }
            scores[modstander] = modstanderPoint
        }

        return scores
    }

    // MARK: - Private (legacy-paritet)

    private static func zeroScores() -> [Seat: Int] {
        Dictionary(uniqueKeysWithValues: Seat.all.map { ($0, 0) })
    }

    /// Én værdi pr. spiller på kontraktholder-holdet (før fordeling til modstandere).
    private static func calculateBasePoints(
        bidTricks: Int,
        actualTricks: Int,
        gameType: NormalGameType,
        suit: Suit?
    ) -> Int {
        let basePoints = basePointsByBid[bidTricks] ?? 0
        let multiplier = gameType.baseMultiplier
        let difference = actualTricks - bidTricks
        var totalPoints = 0

        if difference >= 0 {
            totalPoints = basePoints * (difference + 1) + basePoints
            totalPoints *= multiplier
            if actualTricks == 13 {
                totalPoints *= storslemMultiplier
            }
            if case .vip(.triple) = gameType, suit == .clubs {
                totalPoints *= klørVip3Multiplier
            }
        } else {
            totalPoints = basePoints * abs(difference) * multiplier
            if actualTricks == 0 {
                totalPoints *= storslemMultiplier
            }
            totalPoints = -totalPoints
        }

        return totalPoints
    }

    private static func selfPartnerScores(basePoints: Int, bidder: Seat) -> [Seat: Int] {
        var scores = zeroScores()
        let originalTotal = basePoints * 2
        let adjustedTotal: Int = {
            if originalTotal >= 0 {
                Int(ceil(Double(originalTotal) / 3.0)) * 3
            } else {
                Int(floor(Double(originalTotal) / 3.0)) * 3
            }
        }()
        scores[bidder] = adjustedTotal
        let opponentPoints = -adjustedTotal / 3
        for seat in Seat.all where seat != bidder {
            scores[seat] = opponentPoints
        }
        return scores
    }

    private static func standardPartnershipScores(
        basePoints: Int,
        bidder: Seat,
        partner: Seat
    ) -> [Seat: Int] {
        var scores = zeroScores()
        scores[bidder] = basePoints
        scores[partner] = basePoints
        let opponents = Seat.all.filter { $0 != bidder && $0 != partner }
        guard opponents.count == 2 else { return scores }
        for o in opponents {
            scores[o] = -basePoints
        }
        return scores
    }
}
