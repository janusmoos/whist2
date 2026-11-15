import SwiftUI

struct HandNotePanel: View {
    let hand: RecordedHand

    var body: some View {
        if hand.hasNote {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: "note.text")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(ActiveGamePosterStyle.selectedGreenColor)

                    Text(noteTitle)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(ActiveGamePosterStyle.darkInkColor)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if !hand.trimmedNoteText.isEmpty {
                    Text(hand.trimmedNoteText)
                        .font(.subheadline)
                        .foregroundStyle(ActiveGamePosterStyle.darkInkColor.opacity(0.76))
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let createdAt = hand.noteCreatedAt {
                    Text(createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                    .fill(ActiveGamePosterStyle.panelColor)
            }
            .overlay {
                RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                    .strokeBorder(ActiveGamePosterStyle.borderColor, lineWidth: 1)
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var noteTitle: String {
        let title = hand.trimmedNoteTitle
        return title.isEmpty ? "Note" : title
    }
}
