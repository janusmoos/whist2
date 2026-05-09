import Foundation

struct HistoricalPlayerScoreSummary: Equatable, Identifiable {
    var id: String { player.id }
    var player: HistoricalPlayer
    var totalScore: Int
    var gamesPlayed: Int
    var averageScore: Double
    var bestSingleGame: Int?
    var worstSingleGame: Int?
    var bestSession: HistoricalPlayerSessionScore?
    var worstSession: HistoricalPlayerSessionScore?
}

enum HistoricalStatisticsScope: String, CaseIterable, Identifiable {
    case current
    case recent
    case all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .current: "Nuværende"
        case .recent: "Seneste 10"
        case .all: "Alle"
        }
    }

    func sessionLimit(recentLimit: Int) -> Int? {
        switch self {
        case .current: 1
        case .recent: max(1, recentLimit)
        case .all: nil
        }
    }
}

struct HistoricalPlayerSessionScore: Equatable, Identifiable {
    var id: String { "\(playerId)-\(sessionId)" }
    var playerId: String
    var sessionId: String
    var sessionTitle: String
    var sessionIndex: Int
    var score: Int
    var gamesInSession: Int
}

struct HistoricalScoreTimelinePoint: Equatable, Identifiable {
    var id: String { "\(playerId)-\(sessionId)" }
    var playerId: String
    var playerName: String
    var sessionId: String
    var sessionTitle: String
    var sessionIndex: Int
    var cumulativeScore: Int
    var sessionScore: Int
    var gamesInSession: Int
}

struct HistoricalStatisticsSnapshot: Equatable {
    var scope: HistoricalStatisticsScope
    var playerSummaries: [HistoricalPlayerScoreSummary]
    var timelinePoints: [HistoricalScoreTimelinePoint]
    var sessionCount: Int
    var gameCount: Int
    var playerResultCount: Int
    var zeroSumGameCount: Int
    var issueCount: Int
    var generatedAt: String
    var dataVersion: String

    var nonZeroSumGameCount: Int {
        max(0, gameCount - zeroSumGameCount)
    }
}

struct HistoricalGameScoreDetail: Equatable, Identifiable {
    var id: String { game.id }
    var game: HistoricalGame
    var session: HistoricalSession
    var playerScores: [HistoricalPlayerGameScore]
    var selectedPlayerScore: Int?

    var title: String {
        "Spil \(game.gameNumberInSession)"
    }
}

struct HistoricalPlayerGameScore: Equatable, Identifiable {
    var id: String { player.id }
    var player: HistoricalPlayer
    var score: Int
}

struct HistoricalPlayerBidStatistic: Equatable, Identifiable {
    var id: String { gameType }
    var gameType: String
    var games: Int
    var totalScore: Int
    var averageScore: Double
}

struct HistoricalPlayerProfile: Equatable, Identifiable {
    var id: String { player.id }
    var player: HistoricalPlayer
    var summary: HistoricalPlayerScoreSummary
    var sessionScores: [HistoricalPlayerSessionScore]
    var bestDay: HistoricalPlayerSessionScore?
    var worstDay: HistoricalPlayerSessionScore?
    var bestGame: HistoricalGameScoreDetail?
    var worstGame: HistoricalGameScoreDetail?
    var mostSuccessfulBid: HistoricalPlayerBidStatistic?
    var leastSuccessfulBid: HistoricalPlayerBidStatistic?
    var bidSampleSize: Int
    var gamesWithMetadata: Int
}

struct HistoricalSessionOverview: Equatable, Identifiable {
    var id: String { session.id }
    var session: HistoricalSession
    var sessionIndex: Int
    var gamesPlayed: Int
    var playerTotals: [HistoricalPlayerGameScore]
    var gameDetails: [HistoricalGameScoreDetail]
    var progressPoints: [HistoricalSessionProgressPoint]
    var bestGame: HistoricalGameScoreDetail?
    var worstGame: HistoricalGameScoreDetail?
    var gamesWithType: Int
    var gamesWithBidder: Int
    var gamesWithPartner: Int
    var issueCount: Int
}

struct HistoricalSessionProgressPoint: Equatable, Identifiable {
    var id: String { "\(player.id)-\(gameId)" }
    var player: HistoricalPlayer
    var gameId: String
    var gameNumber: Int
    var gameScore: Int
    var cumulativeScore: Int
}

