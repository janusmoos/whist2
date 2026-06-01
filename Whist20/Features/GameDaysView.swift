import SwiftData
import SwiftUI

struct GameDaysView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.homeNavigationPath) private var homeNavigationPath
    @Query(sort: \GameDay.createdAt, order: .reverse) private var gameDays: [GameDay]

    var navigationPath: Binding<NavigationPath>?

    @State private var showResumeBlocked = false
    @State private var showNeedsEndActiveFirst = false
    @State private var showEndGameDayConfirm = false

    private var activeGameDay: GameDay? {
        GameDay.activeDay(in: gameDays)
    }

    private var finishedGameDays: [GameDay] {
        gameDays.filter { !$0.isActive }
    }

    var body: some View {
        Group {
            if gameDays.isEmpty {
                ContentUnavailableView(
                    "Ingen spilledage endnu",
                    systemImage: "calendar",
                    description: Text("Spilledage gemmes på enheden.")
                )
            } else {
                List {
                    if let activeGameDay {
                        sectionTitle("Denne spilledag")

                        Section {
                            gameDayRow(activeGameDay)
                        }
                    }

                    if !finishedGameDays.isEmpty {
                        sectionTitle("Alle afsluttede spilledage")

                        Section {
                            ForEach(finishedGameDays, id: \.id) { day in
                                gameDayRow(day)
                            }
                            .onDelete(perform: deleteFinishedDays)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                Divider()
                Button(action: activeGameDay != nil ? { showEndGameDayConfirm = true } : requestNewGameDay) {
                    GameDayPrimaryButtonLabel(
                        title: activeGameDay != nil ? "Afslut denne spilledag" : "Start ny spilledag",
                        systemImage: activeGameDay != nil ? "xmark.circle" : "calendar.badge.plus",
                        tint: activeGameDay != nil ? ActiveGamePosterStyle.activeOrangeColor : ActiveGamePosterStyle.selectedGreenColor
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .background(Color(uiColor: .systemGroupedBackground))
        }
        .navigationTitle("Spilledage")
        .navigationBarTitleDisplayMode(.inline)
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
        .alert("Afslut spilledag?", isPresented: $showEndGameDayConfirm) {
            Button("Annuller", role: .cancel) {}
            Button("Afslut", role: .destructive) {
                activeGameDay?.close(modelContext: modelContext)
            }
        } message: {
            Text(
                GameDaySessionDialogs.endGameDayMessage(
                    hasPendingHand: activeGameDay?.pendingHand != nil
                )
            )
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.custom(ActiveGamePosterStyle.fontName, size: 32))
            .fontWidth(.compressed)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }

    private func gameDayRow(_ day: GameDay) -> some View {
        /// Samme `NavigationPath` som forsiden — undgår kæde af implicitte `destination:`-lag.
        NavigationLink(value: day.isActive ? HomeRoute.editGameDay(day.id) : HomeRoute.gameDay(day.id, openAddHand: false)) {
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

    @ViewBuilder
    private func statusBadge(for day: GameDay) -> some View {
        if day.isActive {
            Text("Aktiv")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(ActiveGamePosterStyle.positiveScoreColor.opacity(0.24))
                .clipShape(Capsule())
        } else {
            Text("Afsluttet")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }

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
