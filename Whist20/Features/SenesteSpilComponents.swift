import SwiftUI

// MARK: - Seneste spil (fremhævet kort + kompakte rækker)

/// Stort resumé-kort for den senest afsluttede kamp (tap → fuld kampvisning).
struct FeaturedLatestHandCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let hand: RecordedHand

    private var scores: [Seat: Int] {
        HandScorePersistence.decodeScores(hand.scoresBySeatJSON)
    }

    private var orderedSeats: [Seat] {
        Seat.all.sorted { $0.rawValue < $1.rawValue }
    }

    private var captionParts: HandResumeCaption.CaptionDisplayParts {
        HandResumeCaption.displayParts(for: hand)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 14) {
                handNumberBadge
                VStack(alignment: .leading, spacing: 12) {
                    playerScoreGrid
                    SuitColoredInlineText.build(captionParts.narrative, colorScheme: colorScheme)
                        .font(.body.weight(.medium))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(captionAccessibilityLabel)

                    Text(hand.playedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .padding(.bottom, 4)
        }
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.accentColor.opacity(0.14),
                                    Color.accentColor.opacity(0.02),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .shadow(color: .black.opacity(0.07), radius: 12, x: 0, y: 4)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private var handNumberBadge: some View {
        Text(hand.handNumber > 0 ? "#\(hand.handNumber)" : "—")
            .font(.title2.weight(.heavy).monospacedDigit())
            .foregroundStyle(.primary)
            .frame(minWidth: 56)
            .padding(.vertical, 10)
            .padding(.horizontal, 8)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.accentColor.opacity(0.2))
            }
    }

    private var captionAccessibilityLabel: String {
        captionParts.narrative
    }

    private var bidderSeat: Seat? {
        guard hand.bidderSeatRaw >= 0, let s = Seat(rawValue: hand.bidderSeatRaw) else { return nil }
        guard hand.kindRaw == "normal" || hand.kindRaw == "sol" else { return nil }
        return s
    }

    private var playerScoreGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            ForEach(orderedSeats, id: \.self) { seat in
                let value = scores[seat] ?? 0
                let isBidder = bidderSeat == seat
                Text("\(seat.playerDisplayName) \(HandScoreChipStyle.scoreText(value))")
                    .font(isBidder ? .subheadline.weight(.bold) : .subheadline.weight(.semibold))
                    .textCase(isBidder ? .uppercase : nil)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .padding(.horizontal, 6)
                    .background {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(HandScoreChipStyle.background(for: value))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                    }
                    .accessibilityLabel(
                        isBidder
                            ? "\(seat.playerDisplayName), melder, \(HandScoreChipStyle.scoreText(value)) point"
                            : "\(seat.playerDisplayName), \(HandScoreChipStyle.scoreText(value)) point"
                    )
            }
        }
    }
}

/// Ultrakompakt linje: kampnr. + fire score-knapper; udvid viser resumé som talesprog (`HandResumeCaption`).
struct CompactHandDayRow: View {
    @Environment(\.colorScheme) private var colorScheme

    let hand: RecordedHand
    let isExpanded: Bool
    let onToggle: () -> Void

    private var scores: [Seat: Int] {
        HandScorePersistence.decodeScores(hand.scoresBySeatJSON)
    }

    private var orderedSeats: [Seat] {
        Seat.all.sorted { $0.rawValue < $1.rawValue }
    }

    private var captionParts: HandResumeCaption.CaptionDisplayParts {
        HandResumeCaption.displayParts(for: hand)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onToggle) {
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
                                        .fill(HandScoreChipStyle.background(for: value))
                                }
                                .overlay {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .strokeBorder(Color.primary.opacity(0.07), lineWidth: 1)
                                }
                                .accessibilityLabel(
                                    "\(seat.playerDisplayName) \(HandScoreChipStyle.scoreText(value)) point"
                                )
                        }
                    }
                    .frame(maxWidth: .infinity)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
                .padding(.vertical, 6)
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

                    Text(hand.playedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.leading, 46)
                .padding(.trailing, 4)
                .padding(.bottom, 10)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint(isExpanded ? "Skjul resumé" : "Vis resumé for kampen")
    }

    private func compactInitial(_ seat: Seat) -> String {
        String(seat.playerDisplayName.prefix(1))
    }

    private var expandedAccessibilityLabel: String {
        captionParts.narrative
    }
}

enum HandScoreChipStyle {
    static func scoreText(_ value: Int) -> String {
        if value > 0 { return "+\(value)" }
        return "\(value)"
    }

    static func background(for value: Int) -> Color {
        switch value {
        case let x where x > 0:
            return Color.green.opacity(0.32)
        case let x where x < 0:
            return Color.red.opacity(0.32)
        default:
            return Color.secondary.opacity(0.12)
        }
    }
}
