import XCTest
@testable import Whist20

final class HistoricalStatisticsEngineTests: XCTestCase {

    func testDecodesHistoricalDataShape() throws {
        let json = """
        {
          "version": "test",
          "generatedAt": "2026-05-09T15:49:06",
          "players": [
            { "id": "Thomas", "name": "Thomas", "displayOrder": 1, "isActive": true }
          ],
          "sessions": [],
          "games": [],
          "playerResults": [],
          "auditSummary": {
            "version": "v2",
            "sheetCount": 47,
            "importedSessions": 27,
            "importedGames": 744,
            "playerResultRows": 2976,
            "playerTotals": { "Thomas": 16 },
            "fieldCounts": {
              "gameType": 469,
              "dealer": 515,
              "bidder_or_winner": 532,
              "partner": 165,
              "score_sum_zero": 714
            },
            "issueCount": 46,
            "issueCounts": { "score_sum_not_zero": 30 }
          }
        }
        """
        let data = Data(json.utf8)

        let decoded = try HistoricalDataJSONLoader().decode(data)

        XCTAssertEqual(decoded.version, "test")
        XCTAssertEqual(decoded.players.first?.id, "Thomas")
        XCTAssertEqual(decoded.auditSummary?.fieldCounts.bidderOrWinner, 532)
        XCTAssertEqual(decoded.auditSummary?.fieldCounts.scoreSumZero, 714)
    }

    func testPlayerScoreSummariesAreRankedByTotalScore() {
        let data = HistoricalWhistData(
            version: "test",
            generatedAt: "now",
            players: [
                HistoricalPlayer(id: "Thomas", name: "Thomas", displayOrder: 1, isActive: true),
                HistoricalPlayer(id: "Peter", name: "Peter", displayOrder: 2, isActive: true),
            ],
            sessions: [],
            games: [],
            playerResults: [
                HistoricalPlayerResult(id: "1", gameId: "g1", playerId: "Thomas", score: 10, sourceSheetName: "s", sourceRow: 1),
                HistoricalPlayerResult(id: "2", gameId: "g2", playerId: "Thomas", score: -4, sourceSheetName: "s", sourceRow: 2),
                HistoricalPlayerResult(id: "3", gameId: "g1", playerId: "Peter", score: -10, sourceSheetName: "s", sourceRow: 1),
                HistoricalPlayerResult(id: "4", gameId: "g2", playerId: "Peter", score: 4, sourceSheetName: "s", sourceRow: 2),
            ],
            auditSummary: nil
        )

        let summaries = HistoricalStatisticsEngine.playerScoreSummaries(from: data)

        XCTAssertEqual(summaries.map(\.player.id), ["Thomas", "Peter"])
        XCTAssertEqual(summaries[0].totalScore, 6)
        XCTAssertEqual(summaries[0].gamesPlayed, 2)
        XCTAssertEqual(summaries[0].averageScore, 3)
        XCTAssertEqual(summaries[0].bestSingleGame, 10)
        XCTAssertEqual(summaries[0].worstSingleGame, -4)
        XCTAssertEqual(summaries[1].totalScore, -6)
    }
}
