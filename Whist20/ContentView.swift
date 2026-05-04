import SwiftData
import SwiftUI

struct ContentView: View {
    var body: some View {
        HomeView()
    }
}

#Preview {
    let schema = Schema([GameDay.self, RecordedHand.self, PendingHand.self])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [configuration])
    return ContentView()
        .modelContainer(container)
}