struct HistoricalPlayerTrendSummary: Equatable, Identifiable {
    var id: String { player.id }
    var player: HistoricalPlayer
    var periodScore: Int
    var latestSessionScore: Int
    var averageSessionScore: Double
    var sessionsPlayed: Int
    var bestSession: HistoricalPlayerSessionScore?
    var worstSession: HistoricalPlayerSessionScore?
}

struct HistoricalGameTypePlayerAverage: Equatable, Identifiable {
    var id: String { "\(gameType)-\(player.id)" }
    var gameType: String
    var player: HistoricalPlayer
    var games: Int
    var totalScore: Int
    var averageScore: Double
}

struct HistoricalGameTypeTrendSummary: Equatable, Identifiable {
    var id: String { gameType }
    var gameType: String
    var games: Int
    var playerAverages: [HistoricalGameTypePlayerAverage]
    var bidOutcomeGames: Int
    var successfulBidGames: Int

    var successRate: Double? {
        guard bidOutcomeGames > 0 else { return nil }
        return Double(successfulBidGames) / Double(bidOutcomeGames)
    }
}

enum HistoricalStatisticsEngine {
    static func scopedData(
        from data: HistoricalWhistData,
        scope: HistoricalStatisticsScope,
        recentSessionLimit: Int = 10
    ) -> HistoricalWhistData {
        data.filtered(for: scope, recentSessionLimit: recentSessionLimit)
    }

    static func snapshot(
        from data: HistoricalWhistData,
        scope: HistoricalStatisticsScope = .all,
        recentSessionLimit: Int = 10
    ) -> HistoricalStatisticsSnapshot {
        let scopedData = data.filtered(for: scope, recentSessionLimit: recentSessionLimit)
        let summaries = playerScoreSummaries(from: scopedData)
        let zeroSumCount = scopedData.auditSummary?.fieldCounts.scoreSumZero
            ?? scopedData.games.filter { ($0.checksum ?? 0) == 0 }.count
        let issueCount = scopedData.auditSummary?.issueCount
            ?? scopedData.games.filter { !$0.qualityFlags.isEmpty }.count

        return HistoricalStatisticsSnapshot(
            scope: scope,
            playerSummaries: summaries,
            timelinePoints: scoreTimeline(from: scopedData),
            sessionCount: scopedData.sessions.count,
            gameCount: scopedData.games.count,
            playerResultCount: scopedData.playerResults.count,
            zeroSumGameCount: zeroSumCount,
            issueCount: issueCount,
            generatedAt: scopedData.generatedAt,
            dataVersion: scopedData.version
        )
    }

    static func playerScoreSummaries(from data: HistoricalWhistData) -> [HistoricalPlayerScoreSummary] {
        let groupedResults = Dictionary(grouping: data.playerResults, by: \.playerId)
        let sessionScoresByPlayer = playerSessionScores(from: data)

        return data.players
            .sorted { lhs, rhs in
                if lhs.displayOrder != rhs.displayOrder {
                    return lhs.displayOrder < rhs.displayOrder
                }
                return lhs.name < rhs.name
            }
            .map { player in
                let results = groupedResults[player.id] ?? []
                let scores = results.map(\.score)
                let total = scores.reduce(0, +)
                let count = scores.count
                return HistoricalPlayerScoreSummary(
                    player: player,
                    totalScore: total,
                    gamesPlayed: count,
                    averageScore: count > 0 ? Double(total) / Double(count) : 0,
                    bestSingleGame: scores.max(),
                    worstSingleGame: scores.min(),
                    bestSession: sessionScoresByPlayer[player.id]?.max { lhs, rhs in
                        if lhs.score != rhs.score {
                            return lhs.score < rhs.score
                        }
                        return lhs.sessionIndex > rhs.sessionIndex
                    },
                    worstSession: sessionScoresByPlayer[player.id]?.min { lhs, rhs in
                        if lhs.score != rhs.score {
                            return lhs.score < rhs.score
                        }
                        return lhs.sessionIndex > rhs.sessionIndex
                    }
                )
            }
            .sorted { lhs, rhs in
                if lhs.totalScore != rhs.totalScore {
                    return lhs.totalScore > rhs.totalScore
                }
                return lhs.player.displayOrder < rhs.player.displayOrder
            }
    }

