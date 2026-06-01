import SwiftUI

// MARK: - Row types

private enum TableRow: Identifiable {
    case normal(tricks: Int, base: Int)
    case sol(label: String, points: Int, maxTricks: Int, tint: Color)

    var id: String {
        switch self {
        case .normal(let t, _): return "n\(t)"
        case .sol(let l, _, _, _): return "s\(l)"
        }
    }
}

// MARK: - View

struct ScorecardView: View {
    private static let solColWidth: CGFloat = 76
    private static let trickColWidth: CGFloat = 34

    private let columns = ["alm", "sans\nhalve\ngode\n1. vip", "2. VIP", "3. VIP"]

    private let rows: [TableRow] = [
        .normal(tricks: 8, base: 1),
        .normal(tricks: 9, base: 2),
        .sol(label: "Sol", points: 4, maxTricks: 1,
             tint: Color(red: 240/255, green: 196/255, blue: 24/255).opacity(0.22)),   // gul
        .normal(tricks: 10, base: 4),
        .sol(label: "Ren sol", points: 8, maxTricks: 0,
             tint: Color(red: 230/255, green: 126/255, blue: 37/255).opacity(0.22)),   // orange
        .normal(tricks: 11, base: 8),
        .sol(label: "Halv bordl.", points: 16, maxTricks: 0,
             tint: Color(red: 231/255, green: 76/255, blue: 59/255).opacity(0.22)),    // rød
        .normal(tricks: 12, base: 16),
        .sol(label: "Hel bordl.", points: 32, maxTricks: 0,
             tint: Color(red: 130/255, green: 20/255, blue: 20/255).opacity(0.22)),    // mørkerød
        .normal(tricks: 13, base: 32),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                mainTable
                specialSection
                rankingNote
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Scorecard")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Samlet tabel

    private var mainTable: some View {
        VStack(alignment: .leading, spacing: 0) {
            posterSectionHeader("Pris pr. stik & rangering")
            tableHeader
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                if index > 0 { posterDivider }
                switch row {
                case .normal(let tricks, let base):
                    normalDataRow(tricks: tricks, base: base)
                case .sol(let label, let points, let maxTricks, let tint):
                    solDataRow(label: label, points: points, maxTricks: maxTricks, tint: tint)
                }
            }
        }
        .background(ActiveGamePosterStyle.panelColor)
        .clipShape(RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                .strokeBorder(ActiveGamePosterStyle.borderColor, lineWidth: 1)
        }
    }

