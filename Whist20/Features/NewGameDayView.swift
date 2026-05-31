import SwiftData
import SwiftUI

/// Opret spilledag med navn og noter; efter gem vises tydeligt valg om at gå direkte til melding.
struct NewGameDayView: View {
    @Binding var path: NavigationPath
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var titleText = ""
    @State private var notesText = ""
    @State private var didSave = false
    @State private var savedDayId: UUID?
    @State private var savedTitle = ""
    @State private var showAlreadyHasActiveDay = false
    @State private var seatOrder: [Seat] = Seat.all

    private var trimmedTitle: String {
        titleText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        Group {
            if didSave {
                postSaveContent
            } else {
                editFormContent
            }
        }
        .navigationTitle(didSave ? "Spilledag oprettet" : "Ny spilledag")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(didSave)
        .toolbar {
            if didSave {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Forside") {
                        path = NavigationPath()
                    }
                }
            } else {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuller") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Aktiv spilledag findes allerede", isPresented: $showAlreadyHasActiveDay) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Afslut den nuværende spilledag på forsiden før I opretter en ny.")
        }
    }

    private var editFormContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Giv spilledagen et navn og eventuelle noter. Du kan ændre det senere under spilledagens indstillinger.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Navn")
                        .font(.subheadline.weight(.semibold))
                    TextField("Fx «Lørdag hos Peter»", text: $titleText)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.sentences)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Noter (valgfrit)")
                        .font(.subheadline.weight(.semibold))
                    TextField("Sted, mad, aftaler …", text: $notesText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(4...10)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Rækkefølge ved bordet")
                        .font(.subheadline.weight(.semibold))

                    SeatOrderEditor(seatOrder: $seatOrder, isEditable: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                Divider()
                Button {
                    saveGameDay()
                } label: {
                    Text("Gem spilledag")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 52)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(trimmedTitle.isEmpty)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.bar)
            }
        }
    }

    private var postSaveContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.green, .secondary.opacity(0.35))
                    .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text("«\(savedTitle)» er gemt")
                        .font(.title3.weight(.bold))
                        .multilineTextAlignment(.center)
                    Text("I kan gå direkte til meldingen af jeres første kamp, eller åbne spilledagens oversigt.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 8)

                VStack(spacing: 12) {
                    Button {
                        goToFirstHandMelding()
                    } label: {
                        Label("Start spilledagens første spil", systemImage: "play.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 54)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button {
                        goToGameDayHub()
                    } label: {
                        Text("Gå til spilledags-oversigt")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
            .frame(maxWidth: .infinity)
        }
    }

    private func saveGameDay() {
        let title = trimmedTitle
        guard !title.isEmpty else { return }
        let descriptor = FetchDescriptor<GameDay>()
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        guard GameDay.activeDay(in: existing) == nil else {
            showAlreadyHasActiveDay = true
            return
        }
        let notes = notesText.trimmingCharacters(in: .whitespacesAndNewlines)
        let seatOrderJSON = (try? String(data: JSONEncoder().encode(seatOrder.map(\.rawValue)), encoding: .utf8)) ?? "[0,1,2,3]"
        let day = GameDay(title: title, notes: notes, seatOrderJSON: seatOrderJSON)
        modelContext.insert(day)
        try? modelContext.save()
        LiveSessionSyncCoordinator.shared.schedulePush(gameDayId: day.id, modelContext: modelContext)
        savedDayId = day.id
        savedTitle = title
        didSave = true
    }

    private func goToFirstHandMelding() {
        guard let id = savedDayId else { return }
        var newPath = NavigationPath()
        newPath.append(HomeRoute.gameDay(id, openAddHand: true))
        path = newPath
    }

    private func goToGameDayHub() {
        guard let id = savedDayId else { return }
        var newPath = NavigationPath()
        newPath.append(HomeRoute.gameDay(id, openAddHand: false))
        path = newPath
    }
}

struct GameDayEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var gameDay: GameDay

    @State private var titleText: String
    @State private var notesText: String
    @State private var seatOrder: [Seat]

    init(gameDay: GameDay) {
        self.gameDay = gameDay
        _titleText = State(initialValue: gameDay.title)
        _notesText = State(initialValue: gameDay.notes)
        _seatOrder = State(initialValue: gameDay.seatOrder)
    }

    private var trimmedTitle: String {
        titleText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedNotes: String {
        notesText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canEditSeatOrder: Bool {
        gameDay.hands.isEmpty && gameDay.pendingHand == nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Rediger navn, noter og bordrækkefølge for spilledagen.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Navn")
                        .font(.subheadline.weight(.semibold))
                    TextField("Fx «Lørdag hos Peter»", text: $titleText)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.sentences)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Noter (valgfrit)")
                        .font(.subheadline.weight(.semibold))
                    TextField("Sted, mad, aftaler …", text: $notesText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(4...10)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Rækkefølge ved bordet")
                        .font(.subheadline.weight(.semibold))

                    if !canEditSeatOrder {
                        Text("Rækkefølgen kan kun ændres, før der er gemt spil eller kladde på spilledagen.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    SeatOrderEditor(seatOrder: $seatOrder, isEditable: canEditSeatOrder)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
        .navigationTitle("Rediger spilledag")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                Divider()
                Button {
                    saveChanges()
                } label: {
                    Text("Gem ændringer")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 52)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(trimmedTitle.isEmpty)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.bar)
            }
        }
    }

    private func saveChanges() {
        guard !trimmedTitle.isEmpty else { return }
        gameDay.title = trimmedTitle
        gameDay.notes = trimmedNotes

        if canEditSeatOrder {
            gameDay.seatOrderJSON = (try? String(
                data: JSONEncoder().encode(seatOrder.map(\.rawValue)),
                encoding: .utf8
            )) ?? gameDay.seatOrderJSON
        }

        try? modelContext.save()
        dismiss()
    }
}

private struct SeatOrderEditor: View {
    @Binding var seatOrder: [Seat]
    var isEditable: Bool

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(seatOrder.enumerated()), id: \.element) { index, seat in
                HStack(spacing: 12) {
                    Image(systemName: isEditable ? "line.3.horizontal" : "lock.fill")
                        .foregroundStyle(.secondary)
                        .frame(width: 22)
                        .accessibilityHidden(true)

                    Text(seat.playerDisplayName)
                        .font(.body.weight(.medium))

                    Spacer(minLength: 12)

                    HStack(spacing: 4) {
                        Button {
                            moveSeat(from: index, by: -1)
                        } label: {
                            Image(systemName: "chevron.up")
                                .frame(width: 32, height: 32)
                        }
                        .buttonStyle(.plain)
                        .disabled(!isEditable || index == 0)
                        .accessibilityLabel("Flyt \(seat.playerDisplayName) op")

                        Button {
                            moveSeat(from: index, by: 1)
                        } label: {
                            Image(systemName: "chevron.down")
                                .frame(width: 32, height: 32)
                        }
                        .buttonStyle(.plain)
                        .disabled(!isEditable || index == seatOrder.count - 1)
                        .accessibilityLabel("Flyt \(seat.playerDisplayName) ned")
                    }
                    .foregroundStyle(isEditable ? Color.accentColor : .secondary)
                }
                .padding(.horizontal, 12)
                .frame(height: 48)
                .background(Color(uiColor: .secondarySystemGroupedBackground))

                if index < seatOrder.count - 1 {
                    Divider()
                        .padding(.leading, 46)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
    }

    private func moveSeat(from index: Int, by offset: Int) {
        let target = index + offset
        guard isEditable,
              seatOrder.indices.contains(index),
              seatOrder.indices.contains(target) else { return }
        withAnimation(.easeInOut(duration: 0.16)) {
            seatOrder.swapAt(index, target)
        }
    }
}
