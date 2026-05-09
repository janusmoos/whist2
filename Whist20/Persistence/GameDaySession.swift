import Foundation
import SwiftData

extension GameDay {

    var isActive: Bool {
        endedAt == nil
    }

    /// Højst én aktiv spilledag ad gangen.
    static func activeDay(in days: [GameDay]) -> GameDay? {
        days.first { $0.isActive }
    }

    func close(modelContext: ModelContext) {
        endedAt = Date()
        try? modelContext.save()
    }

    /// Genåbn spilledag. Returnerer `false`, hvis en **anden** spilledag allerede er aktiv.
    func resumeIfAllowed(allDays: [GameDay], modelContext: ModelContext) -> Bool {
        guard !isActive else { return true }
        if allDays.contains(where: { $0.id != id && $0.isActive }) {
            return false
        }
        endedAt = nil
        try? modelContext.save()
        return true
    }
}

enum GameDaySessionDialogs {
    static func endGameDayMessage(hasPendingHand: Bool) -> String {
        if hasPendingHand {
            return """
            Der er et spil undervejs (melding/resultat ikke gemt som kamp). Afslutter I alligevel, ligger kladden stadig under «Aktivt spil», når I genoptager spilledagen — men det er bedst at færdiggøre eller droppe spillet først.

            Vil I afslutte spilledagen?
            """
        }
        return "Spilledagen markeres som afsluttet. I kan genoptage den senere, så længe ingen anden spilledag er aktiv."
    }

    static let resumeBlocked = "En anden spilledag er allerede aktiv. Afslut den først, eller genoptag den afsluttede når der ikke er en aktiv dag."
}
