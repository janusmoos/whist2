import SwiftUI

/// Hvordan «Seneste spil» vises på spilledagssiden.
enum SenesteSpilOversigtVisning: String, CaseIterable, Identifiable {
    case cards
    case table

    var id: String { rawValue }

    var menuTitle: String {
        switch self {
        case .cards: return "Kort"
        case .table: return "Tabel"
        }
    }
}

/// Diskret tabel: spillernavne i header, én række pr. kamp med point pr. spiller.
/// Accordion: **højst én** række viser resumé ad gangen.
struct SenesteSpilDiscreteTable: View {
    @Environment(\.colorScheme) private var colorScheme

    let gameDay: GameDay
    let hands: [RecordedHand]

    @State private var expandedHandID: UUID?

    private var seats: [Seat] {
        gameDay.seatOrder
    }

    /// Bred nok til `#` + tocifret kampnr. ved større tal-skrift.
    private let gameNumberColumnWidth: CGFloat = 52

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerRow
            ForEach(Array(hands.enumerated()), id: \.element.id) { index, hand in
                if index > 0 {
                    Divider()
                }
                accordionRow(hand: hand)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onAppear {
            if expandedHandID == nil, let first = hands.first {
                expandedHandID = first.id
            }
        }
        .onChange(of: hands.map(\.id)) { _, ids in
            if let id = expandedHandID, !ids.contains(id) {
                expandedHandID = hands.first?.id
            }
        }
    }

    private var headerRow: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 8) {
                Text(" ")
                    .frame(width: gameNumberColumnWidth, alignment: .leading)
                ForEach(seats, id: \.self) { seat in
                    Text(headerInitial(for: seat))
                        .font(tableNumberFont)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .accessibilityLabel(seat.playerDisplayName)
                }
                Color.clear.frame(width: 13, height: 1)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 4)
            Divider()
        }
    }

    private func accordionRow(hand: RecordedHand) -> some View {
        let scores = HandScorePersistence.decodeScores(hand.scoresBySeatJSON)
        let captionParts = HandResumeCaption.displayParts(for: hand)
        let isExpanded = expandedHandID == hand.id
        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.22)) {
                    expandedHandID = isExpanded ? nil : hand.id
                }
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    scoreRow(hand: hand, scores: scores)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .frame(width: 13)
                        .accessibilityHidden(true)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                resumeBox(captionParts: captionParts, hand: hand)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint(isExpanded ? "Skjul resumé" : "Vis resumé for kampen")
    }

    /// Resumé i mindre skrift, indrammet med lidt mørkere systemfyld.
    private func resumeBox(
        captionParts: HandResumeCaption.CaptionDisplayParts,
        hand: RecordedHand
    ) -> some View {
        let dateStr = hand.playedAt.formatted(date: .abbreviated, time: .shortened)
        return VStack(alignment: .leading, spacing: 6) {
            SuitColoredInlineText.build(captionParts.narrative, colorScheme: colorScheme)
                .font(.caption)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(captionParts.narrative). Spillet gemt \(dateStr)")
            HStack {
                Spacer(minLength: 0)
                Text(dateStr)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(.tertiarySystemFill))
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 8)
    }

    /// Fælles skrift for kampnr., point og header-forbogstaver.
    private var tableNumberFont: Font {
        .title3.weight(.semibold)
    }

    private func headerInitial(for seat: Seat) -> String {
        String(seat.playerDisplayName.prefix(1)).uppercased()
    }

    private func scoreRow(hand: RecordedHand, scores: [Seat: Int]) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(hand.handNumber > 0 ? "#\(hand.handNumber)" : "—")
                .font(tableNumberFont)
                .monospacedDigit()
                .foregroundStyle(.tertiary)
                .frame(width: gameNumberColumnWidth, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            ForEach(seats, id: \.self) { seat in
                let v = scores[seat] ?? 0
                Text(scoreCell(v))
                    .font(tableNumberFont)
                    .monospacedDigit()
                    .foregroundStyle(scoreForeground(v))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }
        }
    }

    private func scoreCell(_ value: Int) -> String {
        if value > 0 { return "+\(value)" }
        return "\(value)"
    }

    private func scoreForeground(_ value: Int) -> Color {
        if value > 0 { return Color.green.opacity(0.85) }
        if value < 0 { return Color.red.opacity(0.85) }
        return Color.secondary
    }
}
