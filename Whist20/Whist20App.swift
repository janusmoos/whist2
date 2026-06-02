import SwiftData
import SwiftUI
import UIKit

@main
struct Whist20App: App {
    private let modelContainer: ModelContainer = Self.makeModelContainer()

    init() {
        Self.configureNavigationTypography()
        #if DEBUG
        Self.logLiveSyncConfig()
        #endif
    }

    #if DEBUG
    private static func logLiveSyncConfig() {
        let url = LiveSessionSyncSettings.baseURL?.absoluteString ?? "nil"
        let secretOK = LiveSessionSyncSettings.bearerSecret != nil
        print("""
        [LiveSync] baseURL   : \(url)
        [LiveSync] secret sat: \(secretOK)
        [LiveSync] konfigureret: \(LiveSessionSyncSettings.isConfigured)
        """)
    }
    #endif

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

    private static func configureNavigationTypography() {
        guard let titleFont = UIFont(name: ActiveGamePosterStyle.fontName, size: 19),
              let largeTitleFont = UIFont(name: ActiveGamePosterStyle.fontName, size: 42) else {
            return
        }

        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.titleTextAttributes = [
            .font: titleFont,
            .foregroundColor: UIColor.label,
        ]
        appearance.largeTitleTextAttributes = [
            .font: largeTitleFont,
            .foregroundColor: UIColor.label,
        ]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
