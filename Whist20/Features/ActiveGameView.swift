import SwiftData
import SwiftUI
import UIKit

enum ActiveGamePosterStyle {
    static let panelColor = dynamicColor(
        light: RGB(0.93, 0.91, 0.88),
        dark: RGB(0.18, 0.17, 0.15),
        lightHighContrast: RGB(0.96, 0.94, 0.90),
        darkHighContrast: RGB(0.13, 0.12, 0.11)
    )
    static let panelSecondaryColor = dynamicColor(
        light: RGB(0.97, 0.97, 0.96),
        dark: RGB(0.24, 0.23, 0.21),
        lightHighContrast: RGB(1.00, 0.99, 0.97),
        darkHighContrast: RGB(0.29, 0.28, 0.25)
    )
    static let tabBackCardColor = dynamicColor(
        light: RGB(0.74, 0.77, 0.69),
        dark: RGB(0.30, 0.34, 0.29),
        lightHighContrast: RGB(0.68, 0.72, 0.63),
        darkHighContrast: RGB(0.36, 0.42, 0.34)
    )
    static let borderColor = dynamicColor(
        light: RGB(0.70, 0.64, 0.56),
        dark: RGB(0.56, 0.50, 0.43),
        lightHighContrast: RGB(0.54, 0.47, 0.38),
        darkHighContrast: RGB(0.76, 0.69, 0.58)
    )
    static let highlightBorderColor = dynamicColor(
        light: RGB(1.0, 0.98, 0.94),
        dark: RGB(0.44, 0.40, 0.34),
        lightHighContrast: RGB(1.0, 0.99, 0.96),
        darkHighContrast: RGB(0.62, 0.56, 0.48)
    )
    static let darkInkColor = dynamicColor(
        light: RGB(0.10, 0.12, 0.16),
        dark: RGB(0.88, 0.86, 0.80),
        lightHighContrast: RGB(0.02, 0.03, 0.05),
        darkHighContrast: RGB(0.98, 0.96, 0.90)
    )
    static let mutedInkColor = dynamicColor(
        light: RGB(0.38, 0.36, 0.33),
        dark: RGB(0.68, 0.66, 0.60),
        lightHighContrast: RGB(0.23, 0.22, 0.20),
        darkHighContrast: RGB(0.84, 0.81, 0.74)
    )
    static let contrastTextOnColor = dynamicColor(
        light: RGB(1.00, 1.00, 1.00),
        dark: RGB(0.08, 0.07, 0.06),
        lightHighContrast: RGB(1.00, 1.00, 1.00),
        darkHighContrast: RGB(0.00, 0.00, 0.00)
    )
    static let textOnWarmAccentColor = dynamicColor(
        light: RGB(0.08, 0.07, 0.06),
        dark: RGB(0.08, 0.07, 0.06),
        lightHighContrast: RGB(0.00, 0.00, 0.00),
        darkHighContrast: RGB(0.00, 0.00, 0.00)
    )
    static let toastBackgroundColor = dynamicColor(
        light: RGB(0.10, 0.12, 0.16),
        dark: RGB(0.08, 0.08, 0.07),
        lightHighContrast: RGB(0.00, 0.00, 0.00),
        darkHighContrast: RGB(0.00, 0.00, 0.00)
    )
    static let toastForegroundColor = dynamicColor(
        light: RGB(1.00, 1.00, 1.00),
        dark: RGB(1.00, 1.00, 1.00),
        lightHighContrast: RGB(1.00, 1.00, 1.00),
        darkHighContrast: RGB(1.00, 1.00, 1.00)
    )
    static let contractMarkerColor = dynamicColor(
        light: RGB(0.32, 0.27, 0.22),
        dark: RGB(0.86, 0.76, 0.62),
        lightHighContrast: RGB(0.20, 0.16, 0.12),
        darkHighContrast: RGB(1.00, 0.88, 0.68)
    )
    static let selectedGreenColor = dynamicColor(
        light: RGB(0.10, 0.34, 0.27),
        dark: RGB(0.48, 0.78, 0.65),
        lightHighContrast: RGB(0.04, 0.26, 0.18),
        darkHighContrast: RGB(0.58, 0.95, 0.77)
    )
    static let activeOrangeColor = dynamicColor(
        light: RGB(0.93, 0.55, 0.05),
        dark: RGB(1.00, 0.65, 0.18),
        lightHighContrast: RGB(0.78, 0.40, 0.00),
        darkHighContrast: RGB(1.00, 0.77, 0.34)
    )
    static let positiveScoreColor = dynamicColor(
        light: RGB(0.10, 0.48, 0.23),
        dark: RGB(0.46, 0.86, 0.58),
        lightHighContrast: RGB(0.00, 0.36, 0.13),
        darkHighContrast: RGB(0.62, 1.00, 0.72)
    )
    static let negativeScoreColor = dynamicColor(
        light: RGB(0.72, 0.05, 0.10),
        dark: RGB(1.00, 0.46, 0.49),
        lightHighContrast: RGB(0.58, 0.00, 0.04),
        darkHighContrast: RGB(1.00, 0.61, 0.64)
    )
    static let neutralMeterColor = dynamicColor(
        light: RGB(0.72, 0.72, 0.72),
        dark: RGB(0.58, 0.58, 0.56),
        lightHighContrast: RGB(0.52, 0.52, 0.50),
        darkHighContrast: RGB(0.78, 0.78, 0.74)
    )
    static let sectionHeaderColor = dynamicColor(
        light: RGB(0.231, 0.290, 0.188),
        dark: RGB(0.58, 0.70, 0.52),
        lightHighContrast: RGB(0.18, 0.23, 0.14),
        darkHighContrast: RGB(0.72, 0.85, 0.64)
    )
    static let cornerRadius: CGFloat = 12
    static let fontName = "Anton-Regular"
    static let resumeFontName = "ArchivoRoman-Regular"

    private struct RGB {
        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat
        let alpha: CGFloat

        init(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, alpha: CGFloat = 1) {
            self.red = red
            self.green = green
            self.blue = blue
            self.alpha = alpha
        }
    }

