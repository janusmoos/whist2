import SwiftData
import SwiftUI

struct GameDaysView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GameDay.createdAt, order: .reverse) private var gameDays: [GameDay]

    var body: some View {
        Group {
            if gameDays.isEmpty {
                ContentUnavailableView(
                    "Ingen spilledage endnu",
                    systemImage: "calendar",
                    description: Text("Tryk + for at oprette en spilledag. Den gemmes på enheden.")
                )
            } else {
                List {
                    ForEach(gameDays, id: \.id) { day in
                        NavigationLink {
                            GameDayStartView(gameDay: day)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(day.title)
                                    .font(.headline)
                                Text(day.createdAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: deleteDays)
                }
            }
        }
        .navigationTitle("Spilledage")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: addGameDay) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Ny spilledag")
            }
        }
    }

    private func addGameDay() {
        modelContext.insert(GameDay())
        try? modelContext.save()
    }

    private func deleteDays(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(gameDays[index])
        }
        try? modelContext.save()
    }
}

#Preview("Spilledage") {
    let schema = Schema([GameDay.self, RecordedHand.self, PendingHand.self])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [configuration])
    return NavigationStack {
        GameDaysView()
    }
    .modelContainer(container)
}
