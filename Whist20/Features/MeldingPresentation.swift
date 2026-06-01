import SwiftUI

/// Struktureret visning af den aktuelle melding (melding + resultat + «Aktivt spil»).
struct MeldingPresentation {
    var sectionTitle: String = "Nuværende melding"
    var rows: [(String, String)]
    var statusFootnote: String?

    static func from(draft: HandInputDraft, navigationStepLabel: String? = nil) -> MeldingPresentation {
        let foot = navigationStepLabel
        switch draft.kind {
        case .duty:
            return MeldingPresentation(
                rows: [("Type", "Duestraf")],
                statusFootnote: foot
            )
        case .sol:
            var r: [(String, String)] = [
                ("Spiltype", solTypeDanish(draft.solType)),
                ("Melder", draft.solBidder?.playerDisplayName ?? "Ikke valgt"),
            ]
            if !draft.goingWith.isEmpty {
                let names = draft.goingWith.sorted(by: { $0.rawValue < $1.rawValue }).map(\.playerDisplayName).joined(separator: ", ")
                r.append(("Går med", names))
            } else {
                r.append(("Går med", "—"))
            }
            return MeldingPresentation(rows: r, statusFootnote: foot)
        case .normal:
            var r: [(String, String)] = [
                ("Melder", draft.bidder?.playerDisplayName ?? "Ikke valgt"),
                ("Spiltype", draft.normalSubtype.title),
                ("Meldt", "\(draft.bidTricks) stik"),
            ]
            if draft.requiresPartnerAceForBid {
                r.append(("Makker", draft.partner?.playerDisplayName ?? "Ikke valgt"))
            }
            if draft.normalSubtype == .alm, let t = draft.trumpAlm {
                r.append(("Trumf (bud)", t.cardSymbol))
            }
            if draft.normalSubtype == .gode {
                r.append(("Trumf", Suit.clubs.cardSymbol))
            }
            if draft.normalSubtype == .sans {
                r.append(("Trumf", "Ingen trumf"))
            }
            if draft.normalSubtype == .halve {
                if let t = draft.trumpAfterPlay {
                    r.append(("Trumf", t.cardSymbol))
                } else {
                    r.append(("Trumf", "Vælges på næste trin"))
                }
            }
            if draft.normalSubtype == .vip {
                if let t = draft.trumpAfterPlay {
                    r.append(("Trumf", t.cardSymbol))
                } else {
                    r.append(("Trumf", "Vælges ved halve"))
                }
            }
            if draft.requiresPartnerAceForBid, let ace = draft.partnerAceSuit {
                r.append(("Makker-es", ace.shortSymbol))
            } else if draft.requiresPartnerAceForBid {
                r.append(("Makker-es", "Ikke valgt"))
            }
            if draft.normalSubtype == .vip {
                r.append(("VIP-niveau", draft.vipLevel.danishLabel))
            }
            return MeldingPresentation(rows: r, statusFootnote: foot)
        }
    }

    static func from(snapshot: HandDraftPersistence.Snapshot) -> MeldingPresentation {
        let kind = AddHandKind(rawValue: snapshot.kindRaw) ?? .normal
        let step: String? = {
            switch snapshot.navigationStep {
            case HandDraftPersistence.stepResultat: return "Trin: resultat"
            case HandDraftPersistence.stepMelding: return "Trin: melding"
            case HandDraftPersistence.stepHalveTrumf: return "Trin: trumf (halve)"
            default: return nil
            }
        }()
        var draft = HandInputDraft()
        HandDraftPersistence.apply(snapshot, to: draft)
        return from(draft: draft, navigationStepLabel: step)
    }

    private static func solTypeDanish(_ t: SolType) -> String {
        switch t {
        case .normal: return "Sol"
        case .pure: return "Ren sol"
        case .halfDealer: return "½ bordlægger"
        case .dealer: return "Bordlægger"
        }
    }
}

// MARK: - Kort UI

private let meldingBoxTitleFont: Font = .system(size: 15, weight: .semibold)
private let meldingTileLabelFont: Font = .system(size: 13, weight: .semibold)
private let meldingTileValueFont: Font = .system(size: 15, weight: .semibold)
let meldingSeatButtonFontSize: CGFloat = 14
let meldingSeatButtonHorizontalPadding: CGFloat = 12
let meldingSeatButtonVerticalPadding: CGFloat = 12
private let meldingWheelValueFont: Font = .system(size: 17)

