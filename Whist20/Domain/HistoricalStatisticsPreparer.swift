import Foundation

struct HistoricalStatisticsHubModel {
    var data: HistoricalWhistData
    var allSnapshot: HistoricalStatisticsSnapshot
    var currentOverview: HistoricalSessionOverview?
    var gameTypeCount: Int
    var sessionOverviews: [HistoricalSessionOverview]
    var playerSessionScores: [String: [HistoricalPlayerSessionScore]]
    var playerProfiles: [HistoricalPlayerProfile]
    var playerSummaries: [HistoricalPlayerScoreSummary]
    var gameTypeOverviews: [HistoricalGameTypeOverview]
    var snapshotsByScope: [HistoricalStatisticsScopeCacheKey: HistoricalStatisticsSnapshot]
    var scopedDataByScope: [HistoricalStatisticsScopeCacheKey: HistoricalWhistData]
    var playerTrendSummariesByScope: [HistoricalStatisticsScopeCacheKey: [HistoricalPlayerTrendSummary]]
    var gameTypeTrendSummariesByScope: [HistoricalStatisticsScopeCacheKey: [HistoricalGameTypeTrendSummary]]

    init(
        data: HistoricalWhistData,
        allSnapshot: HistoricalStatisticsSnapshot,
        currentOverview: HistoricalSessionOverview?,
        gameTypeCount: Int,
        sessionOverviews: [HistoricalSessionOverview],
        playerSessionScores: [String: [HistoricalPlayerSessionScore]],
        playerProfiles: [HistoricalPlayerProfile],
        playerSummaries: [HistoricalPlayerScoreSummary],
        gameTypeOverviews: [HistoricalGameTypeOverview],
        snapshotsByScope: [HistoricalStatisticsScopeCacheKey: HistoricalStatisticsSnapshot],
        scopedDataByScope: [HistoricalStatisticsScopeCacheKey: HistoricalWhistData],
        playerTrendSummariesByScope: [HistoricalStatisticsScopeCacheKey: [HistoricalPlayerTrendSummary]],
        gameTypeTrendSummariesByScope: [HistoricalStatisticsScopeCacheKey: [HistoricalGameTypeTrendSummary]]
    ) {
        self.data = data
        self.allSnapshot = allSnapshot
        self.currentOverview = currentOverview
        self.gameTypeCount = gameTypeCount
        self.sessionOverviews = sessionOverviews
        self.playerSessionScores = playerSessionScores
        self.playerProfiles = playerProfiles
        self.playerSummaries = playerSummaries
        self.gameTypeOverviews = gameTypeOverviews
        self.snapshotsByScope = snapshotsByScope
        self.scopedDataByScope = scopedDataByScope
        self.playerTrendSummariesByScope = playerTrendSummariesByScope
        self.gameTypeTrendSummariesByScope = gameTypeTrendSummariesByScope
    }

    init(loader: HistoricalDataJSONLoader) throws {
        let prepared = try HistoricalStatisticsPreparer.prepareHubModel(loader: loader)
        self = prepared
    }
}

enum HistoricalStatisticsPreparer {
    static func prepareHubModel(
        loader: HistoricalDataJSONLoader,
        liveSnapshots: [LiveStatisticsGameDaySnapshot] = []
    ) throws -> HistoricalStatisticsHubModel {
        let data = try loader.load()
        return prepareHubModel(historicalData: data, liveSnapshots: liveSnapshots)
    }