    static func playerSessionScores(from data: HistoricalWhistData) -> [String: [HistoricalPlayerSessionScore]] {
        let players = data.players.sorted { lhs, rhs in
            if lhs.displayOrder != rhs.displayOrder {
                return lhs.displayOrder < rhs.displayOrder
            }
            return lhs.name < rhs.name
        }
        let gameById = Dictionary(uniqueKeysWithValues: data.games.map { ($0.id, $0) })
        let gamesBySession = Dictionary(grouping: data.games, by: \.sessionId)
        let sessionOrder = Dictionary(uniqueKeysWithValues: data.sessions.enumerated().map { ($0.element.id, $0.offset + 1) })

        var totalsBySessionAndPlayer: [String: [String: Int]] = [:]
        for result in data.playerResults {
            guard let game = gameById[result.gameId] else { continue }
            totalsBySessionAndPlayer[game.sessionId, default: [:]][result.playerId, default: 0] += result.score
        }

        var output: [String: [HistoricalPlayerSessionScore]] = [:]
        for session in data.sessions {
            let index = sessionOrder[session.id] ?? 0
            let gamesInSession = gamesBySession[session.id]?.count ?? session.importedGameCount
            let sessionTotals = totalsBySessionAndPlayer[session.id] ?? [:]
            for player in players {
                output[player.id, default: []].append(
                    HistoricalPlayerSessionScore(
                        playerId: player.id,
                        sessionId: session.id,
                        sessionTitle: sessionDisplayTitle(session),
                        sessionIndex: index,
                        score: sessionTotals[player.id] ?? 0,
                        gamesInSession: gamesInSession
                    )
                )
            }
        }
        return output
    }

    static func scoreTimeline(from data: HistoricalWhistData) -> [HistoricalScoreTimelinePoint] {
        let players = data.players.sorted { lhs, rhs in
            if lhs.displayOrder != rhs.displayOrder {
                return lhs.displayOrder < rhs.displayOrder
            }
            return lhs.name < rhs.name
        }
        let playerById = Dictionary(uniqueKeysWithValues: players.map { ($0.id, $0) })
        let gameById = Dictionary(uniqueKeysWithValues: data.games.map { ($0.id, $0) })
        let gamesBySession = Dictionary(grouping: data.games, by: \.sessionId)
        let sessionOrder = Dictionary(uniqueKeysWithValues: data.sessions.enumerated().map { ($0.element.id, $0.offset + 1) })

        var sessionTotalsByPlayer: [String: [String: Int]] = [:]
        for result in data.playerResults {
            guard let game = gameById[result.gameId] else { continue }
            sessionTotalsByPlayer[game.sessionId, default: [:]][result.playerId, default: 0] += result.score
        }

        var runningTotals = Dictionary(uniqueKeysWithValues: players.map { ($0.id, 0) })
        var points: [HistoricalScoreTimelinePoint] = []

        for session in data.sessions {
            let index = sessionOrder[session.id] ?? (points.count + 1)
            let sessionTotals = sessionTotalsByPlayer[session.id] ?? [:]
            let gamesInSession = gamesBySession[session.id]?.count ?? session.importedGameCount

            for player in players {
                let sessionScore = sessionTotals[player.id] ?? 0
                runningTotals[player.id, default: 0] += sessionScore
                points.append(
                    HistoricalScoreTimelinePoint(
                        playerId: player.id,
                        playerName: playerById[player.id]?.name ?? player.name,
                        sessionId: session.id,
                        sessionTitle: sessionDisplayTitle(session),
                        sessionIndex: index,
                        cumulativeScore: runningTotals[player.id] ?? 0,
                        sessionScore: sessionScore,
                        gamesInSession: gamesInSession
                    )
                )
            }
        }

        return points
    }