struct MeldingStatusCard: View {
    let presentation: MeldingPresentation

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .center, spacing: 15) {
            Text(presentation.sectionTitle)
                .font(meldingBoxTitleFont)
                .foregroundStyle(headingColor)
                .textCase(.uppercase)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)

            if presentation.rows.contains(where: { $0.0 == "Melder" }) {
                tilesLayout
            } else {
                fallbackRowsLayout
            }

            if let foot = presentation.statusFootnote {
                Text(foot)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .center)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(ActiveGamePosterStyle.panelColor)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(ActiveGamePosterStyle.borderColor, lineWidth: 1)
        }
    }

    private var statusTileBackground: Color {
        ActiveGamePosterStyle.panelSecondaryColor
    }

    private var headingColor: Color {
        ActiveGamePosterStyle.darkInkColor.opacity(0.62)
    }

    private var rowsByKey: [String: String] {
        Dictionary(uniqueKeysWithValues: presentation.rows.map { ($0.0, $0.1) })
    }

    @ViewBuilder
    private var tilesLayout: some View {
        let melder = rowsByKey["Melder"]
        let trump =
            rowsByKey["Trumf (bud)"] ?? rowsByKey["Trumf"] ?? rowsByKey["Trumf (bud)"]
        let ace = rowsByKey["Makker-es"]
        let partner = rowsByKey["Makker"]
        let bid = rowsByKey["Meldt"]
        let subtype = rowsByKey["Spiltype"] ?? rowsByKey["Type"]

        VStack(spacing: 8) {
            HStack(spacing: 8) {
                if let melder {
                    tile(label: "Melder", value: melder)
                }
                if let subtype {
                    tile(label: "Spiltype", value: subtype)
                }
                if let partner {
                    tile(label: "Makker", value: partner)
                }
            }

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                spacing: 8
            ) {
                if let trump {
                    tile(label: "Trumf", value: trump)
                }
                if let bid {
                    tile(label: "Meldt", value: bid)
                }
                if let ace {
                    tile(label: "Makker-es", value: ace)
                }
            }
        }
    }

    @ViewBuilder
    private var fallbackRowsLayout: some View {
        ForEach(Array(presentation.rows.enumerated()), id: \.offset) { _, row in
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(row.0)
                    .foregroundStyle(.secondary)
                    .frame(width: 100, alignment: .leading)
                SuitColoredInlineText.build(row.1, colorScheme: colorScheme)
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
            }
        }
    }

    private func tile(label: String, value: String) -> some View {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let isSuitIcon = (label == "Trumf" || label == "Makker-es") && ["♠", "♥", "♦", "♣"].contains(trimmed)
        let isNoTrumpIcon = label == "Trumf" && trimmed == "Ingen trumf"
        return VStack(alignment: .center, spacing: 7) {
            Text(label)
                .font(meldingTileLabelFont)
                .foregroundStyle(headingColor)
                .frame(maxWidth: .infinity, alignment: .center)
                .frame(height: 16, alignment: .center)
                .multilineTextAlignment(.center)
            if isSuitIcon {
                Text(trimmed)
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(suitIconColor(trimmed))
                    .frame(width: 26, height: 26, alignment: .center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .accessibilityLabel("\(label): \(trimmed)")
            } else if isNoTrumpIcon {
                Image(systemName: "xmark.circle")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(ActiveGamePosterStyle.darkInkColor)
                    .frame(width: 26, height: 26, alignment: .center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .accessibilityLabel("Ingen trumf")
            } else {
                SuitColoredInlineText.build(value, colorScheme: colorScheme)
                    .font(meldingTileValueFont)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 62, alignment: .top)
        .padding(.horizontal, 10)
        .padding(.top, 6)
        .padding(.bottom, 6)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(statusTileBackground)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(ActiveGamePosterStyle.borderColor.opacity(0.72), lineWidth: 1)
        }
    }

    private func suitIconColor(_ symbol: String) -> Color {
        Suit(cardSymbol: symbol)?.color(context: .poster, colorScheme: colorScheme) ?? .primary
    }
}

// MARK: - Melder som knapper (fire spillere)

struct MeldingSeatChoiceButtonStyle: ButtonStyle {
    var isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isSelected ? ActiveGamePosterStyle.panelColor : ActiveGamePosterStyle.panelSecondaryColor)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(isSelected ? ActiveGamePosterStyle.borderColor.opacity(0.86) : Color.gray.opacity(0.24), lineWidth: 1)
            }
            .opacity(configuration.isPressed ? 0.72 : 1)
    }
}