    static func prepareHubModel(
        historicalData data: HistoricalWhistData,
        liveSnapshots: [LiveStatisticsGameDaySnapshot] = []
    ) -> HistoricalStatisticsHubModel {
        let data = LiveHistoricalStatisticsAdapter.combinedData(
            historicalData: data,
            liveSnapshots: liveSnapshots
        )
        let allSnapshot = HistoricalStatisticsEngine.snapshot(from: data, scope: .all)
        let currentData = HistoricalStatisticsEngine.scopedData(from: data, scope: .current)
        let sessionOverviews = HistoricalStatisticsEngine.sessionOverviews(from: data)
        let currentOverview = HistoricalStatisticsEngine.sessionOverviews(from: currentData).last
        let gameTypeOverviews = gameTypeOverviews(from: data)
        let gameTypeCount = gameTypeOverviews.count
        let scopeCache = prepareScopeCache(from: data)

        return HistoricalStatisticsHubModel(
            data: data,
            allSnapshot: allSnapshot,
            currentOverview: currentOverview,
            gameTypeCount: gameTypeCount,
            sessionOverviews: sessionOverviews,
            playerSessionScores: HistoricalStatisticsEngine.playerSessionScores(from: data),
            playerProfiles: HistoricalStatisticsEngine.playerProfiles(from: data),
            playerSummaries: HistoricalStatisticsEngine.playerScoreSummaries(from: data),
            gameTypeOverviews: gameTypeOverviews,
            snapshotsByScope: scopeCache.snapshots,
            scopedDataByScope: scopeCache.scopedData,
            playerTrendSummariesByScope: scopeCache.playerTrends,
            gameTypeTrendSummariesByScope: scopeCache.gameTypeTrends
        )
    }

    private static func prepareScopeCache(
        from data: HistoricalWhistData
    ) -> (
        snapshots: [HistoricalStatisticsScopeCacheKey: HistoricalStatisticsSnapshot],
        scopedData: [HistoricalStatisticsScopeCacheKey: HistoricalWhistData],
        playerTrends: [HistoricalStatisticsScopeCacheKey: [HistoricalPlayerTrendSummary]],
        gameTypeTrends: [HistoricalStatisticsScopeCacheKey: [HistoricalGameTypeTrendSummary]]
    ) {
        let recentLimits = [5, 10, 15, 20, 25, 50]
        var snapshots: [HistoricalStatisticsScopeCacheKey: HistoricalStatisticsSnapshot] = [:]
        var scopedDataByScope: [HistoricalStatisticsScopeCacheKey: HistoricalWhistData] = [:]
        var playerTrends: [HistoricalStatisticsScopeCacheKey: [HistoricalPlayerTrendSummary]] = [:]
        var gameTypeTrends: [HistoricalStatisticsScopeCacheKey: [HistoricalGameTypeTrendSummary]] = [:]

        for scope in HistoricalStatisticsScope.allCases {
            for recentLimit in recentLimits {
                let key = HistoricalStatisticsScopeCacheKey(scope: scope, recentLimit: recentLimit)
                let scopedData = HistoricalStatisticsEngine.scopedData(
                    from: data,
                    scope: scope,
                    recentSessionLimit: recentLimit
                )
                snapshots[key] = HistoricalStatisticsEngine.snapshot(
                    from: data,
                    scope: scope,
                    recentSessionLimit: recentLimit
                )
                scopedDataByScope[key] = scopedData
                playerTrends[key] = HistoricalStatisticsEngine.playerTrendSummaries(from: scopedData)
                gameTypeTrends[key] = HistoricalStatisticsEngine.gameTypeTrendSummaries(from: scopedData)
            }
        }

        return (snapshots, scopedDataByScope, playerTrends, gameTypeTrends)
    }

