import Foundation
import SwiftData

@Model
final class RecordedHand {
    @Attribute(.unique) var id: UUID
    var playedAt: Date
    /// "normal" | "sol" | "duty"
    var kindRaw: String
    /// Synkroniseret med den viste resumé (`HandResumeCaption.displayResumeLine`); ældre rækker kan være punkt‑oversigt.
    var summaryLine: String
    /// JSON: seat rawValue (0…3) som string-nøgle → point
    var scoresBySeatJSON: String

    /// Kort spilbeskrivelse til «Seneste spil»-blok (tom for ældre gemte kampe).
    var resumeCaption: String = ""

    /// Melders plads (`Seat.rawValue`). `-1` = ukendt (ældre kampe).
    var bidderSeatRaw: Int = -1

    /// Makkers plads ved normale spil (`Seat.rawValue`). Lig med `bidderSeatRaw` ved selvmakker. `-1` = ukendt / ikke relevant (sol, duestraf, ældre data).
    var partnerSeatRaw: Int = -1

    /// JSON-array af makkersæders `rawValue` for sol (`goingWith`), fx `[1,2]`. Tom `[]` uden for sol.
    var solAlliesSeatsJSON: String = "[]"

    /// Løbenummer pr. spilledag (#1, #2, …). Sættes ved gem; ældre data får tal via `GameDay.migrateLegacyHandNumbersIfNeeded()`.
    var handNumber: Int = 0

    var gameDay: GameDay?

    init(
        id: UUID = UUID(),
        playedAt: Date = Date(),
        kindRaw: String,
        summaryLine: String,
        scoresBySeatJSON: String,
        resumeCaption: String = "",
        bidderSeatRaw: Int = -1,
        partnerSeatRaw: Int = -1,
        solAlliesSeatsJSON: String = "[]",
        handNumber: Int = 0,
        gameDay: GameDay? = nil
    ) {
        self.id = id
        self.playedAt = playedAt
        self.kindRaw = kindRaw
        self.summaryLine = summaryLine
        self.scoresBySeatJSON = scoresBySeatJSON
        self.resumeCaption = resumeCaption
        self.bidderSeatRaw = bidderSeatRaw
        self.partnerSeatRaw = partnerSeatRaw
        self.solAlliesSeatsJSON = solAlliesSeatsJSON
        self.handNumber = handNumber
        self.gameDay = gameDay
    }
}

extension RecordedHand {
    /// Én indgang: samme resumétekst som «Seneste spil» og kampdetaljer (bygger på `resumeCaption` + metadata).
    var displayResumeNarrative: String {
        HandResumeCaption.displayResumeLine(for: self)
    }

    /// Til summering af point pr. spilledag eller på tværs af dage.
    var scoreContribution: HandScoreContribution {
        HandScoreContribution(
            handNumber: handNumber,
            playedAt: playedAt,
            scoresBySeat: HandScorePersistence.decodeScores(scoresBySeatJSON)
        )
    }
}

extension GameDay {
    /// Tildeler 1…n efter `playedAt` til kampe uden gyldigt nummer (`handNumber < 1`).
    func migrateLegacyHandNumbersIfNeeded() {
        guard hands.contains(where: { $0.handNumber < 1 }) else { return }
        let asc = hands.sorted { $0.playedAt < $1.playedAt }
        for (i, h) in asc.enumerated() {
            h.handNumber = i + 1
        }
    }
}

enum HandScorePersistence {
    static func encodeScores(_ scores: [Seat: Int]) -> String {
        let dict = Dictionary(uniqueKeysWithValues: scores.map { (String($0.key.rawValue), $0.value) })
        guard let data = try? JSONEncoder().encode(dict),
              let str = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return str
    }

    static func decodeScores(_ json: String) -> [Seat: Int] {
        guard let data = json.data(using: .utf8),
              let dict = try? JSONDecoder().decode([String: Int].self, from: data) else {
            return [:]
        }
        var out: [Seat: Int] = [:]
        for (key, value) in dict {
            if let raw = Int(key), let seat = Seat(rawValue: raw) {
                out[seat] = value
            }
        }
        return out
    }
}
