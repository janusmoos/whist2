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
            VStack(alignment: .leading, spacing: 20) {
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

                Text("Noterne er kun til jer i appen — de påvirker ikke point.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
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
        let day = GameDay(title: title, notes: notes)
        modelContext.insert(day)
        try? modelContext.save()
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
