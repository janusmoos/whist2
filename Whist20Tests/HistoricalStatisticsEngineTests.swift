import XCTest
@testable import Whist20

final class HistoricalStatisticsEngineTests: XCTestCase {

    func testHistoricalDataPackResourceNames() {
        XCTAssertEqual(HistoricalDataPack.primary.resourceName, "whist_historical_data_v3")
        XCTAssertEqual(HistoricalDataPack.legacyV2.resourceName, "whist_historical_data_v2")
        XCTAssertEqual(HistoricalDataPack.custom(resourceName: "fixture").resourceName, "fixture")
    }

    func testLoadsPrimaryAndLegacyHistoricalDataPacks() throws {
        let primary = try HistoricalDataJSONLoader(bundle: .main, pack: .primary).load()
        let legacy = try HistoricalDataJSONLoader(bundle: .main, pack: .legacyV2).load()

        XCTAssertEqual(primary.version, "whist_historical_data_v3")
        XCTAssertEqual(primary.auditSummary?.version, "v3")
        XCTAssertEqual(primary.games.count, 903)
        XCTAssertEqual(primary.playerResults.count, primary.games.count * 4)

        XCTAssertEqual(legacy.version, "whist_historical_data_v2_corrected")
        XCTAssertEqual(legacy.auditSummary?.version, "v2")
        XCTAssertEqual(legacy.games.count, 744)
    }

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
        XCTAssertNil(summaries[0].bestSession)
        XCTAssertNil(summaries[0].worstSession)
        XCTAssertEqual(summaries[1].totalScore, -6)
    }

    func testScoreTimelineAccumulatesBySession() {
        let data = HistoricalWhistData(
            version: "test",
            generatedAt: "now",
            players: [
                HistoricalPlayer(id: "Thomas", name: "Thomas", displayOrder: 1, isActive: true),
                HistoricalPlayer(id: "Peter", name: "Peter", displayOrder: 2, isActive: true),
            ],
            sessions: [
                HistoricalSession(
                    id: "s1",
                    sessionNumber: "1",
                    date: "2024-01-01",
                    location: nil,
                    sourceSheetName: "01",
                    expectedGameCount: 1,
                    importedGameCount: 1,
                    missingScoreRows: 0,
                    qualityStatus: "ok",
                    cumulativeBlockStartColumn: nil,
                    deltaBlockStartColumn: nil,
                    preferredScoreBlockNumericRows: nil,
                    headerRow: nil,
                    columnMapping: nil
                ),
                HistoricalSession(
                    id: "s2",
                    sessionNumber: "2",
                    date: "2024-01-02",
                    location: nil,
                    sourceSheetName: "02",
                    expectedGameCount: 1,
                    importedGameCount: 1,
                    missingScoreRows: 0,
                    qualityStatus: "ok",
                    cumulativeBlockStartColumn: nil,
                    deltaBlockStartColumn: nil,
                    preferredScoreBlockNumericRows: nil,
                    headerRow: nil,
                    columnMapping: nil
                ),
            ],
            games: [
                HistoricalGame(
                    id: "g1",
                    sessionId: "s1",
                    sessionNumber: "1",
                    gameNumberInSession: 1,
                    sourceGameMarker: 1,
                    gameTypeRaw: nil,
                    gameTypeNormalized: nil,
                    bidTricks: nil,
                    bidderId: nil,
                    bidderIds: [],
                    winnerId: nil,
                    winnerIds: [],
                    partnerId: nil,
                    dealerId: nil,
                    checksum: 0,
                    scoreSource: "test",
                    sourceSheetName: "01",
                    sourceRow: 1,
                    qualityFlags: []
                ),
                HistoricalGame(
                    id: "g2",
                    sessionId: "s2",
                    sessionNumber: "2",
                    gameNumberInSession: 1,
                    sourceGameMarker: 1,
                    gameTypeRaw: nil,
                    gameTypeNormalized: nil,
                    bidTricks: nil,
                    bidderId: nil,
                    bidderIds: [],
                    winnerId: nil,
                    winnerIds: [],
                    partnerId: nil,
                    dealerId: nil,
                    checksum: 0,
                    scoreSource: "test",
                    sourceSheetName: "02",
                    sourceRow: 1,
                    qualityFlags: []
                ),
            ],
            playerResults: [
                HistoricalPlayerResult(id: "1", gameId: "g1", playerId: "Thomas", score: 5, sourceSheetName: "01", sourceRow: 1),
                HistoricalPlayerResult(id: "2", gameId: "g1", playerId: "Peter", score: -5, sourceSheetName: "01", sourceRow: 1),
                HistoricalPlayerResult(id: "3", gameId: "g2", playerId: "Thomas", score: -2, sourceSheetName: "02", sourceRow: 1),
                HistoricalPlayerResult(id: "4", gameId: "g2", playerId: "Peter", score: 2, sourceSheetName: "02", sourceRow: 1),
            ],
            auditSummary: nil
        )

        let timeline = HistoricalStatisticsEngine.scoreTimeline(from: data)
        let summaries = HistoricalStatisticsEngine.playerScoreSummaries(from: data)
        let thomas = timeline.filter { $0.playerId == "Thomas" }
        let peter = timeline.filter { $0.playerId == "Peter" }
        let thomasSummary = summaries.first { $0.player.id == "Thomas" }

        XCTAssertEqual(thomas.map(\.cumulativeScore), [5, 3])
        XCTAssertEqual(thomas.map(\.sessionScore), [5, -2])
        XCTAssertEqual(peter.map(\.cumulativeScore), [-5, -3])
        XCTAssertEqual(timeline.map(\.sessionIndex).max(), 2)
        XCTAssertEqual(thomasSummary?.bestSession?.score, 5)
        XCTAssertEqual(thomasSummary?.bestSession?.sessionId, "s1")
        XCTAssertEqual(thomasSummary?.worstSession?.score, -2)
        XCTAssertEqual(thomasSummary?.worstSession?.sessionId, "s2")
    }

    func testRecentScopeFiltersOlderSessionsOut() {
        let sessions = (1...11).map { index in
            HistoricalSession(
                id: "s\(index)",
                sessionNumber: "\(index)",
                date: "2024-01-\(String(format: "%02d", index))",
                location: nil,
                sourceSheetName: "\(index)",
                expectedGameCount: 1,
                importedGameCount: 1,
                missingScoreRows: 0,
                qualityStatus: "ok",
                cumulativeBlockStartColumn: nil,
                deltaBlockStartColumn: nil,
                preferredScoreBlockNumericRows: nil,
                headerRow: nil,
                columnMapping: nil
            )
        }
        let games = (1...11).map { index in
            HistoricalGame(
                id: "g\(index)",
                sessionId: "s\(index)",
                sessionNumber: "\(index)",
                gameNumberInSession: 1,
                sourceGameMarker: 1,
                gameTypeRaw: nil,
                gameTypeNormalized: nil,
                bidTricks: nil,
                bidderId: nil,
                bidderIds: [],
                winnerId: nil,
                winnerIds: [],
                partnerId: nil,
                dealerId: nil,
                checksum: 0,
                scoreSource: "test",
                sourceSheetName: "\(index)",
                sourceRow: 1,
                qualityFlags: []
            )
        }
        let results = (1...11).flatMap { index in
            [
                HistoricalPlayerResult(id: "t\(index)", gameId: "g\(index)", playerId: "Thomas", score: index, sourceSheetName: "\(index)", sourceRow: 1),
                HistoricalPlayerResult(id: "p\(index)", gameId: "g\(index)", playerId: "Peter", score: -index, sourceSheetName: "\(index)", sourceRow: 1),
            ]
        }
        let data = HistoricalWhistData(
            version: "test",
            generatedAt: "now",
            players: [
                HistoricalPlayer(id: "Thomas", name: "Thomas", displayOrder: 1, isActive: true),
                HistoricalPlayer(id: "Peter", name: "Peter", displayOrder: 2, isActive: true),
            ],
            sessions: sessions,
            games: games,
            playerResults: results,
            auditSummary: nil
        )

        let snapshot = HistoricalStatisticsEngine.snapshot(from: data, scope: .recent, recentSessionLimit: 10)
        let thomas = snapshot.playerSummaries.first { $0.player.id == "Thomas" }
        let thomasTimeline = snapshot.timelinePoints.filter { $0.playerId == "Thomas" }

        XCTAssertEqual(snapshot.scope, .recent)
        XCTAssertEqual(snapshot.sessionCount, 10)
        XCTAssertEqual(snapshot.gameCount, 10)
        XCTAssertEqual(snapshot.playerResultCount, 20)
        XCTAssertEqual(thomas?.totalScore, 65)
        XCTAssertEqual(thomasTimeline.first?.sessionId, "s2")
        XCTAssertEqual(thomasTimeline.last?.cumulativeScore, 65)
    }

    func testCurrentScopeUsesLatestSessionOnly() {
        let sessions = (1...3).map { index in
            HistoricalSession(
                id: "s\(index)",
                sessionNumber: "\(index)",
                date: "2024-02-0\(index)",
                location: nil,
                sourceSheetName: "\(index)",
                expectedGameCount: 1,
                importedGameCount: 1,
                missingScoreRows: 0,
                qualityStatus: "ok",
                cumulativeBlockStartColumn: nil,
                deltaBlockStartColumn: nil,
                preferredScoreBlockNumericRows: nil,
                headerRow: nil,
                columnMapping: nil
            )
        }
        let games = (1...3).map { index in
            HistoricalGame(
                id: "g\(index)",
                sessionId: "s\(index)",
                sessionNumber: "\(index)",
                gameNumberInSession: 1,
                sourceGameMarker: 1,
                gameTypeRaw: nil,
                gameTypeNormalized: nil,
                bidTricks: nil,
                bidderId: nil,
                bidderIds: [],
                winnerId: nil,
                winnerIds: [],
                partnerId: nil,
                dealerId: nil,
                checksum: 0,
                scoreSource: "test",
                sourceSheetName: "\(index)",
                sourceRow: 1,
                qualityFlags: []
            )
        }
        let results = (1...3).flatMap { index in
            [
                HistoricalPlayerResult(id: "t\(index)", gameId: "g\(index)", playerId: "Thomas", score: index * 10, sourceSheetName: "\(index)", sourceRow: 1),
                HistoricalPlayerResult(id: "p\(index)", gameId: "g\(index)", playerId: "Peter", score: -(index * 10), sourceSheetName: "\(index)", sourceRow: 1),
            ]
        }
        let data = HistoricalWhistData(
            version: "test",
            generatedAt: "now",
            players: [
                HistoricalPlayer(id: "Thomas", name: "Thomas", displayOrder: 1, isActive: true),
                HistoricalPlayer(id: "Peter", name: "Peter", displayOrder: 2, isActive: true),
            ],
            sessions: sessions,
            games: games,
            playerResults: results,
            auditSummary: nil
        )

        let snapshot = HistoricalStatisticsEngine.snapshot(from: data, scope: .current)
        let thomas = snapshot.playerSummaries.first { $0.player.id == "Thomas" }

        XCTAssertEqual(snapshot.scope, .current)
        XCTAssertEqual(snapshot.sessionCount, 1)
        XCTAssertEqual(snapshot.gameCount, 1)
        XCTAssertEqual(snapshot.playerResultCount, 2)
        XCTAssertEqual(thomas?.totalScore, 30)
        XCTAssertEqual(snapshot.timelinePoints.first { $0.playerId == "Thomas" }?.sessionId, "s3")
    }

    func testPlayerProfilesIncludeGameDetailsAndBidStats() {
        let data = HistoricalWhistData(
            version: "test",
            generatedAt: "now",
            players: [
                HistoricalPlayer(id: "Thomas", name: "Thomas", displayOrder: 1, isActive: true),
                HistoricalPlayer(id: "Peter", name: "Peter", displayOrder: 2, isActive: true),
            ],
            sessions: [
                HistoricalSession(
                    id: "s1",
                    sessionNumber: "1",
                    date: "2024-03-01",
                    location: "Thomas",
                    sourceSheetName: "01",
                    expectedGameCount: 2,
                    importedGameCount: 2,
                    missingScoreRows: 0,
                    qualityStatus: "ok",
                    cumulativeBlockStartColumn: nil,
                    deltaBlockStartColumn: nil,
                    preferredScoreBlockNumericRows: nil,
                    headerRow: nil,
                    columnMapping: nil
                )
            ],
            games: [
                HistoricalGame(
                    id: "g1",
                    sessionId: "s1",
                    sessionNumber: "1",
                    gameNumberInSession: 1,
                    sourceGameMarker: 1,
                    gameTypeRaw: "9 vip",
                    gameTypeNormalized: "vip",
                    bidTricks: 9,
                    bidderId: "Thomas",
                    bidderIds: ["Thomas"],
                    winnerId: "Thomas",
                    winnerIds: ["Thomas"],
                    partnerId: nil,
                    dealerId: "Peter",
                    checksum: 0,
                    scoreSource: "test",
                    sourceSheetName: "01",
                    sourceRow: 1,
                    qualityFlags: []
                ),
                HistoricalGame(
                    id: "g2",
                    sessionId: "s1",
                    sessionNumber: "1",
                    gameNumberInSession: 2,
                    sourceGameMarker: 2,
                    gameTypeRaw: "8 halve",
                    gameTypeNormalized: "halve",
                    bidTricks: 8,
                    bidderId: "Thomas",
                    bidderIds: ["Thomas"],
                    winnerId: "Peter",
                    winnerIds: ["Peter"],
                    partnerId: nil,
                    dealerId: "Thomas",
                    checksum: 0,
                    scoreSource: "test",
                    sourceSheetName: "01",
                    sourceRow: 2,
                    qualityFlags: []
                ),
            ],
            playerResults: [
                HistoricalPlayerResult(id: "t1", gameId: "g1", playerId: "Thomas", score: 12, sourceSheetName: "01", sourceRow: 1),
                HistoricalPlayerResult(id: "p1", gameId: "g1", playerId: "Peter", score: -12, sourceSheetName: "01", sourceRow: 1),
                HistoricalPlayerResult(id: "t2", gameId: "g2", playerId: "Thomas", score: -8, sourceSheetName: "01", sourceRow: 2),
                HistoricalPlayerResult(id: "p2", gameId: "g2", playerId: "Peter", score: 8, sourceSheetName: "01", sourceRow: 2),
            ],
            auditSummary: nil
        )

        let profile = HistoricalStatisticsEngine.playerProfiles(from: data).first { $0.player.id == "Thomas" }

        XCTAssertEqual(profile?.bestGame?.game.id, "g1")
        XCTAssertEqual(profile?.bestGame?.selectedPlayerScore, 12)
        XCTAssertEqual(profile?.worstGame?.game.id, "g2")
        XCTAssertEqual(profile?.mostSuccessfulBid?.gameType, "vip")
        XCTAssertEqual(profile?.leastSuccessfulBid?.gameType, "halve")
        XCTAssertEqual(profile?.bidSampleSize, 2)
        XCTAssertEqual(profile?.sessionScores.map(\.sessionId), ["s1"])
        XCTAssertEqual(profile?.sessionScores.first?.score, 4)
    }

    func testSessionOverviewsIncludeBestWorstGamesAndMetadataCounts() {
        let data = HistoricalWhistData(
            version: "test",
            generatedAt: "now",
            players: [
                HistoricalPlayer(id: "Thomas", name: "Thomas", displayOrder: 1, isActive: true),
                HistoricalPlayer(id: "Peter", name: "Peter", displayOrder: 2, isActive: true),
            ],
            sessions: [
                HistoricalSession(
                    id: "s1",
                    sessionNumber: "1",
                    date: "2024-03-01",
                    location: "Thomas",
                    sourceSheetName: "01",
                    expectedGameCount: 2,
                    importedGameCount: 2,
                    missingScoreRows: 0,
                    qualityStatus: "ok",
                    cumulativeBlockStartColumn: nil,
                    deltaBlockStartColumn: nil,
                    preferredScoreBlockNumericRows: nil,
                    headerRow: nil,
                    columnMapping: nil
                )
            ],
            games: [
                HistoricalGame(
                    id: "g1",
                    sessionId: "s1",
                    sessionNumber: "1",
                    gameNumberInSession: 1,
                    sourceGameMarker: 1,
                    gameTypeRaw: "9 vip",
                    gameTypeNormalized: "vip",
                    bidTricks: 9,
                    bidderId: "Thomas",
                    bidderIds: ["Thomas"],
                    winnerId: "Thomas",
                    winnerIds: ["Thomas"],
                    partnerId: "Peter",
                    dealerId: "Peter",
                    checksum: 0,
                    scoreSource: "test",
                    sourceSheetName: "01",
                    sourceRow: 1,
                    qualityFlags: []
                ),
                HistoricalGame(
                    id: "g2",
                    sessionId: "s1",
                    sessionNumber: "1",
                    gameNumberInSession: 2,
                    sourceGameMarker: 2,
                    gameTypeRaw: nil,
                    gameTypeNormalized: nil,
                    bidTricks: nil,
                    bidderId: nil,
                    bidderIds: [],
                    winnerId: nil,
                    winnerIds: [],
                    partnerId: nil,
                    dealerId: nil,
                    checksum: 1,
                    scoreSource: "test",
                    sourceSheetName: "01",
                    sourceRow: 2,
                    qualityFlags: ["score_sum_not_zero"]
                ),
            ],
            playerResults: [
                HistoricalPlayerResult(id: "t1", gameId: "g1", playerId: "Thomas", score: 12, sourceSheetName: "01", sourceRow: 1),
                HistoricalPlayerResult(id: "p1", gameId: "g1", playerId: "Peter", score: -12, sourceSheetName: "01", sourceRow: 1),
                HistoricalPlayerResult(id: "t2", gameId: "g2", playerId: "Thomas", score: -8, sourceSheetName: "01", sourceRow: 2),
                HistoricalPlayerResult(id: "p2", gameId: "g2", playerId: "Peter", score: 7, sourceSheetName: "01", sourceRow: 2),
            ],
            auditSummary: nil
        )

        let overview = HistoricalStatisticsEngine.sessionOverviews(from: data).first

        XCTAssertEqual(overview?.gamesPlayed, 2)
        XCTAssertEqual(overview?.playerTotals.first { $0.player.id == "Thomas" }?.score, 4)
        XCTAssertEqual(overview?.bestGame?.game.id, "g1")
        XCTAssertEqual(overview?.worstGame?.game.id, "g1")
        XCTAssertEqual(overview?.gameDetails.map(\.game.id), ["g1", "g2"])
        XCTAssertEqual(
            overview?.progressPoints.filter { $0.player.id == "Thomas" }.map(\.cumulativeScore),
            [12, 4]
        )
        XCTAssertEqual(
            overview?.progressPoints.filter { $0.player.id == "Peter" }.map(\.cumulativeScore),
            [-12, -5]
        )
        XCTAssertEqual(overview?.gamesWithType, 1)
        XCTAssertEqual(overview?.gamesWithBidder, 1)
        XCTAssertEqual(overview?.gamesWithPartner, 1)
        XCTAssertEqual(overview?.issueCount, 1)
    }

    func testPlayerTrendSummariesRankByPeriodScore() {
        let sessions = (1...3).map { index in
            HistoricalSession(
                id: "s\(index)",
                sessionNumber: "\(index)",
                date: "2024-04-0\(index)",
                location: nil,
                sourceSheetName: "\(index)",
                expectedGameCount: 1,
                importedGameCount: 1,
                missingScoreRows: 0,
                qualityStatus: "ok",
                cumulativeBlockStartColumn: nil,
                deltaBlockStartColumn: nil,
                preferredScoreBlockNumericRows: nil,
                headerRow: nil,
                columnMapping: nil
            )
        }
        let games = (1...3).map { index in
            HistoricalGame(
                id: "g\(index)",
                sessionId: "s\(index)",
                sessionNumber: "\(index)",
                gameNumberInSession: 1,
                sourceGameMarker: 1,
                gameTypeRaw: nil,
                gameTypeNormalized: nil,
                bidTricks: nil,
                bidderId: nil,
                bidderIds: [],
                winnerId: nil,
                winnerIds: [],
                partnerId: nil,
                dealerId: nil,
                checksum: 0,
                scoreSource: "test",
                sourceSheetName: "\(index)",
                sourceRow: 1,
                qualityFlags: []
            )
        }
        let data = HistoricalWhistData(
            version: "test",
            generatedAt: "now",
            players: [
                HistoricalPlayer(id: "Thomas", name: "Thomas", displayOrder: 1, isActive: true),
                HistoricalPlayer(id: "Peter", name: "Peter", displayOrder: 2, isActive: true),
            ],
            sessions: sessions,
            games: games,
            playerResults: [
                HistoricalPlayerResult(id: "t1", gameId: "g1", playerId: "Thomas", score: 4, sourceSheetName: "1", sourceRow: 1),
                HistoricalPlayerResult(id: "p1", gameId: "g1", playerId: "Peter", score: -4, sourceSheetName: "1", sourceRow: 1),
                HistoricalPlayerResult(id: "t2", gameId: "g2", playerId: "Thomas", score: -2, sourceSheetName: "2", sourceRow: 1),
                HistoricalPlayerResult(id: "p2", gameId: "g2", playerId: "Peter", score: 2, sourceSheetName: "2", sourceRow: 1),
                HistoricalPlayerResult(id: "t3", gameId: "g3", playerId: "Thomas", score: 8, sourceSheetName: "3", sourceRow: 1),
                HistoricalPlayerResult(id: "p3", gameId: "g3", playerId: "Peter", score: -8, sourceSheetName: "3", sourceRow: 1),
            ],
            auditSummary: nil
        )

        let trends = HistoricalStatisticsEngine.playerTrendSummaries(from: data)
        let thomas = trends.first { $0.player.id == "Thomas" }

        XCTAssertEqual(trends.map(\.player.id), ["Thomas", "Peter"])
        XCTAssertEqual(thomas?.periodScore, 10)
        XCTAssertEqual(thomas?.latestSessionScore, 8)
        XCTAssertEqual(thomas?.sessionsPlayed, 3)
        XCTAssertEqual(thomas?.bestSession?.sessionId, "s3")
        XCTAssertEqual(thomas?.worstSession?.sessionId, "s2")
        XCTAssertEqual(thomas?.averageSessionScore, 10.0 / 3.0)
    }

    func testGameTypeTrendSummariesIncludePlayerAveragesAndBidSuccessRate() {
        let data = HistoricalWhistData(
            version: "test",
            generatedAt: "now",
            players: [
                HistoricalPlayer(id: "Thomas", name: "Thomas", displayOrder: 1, isActive: true),
                HistoricalPlayer(id: "Peter", name: "Peter", displayOrder: 2, isActive: true),
            ],
            sessions: [
                HistoricalSession(
                    id: "s1",
                    sessionNumber: "1",
                    date: "2024-05-01",
                    location: "Peter",
                    sourceSheetName: "1",
                    expectedGameCount: 3,
                    importedGameCount: 3,
                    missingScoreRows: 0,
                    qualityStatus: "ok",
                    cumulativeBlockStartColumn: nil,
                    deltaBlockStartColumn: nil,
                    preferredScoreBlockNumericRows: nil,
                    headerRow: nil,
                    columnMapping: nil
                )
            ],
            games: [
                HistoricalGame(
                    id: "g1",
                    sessionId: "s1",
                    sessionNumber: "1",
                    gameNumberInSession: 1,
                    sourceGameMarker: 1,
                    gameTypeRaw: "9 vip",
                    gameTypeNormalized: "vip",
                    bidTricks: 9,
                    bidderId: "Thomas",
                    bidderIds: ["Thomas"],
                    winnerId: "Thomas",
                    winnerIds: ["Thomas"],
                    partnerId: nil,
                    dealerId: nil,
                    checksum: 0,
                    scoreSource: "test",
                    sourceSheetName: "1",
                    sourceRow: 1,
                    qualityFlags: []
                ),
                HistoricalGame(
                    id: "g2",
                    sessionId: "s1",
                    sessionNumber: "1",
                    gameNumberInSession: 2,
                    sourceGameMarker: 2,
                    gameTypeRaw: "10 vip",
                    gameTypeNormalized: "vip",
                    bidTricks: 10,
                    bidderId: "Thomas",
                    bidderIds: ["Thomas"],
                    winnerId: "Peter",
                    winnerIds: ["Peter"],
                    partnerId: nil,
                    dealerId: nil,
                    checksum: 0,
                    scoreSource: "test",
                    sourceSheetName: "1",
                    sourceRow: 2,
                    qualityFlags: []
                ),
                HistoricalGame(
                    id: "g3",
                    sessionId: "s1",
                    sessionNumber: "1",
                    gameNumberInSession: 3,
                    sourceGameMarker: 3,
                    gameTypeRaw: "8 halve",
                    gameTypeNormalized: "halve",
                    bidTricks: 8,
                    bidderId: "Peter",
                    bidderIds: ["Peter"],
                    winnerId: "Peter",
                    winnerIds: ["Peter"],
                    partnerId: nil,
                    dealerId: nil,
                    checksum: 0,
                    scoreSource: "test",
                    sourceSheetName: "1",
                    sourceRow: 3,
                    qualityFlags: []
                ),
            ],
            playerResults: [
                HistoricalPlayerResult(id: "t1", gameId: "g1", playerId: "Thomas", score: 10, sourceSheetName: "1", sourceRow: 1),
                HistoricalPlayerResult(id: "p1", gameId: "g1", playerId: "Peter", score: -10, sourceSheetName: "1", sourceRow: 1),
                HistoricalPlayerResult(id: "t2", gameId: "g2", playerId: "Thomas", score: -4, sourceSheetName: "1", sourceRow: 2),
                HistoricalPlayerResult(id: "p2", gameId: "g2", playerId: "Peter", score: 4, sourceSheetName: "1", sourceRow: 2),
                HistoricalPlayerResult(id: "t3", gameId: "g3", playerId: "Thomas", score: -6, sourceSheetName: "1", sourceRow: 3),
                HistoricalPlayerResult(id: "p3", gameId: "g3", playerId: "Peter", score: 6, sourceSheetName: "1", sourceRow: 3),
            ],
            auditSummary: nil
        )

        let summaries = HistoricalStatisticsEngine.gameTypeTrendSummaries(from: data)
        let vip = summaries.first { $0.gameType == "vip" }
        let halve = summaries.first { $0.gameType == "halve" }

        XCTAssertEqual(summaries.map(\.gameType), ["vip", "halve"])
        XCTAssertEqual(vip?.games, 2)
        XCTAssertEqual(vip?.bidOutcomeGames, 2)
        XCTAssertEqual(vip?.successfulBidGames, 1)
        XCTAssertEqual(vip?.successRate, 0.5)
        XCTAssertEqual(vip?.playerAverages.first { $0.player.id == "Thomas" }?.totalScore, 6)
        XCTAssertEqual(vip?.playerAverages.first { $0.player.id == "Thomas" }?.averageScore, 3)
        XCTAssertEqual(vip?.playerAverages.first { $0.player.id == "Peter" }?.averageScore, -3)
        XCTAssertEqual(halve?.successfulBidGames, 1)
        XCTAssertEqual(halve?.successRate, 1)
    }

    func testTeamScoreMismatchFlagsOrdinaryPartnerGames() {
        let game = historicalGame(
            gameTypeNormalized: "sans/sang",
            bidderId: "Peter",
            winnerId: "Peter",
            partnerId: "Janus"
        )
        let scores = playerScores([
            ("Thomas", -92),
            ("Peter", 84),
            ("Janus", 84),
            ("Christian", -76),
        ])

        let flags = HistoricalStatisticsEngine.qualityFlags(for: game, playerScores: scores)

        XCTAssertTrue(flags.contains(HistoricalDataQualityFlag.teamScoreMismatch.rawValue))
    }

    func testTeamScoreMismatchDoesNotFlagBalancedPartnerGames() {
        let game = historicalGame(
            gameTypeNormalized: "gode",
            bidderId: "Peter",
            winnerId: "Peter",
            partnerId: "Janus"
        )
        let scores = playerScores([
            ("Thomas", -84),
            ("Peter", 84),
            ("Janus", 84),
            ("Christian", -84),
        ])

        let flags = HistoricalStatisticsEngine.qualityFlags(for: game, playerScores: scores)

        XCTAssertFalse(flags.contains(HistoricalDataQualityFlag.teamScoreMismatch.rawValue))
    }

    func testTeamScoreMismatchSkipsSoloAndSelfPartnerGames() {
        let soloGame = historicalGame(
            gameTypeNormalized: "ren sol",
            bidderId: "Peter",
            winnerId: "Peter",
            partnerId: "Janus"
        )
        let selfPartnerGame = historicalGame(
            gameTypeNormalized: "alm",
            bidderId: "Peter",
            winnerId: "Peter",
            partnerId: "Selvmakker"
        )
        let unevenScores = playerScores([
            ("Thomas", -92),
            ("Peter", 84),
            ("Janus", 84),
            ("Christian", -76),
        ])

        let soloFlags = HistoricalStatisticsEngine.qualityFlags(for: soloGame, playerScores: unevenScores)
        let selfPartnerFlags = HistoricalStatisticsEngine.qualityFlags(for: selfPartnerGame, playerScores: unevenScores)

        XCTAssertFalse(soloFlags.contains(HistoricalDataQualityFlag.teamScoreMismatch.rawValue))
        XCTAssertFalse(selfPartnerFlags.contains(HistoricalDataQualityFlag.teamScoreMismatch.rawValue))
    }

    private func historicalGame(
        gameTypeNormalized: String?,
        bidderId: String?,
        winnerId: String?,
        partnerId: String?
    ) -> HistoricalGame {
        HistoricalGame(
            id: "g1",
            sessionId: "s1",
            sessionNumber: "1",
            gameNumberInSession: 1,
            sourceGameMarker: 1,
            gameTypeRaw: gameTypeNormalized,
            gameTypeNormalized: gameTypeNormalized,
            bidTricks: nil,
            bidderId: bidderId,
            bidderIds: bidderId.map { [$0] } ?? [],
            winnerId: winnerId,
            winnerIds: winnerId.map { [$0] } ?? [],
            partnerId: partnerId,
            dealerId: nil,
            checksum: 0,
            scoreSource: "test",
            sourceSheetName: "1",
            sourceRow: 1,
            qualityFlags: []
        )
    }

    private func playerScores(_ values: [(String, Int)]) -> [HistoricalPlayerGameScore] {
        values.enumerated().map { index, value in
            HistoricalPlayerGameScore(
                player: HistoricalPlayer(
                    id: value.0,
                    name: value.0,
                    displayOrder: index + 1,
                    isActive: true
                ),
                score: value.1
            )
        }
    }
}