    static func playerProfiles(from data: HistoricalWhistData) -> [HistoricalPlayerProfile] {
        let summariesByPlayer = Dictionary(uniqueKeysWithValues: playerScoreSummaries(from: data).map { ($0.player.id, $0) })
        let sessionScoresByPlayer = playerSessionScores(from: data)
        let gameDetailsByGameId = Dictionary(uniqueKeysWithValues: gameDetails(from: data).map { ($0.game.id, $0) })
        let resultsByPlayer = Dictionary(grouping: data.playerResults, by: \.playerId)
        let gamesById = Dictionary(uniqueKeysWithValues: data.games.map { ($0.id, $0) })

        return data.players
            .sorted { lhs, rhs in
                if lhs.displayOrder != rhs.displayOrder {
                    return lhs.displayOrder < rhs.displayOrder
                }
                return lhs.name < rhs.name
            }
            .compactMap { player in
                guard let summary = summariesByPlayer[player.id] else { return nil }
                let playerResults = resultsByPlayer[player.id] ?? []
                let playerGameDetails = playerResults.compactMap { result -> HistoricalGameScoreDetail? in
                    guard var detail = gameDetailsByGameId[result.gameId] else { return nil }
                    detail.selectedPlayerScore = result.score
                    return detail
                }
                let bestGame = playerGameDetails.max { lhs, rhs in
                    gameScore(lhs) < gameScore(rhs)
                }
                let worstGame = playerGameDetails.min { lhs, rhs in
                    gameScore(lhs) < gameScore(rhs)
                }
                let bidStats = bidStatistics(for: player, playerResults: playerResults, gamesById: gamesById)

                return HistoricalPlayerProfile(
                    player: player,
                    summary: summary,
                    sessionScores: sessionScoresByPlayer[player.id] ?? [],
                    bestDay: summary.bestSession,
                    worstDay: summary.worstSession,
                    bestGame: bestGame,
                    worstGame: worstGame,
                    mostSuccessfulBid: bidStats.max { lhs, rhs in
                        if lhs.averageScore != rhs.averageScore {
                            return lhs.averageScore < rhs.averageScore
                        }
                        return lhs.games < rhs.games
                    },
                    leastSuccessfulBid: bidStats.min { lhs, rhs in
                        if lhs.averageScore != rhs.averageScore {
                            return lhs.averageScore < rhs.averageScore
                        }
                        return lhs.games < rhs.games
                    },
                    bidSampleSize: bidStats.map(\.games).reduce(0, +),
                    gamesWithMetadata: playerResults.filter { result in
                        guard let game = gamesById[result.gameId] else { return false }
                        return game.gameTypeNormalized != nil || game.bidderId != nil || !game.bidderIds.isEmpty
                    }.count
                )
            }
    }

    static func sessionOverviews(from data: HistoricalWhistData) -> [HistoricalSessionOverview] {
        let players = data.players.sorted { lhs, rhs in
            if lhs.displayOrder != rhs.displayOrder {
                return lhs.displayOrder < rhs.displayOrder
            }
            return lhs.name < rhs.name
        }
        let gamesBySession = Dictionary(grouping: data.games, by: \.sessionId)
        let gameDetailsById = Dictionary(uniqueKeysWithValues: gameDetails(from: data).map { ($0.game.id, $0) })
        let gameById = Dictionary(uniqueKeysWithValues: data.games.map { ($0.id, $0) })
        let resultsByGame = Dictionary(grouping: data.playerResults, by: \.gameId)
        var totalsBySessionAndPlayer: [String: [String: Int]] = [:]

        for result in data.playerResults {
            guard let game = gameById[result.gameId] else { continue }
            totalsBySessionAndPlayer[game.sessionId, default: [:]][result.playerId, default: 0] += result.score
        }

        return data.sessions.enumerated().map { offset, session in
            let games = (gamesBySession[session.id] ?? [])
                .sorted { lhs, rhs in lhs.gameNumberInSession < rhs.gameNumberInSession }
            let details = games.compactMap { gameDetailsById[$0.id] }
            let totals = totalsBySessionAndPlayer[session.id] ?? [:]
            var runningTotals = Dictionary(uniqueKeysWithValues: players.map { ($0.id, 0) })
            var progressPoints: [HistoricalSessionProgressPoint] = []

            for game in games {
                let scoresByPlayer = Dictionary(uniqueKeysWithValues: (resultsByGame[game.id] ?? []).map { ($0.playerId, $0.score) })
                for player in players {
                    let score = scoresByPlayer[player.id] ?? 0
                    runningTotals[player.id, default: 0] += score
                    progressPoints.append(
                        HistoricalSessionProgressPoint(
                            player: player,
                            gameId: game.id,
                            gameNumber: game.gameNumberInSession,
                            gameScore: score,
                            cumulativeScore: runningTotals[player.id] ?? 0
                        )
                    )
                }
            }

            return HistoricalSessionOverview(
                session: session,
                sessionIndex: offset + 1,
                gamesPlayed: games.count,
                playerTotals: players.map { player in
                    HistoricalPlayerGameScore(player: player, score: totals[player.id] ?? 0)
                },
                gameDetails: details,
                progressPoints: progressPoints,
                bestGame: details.max { lhs, rhs in
                    bestScore(lhs) < bestScore(rhs)
                },
                worstGame: details.min { lhs, rhs in
                    worstScore(lhs) < worstScore(rhs)
                },
                gamesWithType: games.filter { $0.gameTypeNormalized != nil }.count,
                gamesWithBidder: games.filter { $0.bidderId != nil || !$0.bidderIds.isEmpty }.count,
                gamesWithPartner: games.filter { $0.partnerId != nil }.count,
                issueCount: games.filter { !$0.qualityFlags.isEmpty }.count
            )
        }
    }

