import Foundation
import SwiftData

@Model
final class RecordedHand {
    @Attribute(.unique) var id: UUID
    var playedAt: Date
    /// "normal" | "sol" | "duty"
    var kindRaw: String
    var summaryLine: String
    /// JSON: seat rawValue (0…3) som string-nøgle → point
    var scoresBySeatJSON: String

    /// Kort spilbeskrivelse til «Seneste spil»-blok (tom for ældre gemte kampe).
    var resumeCaption: String = ""

    /// Melders plads (`Seat.rawValue`). `-1` = ukendt (ældre kampe).
    var bidderSeatRaw: Int = -1

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
        self.handNumber = handNumber
        self.gameDay = gameDay
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

    static func makeSummaryLine(kind: String, scores: [Seat: Int]) -> String {
        let bits = Seat.all.map { seat in
            let v = scores[seat] ?? 0
            let sign = v > 0 ? "+" : ""
            return "\(seat.playerDisplayName) \(sign)\(v)"
        }
        let prefix: String = {
            switch kind {
            case "normal": return "Normal"
            case "sol": return "Sol"
            case "duty": return "Duestraf"
            default: return "Spil"
            }
        }()
        return "\(prefix): \(bits.joined(separator: ", "))"
    }
}