    private static func dynamicColor(
        light: RGB,
        dark: RGB,
        lightHighContrast: RGB? = nil,
        darkHighContrast: RGB? = nil
    ) -> Color {
        Color(uiColor: UIColor { traits in
            let isDark = traits.userInterfaceStyle == .dark
            let isHighContrast = traits.accessibilityContrast == .high
            let value: RGB
            if isDark {
                value = isHighContrast ? (darkHighContrast ?? dark) : dark
            } else {
                value = isHighContrast ? (lightHighContrast ?? light) : light
            }
            return UIColor(red: value.red, green: value.green, blue: value.blue, alpha: value.alpha)
        })
    }
}

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

                if let (draft, _) = loadedDraft {
                    let resumeLine = ActiveGamePosterText.resumeLine(for: draft)
                    VStack(alignment: .leading, spacing: 12) {
                        ActiveGameCardIllustration(draft: draft)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if draft.kind != .sol {
                            ActiveGameResumePanel(resumeLine: resumeLine, colorScheme: colorScheme)
                        }

                        if draft.isDuty, draft.kind == .normal {
                            Text("Registreres som duestraf (erstatter spillets point).")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
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

            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle("Aktivt spil")
        .navigationBarTitleDisplayMode(.inline)
    }
}

enum ActiveGamePosterText {
    static func resumeLine(for draft: HandInputDraft) -> String {
        let line = HandResumeCaption.presentTenseLine(from: draft)
        guard draft.kind == .normal, !draft.isDuty else {
            return line
        }
        return "\(line) \(stikPriceText(for: draft))"
    }

    private static func stikPriceText(for draft: HandInputDraft) -> String {
        let basePrice: Int
        switch draft.bidTricks {
        case 8: basePrice = 1
        case 9: basePrice = 2
        case 10: basePrice = 4
        case 11: basePrice = 8
        case 12: basePrice = 16
        case 13: basePrice = 32
        default: basePrice = 0
        }

        let multiplier = draft.resolvedNormalGameType().baseMultiplier
        let price = basePrice * multiplier
        return "(\(price) kr/stik)"
    }

    static func resultResumeLine(for hand: RecordedHand) -> String {
        let prefix = hand.handNumber > 0 ? "Spil #\(hand.handNumber): " : "Spil: "
        let narrative = hand.displayResumeNarrative
        guard hand.isNormalStorslemResult else {
            return prefix + narrative
        }
        let cleaned = narrative
            .replacingOccurrences(of: " – STORSLEM", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: " - STORSLEM", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if bidderScore(for: hand) < 0 {
            return prefix + "STORSLEM! " + cleaned
        }
        guard let loserText = losingPlayersText(for: hand) else {
            return prefix + cleaned
        }
        return prefix + cleaned + ". Storslem til \(loserText)"
    }

    private static func bidderScore(for hand: RecordedHand) -> Int {
        let scores = HandScorePersistence.decodeScores(hand.scoresBySeatJSON)
        return Seat(rawValue: hand.bidderSeatRaw).flatMap { scores[$0] } ?? 0
    }

    private static func losingPlayersText(for hand: RecordedHand) -> String? {
        let scores = HandScorePersistence.decodeScores(hand.scoresBySeatJSON)
        let seats = hand.gameDay?.seatOrder ?? Seat.all.sorted { $0.rawValue < $1.rawValue }
        let names = seats
            .filter { (scores[$0] ?? 0) < 0 }
            .map(\.playerDisplayName)
        guard !names.isEmpty else { return nil }
        return danishNameList(names)
    }

    private static func danishNameList(_ names: [String]) -> String {
        switch names.count {
        case 0:
            return ""
        case 1:
            return names[0]
        case 2:
            return "\(names[0]) og \(names[1])"
        default:
            let head = names.dropLast().joined(separator: ", ")
            return "\(head) og \(names.last!)"
        }
    }
}

struct ActiveGameResumePanel: View {
    var resumeLine: String
    var colorScheme: ColorScheme

    var body: some View {
        SuitColoredInlineText.build(resumeLine, colorScheme: colorScheme, suitFontSize: 14)
            .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 16))
            .fontWidth(.compressed)
            .lineSpacing(1)
            .opacity(0.82)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .posterPanelStyle(
                panelColor: ActiveGamePosterStyle.panelColor,
                borderColor: ActiveGamePosterStyle.borderColor,
                cornerRadius: ActiveGamePosterStyle.cornerRadius
            )
            .accessibilityLabel(resumeLine)
    }
}

struct ActiveGameCardIllustration: View {
    var draft: HandInputDraft
    var isCompact = false

    private var trump: Suit? {
        draft.effectiveTrumpForScoring()
    }

