import Foundation
import SwiftData

@Model
final class GameDay {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var title: String

    @Relationship(deleteRule: .cascade, inverse: \RecordedHand.gameDay)
    var hands: [RecordedHand] = []

    /// Uafsluttet «tilføj spil» (melding/resultat) — højst én pr. spilledag.
    @Relationship(deleteRule: .cascade, inverse: \PendingHand.gameDay)
    var pendingHand: PendingHand?

    init(id: UUID = UUID(), createdAt: Date = Date(), title: String = "Spilledag") {
        self.id = id
        self.createdAt = createdAt
        self.title = title
    }
}
