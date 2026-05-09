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
    @Environment(\.colorScheme) private var colorScheme

    private static let solColWidth: CGFloat = 72
    private static let trickColWidth: CGFloat = 34

    private let columns = ["alm", "sans\nhalve\ngode\n1. vip", "2. VIP", "3. VIP"]

    private let rows: [TableRow] = [
        .normal(tricks: 8, base: 1),
        .normal(tricks: 9, base: 2),
        .sol(label: "Sol", points: 4, maxTricks: 1, tint: Color.blue.opacity(0.12)),
        .normal(tricks: 10, base: 4),
        .sol(label: "Ren sol", points: 8, maxTricks: 0, tint: Color.blue.opacity(0.20)),
        .normal(tricks: 11, base: 8),
        .normal(tricks: 12, base: 16),
        .sol(label: "Halv bordl.", points: 16, maxTricks: 0, tint: Color.blue.opacity(0.30)),
        .normal(tricks: 13, base: 32),
        .sol(label: "Hel bordl.", points: 32, maxTricks: 0, tint: Color.blue.opacity(0.42)),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                mainTable
                specialSection
                rankingNote
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .navigationTitle("Scorecard")
        .navigationBarTitleDisplayMode(.large)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Samlet tabel

    private var mainTable: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Pris pr. stik & rangering")
            tableHeader
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                if index > 0 { thinDivider }
                switch row {
                case .normal(let tricks, let base):
                    normalDataRow(tricks: tricks, base: base)
                case .sol(let label, let points, let maxTricks, let tint):
                    solDataRow(label: label, points: points, maxTricks: maxTricks, tint: tint)
                }
            }
        }
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(.secondarySystemGroupedBackground)))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var tableHeader: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: Self.solColWidth, height: 1)
            Text("Stik")
                .frame(width: Self.trickColWidth, alignment: .center)
            ForEach(columns, id: \.self) { col in
                Text(col)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
            }
            Text("♣")
                .frame(width: 28, alignment: .center)
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .background(Color(.tertiarySystemFill))
    }

    private func normalDataRow(tricks: Int, base: Int) -> some View {
        let alm = base
        let sansEtc = base * 2
        let vip2 = base * 4
        let vip3 = base * 8

        return HStack(spacing: 0) {
            Color.clear.frame(width: Self.solColWidth, height: 1)

            Text("\(tricks)")
                .font(.subheadline.weight(.bold).monospacedDigit())
                .frame(width: Self.trickColWidth, alignment: .center)

            pointCell(alm)
            pointCell(sansEtc)
            pointCell(vip2)
            pointCell(vip3)

            Text("×2")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .center)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 6)
    }

    private func solDataRow(label: String, points: Int, maxTricks: Int, tint: Color) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .font(.caption.weight(.semibold))
                .frame(width: Self.solColWidth, alignment: .leading)

            Text("≤ \(maxTricks)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: Self.trickColWidth, alignment: .center)

            // alm-kolonne: tom
            Color.clear.frame(maxWidth: .infinity, minHeight: 1)

            // Tallet placeret mellem alm og sans-kolonnen
            Text("\(points)")
                .font(.subheadline.weight(.bold).monospacedDigit())

            // sans/halve/gode/1.vip-kolonne: tom
            Color.clear.frame(maxWidth: .infinity, minHeight: 1)

            // 2. VIP: tom
            Color.clear.frame(maxWidth: .infinity, minHeight: 1)
            // 3. VIP: tom
            Color.clear.frame(maxWidth: .infinity, minHeight: 1)

            Color.clear.frame(width: 28, height: 1)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .background(tint)
    }

    // MARK: - Special

    private var specialSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Specielle regler")

            VStack(spacing: 0) {
                specialRow(
                    label: "«Gå hjem»-bonus",
                    value: "+1×",
                    detail: "Vinder man sit bud, får man én ekstra portion basispoint oven i. Fx giver 8 alm med præcis 8 stik: (1+1) × 1 = 2 point — ikke kun 1.",
                    tint: Color.green.opacity(0.08)
                )
                Divider()
                specialRow(label: "Storslem (13 stik)", value: "×2", detail: "Gælder alle typer", tint: Color.pink.opacity(0.1))
                Divider()
                specialRow(label: "Klør i 3. VIP", value: "×2", detail: "Oven i VIP-multiplier", tint: Color.orange.opacity(0.1))
                Divider()
                specialRow(label: "Duestraf", value: "72", detail: "Straffet: −72 / øvrige: +24", tint: Color.yellow.opacity(0.15))
            }
        }
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(.secondarySystemGroupedBackground)))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func specialRow(label: String, value: String, detail: String, tint: Color) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline.weight(.medium))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(value)
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(tint)
    }

    // MARK: - Rangerings-note

    private var rankingNote: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Rangering", systemImage: "arrow.up.arrow.down")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text("Tabellen er sorteret efter rangering fra lavest til højest. Sol-spil er indsat på deres plads i hierarkiet — fx ligger Sol (4 pt) over 9 alm (2 pt) men under 9 med melding, dvs. sans, halve, gode eller 1. VIP (4 pt).")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(.secondarySystemGroupedBackground)))
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 6)
    }

    private func pointCell(_ value: Int) -> some View {
        Text("\(value)")
            .font(.subheadline.monospacedDigit())
            .frame(maxWidth: .infinity)
    }

    private var thinDivider: some View {
        Rectangle()
            .fill(Color(.separator).opacity(0.3))
            .frame(height: 0.5)
    }
}

#Preview {
    NavigationStack {
        ScorecardView()
    }
}