    private var tableHeader: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: Self.solColWidth, height: 1)
            Text("STIK")
                .frame(width: Self.trickColWidth, alignment: .center)
            ForEach(columns, id: \.self) { col in
                Text(col.uppercased())
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
            }
            Text("♣")
                .frame(width: 30, alignment: .center)
        }
        .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 9).weight(.semibold))
        .foregroundStyle(ActiveGamePosterStyle.darkInkColor.opacity(0.5))
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background(ActiveGamePosterStyle.borderColor.opacity(0.25))
    }

    private func normalDataRow(tricks: Int, base: Int) -> some View {
        let alm = base
        let sansEtc = base * 2
        let vip2 = base * 4
        let vip3 = base * 8

        return HStack(spacing: 0) {
            Color.clear.frame(width: Self.solColWidth, height: 1)

            Text("\(tricks)")
                .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 16).weight(.bold).monospacedDigit())
                .foregroundStyle(ActiveGamePosterStyle.darkInkColor)
                .frame(width: Self.trickColWidth, alignment: .center)

            pointCell(alm)
            pointCell(sansEtc)
            pointCell(vip2)
            pointCell(vip3)

            Text("×2")
                .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 11))
                .foregroundStyle(ActiveGamePosterStyle.darkInkColor.opacity(0.45))
                .frame(width: 30, alignment: .center)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
    }

    private func solDataRow(label: String, points: Int, maxTricks: Int, tint: Color) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 12).weight(.semibold))
                .foregroundStyle(ActiveGamePosterStyle.darkInkColor)
                .frame(width: Self.solColWidth, alignment: .leading)

            Text("≤\(maxTricks)")
                .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 11))
                .foregroundStyle(ActiveGamePosterStyle.darkInkColor.opacity(0.5))
                .frame(width: Self.trickColWidth, alignment: .center)

            Color.clear.frame(maxWidth: .infinity, minHeight: 1)

            Text("\(points)")
                .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 16).weight(.bold).monospacedDigit())
                .foregroundStyle(ActiveGamePosterStyle.darkInkColor)

            Color.clear.frame(maxWidth: .infinity, minHeight: 1)
            Color.clear.frame(maxWidth: .infinity, minHeight: 1)
            Color.clear.frame(maxWidth: .infinity, minHeight: 1)
            Color.clear.frame(width: 30, height: 1)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background(tint)
    }

    // MARK: - Special

    private var specialSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            posterSectionHeader("Specielle regler")

            VStack(spacing: 0) {
                specialRow(
                    label: "«Gå hjem»-bonus",
                    value: "+1",
                    detail: "Vinder man sit bud, får man én ekstra portion basispoint oven i.",
                    accent: ActiveGamePosterStyle.positiveScoreColor
                )
                posterDivider
                specialRow(
                    label: "Storslem (13 stik)",
                    value: "×2",
                    detail: "Gælder alle spiltyper",
                    accent: Color(red: 35/255, green: 185/255, blue: 154/255)
                )
                posterDivider
                specialRow(
                    label: "Klør i 3. VIP",
                    value: "×2",
                    detail: "Oven i VIP-multiplikatoren",
                    accent: Color(red: 230/255, green: 126/255, blue: 37/255)
                )
                posterDivider
                specialRow(
                    label: "Duestraf",
                    value: "72",
                    detail: "Straffet: −72 point / øvrige: +24 point",
                    accent: Color(red: 231/255, green: 76/255, blue: 59/255)
                )
            }
        }
        .background(ActiveGamePosterStyle.panelColor)
        .clipShape(RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                .strokeBorder(ActiveGamePosterStyle.borderColor, lineWidth: 1)
        }
    }

    private func specialRow(label: String, value: String, detail: String, accent: Color) -> some View {
        HStack(spacing: 12) {
            // Farvet accent-streg til venstre
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(accent)
                .frame(width: 3)
                .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 14).weight(.semibold))
                    .foregroundStyle(ActiveGamePosterStyle.darkInkColor)
                Text(detail)
                    .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 11))
                    .foregroundStyle(ActiveGamePosterStyle.darkInkColor.opacity(0.55))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            // Stor Anton-værdi med farvet baggrund
            Text(value)
                .font(.custom(ActiveGamePosterStyle.fontName, size: 22))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(accent)
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
    }

    // MARK: - Rangerings-note

    private var rankingNote: some View {
        VStack(alignment: .leading, spacing: 0) {
            posterSectionHeader("Rangering")

            posterDivider

            // Rækkefølge-liste
            VStack(spacing: 0) {
                ForEach(Array(rankingItems.enumerated()), id: \.offset) { index, item in
                    if index > 0 { posterDivider }
                    HStack(spacing: 12) {
                        ScorecardGameTypeIcon(kind: item.kind)
                            .frame(width: 22, height: 30)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.label)
                                .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 14).weight(.semibold))
                                .foregroundStyle(ActiveGamePosterStyle.darkInkColor)
                            if let sub = item.sublabel {
                                Text(sub)
                                    .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 11))
                                    .foregroundStyle(ActiveGamePosterStyle.darkInkColor.opacity(0.5))
                            }
                        }
                        Spacer()
                        Text(item.multiplier)
                            .font(.custom(ActiveGamePosterStyle.fontName, size: 16))
                            .foregroundStyle(ActiveGamePosterStyle.darkInkColor.opacity(0.6))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                }
            }

            posterDivider

            // Forklaringstekst
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ActiveGamePosterStyle.darkInkColor.opacity(0.4))
                    .padding(.top, 1)
                Text("Sol-spil er indsat på deres plads i hierarkiet — fx ligger Sol (4 pt) over 9 alm, men under 9 med melding.")
                    .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 11))
                    .foregroundStyle(ActiveGamePosterStyle.darkInkColor.opacity(0.5))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ActiveGamePosterStyle.panelColor)
        .clipShape(RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: ActiveGamePosterStyle.cornerRadius, style: .continuous)
                .strokeBorder(ActiveGamePosterStyle.borderColor, lineWidth: 1)
        }
    }

    private struct RankingItem {
        var kind: ScorecardGameTypeIcon.Kind
        var label: String
        var sublabel: String?
        var multiplier: String
    }

    private let rankingItems: [RankingItem] = [
        RankingItem(kind: .almindelige, label: "Almindelige",  sublabel: nil,            multiplier: "× 1"),
        RankingItem(kind: .sans,        label: "Sans",         sublabel: "ingen trumf",  multiplier: "× 2"),
        RankingItem(kind: .halve,       label: "Halve",        sublabel: "halv kulør",   multiplier: "× 2"),
        RankingItem(kind: .gode,        label: "Gode",         sublabel: "klør trumf",   multiplier: "× 2"),
        RankingItem(kind: .vip,         label: "VIP",          sublabel: "1./2./3.",     multiplier: "× 2–8"),
    ]

    // MARK: - Helpers

    private func posterSectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.custom(ActiveGamePosterStyle.fontName, size: 14))
            .foregroundStyle(ActiveGamePosterStyle.darkInkColor.opacity(0.55))
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 8)
    }

    private func pointCell(_ value: Int) -> some View {
        Text("\(value)")
            .font(.custom(ActiveGamePosterStyle.resumeFontName, size: 16).monospacedDigit())
            .foregroundStyle(ActiveGamePosterStyle.darkInkColor)
            .frame(maxWidth: .infinity)
    }

    private var posterDivider: some View {
        Rectangle()
            .fill(ActiveGamePosterStyle.borderColor)
            .frame(height: 0.5)
            .padding(.horizontal, 8)
    }
}

// MARK: - Spiltype-ikon (samme kortdesign som i Statistik)

private struct ScorecardGameTypeIcon: View {
    enum Kind {
        case almindelige, sans, halve, gode, vip
    }

    var kind: Kind
    private let color = ActiveGamePosterStyle.darkInkColor

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .strokeBorder(color, lineWidth: 1.8)
            content
                .foregroundStyle(color)
                .padding(2)
        }
        .aspectRatio(0.72, contentMode: .fit)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var content: some View {
        switch kind {
        case .almindelige:
            EmptyView()
        case .sans:
            Image(systemName: "xmark.circle")
                .font(.system(size: 12, weight: .semibold))
        case .halve:
            HStack(spacing: 0) {
                Color.clear
                color
            }
        case .gode:
            Text(Suit.clubs.cardSymbol)
                .font(.system(size: 13, weight: .black))
        case .vip:
            Text("V")
                .font(.system(size: 10, weight: .black, design: .rounded))
        }
    }
}

#Preview {
    NavigationStack {
        ScorecardView()
    }
}
