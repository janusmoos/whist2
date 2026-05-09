import SwiftData
import SwiftUI

/// Læsevisning af kladde i `PendingHand` — nutidsform uden resultat (se `HandResumeCaption.presentTenseLine`).
struct ActiveGameView: View {
    @Bindable var gameDay: GameDay

    @Environment(\.colorScheme) private var colorScheme

    private var loadedDraft: (draft: HandInputDraft, stepRaw: String?)? {
        guard let json = gameDay.pendingHand?.draftJSON,
              let snap = try? HandDraftPersistence.decode(json) else {
            return nil
        }
        let d = HandInputDraft()
        HandDraftPersistence.apply(snap, to: d)
        return (d, snap.navigationStep)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(gameDay.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                if let (draft, step) = loadedDraft {
                    let resumeLine = HandResumeCaption.presentTenseLine(from: draft)
                    VStack(alignment: .leading, spacing: 12) {
                        SuitColoredInlineText.build(resumeLine, colorScheme: colorScheme)
                            .font(.title2.weight(.semibold))
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityLabel(resumeLine)

                        if draft.isDuty, draft.kind == .normal {
                            Text("Registreres som duestraf (erstatter spillets point).")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(activeGameResumeBackground())
                } else {
                    ContentUnavailableView(
                        "Ingen kladde lige nu",
                        systemImage: "tray",
                        description: Text(
                            "Når nogen åbner «Tilføj spil» og gemmer undervejs, vises den samme resumétekst her som efter et gemt spil."
                        )
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                }

                Text(
                    "På hver telefon vises den kladde, der er gemt dér. Fælles visning på tværs af telefoner kræver synk (fx iCloud) eller en server — se MULTI_DEVICE.md i projektet."
                )
                .font(.footnote)
                .foregroundStyle(.tertiary)
                .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle("Aktivt spil")
        .navigationBarTitleDisplayMode(.inline)
    }
}

@ViewBuilder
private func activeGameResumeBackground() -> some View {
    RoundedRectangle(cornerRadius: 16, style: .continuous)
        .fill(.thinMaterial)
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
        }
}
