import Foundation

struct HistoricalStatisticsHubModel {
    var data: HistoricalWhistData
    var allSnapshot: HistoricalStatisticsSnapshot
    var currentOverview: HistoricalSessionOverview?
    var gameTypeCount: Int

    init(
        data: HistoricalWhistData,
        allSnapshot: HistoricalStatisticsSnapshot,
        currentOverview: HistoricalSessionOverview?,
        gameTypeCount: Int
    ) {
        self.data = data
        self.allSnapshot = allSnapshot
        self.currentOverview = currentOverview
        self.gameTypeCount = gameTypeCount
    }

    init(loader: HistoricalDataJSONLoader) throws {
        let prepared = try HistoricalStatisticsPreparer.prepareHubModel(loader: loader)
        self = prepared
    }
}

enum HistoricalStatisticsPreparer {
    static func prepareHubModel(loader: HistoricalDataJSONLoader) throws -> HistoricalStatisticsHubModel {
        let data = try loader.load()
        let allSnapshot = HistoricalStatisticsEngine.snapshot(from: data, scope: .all)
        let currentData = HistoricalStatisticsEngine.scopedData(from: data, scope: .current)
        let currentOverview = HistoricalStatisticsEngine.sessionOverviews(from: currentData).last
        let gameTypeCount = Set(data.games.compactMap(HistoricalGameTypeClassifier.canonicalGameType)).count

        return HistoricalStatisticsHubModel(
            data: data,
            allSnapshot: allSnapshot,
            currentOverview: currentOverview,
            gameTypeCount: gameTypeCount
        )
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
