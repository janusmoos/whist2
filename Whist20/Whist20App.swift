import SwiftData
import SwiftUI

@main
struct Whist20App: App {
    private let modelContainer: ModelContainer = Self.makeModelContainer()

    /// Egen store-sti (ikke Apples default), så skemaændringer ikke kolliderer med ældre testfiler.
    private static func persistenceStoreURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("Whist20", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("game.store", isDirectory: false)
    }

    private static func removeStoreFiles(at storeURL: URL) {
        let fm = FileManager.default
        let paths = [
            storeURL,
            URL(fileURLWithPath: storeURL.path + "-shm"),
            URL(fileURLWithPath: storeURL.path + "-wal"),
        ]
        for url in paths {
            try? fm.removeItem(at: url)
        }
    }

    private static func makeModelContainer() -> ModelContainer {
        let schema = Schema([GameDay.self, RecordedHand.self, PendingHand.self])
        let storeURL = persistenceStoreURL()
        let configuration = ModelConfiguration(schema: schema, url: storeURL)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // Ofte uforeneligt skema efter modelændring — ryd denne butik og prøv én gang til.
            removeStoreFiles(at: storeURL)
            do {
                return try ModelContainer(for: schema, configurations: [configuration])
            } catch {
                fatalError("Kunne ikke starte SwiftData: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
