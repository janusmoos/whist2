import SwiftUI

// MARK: - Seneste spil (fremhævet kort + kompakte rækker)

/// Fælles top-række: kampnr. + fire score-chips som i de kompakte rækker.
/// Dato vises ikke her; den ligger i fold-ud-delen for kompakte rækker.
struct HandDayCompactTopLine: View {
    @Environment(\.colorScheme) private var colorScheme

    let hand: RecordedHand
    let gameDay: GameDay?
    var showsDate: Bool

    enum Trailing {
        case none
        case chevron(isUp: Bool)
    }
    var trailing: Trailing

    private var scores: [Seat: Int] {
        HandScorePersistence.decodeScores(hand.scoresBySeatJSON)
    }

    private var orderedSeats: [Seat] {
        gameDay?.seatOrder ?? Seat.all.sorted { $0.rawValue < $1.rawValue }
    }

    private var dateString: String {
        hand.playedAt.formatted(date: .abbreviated, time: .shortened)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Text(hand.handNumber > 0 ? "#\(hand.handNumber)" : "—")
                .font(.subheadline.weight(.bold).monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 36, alignment: .leading)

            HStack(spacing: 5) {
                ForEach(orderedSeats, id: \.self) { seat in
                    let value = scores[seat] ?? 0
                    Text("\(compactInitial(seat)) \(HandScoreChipStyle.scoreText(value))")
                        .font(.caption2.weight(.bold))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 4)
                        .background {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(HandScoreChipStyle.chipBackground(for: value, colorScheme: colorScheme))
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(HandScoreChipStyle.border(for: value), lineWidth: 1)
                        }
                        .accessibilityLabel(
                            "\(seat.playerDisplayName) \(HandScoreChipStyle.scoreText(value)) point"
                        )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if showsDate {
                Text(dateString)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
            }

            switch trailing {
            case .none:
                Color.clear.frame(width: 13, height: 1)
            case .chevron(let isUp):
                Image(systemName: isUp ? "chevron.up" : "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .frame(width: 13)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, 5)
    }

    private func compactInitial(_ seat: Seat) -> String {
        String(seat.playerDisplayName.prefix(1))
    }
}

/// Seneste kamp: samme top-række som øvrige, men resumé altid synligt og uden dato i UI.
struct FeaturedLatestHandCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let hand: RecordedHand
    let gameDay: GameDay?

    private var captionParts: HandResumeCaption.CaptionDisplayParts {
        HandResumeCaption.displayParts(for: hand)
    }

    private var playedAtFormatted: String {
        hand.playedAt.formatted(date: .abbreviated, time: .shortened)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HandDayCompactTopLine(
                hand: hand,
                gameDay: gameDay,
                showsDate: false,
                trailing: .none
            )
            SuitColoredInlineText.build(captionParts.narrative, colorScheme: colorScheme)
                .font(.subheadline)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 46)
                .padding(.trailing, 4)
                .padding(.bottom, 6)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(captionAccessibilityLabel)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(captionAccessibilityLabel). Spillet gemt \(playedAtFormatted)")
    }

    private var captionAccessibilityLabel: String {
        captionParts.narrative
    }
}

/// Ultrakompakt linje: kampnr. + fire score-knapper; udvid viser resumé som talesprog (`HandResumeCaption`).
struct CompactHandDayRow: View {
    @Environment(\.colorScheme) private var colorScheme

    let hand: RecordedHand
    let gameDay: GameDay?
    let isExpanded: Bool
    let onToggle: () -> Void

    private var captionParts: HandResumeCaption.CaptionDisplayParts {
        HandResumeCaption.displayParts(for: hand)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onToggle) {
                HandDayCompactTopLine(
                    hand: hand,
                    gameDay: gameDay,
                    showsDate: false,
                    trailing: .chevron(isUp: isExpanded)
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    SuitColoredInlineText.build(captionParts.narrative, colorScheme: colorScheme)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(expandedAccessibilityLabel)
                    HStack {
                        Spacer(minLength: 0)
                        Text(hand.playedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.trailing)
                            .accessibilityHidden(true)
                    }
                }
                .padding(.leading, 46)
                .padding(.trailing, 4)
                .padding(.bottom, 10)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint(isExpanded ? "Skjul resumé og dato" : "Vis resumé og dato for kampen")
    }

    private var expandedAccessibilityLabel: String {
        let dateStr = hand.playedAt.formatted(date: .abbreviated, time: .shortened)
        return "\(captionParts.narrative). Spillet gemt \(dateStr)"
    }
}

enum HandScoreChipStyle {
    static func scoreText(_ value: Int) -> String {
        if value > 0 { return "+\(value)" }
        return "\(value)"
    }

    /// Næsten hvid chip med meget svag grøn/rød tone; fortegn tydeliggøres stadig med kanten.
    static func chipBackground(for value: Int, colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .light:
            switch value {
            case _ where value > 0:
                return Color(red: 0.96, green: 0.99, blue: 0.97)
            case _ where value < 0:
                return Color(red: 0.99, green: 0.965, blue: 0.965)
            default:
                return Color.white
            }
        case .dark:
            switch value {
            case _ where value > 0:
                return Color(red: 0.20, green: 0.26, blue: 0.22)
            case _ where value < 0:
                return Color(red: 0.26, green: 0.20, blue: 0.20)
            default:
                return Color(white: 0.22)
            }
        @unknown default:
            return Color.white
        }
    }

    /// 1 px kant: grøn / rød / neutral efter fortegn.
    static func border(for value: Int) -> Color {
        if value > 0 { return Color.green }
        if value < 0 { return Color.red }
        return Color.secondary.opacity(0.45)
    }
}