    static func gameTypeOverviews(from data: HistoricalWhistData) -> [HistoricalGameTypeOverview] {
        let gamesByType = Dictionary(grouping: data.games.compactMap { game -> (type: String, game: HistoricalGame)? in
            guard let type = HistoricalGameTypeClassifier.canonicalGameType(for: game) else { return nil }
            return (type, game)
        }) { $0.type }
        let playersById = Dictionary(uniqueKeysWithValues: data.players.map { ($0.id, $0) })
        let sessionsById = Dictionary(uniqueKeysWithValues: data.sessions.map { ($0.id, $0) })
        let resultsByGame = Dictionary(grouping: data.playerResults, by: \.gameId)
        let allGameDetails = Dictionary(uniqueKeysWithValues: data.games.compactMap { game -> (String, HistoricalGameScoreDetail)? in
            let results = resultsByGame[game.id] ?? []
            guard let session = sessionsById[game.sessionId] else { return nil }
            let scores = results.compactMap { result -> HistoricalPlayerGameScore? in
                guard let player = playersById[result.playerId] else { return nil }
                return HistoricalPlayerGameScore(player: player, score: result.score)
            }
            return (
                game.id,
                HistoricalGameScoreDetail(
                    game: game,
                    session: session,
                    playerScores: scores,
                    selectedPlayerScore: nil,
                    qualityFlags: HistoricalStatisticsEngine.qualityFlags(for: game, playerScores: scores)
                )
            )
        })

        return gamesByType
            .filter { !$0.key.isEmpty }
            .map { type, groupedGames in
                let games = groupedGames.map { $0.game }
                let gameIds = Set(games.map(\.id))
                let matchingResults = data.playerResults.filter { gameIds.contains($0.gameId) }
                let playerScores = matchingResults
                    .reduce(into: [String: Int]()) { totals, result in
                        totals[result.playerId, default: 0] += result.score
                    }
                    .compactMap { playerId, score -> HistoricalPlayerGameScore? in
                        guard let player = playersById[playerId] else { return nil }
                        return HistoricalPlayerGameScore(player: player, score: score)
                    }
                let details = games.compactMap { allGameDetails[$0.id] }
                let playerResultCount = matchingResults.count
                let totalScore = playerScores.map(\.score).reduce(0, +)
                let playerResultGroups = Dictionary(grouping: matchingResults, by: \.playerId)
                let playerAverages = playerResultGroups.compactMap { playerId, results -> HistoricalGameTypePlayerAverage? in
                    guard let player = playersById[playerId] else { return nil }
                    let total = results.map(\.score).reduce(0, +)
                    return HistoricalGameTypePlayerAverage(
                        gameType: type,
                        player: player,
                        games: results.count,
                        totalScore: total,
                        averageScore: results.isEmpty ? 0 : Double(total) / Double(results.count)
                    )
                }
                .sorted { lhs, rhs in
                    if lhs.player.displayOrder != rhs.player.displayOrder {
                        return lhs.player.displayOrder < rhs.player.displayOrder
                    }
                    return lhs.player.name < rhs.player.name
                }

                return HistoricalGameTypeOverview(
                    gameType: type,
                    games: games.count,
                    playerResultCount: playerResultCount,
                    averageScore: playerResultCount > 0 ? Double(totalScore) / Double(playerResultCount) : 0,
                    gamesWithBidder: games.filter { $0.bidderId != nil || !$0.bidderIds.isEmpty }.count,
                    playerTotals: playerScores,
                    playerAverages: playerAverages,
                    gameDetails: details,
                    bestGame: details.max { lhs, rhs in
                        (lhs.playerScores.map(\.score).max() ?? 0) < (rhs.playerScores.map(\.score).max() ?? 0)
                    },
                    worstGame: details.min { lhs, rhs in
                        (lhs.playerScores.map(\.score).min() ?? 0) < (rhs.playerScores.map(\.score).min() ?? 0)
                    }
                )
            }
            .sorted { lhs, rhs in
                if lhs.games != rhs.games {
                    return lhs.games > rhs.games
                }
                return lhs.title < rhs.title
            }
    }
}

struct HistoricalStatisticsScopeCacheKey: Hashable {
    var scope: HistoricalStatisticsScope
    var recentLimit: Int
}

struct LiveStatisticsGameDaySnapshot: Equatable, Sendable {
    var id: UUID
    var createdAt: Date
    var title: String
    var endedAt: Date?
    var seatOrder: [Seat]
    var hands: [LiveStatisticsHandSnapshot]
    var hasPendingHand: Bool
}

