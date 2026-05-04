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