struct MelderSeatButtonGrid: View {
    @Binding var selectedSeat: Seat

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
            ForEach(Seat.all, id: \.self) { seat in
                let on = selectedSeat == seat
                Button {
                    selectedSeat = seat
                } label: {
                    Text(seat.playerDisplayName)
                        .font(.system(size: meldingSeatButtonFontSize, weight: on ? .bold : .semibold))
                        .foregroundStyle(ActiveGamePosterStyle.darkInkColor.opacity(on ? 0.96 : 0.82))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, meldingSeatButtonHorizontalPadding)
                        .padding(.vertical, meldingSeatButtonVerticalPadding)
                }
                .buttonStyle(MeldingSeatChoiceButtonStyle(isSelected: on))
                .accessibilityLabel("Melder: \(seat.playerDisplayName)")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Vælg melder")
    }
}

// MARK: - Makker som knapper (samme udtryk som melder på meldingssiden)

struct PartnerSeatButtonGrid: View {
    @Binding var selectedPartner: Seat?

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
            ForEach(Seat.all, id: \.self) { seat in
                let on = selectedPartner == seat
                Button {
                    selectedPartner = seat
                } label: {
                    Text(seat.playerDisplayName)
                        .font(.system(size: meldingSeatButtonFontSize, weight: on ? .bold : .semibold))
                        .foregroundStyle(ActiveGamePosterStyle.darkInkColor.opacity(on ? 0.96 : 0.82))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, meldingSeatButtonHorizontalPadding)
                        .padding(.vertical, meldingSeatButtonVerticalPadding)
                }
                .buttonStyle(MeldingSeatChoiceButtonStyle(isSelected: on))
                .accessibilityLabel("Makker: \(seat.playerDisplayName)")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Vælg makker")
    }
}

// MARK: - Antal stik (normal) — hjul som i Ur-appen

struct NormalBidTricksWheelPicker: View {
    @Binding var bidTricks: Int

    var body: some View {
        Picker("Meldt antal stik", selection: $bidTricks) {
            ForEach(Array(8 ... 13), id: \.self) { n in
                Text("\(n) stik").tag(n)
            }
        }
        .pickerStyle(.wheel)
        .labelsHidden()
        .frame(height: 128)
        .clipped()
        .frame(maxWidth: .infinity)
        .accessibilityLabel("Meldt antal stik")
    }
}

// MARK: - Taget stik (resultat, normal)

struct ActualTricksWheelPicker: View {
    @Binding var actualTricks: Int
    /// Meldt antal stik — hjulet viser afvigelse pr. valg, fx «8 stik (-2)» ved melding 10.
    var bidTricks: Int

    var body: some View {
        Picker("Vundne stik", selection: $actualTricks) {
            ForEach(Array(0 ... 13), id: \.self) { n in
                Text("\(n) stik \(Self.deltaSuffix(n, bid: bidTricks))")
                    .font(meldingWheelValueFont)
                    .tag(n)
            }
        }
        .pickerStyle(.wheel)
        .labelsHidden()
        .frame(height: 128)
        .clipped()
        .frame(maxWidth: .infinity)
        .accessibilityLabel("Vundne stik for kontrakt-holdet, relativt til meldingen på \(bidTricks)")
    }

    private static func deltaSuffix(_ actual: Int, bid: Int) -> String {
        let d = actual - bid
        if d > 0 { return "(+\(d))" }
        if d < 0 { return "(\(d))" }
        return "(0)"
    }
}

private extension Suit {
    var shortSymbol: String {
        switch self {
        case .spades: return "♠"
        case .hearts: return "♥"
        case .diamonds: return "♦"
        case .clubs: return "♣"
        }
    }
}

private extension VipLevel {
    var danishLabel: String {
        switch self {
        case .single: return "Første"
        case .double: return "Anden"
        case .triple: return "Tredje"
        }
    }
}
