import Foundation
import SwiftData

@Model
final class GameDay {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var title: String
    /// Fritekst (sted, aftaler m.m.) — kun til visning i appen.
    var notes: String = ""
    /// `nil` = aktiv spilledag; sat dato = afsluttet (kan genoptages hvis ingen anden er aktiv).
    var endedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \RecordedHand.gameDay)
    var hands: [RecordedHand] = []

    /// Uafsluttet «tilføj spil» (melding/resultat) — højst én pr. spilledag.
    @Relationship(deleteRule: .cascade, inverse: \PendingHand.gameDay)
    var pendingHand: PendingHand?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        title: String = "Spilledag",
        notes: String = "",
        endedAt: Date? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.title = title
        self.notes = notes
        self.endedAt = endedAt
    }
}

extension GameDay {
    /// Akkumuleret score for alle gemte kampe på denne spilledag.
    var scoreStanding: GameDayStanding {
        GameDayScoreAggregation.standing(from: hands.map(\.scoreContribution))
    }

    /// Den spilledag der typisk er «aktuel»: seneste `playedAt` blandt kampe; ellers senest oprettede dag.
    static func focusForStandings(in days: [GameDay]) -> GameDay? {
        days.max { d1, d2 in
            let latest1 = d1.hands.map(\.playedAt).max()
            let latest2 = d2.hands.map(\.playedAt).max()
            switch (latest1, latest2) {
            case let (l1?, l2?) where l1 != l2:
                return l1 < l2
            case (_?, nil):
                return false
            case (nil, _?):
                return true
            default:
                return d1.createdAt < d2.createdAt
            }
        }
    }

    /// Sum af alle spilledages kamp-point pr. plads (nul-sum bevares pr. kamp, ikke nødvendigvis på tværs af dage).
    static func allTimeSeatTotals(days: [GameDay]) -> [Seat: Int] {
        var totals = Dictionary(uniqueKeysWithValues: Seat.all.map { ($0, 0) })
        for day in days {
            let dayTotals = day.scoreStanding.totalsBySeat
            for seat in Seat.all {
                totals[seat] = (totals[seat] ?? 0) + (dayTotals[seat] ?? 0)
            }
        }
        return totals
    }
}