    static func playerTrendSummaries(from data: HistoricalWhistData) -> [HistoricalPlayerTrendSummary] {
        let sessionScoresByPlayer = playerSessionScores(from: data)

        return data.players
            .sorted { lhs, rhs in
                if lhs.displayOrder != rhs.displayOrder {
                    return lhs.displayOrder < rhs.displayOrder
                }
                return lhs.name < rhs.name
            }
            .map { player in
                let scores = sessionScoresByPlayer[player.id] ?? []
                let periodScore = scores.map(\.score).reduce(0, +)
                return HistoricalPlayerTrendSummary(
                    player: player,
                    periodScore: periodScore,
                    latestSessionScore: scores.last?.score ?? 0,
                    averageSessionScore: scores.isEmpty ? 0 : Double(periodScore) / Double(scores.count),
                    sessionsPlayed: scores.count,
                    bestSession: scores.max { lhs, rhs in
                        if lhs.score != rhs.score {
                            return lhs.score < rhs.score
                        }
                        return lhs.sessionIndex > rhs.sessionIndex
                    },
                    worstSession: scores.min { lhs, rhs in
                        if lhs.score != rhs.score {
                            return lhs.score < rhs.score
                        }
                        return lhs.sessionIndex > rhs.sessionIndex
                    }
                )
            }
            .sorted { lhs, rhs in
                if lhs.periodScore != rhs.periodScore {
                    return lhs.periodScore > rhs.periodScore
                }
                return lhs.player.displayOrder < rhs.player.displayOrder
            }
    }

    static func gameTypeTrendSummaries(from data: HistoricalWhistData) -> [HistoricalGameTypeTrendSummary] {
        let players = data.players.sorted { lhs, rhs in
            if lhs.displayOrder != rhs.displayOrder {
                return lhs.displayOrder < rhs.displayOrder
            }
            return lhs.name < rhs.name
        }
        let resultsByGame = Dictionary(grouping: data.playerResults, by: \.gameId)
        let gamesByType = Dictionary(grouping: data.games) { game in
            game.gameTypeNormalized?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        }

        return gamesByType
            .filter { !$0.key.isEmpty }
            .map { gameType, games in
                var successfulBidGames = 0
                var bidOutcomeGames = 0
                var totalsByPlayer: [String: (games: Int, total: Int)] = [:]

                for game in games {
                    let bidderIds = normalizedPlayerIds(game.bidderIds, fallback: game.bidderId)
                    let winnerIds = normalizedPlayerIds(game.winnerIds, fallback: game.winnerId)

                    if !bidderIds.isEmpty, !winnerIds.isEmpty {
                        bidOutcomeGames += 1
                        if !Set(bidderIds).isDisjoint(with: Set(winnerIds)) {
                            successfulBidGames += 1
                        }
                    }

                    for result in resultsByGame[game.id] ?? [] {
                        totalsByPlayer[result.playerId, default: (0, 0)].games += 1
                        totalsByPlayer[result.playerId, default: (0, 0)].total += result.score
                    }
                }

                return HistoricalGameTypeTrendSummary(
                    gameType: gameType,
                    games: games.count,
                    playerAverages: players.map { player in
                        let totals = totalsByPlayer[player.id] ?? (0, 0)
                        return HistoricalGameTypePlayerAverage(
                            gameType: gameType,
                            player: player,
                            games: totals.games,
                            totalScore: totals.total,
                            averageScore: totals.games > 0 ? Double(totals.total) / Double(totals.games) : 0
                        )
                    },
                    bidOutcomeGames: bidOutcomeGames,
                    successfulBidGames: successfulBidGames
                )
            }
            .sorted { lhs, rhs in
                if lhs.games != rhs.games {
                    return lhs.games > rhs.games
                }
                return lhs.gameType < rhs.gameType
            }
    }

