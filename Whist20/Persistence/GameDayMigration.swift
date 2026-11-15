import Foundation
import SwiftData

/// Én gang: alle eksisterende spilledage markeres som afsluttet (`endedAt`), så ingen «aktiv» arves fra før feltet fandtes.
enum GameDayEndedAtMigration {
    private static let userDefaultsKey = "Whist20.GameDay.endedAtAllClosed.v1"

    static func runIfNeeded(modelContext: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: userDefaultsKey) else { return }

        let descriptor = FetchDescriptor<GameDay>()
        guard let days = try? modelContext.fetch(descriptor) else {
            UserDefaults.standard.set(true, forKey: userDefaultsKey)
            return
        }

        for day in days where day.endedAt == nil {
            day.endedAt = day.createdAt
        }

        try? modelContext.save()
        UserDefaults.standard.set(true, forKey: userDefaultsKey)
    }
}

/// Gør den officielle serverbackup tilgængelig i lokale visninger på enheder,
/// der ikke deltog i registreringen. Samme UUID forhindrer dubletter.
enum BundledServerGameDayMigration {
    private static let gameDayId = UUID(uuidString: "96CC63A7-E5B4-48D9-ACAC-318296D1BB72")!
    private static let historicalSessionId = "live-96cc63a7-e5b4-48d9-acac-318296d1bb72"
    private static let dealerCorrectionKey = "Whist20.WhistGus.firstDealer.v1"

    static func runIfNeeded(modelContext: ModelContext) {
        var descriptor = FetchDescriptor<GameDay>(
            predicate: #Predicate { $0.id == gameDayId }
        )
        descriptor.fetchLimit = 1
        if let existingDay = try? modelContext.fetch(descriptor).first {
            correctWhistGusDealerIfNeeded(existingDay, modelContext: modelContext)
            return
        }
        guard let data = try? HistoricalDataJSONLoader().load(),
              let session = data.sessions.first(where: { $0.id == historicalSessionId }) else {
            return
        }

        let games = data.games
            .filter { $0.sessionId == historicalSessionId }
            .sorted { $0.gameNumberInSession < $1.gameNumberInSession }
        guard !games.isEmpty else { return }

        let resultsByGame = Dictionary(grouping: data.playerResults, by: \.gameId)
        let seatByPlayerId = Dictionary(
            uniqueKeysWithValues: Seat.all.map { ($0.playerDisplayName, $0) }
        )
        let playedDates = games.compactMap { parseDate($0.playedAt) }
        let createdAt = playedDates.min() ?? parseDate(session.date) ?? Date()
        let endedAt = playedDates.max() ?? createdAt
        let day = GameDay(
            id: gameDayId,
            createdAt: createdAt,
            title: "Whist-gus",
            notes: "Whist og saunagus hos Peter",
            endedAt: endedAt,
            firstDealerSeatRaw: Seat.east.rawValue
        )
        modelContext.insert(day)

        for game in games {
            let scoreMap = Dictionary(
                uniqueKeysWithValues: (resultsByGame[game.id] ?? []).compactMap { result in
                    seatByPlayerId[result.playerId].map { ($0, result.score) }
                }
            )
            let caption = game.resumeCaption ?? "Spil #\(game.gameNumberInSession)"
            let bidderSeat = game.bidderId.flatMap { seatByPlayerId[$0] }
            let partnerSeat = game.partnerId.flatMap { seatByPlayerId[$0] }
            let hand = RecordedHand(
                playedAt: parseDate(game.playedAt) ?? createdAt,
                kindRaw: kindRaw(for: game.gameTypeNormalized),
                summaryLine: caption,
                scoresBySeatJSON: HandScorePersistence.encodeScores(scoreMap),
                resumeCaption: caption,
                bidderSeatRaw: bidderSeat?.rawValue ?? -1,
                partnerSeatRaw: partnerSeat?.rawValue ?? -1,
                handNumber: game.gameNumberInSession,
                gameDay: day
            )
            modelContext.insert(hand)
        }

        try? modelContext.save()
        UserDefaults.standard.set(true, forKey: dealerCorrectionKey)
    }

    private static func correctWhistGusDealerIfNeeded(
        _ gameDay: GameDay,
        modelContext: ModelContext
    ) {
        guard !UserDefaults.standard.bool(forKey: dealerCorrectionKey) else { return }
        gameDay.firstDealerSeatRaw = Seat.east.rawValue
        try? modelContext.save()
        UserDefaults.standard.set(true, forKey: dealerCorrectionKey)
    }

    private static func kindRaw(for gameType: String?) -> String {
        let value = gameType?.lowercased() ?? ""
        if value.contains("sol") || value.contains("bordlægger") {
            return "sol"
        }
        if value.contains("due") {
            return "duty"
        }
        return "normal"
    }

    private static func parseDate(_ value: String?) -> Date? {
        guard let value else { return nil }
        let withFractions = ISO8601DateFormatter()
        withFractions.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = withFractions.date(from: value) {
            return date
        }
        let standard = ISO8601DateFormatter()
        if let date = standard.date(from: value) {
            return date
        }
        let dayOnly = DateFormatter()
        dayOnly.locale = Locale(identifier: "en_US_POSIX")
        dayOnly.dateFormat = "yyyy-MM-dd"
        return dayOnly.date(from: value)
    }
}