struct LiveStatisticsHandSnapshot: Equatable, Sendable {
    var id: UUID
    var playedAt: Date
    var kindRaw: String
    var scoresBySeat: [Seat: Int]
    var bidderSeat: Seat?
    var partnerSeat: Seat?
    var handNumber: Int
    /// Rå resumeCaption fra RecordedHand – bruges til at udlede bidTricks og actualTricks.
    var resumeCaption: String
}

enum LiveHistoricalStatisticsAdapter {
    private static let sourceName = "SwiftData"
    private static let scoreSource = "live_local"

    @MainActor
    static func snapshots(from gameDays: [GameDay]) -> [LiveStatisticsGameDaySnapshot] {
        gameDays.map { day in
            LiveStatisticsGameDaySnapshot(
                id: day.id,
                createdAt: day.createdAt,
                title: day.title,
                endedAt: day.endedAt,
                seatOrder: day.seatOrder,
                hands: day.hands.map { hand in
                    LiveStatisticsHandSnapshot(
                        id: hand.id,
                        playedAt: hand.playedAt,
                        kindRaw: hand.kindRaw,
                        scoresBySeat: HandScorePersistence.decodeScores(hand.scoresBySeatJSON),
                        bidderSeat: Seat(rawValue: hand.bidderSeatRaw),
                        partnerSeat: Seat(rawValue: hand.partnerSeatRaw),
                        handNumber: hand.handNumber,
                        resumeCaption: hand.resumeCaption
                    )
                },
                hasPendingHand: day.pendingHand != nil
            )
        }
    }

    static func combinedData(
        historicalData: HistoricalWhistData,
        liveSnapshots: [LiveStatisticsGameDaySnapshot]
    ) -> HistoricalWhistData {
        let liveSnapshots = liveSnapshots
            .map { snapshot in
                var copy = snapshot
                copy.hands = orderedHands(snapshot.hands)
                return copy
            }
            .filter { !$0.hands.isEmpty }
            .sorted { lhs, rhs in
                if lhs.createdAt != rhs.createdAt {
                    return lhs.createdAt < rhs.createdAt
                }
                return lhs.id.uuidString < rhs.id.uuidString
            }

        guard !liveSnapshots.isEmpty else { return historicalData }

        let playersBySeat = playerMapping(players: historicalData.players)
        let sessionOffset = historicalData.sessions.count
        let liveSessions = liveSnapshots.enumerated().map { offset, snapshot in
            makeSession(
                from: snapshot,
                sessionNumber: "\(sessionOffset + offset + 1)"
            )
        }
        let sessionNumberById = Dictionary(uniqueKeysWithValues: liveSessions.map { ($0.id, $0.sessionNumber) })

        var liveGames: [HistoricalGame] = []
        var liveResults: [HistoricalPlayerResult] = []

        for snapshot in liveSnapshots {
            let sessionId = sessionId(for: snapshot.id)
            let sessionNumber = sessionNumberById[sessionId] ?? "\(sessionOffset + 1)"
            for (index, hand) in snapshot.hands.enumerated() {
                let handNumber = hand.handNumber > 0 ? hand.handNumber : index + 1
                let gameId = gameId(for: hand.id)
                let scoresByPlayer = scoresByPlayerId(
                    scoresBySeat: hand.scoresBySeat,
                    playersBySeat: playersBySeat
                )
                let checksum = scoresByPlayer.values.reduce(0, +)
                let gameType = canonicalLiveGameType(kindRaw: hand.kindRaw)
                let qualityFlags = qualityFlags(
                    hand: hand,
                    scoresByPlayerCount: scoresByPlayer.count,
                    checksum: checksum
                )

                let parsedBidTricks = parseBidTricks(from: hand.resumeCaption)
                let parsedActualTricks = parsedBidTricks.flatMap { bid in
                    parseDelta(from: hand.resumeCaption).map { delta in
                        max(0, min(13, bid + delta))
                    }
                }

                liveGames.append(
                    HistoricalGame(
                        id: gameId,
                        sessionId: sessionId,
                        sessionNumber: sessionNumber,
                        gameNumberInSession: handNumber,
                        sourceGameMarker: handNumber,
                        gameTypeRaw: hand.kindRaw,
                        gameTypeNormalized: gameType,
                        bidTricks: parsedBidTricks,
                        actualTricksTaken: parsedActualTricks,
                        bidderId: hand.bidderSeat.flatMap { playersBySeat[$0]?.id },
                        bidderIds: hand.bidderSeat.flatMap { playersBySeat[$0]?.id }.map { [$0] } ?? [],
                        winnerId: nil,
                        winnerIds: [],
                        partnerId: hand.partnerSeat.flatMap { playersBySeat[$0]?.id },
                        dealerId: dealerSeat(forHandNumber: handNumber, seatOrder: snapshot.seatOrder)
                            .flatMap { playersBySeat[$0]?.id },
                        checksum: checksum,
                        scoreSource: scoreSource,
                        sourceSheetName: sourceName,
                        sourceRow: handNumber,
                        qualityFlags: qualityFlags
                    )
                )

                liveResults.append(contentsOf: scoresByPlayer
                    .sorted { lhs, rhs in lhs.key < rhs.key }
                    .map { playerId, score in
                        HistoricalPlayerResult(
                            id: "\(gameId)-\(playerId)",
                            gameId: gameId,
                            playerId: playerId,
                            score: score,
                            sourceSheetName: sourceName,
                            sourceRow: handNumber
                        )
                    })
            }
        }

        return HistoricalWhistData(
            version: historicalData.version,
            generatedAt: historicalData.generatedAt,
            players: historicalData.players,
            sessions: historicalData.sessions + liveSessions,
            games: historicalData.games + liveGames,
            playerResults: historicalData.playerResults + liveResults,
            auditSummary: nil
        )
    }

