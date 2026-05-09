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

enum HistoricalStatisticsEngine {
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

    private static func sessionDisplayTitle(_ session: HistoricalSession) -> String {
        if let date = session.date, !date.isEmpty {
            return "#\(session.sessionNumber) · \(date)"
        }
        return "#\(session.sessionNumber) · \(session.sourceSheetName)"
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
