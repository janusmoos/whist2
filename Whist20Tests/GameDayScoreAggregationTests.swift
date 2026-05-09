import XCTest
@testable import Whist20

final class GameDayScoreAggregationTests: XCTestCase {

    func testEmptyHandsProducesZerosAndNoSteps() {
        let s = GameDayScoreAggregation.standing(from: [])
        XCTAssertEqual(s.totalsBySeat[.north], 0)
        XCTAssertEqual(s.totalsBySeat[.east], 0)
        XCTAssertEqual(s.totalsBySeat[.south], 0)
        XCTAssertEqual(s.totalsBySeat[.west], 0)
        XCTAssertTrue(s.steps.isEmpty)
    }

    func testSingleHandTotals() {
        let t0 = Date()
        let c = HandScoreContribution(
            handNumber: 1,
            playedAt: t0,
            scoresBySeat: [.north: 4, .east: -4, .south: 4, .west: -4]
        )
        let s = GameDayScoreAggregation.standing(from: [c])
        XCTAssertEqual(s.totalsBySeat[.north], 4)
        XCTAssertEqual(s.totalsBySeat[.east], -4)
        XCTAssertEqual(s.steps.count, 1)
        XCTAssertEqual(s.steps[0].afterHandNumber, 1)
        XCTAssertEqual(s.steps[0].cumulative[.north], 4)
    }

    func testCumulativeOverTwoHands() {
        let t0 = Date()
        let c1 = HandScoreContribution(
            handNumber: 1,
            playedAt: t0,
            scoresBySeat: [.north: 2, .east: -2, .south: 2, .west: -2]
        )
        let c2 = HandScoreContribution(
            handNumber: 2,
            playedAt: t0.addingTimeInterval(60),
            scoresBySeat: [.north: 1, .east: -1, .south: 1, .west: -1]
        )
        let s = GameDayScoreAggregation.standing(from: [c1, c2])
        XCTAssertEqual(s.totalsBySeat[.north], 3)
        XCTAssertEqual(s.steps.count, 2)
        XCTAssertEqual(s.steps[0].cumulative[.north], 2)
        XCTAssertEqual(s.steps[1].cumulative[.north], 3)
    }

    func testOrderByHandNumberNotInsertion() {
        let t0 = Date()
        let first = HandScoreContribution(
            handNumber: 2,
            playedAt: t0.addingTimeInterval(120),
            scoresBySeat: [.north: 10, .east: 0, .south: 0, .west: 0]
        )
        let second = HandScoreContribution(
            handNumber: 1,
            playedAt: t0,
            scoresBySeat: [.north: 1, .east: 0, .south: 0, .west: 0]
        )
        let s = GameDayScoreAggregation.standing(from: [first, second])
        XCTAssertEqual(s.steps[0].cumulative[.north], 1)
        XCTAssertEqual(s.steps[1].cumulative[.north], 11)
    }

    func testStandingsPresentationRanksWithTies() {
        let scores: [Seat: Int] = [
            .north: 30,
            .east: 30,
            .south: 10,
            .west: 10,
        ]
        let rows = StandingsPresentation.rankedRows(scores: scores)
        XCTAssertEqual(rows.count, 4)
        XCTAssertEqual(rows[0].rank, 1)
        XCTAssertEqual(rows[1].rank, 1)
        XCTAssertEqual(rows[2].rank, 3)
        XCTAssertEqual(rows[3].rank, 3)
    }

    func testOrderByPlayedAtWhenHandNumbersInvalid() {
        let t0 = Date()
        let a = HandScoreContribution(
            handNumber: 0,
            playedAt: t0,
            scoresBySeat: [.north: 5, .east: 0, .south: 0, .west: 0]
        )
        let b = HandScoreContribution(
            handNumber: 0,
            playedAt: t0.addingTimeInterval(60),
            scoresBySeat: [.north: 3, .east: 0, .south: 0, .west: 0]
        )
        let s = GameDayScoreAggregation.standing(from: [b, a])
        XCTAssertEqual(s.steps[0].cumulative[.north], 5)
        XCTAssertEqual(s.steps[1].cumulative[.north], 8)
    }
}
