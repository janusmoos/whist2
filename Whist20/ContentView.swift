import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HomeView()
            .onAppear {
                GameDayEndedAtMigration.runIfNeeded(modelContext: modelContext)
            }
    }
}

#Preview {
    let schema = Schema([GameDay.self, RecordedHand.self, PendingHand.self])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [configuration])
    return ContentView()
        .modelContainer(container)
}