    private static func sessionDisplayTitle(_ session: HistoricalSession) -> String {
        if let date = session.date, !date.isEmpty {
            return "#\(session.sessionNumber) · \(date)"
        }
        return "#\(session.sessionNumber) · \(session.sourceSheetName)"
    }

    private static func normalizedPlayerIds(_ ids: [String], fallback: String?) -> [String] {
        let normalizedIds = ids
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if !normalizedIds.isEmpty {
            return normalizedIds
        }
        guard let fallback = fallback?.trimmingCharacters(in: .whitespacesAndNewlines), !fallback.isEmpty else {
            return []
        }
        return [fallback]
    }

    private static func gameDetails(from data: HistoricalWhistData) -> [HistoricalGameScoreDetail] {
        let playersById = Dictionary(uniqueKeysWithValues: data.players.map { ($0.id, $0) })
        let sessionsById = Dictionary(uniqueKeysWithValues: data.sessions.map { ($0.id, $0) })
        let resultsByGame = Dictionary(grouping: data.playerResults, by: \.gameId)

        return data.games.compactMap { game in
            guard let session = sessionsById[game.sessionId] else { return nil }
            let scores = (resultsByGame[game.id] ?? [])
                .compactMap { result -> HistoricalPlayerGameScore? in
                    guard let player = playersById[result.playerId] else { return nil }
                    return HistoricalPlayerGameScore(player: player, score: result.score)
                }
                .sorted { lhs, rhs in
                    if lhs.player.displayOrder != rhs.player.displayOrder {
                        return lhs.player.displayOrder < rhs.player.displayOrder
                    }
                    return lhs.player.name < rhs.player.name
                }
            return HistoricalGameScoreDetail(
                game: game,
                session: session,
                playerScores: scores,
                selectedPlayerScore: nil
            )
        }
    }

    private static func bidStatistics(
        for player: HistoricalPlayer,
        playerResults: [HistoricalPlayerResult],
        gamesById: [String: HistoricalGame]
    ) -> [HistoricalPlayerBidStatistic] {
        var totalsByType: [String: (games: Int, total: Int)] = [:]

        for result in playerResults {
            guard let game = gamesById[result.gameId],
                  let gameType = game.gameTypeNormalized?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !gameType.isEmpty,
                  game.bidderIds.contains(player.id) || game.bidderId == player.id else {
                continue
            }
            totalsByType[gameType, default: (0, 0)].games += 1
            totalsByType[gameType, default: (0, 0)].total += result.score
        }

        return totalsByType.map { gameType, values in
            HistoricalPlayerBidStatistic(
                gameType: gameType,
                games: values.games,
                totalScore: values.total,
                averageScore: values.games > 0 ? Double(values.total) / Double(values.games) : 0
            )
        }
        .sorted { lhs, rhs in
            if lhs.averageScore != rhs.averageScore {
                return lhs.averageScore > rhs.averageScore
            }
            return lhs.gameType < rhs.gameType
        }
    }

    private static func gameScore(_ detail: HistoricalGameScoreDetail) -> Int {
        detail.selectedPlayerScore ?? 0
    }

    private static func bestScore(_ detail: HistoricalGameScoreDetail) -> Int {
        detail.playerScores.map(\.score).max() ?? 0
    }

    private static func worstScore(_ detail: HistoricalGameScoreDetail) -> Int {
        detail.playerScores.map(\.score).min() ?? 0
    }
}

private extension HistoricalWhistData {
    func filtered(for scope: HistoricalStatisticsScope, recentSessionLimit: Int) -> HistoricalWhistData {
        guard let limit = scope.sessionLimit(recentLimit: recentSessionLimit), sessions.count > limit else {
            return self
        }

        let scopedSessions = Array(sessions.suffix(limit))
        let sessionIds = Set(scopedSessions.map(\.id))
        let scopedGames = games.filter { sessionIds.contains($0.sessionId) }
        let gameIds = Set(scopedGames.map(\.id))
        let scopedResults = playerResults.filter { gameIds.contains($0.gameId) }

        return HistoricalWhistData(
            version: version,
            generatedAt: generatedAt,
            players: players,
            sessions: scopedSessions,
            games: scopedGames,
            playerResults: scopedResults,
            auditSummary: nil
        )
    }
}
