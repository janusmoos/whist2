import SwiftData
import SwiftUI

/// Viser den melding der ligger i `PendingHand` (samme data som «tilføj spil»-kladde). Lokalt på enheden.
struct ActiveGameView: View {
    @Bindable var gameDay: GameDay

    private var presentation: MeldingPresentation? {
        guard let json = gameDay.pendingHand?.draftJSON,
              let snap = try? HandDraftPersistence.decode(json) else {
            return nil
        }
        return MeldingPresentation.from(snapshot: snap)
    }

    var body: some View {
        Group {
            if let p = presentation {
                List {
                    Section {
                        MeldingStatusCard(presentation: p)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                    }

                    Section {
                        Text(
                            "Dette er den gemte kladde på denne telefon. Andre spillere ser det samme først når I synkroniserer (fx iCloud/CloudKit eller en fælles server). Se MULTI_DEVICE.md i projektroden."
                        )
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                }
            } else {
                ContentUnavailableView(
                    "Intet aktivt spil",
                    systemImage: "tray",
                    description: Text("Når nogen er begyndt på «Tilføj spil» uden at gemme, vises meldingen her. Start et nyt spil fra startsiden.")
                )
            }
        }
        .navigationTitle("Aktivt spil")
        .navigationBarTitleDisplayMode(.inline)
    }
}
