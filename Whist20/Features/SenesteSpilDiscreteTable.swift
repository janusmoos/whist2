import SwiftUI

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
    private let gameNumberColumnWidth: CGFloat = 44
    private let gameTypeIconColumnWidth: CGFloat = 28
    private let metaForeground = Color.secondary.opacity(0.72)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerRow
            ForEach(Array(hands.enumerated()), id: \.element.id) { index, hand in
                accordionRow(hand: hand)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background {
            RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                .fill(ActiveGamePosterStyle.panelColor)
        }
        .overlay {
            RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                .strokeBorder(ActiveGamePosterStyle.borderColor, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous))
        .onChange(of: hands.map(\.id)) { _, ids in
            if let id = expandedHandID, !ids.contains(id) {
                expandedHandID = nil
            }
        }
    }

    private var headerRow: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 8) {
                Text(" ")
                    .frame(width: gameNumberColumnWidth, alignment: .leading)
                Color.clear
                    .frame(width: gameTypeIconColumnWidth, height: 1)
                ForEach(seats, id: \.self) { seat in
                    Text(headerInitial(for: seat))
                        .font(tableNumberFont)
                        .fontWidth(.compressed)
                        .fontWeight(.black)
                        .foregroundStyle(ActiveGamePosterStyle.darkInkColor)
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
        return VStack(alignment: .leading, spacing: 10) {
            SuitColoredInlineText.build(captionParts.narrative, colorScheme: colorScheme)
                .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 15))
                .fontWidth(.compressed)
                .lineSpacing(2)
                .opacity(0.82)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
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
        .padding(.horizontal, 4)
        .padding(.bottom, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(captionParts.narrative). Spillet gemt \(dateStr)")
    }

    /// Fælles skrift for kampnr., point og header-forbogstaver.
    private var tableNumberFont: Font {
        .custom(ActiveGamePosterStyle.resumeFontName, size: 16)
    }

    private func headerInitial(for seat: Seat) -> String {
        String(seat.playerDisplayName.prefix(1)).uppercased()
    }

    private func scoreRow(hand: RecordedHand, scores: [Seat: Int]) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Text(hand.handNumber > 0 ? "#\(hand.handNumber)" : "—")
                .font(tableNumberFont)
                .fontWidth(.compressed)
                .monospacedDigit()
                .foregroundStyle(metaForeground)
                .frame(width: gameNumberColumnWidth, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            SenesteSpilGameTypeIcon(kind: SenesteSpilGameTypeIconKind(hand: hand), color: metaForeground)
                .frame(width: gameTypeIconColumnWidth, height: 24)
                .accessibilityLabel(gameTypeIconAccessibilityLabel(for: hand))

            ForEach(seats, id: \.self) { seat in
                let v = scores[seat] ?? 0
                let isBidder = seat.rawValue == hand.bidderSeatRaw
                Text(scoreCell(v))
                    .font(scoreNumberFont)
                    .fontWidth(.compressed)
                    .fontWeight(isBidder ? .black : .regular)
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

    private var scoreNumberFont: Font {
        tableNumberFont
    }

    private func gameTypeIconAccessibilityLabel(for hand: RecordedHand) -> String {
        SenesteSpilGameTypeIconKind(hand: hand).accessibilityLabel
    }

    private func scoreForeground(_ value: Int) -> Color {
        if value > 0 { return ActiveGamePosterStyle.positiveScoreColor }
        if value < 0 { return ActiveGamePosterStyle.negativeScoreColor }
        return Color.secondary
    }
}

private enum SenesteSpilGameTypeIconKind: Equatable {
    case almindelige
    case halve
    case gode
    case sans
    case vip(Int)
    case sol(SolType)
    case duty
    case unknown

    init(hand: RecordedHand) {
        let narrative = hand.displayResumeNarrative.lowercased()
        if hand.kindRaw == "sol" {
            self = .sol(Self.parseSolType(from: narrative))
        } else if hand.kindRaw == "duty" || narrative.contains("duestraf") {
            self = .duty
        } else if narrative.contains("vip i tredje") || narrative.contains("vip 3") {
            self = .vip(3)
        } else if narrative.contains("vip i anden") || narrative.contains("vip 2") {
            self = .vip(2)
        } else if narrative.contains("vip i første") || narrative.contains("vip 1") || narrative.contains("vip") {
            self = .vip(1)
        } else if narrative.contains("gode") {
            self = .gode
        } else if narrative.contains("halve") {
            self = .halve
        } else if narrative.contains("sans") {
            self = .sans
        } else if narrative.contains("almindelige") {
            self = .almindelige
        } else {
            self = .unknown
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .almindelige:
            return "Almindelige"
        case .halve:
            return "Halve"
        case .gode:
            return "Gode"
        case .sans:
            return "Sans"
        case .vip(let level):
            return "VIP \(level)"
        case .sol(let solType):
            switch solType {
            case .normal: return "Sol"
            case .pure: return "Ren sol"
            case .halfDealer: return "Halv bordlægger"
            case .dealer: return "Bordlægger"
            }
        case .duty:
            return "Duestraf"
        case .unknown:
            return "Spiltype ukendt"
        }
    }

    private static func parseSolType(from narrative: String) -> SolType {
        if narrative.contains("halv bordlægger") || narrative.contains("½ bordlægger") {
            return .halfDealer
        }
        if narrative.contains("bordlægger") {
            return .dealer
        }
        if narrative.contains("ren sol") {
            return .pure
        }
        return .normal
    }
}

private struct SenesteSpilGameTypeIcon: View {
    var kind: SenesteSpilGameTypeIconKind
    var color: Color = .secondary

    var body: some View {
        switch kind {
        case .sol(let solType):
            SenesteSpilSolIcon(solType: solType, color: color)
        case .duty:
            gameCard {
                Image(systemName: "exclamationmark")
                    .font(.system(size: 11, weight: .black))
            }
        case .unknown:
            gameCard {
                Text("?")
                    .font(.system(size: 11, weight: .black, design: .rounded))
            }
        default:
            normalGameCard
        }
    }

    @ViewBuilder
    private var normalGameCard: some View {
        gameCard {
            switch kind {
            case .almindelige:
                EmptyView()
            case .halve:
                HStack(spacing: 0) {
                    Color.clear
                color
                }
            case .gode:
                Text(Suit.clubs.cardSymbol)
                    .font(.system(size: 13, weight: .black))
            case .sans:
                Image(systemName: "xmark.circle")
                    .font(.system(size: 12, weight: .bold))
            case .vip(let level):
                Text("V\(level)")
                    .font(.system(size: 9.5, weight: .black, design: .rounded))
                    .minimumScaleFactor(0.65)
            default:
                EmptyView()
            }
        }
    }

    private func gameCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Color.clear)
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .strokeBorder(color, lineWidth: 1.8)
            content()
                .foregroundStyle(color)
                .padding(2)
        }
        .aspectRatio(0.72, contentMode: .fit)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct SenesteSpilSolIcon: View {
    var solType: SolType
    var color: Color = .secondary

    var body: some View {
        ZStack {
            ForEach(0..<rayCount, id: \.self) { index in
                Capsule()
                    .fill(color)
                    .frame(width: 2.2, height: rayLength)
                    .offset(y: -rayOffset)
                    .rotationEffect(.degrees(Double(index) / Double(rayCount) * 360))
            }
            disc
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var disc: some View {
        switch solType {
        case .normal:
            Circle()
                .stroke(color, lineWidth: 2)
                .frame(width: discSize, height: discSize)
        case .pure:
            Circle()
                .stroke(color, lineWidth: 2.3)
                .frame(width: discSize, height: discSize)
        case .halfDealer:
            Circle()
                .stroke(color, lineWidth: 2.2)
                .background {
                    HStack(spacing: 0) {
                        Color.clear
                        color
                    }
                    .clipShape(Circle())
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
        case .normal: return 6
        case .pure: return 8
        case .halfDealer, .dealer: return 12
        }
    }

    private var rayLength: CGFloat {
        solType == .normal ? 4.8 : 5.5
    }

    private var rayOffset: CGFloat {
        solType == .normal ? 9.5 : 10.2
    }

    private var discSize: CGFloat {
        switch solType {
        case .normal: return 10
        case .pure: return 10.5
        case .halfDealer, .dealer: return 11
        }
    }
}
