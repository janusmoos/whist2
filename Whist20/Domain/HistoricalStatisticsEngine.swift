import Foundation

struct HistoricalPlayerScoreSummary: Equatable, Identifiable {
    var id: String { player.id }
    var player: HistoricalPlayer
    var totalScore: Int
    var gamesPlayed: Int
    var averageScore: Double
    var bestSingleGame: Int?
    var worstSingleGame: Int?
}

struct HistoricalStatisticsSnapshot: Equatable {
    var playerSummaries: [HistoricalPlayerScoreSummary]
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
    static func snapshot(from data: HistoricalWhistData) -> HistoricalStatisticsSnapshot {
        let summaries = playerScoreSummaries(from: data)
        let zeroSumCount = data.auditSummary?.fieldCounts.scoreSumZero
            ?? data.games.filter { ($0.checksum ?? 0) == 0 }.count

        return HistoricalStatisticsSnapshot(
            playerSummaries: summaries,
            sessionCount: data.sessions.count,
            gameCount: data.games.count,
            playerResultCount: data.playerResults.count,
            zeroSumGameCount: zeroSumCount,
            issueCount: data.auditSummary?.issueCount ?? 0,
            generatedAt: data.generatedAt,
            dataVersion: data.version
        )
    }

    static func playerScoreSummaries(from data: HistoricalWhistData) -> [HistoricalPlayerScoreSummary] {
        let groupedResults = Dictionary(grouping: data.playerResults, by: \.playerId)

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
                    worstSingleGame: scores.min()
                )
            }
            .sorted { lhs, rhs in
                if lhs.totalScore != rhs.totalScore {
                    return lhs.totalScore > rhs.totalScore
                }
                return lhs.player.displayOrder < rhs.player.displayOrder
            }
    }
}
