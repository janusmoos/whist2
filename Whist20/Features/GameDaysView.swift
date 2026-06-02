import SwiftData
import SwiftUI

struct GameDaysView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.homeNavigationPath) private var homeNavigationPath
    @Query(sort: \GameDay.createdAt, order: .reverse) private var gameDays: [GameDay]

    var navigationPath: Binding<NavigationPath>?

    @State private var showResumeBlocked = false
    @State private var showNeedsEndActiveFirst = false

    private var activeGameDay: GameDay? {
        GameDay.activeDay(in: gameDays)
    }

    private var finishedGameDays: [GameDay] {
        gameDays.filter { !$0.isActive }
    }

    var body: some View {
        Group {
            if gameDays.isEmpty {
                emptyState
            } else {
                List {
                    if activeGameDay == nil {
                        newGameDayButtonRow
                    }

                    if let activeGameDay {
                        sectionHeader("Denne spilledag")
                        gameDayRow(activeGameDay)
                    }

                    if !finishedGameDays.isEmpty {
                        sectionHeader("Afsluttede spilledage")
                        ForEach(finishedGameDays, id: \.id) { day in
                            gameDayRow(day)
                        }
                        .onDelete(perform: deleteFinishedDays)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color(uiColor: .systemGroupedBackground))
            }
        }
        .navigationTitle("Spilledage")
        .navigationBarTitleDisplayMode(.large)
        .alert("Kan ikke genoptage", isPresented: $showResumeBlocked) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(GameDaySessionDialogs.resumeBlocked)
        }
        .alert("Afslut aktiv spilledag først", isPresented: $showNeedsEndActiveFirst) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Der er allerede en aktiv spilledag. Afslut den her på Spilledage, før I opretter en ny.")
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 20) {
            ContentUnavailableView(
                "Ingen spilledage endnu",
                systemImage: "calendar",
                description: Text("Spilledage gemmes på enheden.")
            )
            Button(action: requestNewGameDay) {
                GameDayPrimaryButtonLabel(title: "Start ny spilledag", systemImage: "calendar.badge.plus")
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Listelementer

    private var newGameDayButtonRow: some View {
        Button(action: requestNewGameDay) {
            GameDayPrimaryButtonLabel(title: "Start ny spilledag", systemImage: "calendar.badge.plus")
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 4, trailing: 16))
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.custom(ActiveGamePosterStyle.fontName, size: 22))
            .foregroundStyle(ActiveGamePosterStyle.sectionHeaderColor)
            .frame(maxWidth: .infinity, alignment: .leading)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 20, leading: 20, bottom: 4, trailing: 16))
    }

    private func gameDayRow(_ day: GameDay) -> some View {
        NavigationLink(value: day.isActive ? HomeRoute.editGameDay(day.id) : HomeRoute.gameDay(day.id, openAddHand: false)) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(day.title)
                        .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 15).weight(.semibold))
                        .foregroundStyle(ActiveGamePosterStyle.darkInkColor)
                    Text(day.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 12))
                        .foregroundStyle(ActiveGamePosterStyle.darkInkColor.opacity(0.5))
                }

                Spacer(minLength: 8)
                statusBadge(for: day)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(ActiveGamePosterStyle.panelColor)
            .clipShape(RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                    .strokeBorder(ActiveGamePosterStyle.borderColor, lineWidth: 1)
            }
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if !day.isActive, GameDay.activeDay(in: gameDays) == nil {
                Button { resume(day) } label: {
                    Label("Genoptag", systemImage: "arrow.uturn.backward.circle.fill")
                }
                .tint(ActiveGamePosterStyle.selectedGreenColor)
            }
        }
    }

    @ViewBuilder
    private func statusBadge(for day: GameDay) -> some View {
        if day.isActive {
            HStack(spacing: 4) {
                Circle()
                    .fill(ActiveGamePosterStyle.selectedGreenColor)
                    .frame(width: 6, height: 6)
                Text("Aktiv")
                    .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 11).weight(.semibold))
                    .foregroundStyle(ActiveGamePosterStyle.selectedGreenColor)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(ActiveGamePosterStyle.selectedGreenColor.opacity(0.12))
            .clipShape(Capsule())
        } else {
            Text("\(day.hands.count) spil")
                .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 12))
                .foregroundStyle(ActiveGamePosterStyle.darkInkColor.opacity(0.4))
        }
    }

    // MARK: - Actions

    private func requestNewGameDay() {
        guard activeGameDay == nil else {
            showNeedsEndActiveFirst = true
            return
        }
        if let navigationPath {
            navigationPath.wrappedValue.append(HomeRoute.newGameDay)
        } else {
            homeNavigationPath?.wrappedValue.append(HomeRoute.newGameDay)
        }
    }

    private func resume(_ day: GameDay) {
        if day.resumeIfAllowed(allDays: gameDays, modelContext: modelContext) {
            return
        }
        showResumeBlocked = true
    }

    private func deleteFinishedDays(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(finishedGameDays[index])
        }
        try? modelContext.save()
    }
}

#Preview("Spilledage") {
    @Previewable @State var path = NavigationPath()
    let schema = Schema([GameDay.self, RecordedHand.self, PendingHand.self])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [configuration])
    return NavigationStack(path: $path) {
        GameDaysView()
    }
    .navigationDestination(for: HomeRoute.self) { route in
        switch route {
        case .gameDay(let id, _):
            Text("Preview spilledag \(id.uuidString.prefix(8))…")
        default:
            Text(String(describing: route))
        }
    }
    .environment(\.homeNavigationPath, $path)
    .modelContainer(container)
}
