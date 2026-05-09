import Foundation

struct HistoricalWhistData: Codable, Equatable {
    var version: String
    var generatedAt: String
    var players: [HistoricalPlayer]
    var sessions: [HistoricalSession]
    var games: [HistoricalGame]
    var playerResults: [HistoricalPlayerResult]
    var auditSummary: HistoricalAuditSummary?
}

struct HistoricalPlayer: Codable, Equatable, Identifiable {
    var id: String
    var name: String
    var displayOrder: Int
    var isActive: Bool
}

struct HistoricalSession: Codable, Equatable, Identifiable {
    var id: String
    var sessionNumber: String
    var date: String?
    var location: String?
    var sourceSheetName: String
    var expectedGameCount: Int?
    var importedGameCount: Int
    var missingScoreRows: Int
    var qualityStatus: String
    var cumulativeBlockStartColumn: Int?
    var deltaBlockStartColumn: Int?
    var preferredScoreBlockNumericRows: Int?
    var headerRow: Int?
    var columnMapping: HistoricalColumnMapping?
}

struct HistoricalColumnMapping: Codable, Equatable {
    var gameTypeCol: Int?
    var bidderCol: Int?
    var winnerCol: Int?
    var dealerCol: Int?
    var partnerCol: Int?

    private enum CodingKeys: String, CodingKey {
        case gameTypeCol = "game_type_col"
        case bidderCol = "bidder_col"
        case winnerCol = "winner_col"
        case dealerCol = "dealer_col"
        case partnerCol = "partner_col"
    }
}

struct HistoricalGame: Codable, Equatable, Identifiable {
    var id: String
    var sessionId: String
    var sessionNumber: String
    var gameNumberInSession: Int
    var sourceGameMarker: Int?
    var gameTypeRaw: String?
    var gameTypeNormalized: String?
    var bidTricks: Int?
    var bidderId: String?
    var bidderIds: [String]
    var winnerId: String?
    var winnerIds: [String]
    var partnerId: String?
    var dealerId: String?
    var checksum: Int?
    var scoreSource: String
    var sourceSheetName: String
    var sourceRow: Int
    var qualityFlags: [String]
}

struct HistoricalPlayerResult: Codable, Equatable, Identifiable {
    var id: String
    var gameId: String
    var playerId: String
    var score: Int
    var sourceSheetName: String
    var sourceRow: Int
}

struct HistoricalAuditSummary: Codable, Equatable {
    var version: String
    var sheetCount: Int
    var importedSessions: Int
    var importedGames: Int
    var playerResultRows: Int
    var playerTotals: [String: Int]
    var fieldCounts: HistoricalFieldCounts
    var issueCount: Int
    var issueCounts: [String: Int]
}

struct HistoricalFieldCounts: Codable, Equatable {
    var gameType: Int
    var dealer: Int
    var bidderOrWinner: Int
    var partner: Int
    var scoreSumZero: Int

    private enum CodingKeys: String, CodingKey {
        case gameType
        case dealer
        case bidderOrWinner = "bidder_or_winner"
        case partner
        case scoreSumZero = "score_sum_zero"
    }
}