    var body: some View {
        if draft.kind == .sol {
            ActiveGameSolPoster(
                bidderName: bidderName,
                solType: draft.solType,
                allyNames: solAllyNames,
                isCompact: isCompact
            )
        } else if draft.kind == .normal, draft.normalSubtype == .sans {
            ActiveGameTrumpPoster(
                bidderName: bidderName,
                bidTricks: draft.bidTricks,
                gameType: normalSubtypeText,
                trump: nil,
                partnerAceSuit: draft.partnerAceSuit,
                isCompact: isCompact
            )
        } else if draft.kind == .normal {
            ActiveGameTrumpPoster(
                bidderName: bidderName,
                bidTricks: draft.bidTricks,
                gameType: normalSubtypeText,
                trump: trump,
                partnerAceSuit: draft.partnerAceSuit,
                isTrumpPending: isTrumpPending,
                isCompact: isCompact
            )
        } else {
            HStack(alignment: .center, spacing: 14) {
                fallbackIllustration
                    .frame(width: 88, height: 124)

                VStack(alignment: .leading, spacing: 5) {
                    Text(primaryTitle)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(secondaryTitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(primaryTitle). \(secondaryTitle)")
        }
    }

    @ViewBuilder
    private var fallbackIllustration: some View {
        switch draft.kind {
        case .normal where draft.normalSubtype == .sans:
            CardShell(accent: .secondary.opacity(0.75)) {
                Text("\(draft.bidTricks)")
                    .font(.title2.weight(.bold).monospacedDigit())
                Text("Sans")
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
        case .normal:
            if let trump {
                CardShell(accent: trump.illustrationColor) {
                    Text("\(draft.bidTricks)")
                        .font(.title.weight(.bold).monospacedDigit())
                    Text(trump.cardSymbol)
                        .font(.system(size: 42, weight: .semibold))
                    Text(normalSubtypeText)
                        .font(.caption2.weight(.semibold))
                        .textCase(.uppercase)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            } else {
                CardShell(accent: .secondary.opacity(0.7), dashed: true) {
                    Text(normalSubtypeText)
                        .font(.headline.weight(.bold))
                        .multilineTextAlignment(.center)
                    Text("Trumf")
                        .font(.caption.weight(.semibold))
                    Text("mangler")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
        case .sol:
            CardShell(accent: Color(red: 0.92, green: 0.55, blue: 0.05)) {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 42, weight: .semibold))
                Text(solTypeText)
                    .font(.caption.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
            }
        case .duty:
            CardShell(accent: .orange, dashed: true) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2.weight(.semibold))
                Text("Duestraf")
                    .font(.caption.weight(.semibold))
            }
        }
    }

    private var primaryTitle: String {
        switch draft.kind {
        case .normal:
            return "\(draft.bidTricks) \(normalSubtypeText)"
        case .sol:
            return solTypeText
        case .duty:
            return "Duestraf"
        }
    }

    private var secondaryTitle: String {
        switch draft.kind {
        case .normal where draft.normalSubtype == .sans:
            return "Sans vises uden kulør."
        case .normal:
            if let trump {
                return "Illustrationen følger trumf: \(trump.rawValue)."
            }
            return "\(normalSubtypeText) venter på, at trumf bliver valgt."
        case .sol:
            return "Solspil vises med sol-grafik og variantnavn."
        case .duty:
            return "Duestraf vises som advarsel, ikke som trumfkort."
        }
    }

    private var normalSubtypeText: String {
        if draft.normalSubtype == .vip {
            switch draft.vipLevel {
            case .single: return "VIP i første"
            case .double: return "VIP i anden"
            case .triple: return "VIP i tredje"
            }
        }
        return draft.normalSubtype.title
    }

    private var bidderName: String {
        switch draft.kind {
        case .normal:
            return draft.bidder?.playerDisplayName ?? "Melder"
        case .sol:
            return draft.solBidder?.playerDisplayName ?? "Melder"
        case .duty:
            return draft.dutySeat?.playerDisplayName ?? "Spiller"
        }
    }

    private var solTypeText: String {
        switch draft.solType {
        case .normal:
            return "Sol"
        case .pure:
            return "Ren sol"
        case .halfDealer:
            return "½ bordlægger"
        case .dealer:
            return "Bordlægger"
        }
    }

    private var solAllyNames: [String] {
        draft.goingWith
            .sorted { $0.rawValue < $1.rawValue }
            .map(\.playerDisplayName)
    }

    private var isTrumpPending: Bool {
        guard draft.kind == .normal else { return false }
        guard draft.normalSubtype == .halve || draft.normalSubtype == .vip else { return false }
        return trump == nil
    }
}

struct RecordedHandCardIllustration: View {
    @Environment(\.colorScheme) private var colorScheme

    var hand: RecordedHand
    var isCompact = false

    private var posterContent: PosterContent? {
        PosterContent(hand: hand)
    }

    private var solPosterContent: SolPosterContent? {
        SolPosterContent(hand: hand)
    }

    private var scoreItems: [ActiveGamePosterScoreItem] {
        let scores = HandScorePersistence.decodeScores(hand.scoresBySeatJSON)
        let seats = hand.gameDay?.seatOrder ?? Seat.all.sorted { $0.rawValue < $1.rawValue }
        let bidder = Seat(rawValue: hand.bidderSeatRaw)
        let partner = hand.kindRaw == "normal" ? Seat(rawValue: hand.partnerSeatRaw) : nil
        let solAllies = hand.kindRaw == "sol" ? Self.solAllies(for: hand) : []
        let bidderScore = bidder.flatMap { scores[$0] } ?? 0
        let showsLoserStorslemRibbon = hand.isNormalStorslemResult && bidderScore > 0
        return seats.map { seat in
            let score = scores[seat] ?? 0
            return ActiveGamePosterScoreItem(
                name: seat.playerDisplayName,
                score: score,
                role: Self.scoreRole(for: seat, handKind: hand.kindRaw, bidder: bidder, partner: partner, solAllies: solAllies),
                storslemRibbon: showsLoserStorslemRibbon && score < 0
            )
        }
    }

    private var bidderScore: Int {
        let scores = HandScorePersistence.decodeScores(hand.scoresBySeatJSON)
        return Seat(rawValue: hand.bidderSeatRaw).flatMap { scores[$0] } ?? 0
    }

    private static func scoreRole(
        for seat: Seat,
        handKind: String,
        bidder: Seat?,
        partner: Seat?,
        solAllies: Set<Seat>
    ) -> ActiveGamePosterScoreRole {
        if handKind == "sol", solAllies.contains(seat), seat != bidder {
            return .partner
        }
        if seat == bidder {
            return .bidder
        }
        if handKind == "normal", let partner, partner != bidder, seat == partner {
            return .partner
        }
        return .none
    }

    private static func solAllies(for hand: RecordedHand) -> Set<Seat> {
        guard let data = hand.solAlliesSeatsJSON.data(using: .utf8),
              let rawSeats = try? JSONDecoder().decode([Int].self, from: data) else {
            return []
        }
        return Set(rawSeats.compactMap { Seat(rawValue: $0) })
    }

    private var topPanelBorderColor: Color {
        if bidderScore > 0 {
            return ActiveGamePosterStyle.positiveScoreColor
        }
        if bidderScore < 0 {
            return ActiveGamePosterStyle.negativeScoreColor
        }
        return ActiveGamePosterStyle.borderColor
    }

    var body: some View {
        if let posterContent {
            ActiveGameTrumpPoster(
                bidderName: posterContent.bidderName,
                actionText: "MELDTE",
                bidTricks: posterContent.bidTricks,
                gameType: posterContent.gameType,
                trump: posterContent.trump,
                partnerAceSuit: posterContent.partnerAceSuit,
                scoreItems: scoreItems,
                topPanelBorderColor: ActiveGamePosterStyle.borderColor,
                actionColor: topPanelBorderColor,
                actualTricks: posterContent.actualTricks,
                showsTopStorslemRibbon: hand.isNormalStorslemResult && bidderScore < 0,
                isCompact: isCompact
            )
        } else if let solPosterContent {
            ActiveGameSolPoster(
                bidderName: solPosterContent.bidderName,
                actionText: "MELDTE",
                solType: solPosterContent.solType,
                allyNames: solPosterContent.allyNames,
                scoreItems: scoreItems,
                topPanelBorderColor: ActiveGamePosterStyle.borderColor,
                actionColor: topPanelBorderColor,
                isCompact: isCompact
            )
        } else {
            SuitColoredInlineText.build(ActiveGamePosterText.resultResumeLine(for: hand), colorScheme: colorScheme)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .posterPanelStyle(
                    panelColor: ActiveGamePosterStyle.panelColor,
                    borderColor: ActiveGamePosterStyle.borderColor,
                    cornerRadius: ActiveGamePosterStyle.cornerRadius
                )
        }
    }

    private struct PosterContent {
        var bidderName: String
        var bidTricks: Int
        var gameType: String
        var trump: Suit?
        var partnerAceSuit: Suit?
        var actualTricks: Int?

        init?(hand: RecordedHand) {
            guard hand.kindRaw == "normal" else { return nil }
            let narrative = hand.displayResumeNarrative
            guard let bidTricks = Self.parseBidTricks(from: narrative) else {
                return nil
            }
            self.bidderName = Seat(rawValue: hand.bidderSeatRaw)?.playerDisplayName ?? "Melder"
            self.bidTricks = bidTricks
            self.gameType = Self.parseGameType(from: narrative)
            self.trump = Self.parseTrump(from: narrative)
            self.partnerAceSuit = Self.parsePartnerAceSuit(from: narrative)
                ?? hand.partnerAceSuitRaw.flatMap { Suit(rawValue: $0) }
            self.actualTricks = Self.parseActualTricks(bidTricks: bidTricks, resumeCaption: hand.resumeCaption)
        }

        private static func parseBidTricks(from narrative: String) -> Int? {
            let markers = ["meldte ", "melder "]
            for marker in markers {
                if let range = narrative.range(of: marker, options: [.backwards, .caseInsensitive]) {
                    let after = narrative[range.upperBound...].trimmingCharacters(in: .whitespaces)
                    if let bid = after.split(separator: " ").first.flatMap({ Int($0) }) {
                        return bid
                    }
                }
            }
            return nil
        }

        private static func parseGameType(from narrative: String) -> String {
            let lower = narrative.lowercased()
            if lower.contains("vip i tredje") || lower.contains("vip 3") { return "VIP i tredje" }
            if lower.contains("vip i anden") || lower.contains("vip 2") { return "VIP i anden" }
            if lower.contains("vip i første") || lower.contains("vip 1") || lower.contains("vip") { return "VIP i første" }
            if lower.contains("gode") { return "Gode" }
            if lower.contains("halve") { return "Halve" }
            if lower.contains("sans") { return "Sans" }
            if lower.contains("almindelige") { return "Almindelige" }
            return "Spil"
        }

        private static func parseTrump(from narrative: String) -> Suit? {
            let lower = narrative.lowercased()
            if lower.contains("sans") { return nil }
            if lower.contains("gode") { return .clubs }
            guard let range = narrative.range(of: "som trumf", options: .caseInsensitive) else { return nil }
            return lastSuitSymbol(in: String(narrative[..<range.lowerBound]))
        }

        private static func parsePartnerAceSuit(from narrative: String) -> Suit? {
            if let range = narrative.range(of: "som makker-es", options: .caseInsensitive) {
                return lastSuitSymbol(in: String(narrative[..<range.lowerBound]))
            }
            guard let range = narrative.range(of: " til ", options: .caseInsensitive) else { return nil }
            let after = String(narrative[range.upperBound...])
            return firstSuitSymbol(in: after)
        }

        private static func firstSuitSymbol(in text: String) -> Suit? {
            text.compactMap { suit(for: $0) }.first
        }

        private static func lastSuitSymbol(in text: String) -> Suit? {
            text.compactMap { suit(for: $0) }.last
        }

        private static func suit(for character: Character) -> Suit? {
            switch character {
            case "♠": return .spades
            case "♥": return .hearts
            case "♦": return .diamonds
            case "♣": return .clubs
            default: return nil
            }
        }

        private static func parseActualTricks(bidTricks: Int, resumeCaption: String) -> Int? {
            guard let range = resumeCaption.range(of: "||") else { return nil }
            let token = resumeCaption[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
            guard let delta = Int(token) else { return nil }
            return max(0, min(13, bidTricks + delta))
        }
    }

    private struct SolPosterContent {
        var bidderName: String
        var solType: SolType
        var allyNames: [String]

        init?(hand: RecordedHand) {
            guard hand.kindRaw == "sol" else { return nil }
            self.bidderName = Seat(rawValue: hand.bidderSeatRaw)?.playerDisplayName ?? "Melder"
            self.solType = Self.parseSolType(from: hand.displayResumeNarrative)
            self.allyNames = Self.parseAllyNames(from: hand)
        }

        private static func parseSolType(from narrative: String) -> SolType {
            let lower = narrative.lowercased()
            if lower.contains("halv bordlægger") || lower.contains("halv-bordlægger") {
                return .halfDealer
            }
            if lower.contains("bordlægger") {
                return .dealer
            }
            if lower.contains("ren sol") || lower.contains("ren-sol") {
                return .pure
            }
            return .normal
        }

        private static func parseAllyNames(from hand: RecordedHand) -> [String] {
            guard let data = hand.solAlliesSeatsJSON.data(using: .utf8),
                  let rawSeats = try? JSONDecoder().decode([Int].self, from: data) else {
                return []
            }
            return rawSeats
                .compactMap { Seat(rawValue: $0) }
                .sorted { $0.rawValue < $1.rawValue }
                .map(\.playerDisplayName)
        }
    }
}

private struct ActiveGameSolPoster: View {
    var bidderName: String
    var actionText = "MELDER"
    var solType: SolType
    var allyNames: [String] = []
    var scoreItems: [ActiveGamePosterScoreItem] = []
    var topPanelBorderColor = ActiveGamePosterStyle.borderColor
    var actionColor: Color?
    var isCompact = false

    private let iconColor = ActiveGamePosterStyle.darkInkColor

    var body: some View {
        VStack(spacing: verticalSpacing) {
            topPanel

            if !scoreItems.isEmpty {
                ActiveGamePosterScoreStrip(items: scoreItems, isCompact: isCompact)
            }

            if let allyText {
                allyPanel(text: allyText)
            }
        }
        .frame(height: posterHeight)
        .clipped()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var topPanel: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: textLineSpacing) {
                posterText(bidderName.uppercased())
                    .lineLimit(1)
                    .minimumScaleFactor(0.42)
                posterActionText(actionText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
                posterText(solTypeText.uppercased(), size: solTypeFontSize)
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)
            }
            .padding(.leading, 14)
            .padding(.vertical, isCompact ? 12 : 14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

            SolGameIcon(solType: solType, color: iconColor)
                .frame(width: solIconSize, height: solIconSize)
                .frame(width: solIconColumnWidth, alignment: .center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: topPanelHeight)
        .posterPanelStyle(
            panelColor: ActiveGamePosterStyle.panelColor,
            borderColor: topPanelBorderColor,
            cornerRadius: ActiveGamePosterStyle.cornerRadius,
            borderWidth: 1
        )
        .clipped()
    }

    private func allyPanel(text: String) -> some View {
        Text(text.uppercased())
            .font(.custom(ActiveGamePosterStyle.fontName, size: solTypeFontSize))
            .fontWidth(.compressed)
            .foregroundStyle(ActiveGamePosterStyle.darkInkColor)
            .lineLimit(1)
            .minimumScaleFactor(0.55)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .frame(height: allyPanelHeight, alignment: .center)
            .posterPanelStyle(
                panelColor: ActiveGamePosterStyle.panelColor,
                borderColor: ActiveGamePosterStyle.borderColor,
                cornerRadius: ActiveGamePosterStyle.cornerRadius
            )
    }

    private func posterText(_ text: String, size: CGFloat? = nil) -> some View {
        Text(text)
            .font(.custom(ActiveGamePosterStyle.fontName, size: size ?? posterFontSize))
            .fontWidth(.compressed)
            .foregroundStyle(ActiveGamePosterStyle.darkInkColor)
    }

    @ViewBuilder
    private func posterActionText(_ text: String) -> some View {
        if let actionColor {
            Text(text)
                .font(.custom(ActiveGamePosterStyle.fontName, size: posterFontSize))
                .fontWidth(.compressed)
                .tracking(1.2)
                .foregroundStyle(actionColor)
        } else {
            posterOutlineText(text)
        }
    }

    private func posterOutlineText(_ text: String) -> some View {
        ZStack {
            ForEach(outlineOffsets.indices, id: \.self) { index in
                let offset = outlineOffsets[index]
                Text(text)
                    .font(.custom(ActiveGamePosterStyle.fontName, size: posterFontSize))
                    .fontWidth(.compressed)
                    .tracking(1.2)
                    .foregroundStyle(ActiveGamePosterStyle.darkInkColor)
                    .offset(x: offset.width, y: offset.height)
            }

            Text(text)
                .font(.custom(ActiveGamePosterStyle.fontName, size: posterFontSize))
                .fontWidth(.compressed)
                .tracking(1.2)
                .foregroundStyle(ActiveGamePosterStyle.panelColor)
        }
    }

    private var solTypeText: String {
        switch solType {
        case .normal:
            return "Sol"
        case .pure:
            return "Ren sol"
        case .halfDealer:
            return "½ bordlægger"
        case .dealer:
            return "Bordlægger"
        }
    }

    private var solTypeFontSize: CGFloat {
        solType == .halfDealer ? posterFontSize * 0.9 : posterFontSize
    }

    private var topPanelHeight: CGFloat {
        isCompact ? 164 : 154
    }

    private var posterHeight: CGFloat {
        var height = topPanelHeight
        if !scoreItems.isEmpty {
            height += verticalSpacing + scoreStripHeight
        }
        if allyText != nil {
            height += verticalSpacing + allyPanelHeight
        }
        return height
    }

    private var posterFontSize: CGFloat {
        isCompact ? 31 : 36
    }

    private var textLineSpacing: CGFloat {
        isCompact ? -8 : -10
    }

    private var solIconSize: CGFloat {
        isCompact ? 118 : 132
    }

    private var solIconColumnWidth: CGFloat {
        isCompact ? 138 : 168
    }

    private var allyPanelHeight: CGFloat {
        isCompact ? 58 : 66
    }

    private var scoreStripHeight: CGFloat {
        ActiveGamePosterScoreStrip.height(isCompact: isCompact)
    }

    private var verticalSpacing: CGFloat {
        isCompact ? 16 : 18
    }

    private var allyText: String? {
        guard !allyNames.isEmpty else { return nil }
        return "\(Self.danishNameList(allyNames)) går med"
    }

    private var accessibilityText: String {
        var text = "\(bidderName) \(actionText.lowercased()) \(solTypeText)."
        if let allyText {
            text += " \(allyText)."
        }
        return text
    }

    private static func danishNameList(_ names: [String]) -> String {
        let trimmed = names.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        switch trimmed.count {
        case 0:
            return ""
        case 1:
            return trimmed[0]
        case 2:
            return "\(trimmed[0]) og \(trimmed[1])"
        default:
            let head = trimmed.dropLast().joined(separator: ", ")
            return "\(head) og \(trimmed.last!)"
        }
    }

    private var outlineOffsets: [CGSize] {
        [
            CGSize(width: -1, height: 0),
            CGSize(width: 1, height: 0),
            CGSize(width: 0, height: -1),
            CGSize(width: 0, height: 1),
            CGSize(width: -1, height: -1),
            CGSize(width: 1, height: -1),
            CGSize(width: -1, height: 1),
            CGSize(width: 1, height: 1)
        ]
    }
}

private struct SolGameIcon: View {
    var solType: SolType
    var color: Color

    var body: some View {
        ZStack {
            ForEach(0..<rayCount, id: \.self) { index in
                Capsule(style: .continuous)
                    .fill(color)
                    .frame(width: rayThickness, height: rayLength)
                    .offset(y: -rayOffset)
                    .rotationEffect(.degrees(Double(index) * 360 / Double(rayCount)))
            }

            sunDisc
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var sunDisc: some View {
        switch solType {
        case .normal, .pure:
            Circle()
                .stroke(color, lineWidth: ringLineWidth)
                .frame(width: discSize, height: discSize)
        case .halfDealer:
            ZStack {
                Circle()
                    .stroke(color, lineWidth: ringLineWidth)
                Circle()
                    .fill(color)
                    .mask {
                        HStack(spacing: 0) {
                            Color.clear
                            Color.black
                        }
                    }
            }
            .frame(width: discSize, height: discSize)
        case .dealer:
            Circle()
                .fill(color)
                .frame(width: discSize, height: discSize)
        }
    }

    private var rayCount: Int {
        switch solType {
        case .normal:
            return 6
        case .pure:
            return 8
        case .halfDealer, .dealer:
            return 12
        }
    }

    private var rayLength: CGFloat {
        switch solType {
        case .normal:
            return 16
        case .pure:
            return 18
        case .halfDealer, .dealer:
            return 18
        }
    }

    private var rayThickness: CGFloat {
        switch solType {
        case .normal:
            return 5
        case .pure:
            return 6
        case .halfDealer, .dealer:
            return 5
        }
    }

    private var rayOffset: CGFloat {
        switch solType {
        case .normal:
            return 35
        case .pure:
            return 37
        case .halfDealer, .dealer:
            return 38
        }
    }

    private var discSize: CGFloat {
        switch solType {
        case .normal:
            return 34
        case .pure:
            return 36
        case .halfDealer, .dealer:
            return 38
        }
    }

    private var ringLineWidth: CGFloat {
        switch solType {
        case .normal:
            return 6
        case .pure, .halfDealer:
            return 7
        case .dealer:
            return 0
        }
    }
}

struct ActiveGamePosterScoreItem: Identifiable {
    var id: String { name }
    var name: String
    var score: Int
    var role: ActiveGamePosterScoreRole = .none
    var storslemRibbon = false
}

enum ActiveGamePosterScoreRole {
    case none
    case bidder
    case partner
}

private struct ActiveGamePosterScoreStrip: View {
    var items: [ActiveGamePosterScoreItem]
    var isCompact = false

    var body: some View {
        HStack(spacing: isCompact ? 8 : 10) {
            ForEach(items) { item in
                scoreCell(item)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: Self.height(isCompact: isCompact))
    }

    static func height(isCompact: Bool) -> CGFloat {
        isCompact ? 62 : 74
    }

    private func scoreCell(_ item: ActiveGamePosterScoreItem) -> some View {
        VStack(spacing: isCompact ? 1 : 2) {
            Text(item.name.uppercased())
                .font(.custom(ActiveGamePosterStyle.resumeFontName, size: isCompact ? 11 : 12))
                .fontWidth(.compressed)
                .fontWeight(.semibold)
                .foregroundStyle(ActiveGamePosterStyle.darkInkColor)
                .lineLimit(1)
                .minimumScaleFactor(0.62)

            Text(scoreText(item.score))
                .font(.custom(ActiveGamePosterStyle.fontName, size: isCompact ? 34 : 42))
                .fontWidth(.compressed)
                .monospacedDigit()
                .foregroundStyle(scoreColor(item.score))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.top, isCompact ? 7 : 9)
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity)
        .frame(height: Self.height(isCompact: isCompact))
        .background {
            RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                .fill(ActiveGamePosterStyle.panelColor)
        }
        .overlay {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                    .strokeBorder(borderColor(for: item.role), style: contractBorderStyle(for: item.role))

                if item.storslemRibbon {
                    storslemScoreCornerRibbon
                        .accessibilityHidden(true)
                }
            }
        }
        .clipped()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.name) \(scoreText(item.score)) point\(item.role != .none ? ", kontraktside" : "")\(item.storslemRibbon ? ", tabte storslem" : "")")
    }

    private var storslemScoreCornerRibbon: some View {
        Text("SS")
            .font(.custom(ActiveGamePosterStyle.fontName, size: isCompact ? 10 : 11))
            .fontWidth(.compressed)
            .foregroundStyle(ActiveGamePosterStyle.contrastTextOnColor)
            .lineLimit(1)
            .minimumScaleFactor(0.65)
            .frame(width: isCompact ? 62 : 68, height: isCompact ? 15 : 17)
            .background(ActiveGamePosterStyle.negativeScoreColor.opacity(0.85))
            .rotationEffect(.degrees(45))
            .offset(x: isCompact ? 22 : 24, y: isCompact ? -18 : -20)
    }

    private func borderColor(for role: ActiveGamePosterScoreRole) -> Color {
        role == .none ? ActiveGamePosterStyle.borderColor : ActiveGamePosterStyle.contractMarkerColor
    }

    private func contractBorderStyle(for role: ActiveGamePosterScoreRole) -> StrokeStyle {
        switch role {
        case .none:
            return StrokeStyle(lineWidth: 1)
        case .bidder:
            return StrokeStyle(lineWidth: 2)
        case .partner:
            return StrokeStyle(lineWidth: 2, dash: [6, 4])
        }
    }

    private func scoreText(_ value: Int) -> String {
        value > 0 ? "+\(value)" : "\(value)"
    }

    private func scoreColor(_ value: Int) -> Color {
        if value > 0 {
            return ActiveGamePosterStyle.positiveScoreColor
        }
        if value < 0 {
            return ActiveGamePosterStyle.negativeScoreColor
        }
        return .secondary
    }
}

private struct ActiveGameTrumpPoster: View {
    var bidderName: String
    var actionText = "MELDER"
    var bidTricks: Int
    var gameType: String
    var trump: Suit?
    var partnerAceSuit: Suit?
    var scoreItems: [ActiveGamePosterScoreItem] = []
    var topPanelBorderColor = ActiveGamePosterStyle.borderColor
    var actionColor: Color?
    var actualTricks: Int?
    var showsTopStorslemRibbon = false
    var isTrumpPending = false
    var isCompact = false

    private let thermometerWidth: CGFloat = 14
    private let sansThermometerColor = ActiveGamePosterStyle.neutralMeterColor

    var body: some View {
        Grid(horizontalSpacing: horizontalSpacing, verticalSpacing: verticalSpacing) {
            GridRow {
                topPanel
                    .gridCellColumns(2)
            }

            if !scoreItems.isEmpty {
                GridRow {
                    ActiveGamePosterScoreStrip(items: scoreItems, isCompact: isCompact)
                        .gridCellColumns(2)
                }
            }

            GridRow {
                suitPanel(title: "TRUMF", suit: trump, isTrumpPending: isTrumpPending)
                suitPanel(title: "MAKKER", suit: partnerAceSuit)
            }
        }
        .frame(height: posterHeight)
        .clipped()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var topPanel: some View {
        ZStack(alignment: .trailing) {
            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: textLineSpacing) {
                    posterText(bidderName.uppercased())
                        .lineLimit(1)
                        .minimumScaleFactor(0.42)
                    posterActionText(actionText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                    posterText(gameType.uppercased())
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                }
                .padding(.leading, 14)
                .padding(.vertical, topTextPadding)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

                bidNumberWithResultBadge

                Color.clear
                    .frame(width: thermometerWidth)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

            thermometer()
                .accessibilityHidden(true)

            if showsTopStorslemRibbon {
                storslemCornerRibbon
                    .accessibilityHidden(true)
            }
        }
        .frame(height: topPanelHeight)
        .posterPanelStyle(
            panelColor: ActiveGamePosterStyle.panelColor,
            borderColor: topPanelBorderColor,
            cornerRadius: ActiveGamePosterStyle.cornerRadius,
            borderWidth: 1
        )
        .clipped()
    }

    private var storslemCornerRibbon: some View {
        Text("STORSLEM")
            .font(.custom(ActiveGamePosterStyle.fontName, size: storslemRibbonFontSize))
            .fontWidth(.compressed)
            .foregroundStyle(ActiveGamePosterStyle.contrastTextOnColor)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(width: storslemRibbonWidth, height: storslemRibbonHeight)
            .background(ActiveGamePosterStyle.negativeScoreColor.opacity(0.85))
            .rotationEffect(.degrees(45))
            .offset(x: storslemRibbonOffsetX, y: storslemRibbonOffsetY)
    }

    private func suitPanel(title: String, suit: Suit?, isTrumpPending: Bool = false) -> some View {
        VStack(spacing: 0) {
            posterText(title, size: suitTitleFontSize)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .frame(height: suitTitleSlotHeight, alignment: .center)

            suitPanelSymbol(title: title, suit: suit, isTrumpPending: isTrumpPending)
                .frame(maxWidth: .infinity)
                .frame(height: suitSymbolSlotHeight, alignment: .center)
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .frame(height: suitPanelsRowHeight)
        .posterPanelStyle(
            panelColor: ActiveGamePosterStyle.panelColor,
            borderColor: ActiveGamePosterStyle.borderColor,
            cornerRadius: ActiveGamePosterStyle.cornerRadius
        )
    }

    @ViewBuilder
    private func suitPanelSymbol(title: String, suit: Suit?, isTrumpPending: Bool = false) -> some View {
        if let suit {
            Text(suit.cardSymbol)
                .font(.system(size: suitSymbolSize, weight: .black))
                .foregroundStyle(suit.illustrationColor)
        } else if title == "TRUMF", isTrumpPending {
            Text("VÆLGES")
                .font(.custom(ActiveGamePosterStyle.fontName, size: pendingTrumpFontSize))
                .fontWidth(.compressed)
                .foregroundStyle(contractColor)
                .lineLimit(1)
                .minimumScaleFactor(0.62)
                .frame(maxWidth: .infinity)
        } else if title == "TRUMF" {
            NoTrumpIcon(isCompact: isCompact)
                .foregroundStyle(contractColor)
        } else {
            Text("—")
                .font(.custom(ActiveGamePosterStyle.fontName, size: noPartnerSymbolSize))
                .fontWidth(.compressed)
                .foregroundStyle(.secondary)
        }
    }

    private func posterText(_ text: String, size: CGFloat? = nil) -> some View {
        Text(text)
            .font(.custom(ActiveGamePosterStyle.fontName, size: size ?? posterFontSize))
            .fontWidth(.compressed)
            .foregroundStyle(ActiveGamePosterStyle.darkInkColor)
    }

    @ViewBuilder
    private func posterActionText(_ text: String) -> some View {
        if let actionColor {
            Text(text)
                .font(.custom(ActiveGamePosterStyle.fontName, size: posterFontSize))
                .fontWidth(.compressed)
                .tracking(1.2)
                .foregroundStyle(actionColor)
        } else {
            posterOutlineText(text)
        }
    }

    private var bidNumberWithResultBadge: some View {
        ZStack(alignment: .topTrailing) {
            Text("\(bidTricks)")
                .font(.custom(ActiveGamePosterStyle.fontName, size: bidNumberFontSize))
                .monospacedDigit()
                .foregroundStyle(ActiveGamePosterStyle.darkInkColor)
                .lineLimit(1)
                .minimumScaleFactor(0.62)
                .fixedSize(horizontal: true, vertical: false)
                .overlay(alignment: .topTrailing) {
                    if let resultDelta {
                        resultDeltaBadge(resultDelta)
                            .offset(x: resultDeltaBadgeOffsetX, y: resultDeltaBadgeOffsetY)
                    }
                }
                .frame(width: bidNumberColumnWidth, alignment: .center)
        }
        .frame(width: bidNumberColumnWidth, height: topPanelHeight, alignment: .center)
    }

    private func resultDeltaBadge(_ delta: Int) -> some View {
        Text(delta > 0 ? "+\(delta)" : "\(delta)")
            .font(.system(size: resultDeltaBadgeFontSize, weight: .heavy, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(ActiveGamePosterStyle.contrastTextOnColor)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .offset(y: resultDeltaBadgeTextYOffset)
            .frame(minWidth: resultDeltaBadgeMinWidth, minHeight: resultDeltaBadgeHeight, alignment: .center)
            .padding(.horizontal, 1)
            .background {
                Capsule()
                    .fill(resultDeltaBadgeColor(delta))
            }
            .accessibilityLabel(delta > 0 ? "Plus \(delta)" : "Minus \(abs(delta))")
    }

    private func thermometer() -> some View {
        ZStack(alignment: .bottom) {
            Rectangle()
                .fill(thermometerColor.opacity(0.13))
            Rectangle()
                .fill(thermometerColor)
                .frame(height: bidFillHeight)
            if let actualTricks {
                thermometerResultOverlay(actualTricks: actualTricks)
            }
        }
        .frame(width: thermometerWidth, height: topPanelHeight)
    }

    @ViewBuilder
    private func thermometerResultOverlay(actualTricks: Int) -> some View {
        let actualHeight = CGFloat(max(0, min(13, actualTricks))) / 13 * topPanelHeight
        if actualTricks > bidTricks {
            Rectangle()
                .fill(ActiveGamePosterStyle.positiveScoreColor)
                .frame(height: max(0, actualHeight - bidFillHeight))
                .offset(y: -bidFillHeight)
        } else if actualTricks < bidTricks {
            Rectangle()
                .fill(negativeThermometerResultColor)
                .frame(height: max(0, bidFillHeight - actualHeight))
                .offset(y: -actualHeight)
        }
    }

    private var negativeThermometerResultColor: Color {
        switch trump {
        case .hearts, .diamonds:
            return ActiveGamePosterStyle.darkInkColor
        default:
            return ActiveGamePosterStyle.negativeScoreColor
        }
    }

    private var thermometerColor: Color {
        trump == nil ? sansThermometerColor : contractColor
    }

    private var bidFraction: CGFloat {
        max(0, min(1, CGFloat(bidTricks) / 13))
    }

    private var bidFillHeight: CGFloat {
        bidFraction * topPanelHeight
    }

    private var isStorslemResult: Bool {
        actualTricks == 13 || actualTricks == 0
    }

    private var suitPanelsRowHeight: CGFloat {
        isCompact ? 132 : 160
    }

    private var posterHeight: CGFloat {
        var height = topPanelHeight + verticalSpacing + suitPanelsRowHeight
        if !scoreItems.isEmpty {
            height += verticalSpacing + scoreStripHeight
        }
        return height
    }

    private var posterFontSize: CGFloat {
        isCompact ? 31 : 36
    }

    private var suitTitleFontSize: CGFloat {
        isCompact ? 35 : 42
    }

    private var topPanelHeight: CGFloat {
        isCompact ? 164 : 154
    }

    private var bidNumberFontSize: CGFloat {
        isCompact ? 178 : 188
    }

    private var bidNumberColumnWidth: CGFloat {
        isCompact ? 136 : 154
    }

    private var textLineSpacing: CGFloat {
        isCompact ? -8 : -10
    }

    private var topTextPadding: CGFloat {
        isCompact ? 12 : 14
    }

    private var suitTitleSlotHeight: CGFloat {
        isCompact ? 52 : 58
    }

    private var suitSymbolSlotHeight: CGFloat {
        suitPanelsRowHeight - suitTitleSlotHeight
    }

    private var suitSymbolSize: CGFloat {
        isCompact ? 58 : 74
    }

    private var noPartnerSymbolSize: CGFloat {
        isCompact ? 46 : 62
    }

    private var pendingTrumpFontSize: CGFloat {
        isCompact ? 28 : 34
    }

    private var storslemRibbonFontSize: CGFloat {
        isCompact ? 16 : 18
    }

    private var storslemRibbonWidth: CGFloat {
        isCompact ? 128 : 138
    }

    private var storslemRibbonHeight: CGFloat {
        isCompact ? 28 : 30
    }

    private var storslemRibbonOffsetX: CGFloat {
        isCompact ? 36 : 38
    }

    private var storslemRibbonOffsetY: CGFloat {
        isCompact ? -52 : -50
    }

    private var resultDeltaBadgeFontSize: CGFloat {
        isCompact ? 17 : 18
    }

    private var resultDeltaBadgeMinWidth: CGFloat {
        isCompact ? 34 : 36
    }

    private var resultDeltaBadgeHeight: CGFloat {
        isCompact ? 26 : 28
    }

    private var resultDeltaBadgeTextYOffset: CGFloat {
        0
    }

    private var resultDeltaBadgeOffsetX: CGFloat {
        isCompact ? 18 : 20
    }

    private var resultDeltaBadgeOffsetY: CGFloat {
        isCompact ? 24 : 20
    }

    private var horizontalSpacing: CGFloat {
        isCompact ? 10 : 12
    }

    private var verticalSpacing: CGFloat {
        isCompact ? 10 : 12
    }

    private var scoreStripHeight: CGFloat {
        ActiveGamePosterScoreStrip.height(isCompact: isCompact)
    }

    private var contractColor: Color {
        trump?.illustrationColor ?? ActiveGamePosterStyle.darkInkColor
    }

    private var resultDelta: Int? {
        guard let actualTricks else { return nil }
        let delta = actualTricks - bidTricks
        return delta == 0 ? nil : delta
    }

    private func resultDeltaBadgeColor(_ delta: Int) -> Color {
        delta > 0
            ? ActiveGamePosterStyle.positiveScoreColor
            : ActiveGamePosterStyle.negativeScoreColor
    }

    private func posterOutlineText(_ text: String) -> some View {
        ZStack {
            ForEach(outlineOffsets.indices, id: \.self) { index in
                let offset = outlineOffsets[index]
                Text(text)
                    .font(.custom(ActiveGamePosterStyle.fontName, size: posterFontSize))
                    .fontWidth(.compressed)
                    .tracking(1.2)
                    .foregroundStyle(ActiveGamePosterStyle.darkInkColor)
                    .offset(x: offset.width, y: offset.height)
            }

            Text(text)
                .font(.custom(ActiveGamePosterStyle.fontName, size: posterFontSize))
                .fontWidth(.compressed)
                .tracking(1.2)
                .foregroundStyle(ActiveGamePosterStyle.panelColor)
        }
    }

    private var outlineOffsets: [CGSize] {
        [
            CGSize(width: -1, height: 0),
            CGSize(width: 1, height: 0),
            CGSize(width: 0, height: -1),
            CGSize(width: 0, height: 1),
            CGSize(width: -1, height: -1),
            CGSize(width: 1, height: -1),
            CGSize(width: -1, height: 1),
            CGSize(width: 1, height: 1)
        ]
    }

    private var accessibilityText: String {
        let partnerText = partnerAceSuit.map { "Makker-es \($0.rawValue)" } ?? "Makker-es ikke valgt"
        let trumpText = trump.map { "Trumf \($0.rawValue)" } ?? (isTrumpPending ? "Trumf vælges senere" : "Ingen trumf")
        let actualText = actualTricks.map { " Faktiske stik \($0)." } ?? ""
        let deltaText = resultDelta.map { $0 > 0 ? " Resultat plus \($0)." : " Resultat minus \(abs($0))." } ?? ""
        let storslemText = isStorslemResult ? " Storslem." : ""
        return "\(bidderName) \(actionText.lowercased()) \(bidTricks) \(gameType). \(trumpText). \(partnerText).\(actualText)\(deltaText)\(storslemText)"
    }
}

private struct NoTrumpIcon: View {
    var isCompact = false

    var body: some View {
        Image(systemName: "xmark.circle")
            .font(.system(size: isCompact ? 50 : 62, weight: .bold))
            .symbolRenderingMode(.monochrome)
            .frame(width: isCompact ? 78 : 96, height: isCompact ? 72 : 88)
            .accessibilityLabel("Ingen trumf")
    }
}

private extension View {
    func posterPanelStyle(panelColor: Color, borderColor: Color, cornerRadius: CGFloat, borderWidth: CGFloat = 1) -> some View {
        background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(panelColor)
        }
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(borderColor, lineWidth: borderWidth)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

private struct CardShell<Content: View>: View {
    var accent: Color
    var dashed = false
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.10), radius: 8, y: 4)

            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(
                    accent.opacity(dashed ? 0.48 : 0.82),
                    style: StrokeStyle(lineWidth: 2, dash: dashed ? [6, 4] : [])
                )

            VStack(spacing: 6) {
                content
            }
            .foregroundStyle(accent)
            .padding(10)
        }
    }
}

private extension VipLevel {
    var shortTitle: String {
        switch self {
        case .single:
            return "1"
        case .double:
            return "2"
        case .triple:
            return "3"
        }
    }
}
