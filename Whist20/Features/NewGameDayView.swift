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
            VStack(alignment: .leading, spacing: 10) {
                GameDayFieldPanel(title: "Navn") {
                    TextField("Fx «Lørdag hos Peter»", text: $titleText)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .textInputAutocapitalization(.sentences)
                }

                GameDayFieldPanel(title: "Noter (valgfrit)") {
                    TextField("Sted, mad, aftaler …", text: $notesText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .lineLimit(3...8)
                        .frame(minHeight: 76, alignment: .topLeading)
                }

                GameDayFieldPanel(title: "Rækkefølge ved bordet", contentPadding: 0) {
                    SeatOrderEditor(seatOrder: $seatOrder, isEditable: true)
                }

                Button {
                    saveGameDay()
                } label: {
                    GameDayPrimaryButtonLabel(title: "Gem spilledag", systemImage: "checkmark")
                }
                .buttonStyle(.plain)
                .disabled(trimmedTitle.isEmpty)
                .padding(.top, 6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 28)
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private var postSaveContent: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(ActiveGamePosterStyle.selectedGreenColor)
                        .frame(width: 86, height: 86)
                        .background {
                            Circle()
                                .fill(ActiveGamePosterStyle.selectedGreenColor.opacity(0.14))
                        }
                        .overlay {
                            Circle()
                                .strokeBorder(ActiveGamePosterStyle.selectedGreenColor.opacity(0.30), lineWidth: 1)
                        }
                        .accessibilityHidden(true)

                    VStack(spacing: 8) {
                        Text(savedTitle.uppercased())
                            .font(.custom(ActiveGamePosterStyle.fontName, size: 34))
                            .fontWidth(.compressed)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.62)
                            .foregroundStyle(ActiveGamePosterStyle.darkInkColor)

                        Text("Spilledagen er gemt")
                            .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 18))
                            .fontWeight(.semibold)
                            .foregroundStyle(ActiveGamePosterStyle.darkInkColor.opacity(0.78))

                        Text("I kan gå direkte til meldingen af jeres første kamp, eller åbne spilledagens oversigt.")
                            .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 15))
                            .foregroundStyle(ActiveGamePosterStyle.darkInkColor.opacity(0.66))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 22)
                .frame(maxWidth: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                        .fill(ActiveGamePosterStyle.panelColor)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                        .strokeBorder(ActiveGamePosterStyle.borderColor, lineWidth: 1)
                }

                VStack(spacing: 12) {
                    Button {
                        goToFirstHandMelding()
                    } label: {
                        GameDayPrimaryButtonLabel(title: "Start første spil", systemImage: "play.fill")
                    }
                    .buttonStyle(.plain)

                    Button {
                        goToGameDayHub()
                    } label: {
                        GameDaySecondaryButtonLabel(title: "Gå til spilledags-oversigt")
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 28)
            .frame(maxWidth: .infinity)
        }
        .background(Color(uiColor: .systemGroupedBackground))
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
            VStack(alignment: .leading, spacing: 10) {
                GameDayFieldPanel(title: "Navn") {
                    TextField("Fx «Lørdag hos Peter»", text: $titleText)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .textInputAutocapitalization(.sentences)
                }

                GameDayFieldPanel(title: "Noter (valgfrit)") {
                    TextField("Sted, mad, aftaler …", text: $notesText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .lineLimit(3...8)
                        .frame(minHeight: 76, alignment: .topLeading)
                }

                GameDayFieldPanel(title: "Rækkefølge ved bordet", contentPadding: 0) {
                    if !canEditSeatOrder {
                        Text("Rækkefølgen kan kun ændres, før der er gemt spil eller kladde på spilledagen.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 14)
                            .padding(.top, 12)
                    }

                    SeatOrderEditor(seatOrder: $seatOrder, isEditable: canEditSeatOrder)
                }

                Button {
                    saveChanges()
                } label: {
                    GameDayPrimaryButtonLabel(title: "Gem ændringer", systemImage: "checkmark")
                }
                .buttonStyle(.plain)
                .disabled(trimmedTitle.isEmpty)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 28)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Rediger spilledag")
        .navigationBarTitleDisplayMode(.inline)
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
                    Text("\(index + 1)")
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundStyle(ActiveGamePosterStyle.mutedInkColor)
                        .frame(width: 22)
                        .accessibilityHidden(true)

                    Text(seat.playerDisplayName)
                        .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 20))
                        .fontWeight(.semibold)
                        .foregroundStyle(ActiveGamePosterStyle.darkInkColor)

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
                    .foregroundStyle(isEditable ? ActiveGamePosterStyle.selectedGreenColor : .secondary)
                }
                .padding(.horizontal, 14)
                .frame(height: 50)
                .background(ActiveGamePosterStyle.panelColor)

                if index < seatOrder.count - 1 {
                    Divider()
                        .padding(.leading, 46)
                }
            }
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