    private static func playerMapping(players: [HistoricalPlayer]) -> [Seat: HistoricalPlayer] {
        let playersByName = Dictionary(uniqueKeysWithValues: players.map { (normalizedName($0.name), $0) })
        return Dictionary(uniqueKeysWithValues: Seat.all.compactMap { seat in
            guard let player = playersByName[normalizedName(seat.playerDisplayName)] else { return nil }
            return (seat, player)
        })
    }

    private static func scoresByPlayerId(
        scoresBySeat: [Seat: Int],
        playersBySeat: [Seat: HistoricalPlayer]
    ) -> [String: Int] {
        scoresBySeat.reduce(into: [String: Int]()) { output, entry in
            guard let player = playersBySeat[entry.key] else { return }
            output[player.id] = entry.value
        }
    }

    private static func makeSession(
        from snapshot: LiveStatisticsGameDaySnapshot,
        sessionNumber: String
    ) -> HistoricalSession {
        HistoricalSession(
            id: sessionId(for: snapshot.id),
            sessionNumber: sessionNumber,
            date: isoDateFormatter.string(from: snapshot.createdAt),
            location: snapshot.title.isEmpty ? nil : snapshot.title,
            sourceSheetName: sourceName,
            expectedGameCount: nil,
            importedGameCount: snapshot.hands.count,
            missingScoreRows: 0,
            qualityStatus: "live_local",
            cumulativeBlockStartColumn: nil,
            deltaBlockStartColumn: nil,
            preferredScoreBlockNumericRows: nil,
            headerRow: nil,
            columnMapping: nil
        )
    }

    private static func qualityFlags(
        hand: LiveStatisticsHandSnapshot,
        scoresByPlayerCount: Int,
        checksum: Int
    ) -> [String] {
        var flags: [String] = []
        if scoresByPlayerCount != Seat.all.count {
            flags.append("live_player_mapping_missing")
        }
        if checksum != 0 {
            flags.append(HistoricalDataQualityFlag.teamScoreMismatch.rawValue)
        }
        return flags
    }

