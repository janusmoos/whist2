import Foundation
import SwiftData

@Model
final class PendingHand {
    @Attribute(.unique) var id: UUID
    var updatedAt: Date
    /// JSON fra `HandDraftPersistence`
    var draftJSON: String

    var gameDay: GameDay?

    init(id: UUID = UUID(), updatedAt: Date = Date(), draftJSON: String, gameDay: GameDay? = nil) {
        self.id = id
        self.updatedAt = updatedAt
        self.draftJSON = draftJSON
        self.gameDay = gameDay
    }
}
