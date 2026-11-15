import XCTest
@testable import Whist20

final class ScoringEngineTests: XCTestCase {

    private func sum(_ m: [Seat: Int]) -> Int {
        m.values.reduce(0, +)
    }

    func testAlmindeligPræcis8_giverPlus2PerKontraktspiller() {
        let s = ScoringEngine.scoreNormalHand(NormalHandScoreInput(
            gameType: .almindelig,
            bidTricks: 8,
            actualTricks: 8,
            bidder: .north,
            partner: .east,
            trumpSuit: nil
        ))!
        XCTAssertEqual(s[.north], 2)
        XCTAssertEqual(s[.east], 2)
        XCTAssertEqual(s[.south], -2)
        XCTAssertEqual(s[.west], -2)
        XCTAssertEqual(sum(s), 0)
    }

    func testSans9Taget10_dokumenteksempel12Point() {
        let s = ScoringEngine.scoreNormalHand(NormalHandScoreInput(
            gameType: .sans,
            bidTricks: 9,
            actualTricks: 10,
            bidder: .north,
            partner: .east,
            trumpSuit: nil
        ))!
        XCTAssertEqual(s[.north], 12)
        XCTAssertEqual(s[.east], 12)
        XCTAssertEqual(s[.south], -12)
        XCTAssertEqual(s[.west], -12)
        XCTAssertEqual(sum(s), 0)
    }

    func testSelvmakkerAlmindelig8Præcis_giver6OgTreGangeMinus2() {
        // P = B*(diff+2)*M = 1*2*1 = +2 → (3P, −P, −P, −P)
        let s = ScoringEngine.scoreNormalHand(NormalHandScoreInput(
            gameType: .almindelig,
            bidTricks: 8,
            actualTricks: 8,
            bidder: .north,
            partner: .north,
            trumpSuit: nil
        ))!
        XCTAssertEqual(s[.north], 6)
        XCTAssertEqual(s[.east], -2)
        XCTAssertEqual(s[.south], -2)
        XCTAssertEqual(s[.west], -2)
        XCTAssertEqual(sum(s), 0)
    }

    func testSelvmakkerAlmindelig9Præcis_P4_giver12OgTreGangeMinus4() {
        // P = 2*(0+2)*1 = +4 → afslører den gamle afrunding (+9/−3)
        let s = ScoringEngine.scoreNormalHand(NormalHandScoreInput(
            gameType: .almindelig,
            bidTricks: 9,
            actualTricks: 9,
            bidder: .east,
            partner: .east,
            trumpSuit: nil
        ))!
        XCTAssertEqual(s[.east], 12)
        XCTAssertEqual(s[.north], -4)
        XCTAssertEqual(s[.south], -4)
        XCTAssertEqual(s[.west], -4)
        XCTAssertEqual(sum(s), 0)
    }

    func testSelvmakkerAlmindelig10Præcis_P8_giver24OgTreGangeMinus8() {
        // P = 4*(0+2)*1 = +8
        let s = ScoringEngine.scoreNormalHand(NormalHandScoreInput(
            gameType: .almindelig,
            bidTricks: 10,
            actualTricks: 10,
            bidder: .south,
            partner: .south,
            trumpSuit: nil
        ))!
        XCTAssertEqual(s[.south], 24)
        XCTAssertEqual(s[.north], -8)
        XCTAssertEqual(s[.east], -8)
        XCTAssertEqual(s[.west], -8)
        XCTAssertEqual(sum(s), 0)
    }

    func testSelvmakkerAlmindelig10Ned1_PMinus4_giverMinus12OgTreGangePlus4() {
        // P = −(4*|−1|*1) = −4
        let s = ScoringEngine.scoreNormalHand(NormalHandScoreInput(
            gameType: .almindelig,
            bidTricks: 10,
            actualTricks: 9,
            bidder: .west,
            partner: .west,
            trumpSuit: nil
        ))!
        XCTAssertEqual(s[.west], -12)
        XCTAssertEqual(s[.north], 4)
        XCTAssertEqual(s[.east], 4)
        XCTAssertEqual(s[.south], 4)
        XCTAssertEqual(sum(s), 0)
    }

    func testSelvmakkerFordeling_uafhængigAfMelderPlads() {
        for bidder in Seat.all {
            let s = ScoringEngine.scoreNormalHand(NormalHandScoreInput(
                gameType: .almindelig,
                bidTricks: 9,
                actualTricks: 9,
                bidder: bidder,
                partner: bidder,
                trumpSuit: nil
            ))!
            XCTAssertEqual(s[bidder], 12, "melder \(bidder)")
            for seat in Seat.all where seat != bidder {
                XCTAssertEqual(s[seat], -4, "modspiller \(seat) ved melder \(bidder)")
            }
            XCTAssertEqual(sum(s), 0)
        }
    }

    func testSelvmakkerStorslem_påvirkerPFørFordeling() {
        // Alm. 8 taget 13: P = 1*(5+2)*1*2 (storslem) = 14 → (42, −14, −14, −14)
        let s = ScoringEngine.scoreNormalHand(NormalHandScoreInput(
            gameType: .almindelig,
            bidTricks: 8,
            actualTricks: 13,
            bidder: .north,
            partner: .north,
            trumpSuit: nil
        ))!
        XCTAssertEqual(s[.north], 42)
        XCTAssertEqual(s[.east], -14)
        XCTAssertEqual(s[.south], -14)
        XCTAssertEqual(s[.west], -14)
        XCTAssertEqual(sum(s), 0)
    }

    func testSelvmakkerVip3Klør_påvirkerPFørFordeling() {
        // VIP 3. ×8, 8 præcis → 16, dernæst klør ×2 → P = 32 → (96, −32, −32, −32)
        let s = ScoringEngine.scoreNormalHand(NormalHandScoreInput(
            gameType: .vip(.triple),
            bidTricks: 8,
            actualTricks: 8,
            bidder: .north,
            partner: .north,
            trumpSuit: .clubs
        ))!
        XCTAssertEqual(s[.north], 96)
        XCTAssertEqual(s[.east], -32)
        XCTAssertEqual(s[.south], -32)
        XCTAssertEqual(s[.west], -32)
        XCTAssertEqual(sum(s), 0)
    }

    func testDuestraf() {
        let s = ScoringEngine.dutyScores(dutyHolder: .west)
        XCTAssertEqual(s[.west], -72)
        XCTAssertEqual(s[.north], 24)
        XCTAssertEqual(s[.east], 24)
        XCTAssertEqual(s[.south], 24)
        XCTAssertEqual(sum(s), 0)
    }

    func testSolNormalMelderAleneVinder() {
        let s = ScoringEngine.scoreSolHand(SolHandScoreInput(
            solType: .normal,
            bidder: .north,
            goingWith: [],
            tricksBySeat: [.north: 0, .east: 5, .south: 4, .west: 4]
        ))!
        XCTAssertEqual(s[.north], 12)
        XCTAssertEqual(s[.east], -4)
        XCTAssertEqual(s[.south], -4)
        XCTAssertEqual(s[.west], -4)
        XCTAssertEqual(sum(s), 0)
    }

    func testUgyldigMelding_returnererNil() {
        XCTAssertNil(ScoringEngine.scoreNormalHand(NormalHandScoreInput(
            gameType: .almindelig,
            bidTricks: 7,
            actualTricks: 8,
            bidder: .north,
            partner: .east,
            trumpSuit: nil
        )))
    }
}
