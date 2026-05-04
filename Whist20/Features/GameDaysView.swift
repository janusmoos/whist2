import SwiftData
import SwiftUI

struct GameDaysView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.homeNavigationPath) private var homeNavigationPath
    @Query(sort: \GameDay.createdAt, order: .reverse) private var gameDays: [GameDay]

    @State private var showResumeBlocked = false
    @State private var showNeedsEndActiveFirst = false

    var body: some View {
        Group {
            if gameDays.isEmpty {
                ContentUnavailableView(
                    "Ingen spilledage endnu",
                    systemImage: "calendar",
                    description: Text("Brug «Ny spilledag» på forsiden. Spilledage gemmes på enheden.")
                )
            } else {
                List {
                    ForEach(gameDays, id: \.id) { day in
                        NavigationLink {
                            GameDayStartView(gameDay: day)
                        } label: {
                            HStack(alignment: .firstTextBaseline) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(day.title)
                                        .font(.headline)
                                    Text(day.createdAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer(minLength: 8)
                                statusBadge(for: day)
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if !day.isActive, GameDay.activeDay(in: gameDays) == nil {
                                Button {
                                    resume(day)
                                } label: {
                                    Label("Genoptag", systemImage: "arrow.uturn.backward.circle.fill")
                                }
                                .tint(.indigo)
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
                Button(action: requestNewGameDay) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Ny spilledag")
                .disabled(GameDay.activeDay(in: gameDays) != nil)
            }
        }
        .alert("Kan ikke genoptage", isPresented: $showResumeBlocked) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(GameDaySessionDialogs.resumeBlocked)
        }
        .alert("Afslut aktiv spilledag først", isPresented: $showNeedsEndActiveFirst) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Der er allerede en aktiv spilledag. Afslut den på forsiden, før I opretter en ny.")
        }
    }

    @ViewBuilder
    private func statusBadge(for day: GameDay) -> some View {
        if day.isActive {
            Text("Aktiv")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.22))
                .clipShape(Capsule())
        } else {
            Text("Afsluttet")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }

    private func requestNewGameDay() {
        guard GameDay.activeDay(in: gameDays) == nil else {
            showNeedsEndActiveFirst = true
            return
        }
        homeNavigationPath?.wrappedValue.append(HomeRoute.newGameDay)
    }

    private func resume(_ day: GameDay) {
        if day.resumeIfAllowed(allDays: gameDays, modelContext: modelContext) {
            return
        }
        showResumeBlocked = true
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
