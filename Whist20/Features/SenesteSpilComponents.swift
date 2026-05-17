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

// MARK: - Seneste spil (fremhævet hero)

/// Stor, grafisk oversigt over den seneste kamp — point, kulører og roller.
struct SenesteSpilLatestHeroCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let hand: RecordedHand
    let gameDay: GameDay

    private var seats: [Seat] { gameDay.seatOrder }
    private var scores: [Seat: Int] {
        HandScorePersistence.decodeScores(hand.scoresBySeatJSON)
    }
    private var captionParts: HandResumeCaption.CaptionDisplayParts {
        HandResumeCaption.displayParts(for: hand)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerRow

            scoreArena
                .padding(.top, 22)

            rolesHint
                .padding(.top, 14)

            contractBadgeStrip
                .padding(.top, 20)

            SuitColoredInlineText.build(captionParts.narrative, colorScheme: colorScheme)
                .font(.body)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 22)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(captionParts.narrative)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.primary.opacity(0.14),
                            Color.primary.opacity(0.05),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.35 : 0.08), radius: 18, y: 10)
        .accessibilityElement(children: .combine)
    }

    private var headerRow: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(gameDay.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(hand.handNumber > 0 ? "Kamp nr. \(hand.handNumber)" : "Seneste kamp")
                    .font(.title2.weight(.bold))
            }
            Spacer(minLength: 12)
            Text(hand.playedAt.formatted(date: .abbreviated, time: .shortened))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }

    private var scoreArena: some View {
        HStack(alignment: .top, spacing: 10) {
            ForEach(seats, id: \.self) { seat in
                let value = scores[seat] ?? 0
                VStack(spacing: 12) {
                    Text(playerInitial(seat))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 56, height: 56)
                        .background {
                            Circle()
                                .fill(Color.accentColor.opacity(0.14))
                        }
                        .overlay {
                            Circle()
                                .strokeBorder(Color.accentColor.opacity(0.35), lineWidth: 1)
                        }
                        .accessibilityHidden(true)

                    Text(HandScoreChipStyle.scoreText(value))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(scoreHeroForeground(value))
                        .minimumScaleFactor(0.65)
                        .lineLimit(1)
                        .accessibilityLabel("\(seat.playerDisplayName) \(HandScoreChipStyle.scoreText(value)) point")
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var rolesHint: some View {
        HStack(spacing: 8) {
            ForEach(seats, id: \.self) { seat in
                VStack(spacing: 4) {
                    Text(seat.playerDisplayName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    if let tag = roleTag(for: seat) {
                        Text(tag)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color.accentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background {
                                Capsule().fill(Color.accentColor.opacity(0.12))
                            }
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    } else {
                        Text(" ")
                            .font(.caption2)
                            .accessibilityHidden(true)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private var contractBadgeStrip: some View {
        switch hand.kindRaw {
        case "duty":
            Label("Duestraf", systemImage: "flag.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.orange)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.orange.opacity(0.15))
                }
        case "sol":
            solBadgeRow
        default:
            normalContractBadges
        }
    }

    private var solBadgeRow: some View {
        let allies = SenesteSpilHeroParsing.solAllySeats(from: hand)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "person.3.sequence.fill")
                    .foregroundStyle(.purple)
                Text(SenesteSpilHeroParsing.solHeadline(from: captionParts.narrative))
                    .font(.subheadline.weight(.bold))
                Spacer(minLength: 0)
            }
            if !allies.isEmpty {
                FlowWrap(spacing: 8) {
                    ForEach(allies, id: \.self) { seat in
                        HStack(spacing: 6) {
                            Text(playerInitial(seat))
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                            Text(seat.playerDisplayName)
                                .font(.caption.weight(.semibold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background {
                            Capsule().fill(Color(.tertiarySystemFill))
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.purple.opacity(0.1))
        }
    }

    private var normalContractBadges: some View {
        let narrative = captionParts.narrative
        let kind = SenesteSpilHeroParsing.normalGameKindLabel(narrative)
        let trump = SenesteSpilHeroParsing.trumpSuit(narrative: narrative, hand: hand)
        let makkerEs = SenesteSpilHeroParsing.partnerAceSuit(narrative: narrative)
        let halveTil = SenesteSpilHeroParsing.halveColorSuit(narrative: narrative)
        let lower = narrative.lowercased()

        return FlowWrap(spacing: 10) {
            if kind == "Gode" {
                suitIconPill(title: "Gode", suit: .clubs)
            } else {
                contractKindPill(kind)
            }

            if let halveTil, makkerEs == nil, lower.contains("halve") {
                suitIconPill(title: "Halve til", suit: halveTil)
            }

            if let makkerEs {
                suitIconPill(title: "Makker-es", suit: makkerEs)
            }

            if let trump {
                suitIconPill(title: lower.contains("sans") ? "Farve" : "Trumf", suit: trump)
            }
        }
    }

    private func contractKindPill(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.bold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                Capsule().fill(Color(.tertiarySystemFill))
            }
    }

    private func suitIconPill(title: String, suit: Suit) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(suit.cardSymbol)
                .font(.title3.weight(.bold))
                .foregroundStyle(suit.playingCardForegroundColor(colorScheme: colorScheme))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.tertiarySystemGroupedBackground))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        }
        .accessibilityLabel("\(title) \(suit.rawValue)")
    }

    private func playerInitial(_ seat: Seat) -> String {
        String(seat.playerDisplayName.prefix(1)).uppercased()
    }

    private func scoreHeroForeground(_ value: Int) -> Color {
        if value > 0 { return Color.green }
        if value < 0 { return Color.red }
        return Color.secondary
    }

    private func roleTag(for seat: Seat) -> String? {
        guard hand.kindRaw == "normal" else { return nil }
        guard hand.bidderSeatRaw >= 0, let bidder = Seat(rawValue: hand.bidderSeatRaw) else { return nil }
        if seat == bidder {
            return hand.partnerSeatRaw >= 0 && hand.bidderSeatRaw == hand.partnerSeatRaw ? "Selvmakker" : "Melder"
        }
        if hand.partnerSeatRaw >= 0, seat == Seat(rawValue: hand.partnerSeatRaw), bidder != seat {
            return "Makker"
        }
        return nil
    }
}

// MARK: - Hero parsing / layout helpers

private enum SenesteSpilHeroParsing {
    static func normalGameKindLabel(_ narrative: String) -> String {
        let l = narrative.lowercased()
        if l.contains("vip") { return "VIP" }
        if l.contains("halve") { return "Halve" }
        if l.contains("sans") { return "Sans" }
        if l.contains("(gode)") || l.contains("♣ (gode)") { return "Gode" }
        if l.contains("almindelige") { return "Almindelig" }
        return "Spil"
    }

    static func trumpSuit(narrative: String, hand: RecordedHand) -> Suit? {
        guard hand.kindRaw == "normal" else { return nil }
        let lower = narrative.lowercased()
        if lower.contains("sans") { return nil }
        if lower.contains("(gode)") || lower.contains("♣ (gode)") { return nil }
        return lastSuit(in: narrative, beforePhrase: "som trumf")
    }

    static func partnerAceSuit(narrative: String) -> Suit? {
        lastSuit(in: narrative, beforePhrase: "som makker-es")
    }

    /// «halve til ♥ med …»
    static func halveColorSuit(narrative: String) -> Suit? {
        guard narrative.lowercased().contains("halve") else { return nil }
        guard let til = narrative.range(of: "til ") else { return nil }
        let rest = narrative[til.upperBound...]
        guard let med = rest.range(of: " med ") else { return nil }
        let slice = rest[..<med.lowerBound]
        return firstSuit(in: String(slice))
    }

    static func solHeadline(from narrative: String) -> String {
        let trimmed = narrative.trimmingCharacters(in: .whitespacesAndNewlines)
        if let dot = trimmed.firstIndex(of: ".") {
            return String(trimmed[..<dot])
        }
        let line = trimmed.split(separator: "\n").first.map(String.init) ?? trimmed
        return line.count > 80 ? String(line.prefix(77)) + "…" : line
    }

    static func solAllySeats(from hand: RecordedHand) -> [Seat] {
        guard hand.kindRaw == "sol",
              let data = hand.solAlliesSeatsJSON.data(using: .utf8),
              let rawInts = try? JSONDecoder().decode([Int].self, from: data) else {
            return []
        }
        return rawInts.compactMap { Seat(rawValue: $0) }.sorted { $0.rawValue < $1.rawValue }
    }

    private static func lastSuit(in string: String, beforePhrase phrase: String) -> Suit? {
        guard let range = string.range(of: phrase, options: .caseInsensitive) else { return nil }
        let before = string[..<range.lowerBound]
        return lastSuitSymbol(in: Substring(before))
    }

    private static func firstSuit(in string: String) -> Suit? {
        for ch in string where suit(for: ch) != nil {
            return suit(for: ch)
        }
        return nil
    }

    private static func lastSuitSymbol(in substring: Substring) -> Suit? {
        var last: Suit?
        for ch in substring {
            if let s = suit(for: ch) { last = s }
        }
        return last
    }

    private static func suit(for char: Character) -> Suit? {
        switch char {
        case "♠": return .spades
        case "♥": return .hearts
        case "♦": return .diamonds
        case "♣": return .clubs
        default: return nil
        }
    }
}

/// Simpel wrap af badges på flere linjer (uden eksterne pakker).
private struct FlowWrap<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: Content

    init(spacing: CGFloat = 8, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 120), spacing: spacing, alignment: .leading)],
            alignment: .leading,
            spacing: spacing
        ) {
            content
        }
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