    private static func canonicalLiveGameType(kindRaw: String) -> String? {
        switch kindRaw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "normal":
            return "Almindelige"
        case "sol":
            return "Sol"
        case "duty":
            return "Duestraf"
        default:
            return nil
        }
    }

    private static func orderedHands(_ hands: [LiveStatisticsHandSnapshot]) -> [LiveStatisticsHandSnapshot] {
        hands.sorted { lhs, rhs in
            if lhs.handNumber > 0, rhs.handNumber > 0, lhs.handNumber != rhs.handNumber {
                return lhs.handNumber < rhs.handNumber
            }
            if lhs.playedAt != rhs.playedAt {
                return lhs.playedAt < rhs.playedAt
            }
            return lhs.id.uuidString < rhs.id.uuidString
        }
    }

    private static func dealerSeat(forHandNumber handNumber: Int, seatOrder: [Seat]) -> Seat? {
        let order = seatOrder.isEmpty ? Seat.all : seatOrder
        guard !order.isEmpty else { return nil }
        return order[max(0, handNumber - 1) % order.count]
    }

    private static func sessionId(for id: UUID) -> String {
        "live-\(id.uuidString.lowercased())"
    }

    private static func gameId(for id: UUID) -> String {
        "live-\(id.uuidString.lowercased())"
    }

    private static func normalizedName(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    /// Parser antal meldte stik fra resumeCaption — format: "... meldte X ..."
    private static func parseBidTricks(from caption: String) -> Int? {
        guard let range = caption.range(of: "meldte ", options: [.caseInsensitive, .backwards]) else { return nil }
        let after = caption[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
        return after.split(separator: " ").first.flatMap { Int($0) }
    }

    /// Parser delta (faktiske stik minus meldte stik) fra resumeCaption — format: "... || ±N"
    private static func parseDelta(from caption: String) -> Int? {
        guard let range = caption.range(of: "||") else { return nil }
        let token = caption[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
        return Int(token)
    }

    private static let isoDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter
    }()
}

enum HistoricalGameTypeClassifier {
    static func canonicalGameType(for game: HistoricalGame) -> String? {
        let normalized = normalizedText(game.gameTypeNormalized)
        let raw = normalizedText(game.gameTypeRaw)
        let combined = "\(normalized) \(raw)"

        if combined.contains("halv bord") || combined.contains("halv bordlaeg") {
            return "Halv bordlægger"
        }
        if combined.contains("bordlægger") || combined.contains("bordlaegger") || combined.contains("bordlaegning") {
            return "Bordlægger"
        }
        if combined.contains("ren sol") || combined.contains("rent sol") || combined.contains("ren_sol") {
            return "Ren sol"
        }
        if combined.contains("sol") {
            return "Sol"
        }
        if combined.contains("vip") {
            return "VIP"
        }
        if combined.contains("sans") || combined.contains("sang") {
            return "Sans"
        }
        if combined.contains("gode") {
            return "Gode"
        }
        if combined.contains("halve") {
            return "Halve"
        }
        if normalized == "alm" || combined.contains(" almindelige") || combined.contains(" alm") || combined.hasPrefix("alm") {
            return "Almindelige"
        }
        if combined.contains("duestraf") || combined.contains("duefejl") || combined.contains("due fejl") {
            return "Duestraf"
        }

        return nil
    }

    private static func normalizedText(_ value: String?) -> String {
        value?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased() ?? ""
    }
}

struct HistoricalGameTypeOverview: Identifiable {
    var id: String { gameType }
    var gameType: String
    var games: Int
    var playerResultCount: Int
    var averageScore: Double
    var gamesWithBidder: Int
    var playerTotals: [HistoricalPlayerGameScore]
    var playerAverages: [HistoricalGameTypePlayerAverage]
    var gameDetails: [HistoricalGameScoreDetail]
    var bestGame: HistoricalGameScoreDetail?
    var worstGame: HistoricalGameScoreDetail?

    var title: String {
        gameType
    }

    var bestPlayer: HistoricalPlayerGameScore? {
        playerTotals.max { lhs, rhs in lhs.score < rhs.score }
    }
}
