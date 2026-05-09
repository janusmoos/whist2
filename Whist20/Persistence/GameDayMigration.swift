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
