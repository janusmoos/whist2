import SwiftData
import SwiftUI
import UIKit

/// Startskærms-stilling: tydeligt adskilt «seneste aktivitet på én dag» vs. total på tværs af alle dage.
/// Design: tydelige tidsrammer i overskrift, rangliste, rolig baggrund — jf. leaderboard-praksis (segmentering efter periode).
struct StandingsView: View {
    @Query(sort: \GameDay.createdAt, order: .reverse) private var gameDays: [GameDay]

    /// Aktiv spilledag først; ellers seneste aktivitet som før.
    private var focusDay: GameDay? {
        if let active = GameDay.activeDay(in: gameDays) {
            return active
        }
        return GameDay.focusForStandings(in: gameDays)
    }
    private var allTimeTotals: [Seat: Int] { GameDay.allTimeSeatTotals(days: gameDays) }
    private var totalHandCount: Int { gameDays.reduce(0) { $0 + $1.hands.count } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("To niveauer")
                        .font(.subheadline.weight(.semibold))
                    Text(
                        "Spilledag er den dag, hvor I sidst gemte en kamp. Hele perioden summerer alle gemte kampe på tværs af alle spilledage."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)

                if gameDays.isEmpty {
                    ContentUnavailableView(
                        "Ingen spilledage endnu",
                        systemImage: "calendar.badge.plus",
                        description: Text("Opret en spilledag fra forsiden for at begynde at registrere kampe.")
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                } else if let day = focusDay {
                    dayStandingsCard(day: day)
                    allTimeStandingsCard()
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .padding(.bottom, 12)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Stilling")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var allTimeSubtitle: String {
        let days = gameDays.count
        let hands = totalHandCount
        return "\(days) spilledag\(days == 1 ? "" : "e") · \(hands) kamp\(hands == 1 ? "" : "e")"
    }

    private func dayCardSubtitle(_ day: GameDay) -> String {
        if let last = day.hands.map(\.playedAt).max() {
            return "\(day.title) · seneste kamp \(last.formatted(date: .abbreviated, time: .shortened))"
        }
        return "\(day.title) · oprettet \(day.createdAt.formatted(date: .abbreviated, time: .omitted))"
    }

    @ViewBuilder
    private func dayStandingsCard(day: GameDay) -> some View {
        let totals = day.scoreStanding.totalsBySeat
        let empty = day.hands.isEmpty
        standingsCardChrome(
            badge: "Seneste gemte kampe",
            title: "Spilledag",
            subtitle: dayCardSubtitle(day),
            totals: totals,
            emptyMessage: empty ? "Ingen gemte kampe på «\(day.title)» endnu." : nil,
            footer: "Kun kampe registreret på denne spilledag."
        ) {
            if !empty {
                NavigationLink {
                    PointStandingView(gameDay: day)
                } label: {
                    Label("Pointfordeling for denne dag", systemImage: "person.3.sequence")
                        .font(.subheadline.weight(.semibold))
                }
                .padding(.top, 4)
            }
        }
    }

    private func allTimeStandingsCard() -> some View {
        standingsCardChrome(
            badge: "Alle spilledage",
            title: "Hele perioden",
            subtitle: allTimeSubtitle,
            totals: allTimeTotals,
            emptyMessage: totalHandCount == 0
                ? "Når I gemmer kampe, vises den samlede stilling her."
                : nil,
            footer: "Alle gemte kampe på tværs af \(gameDays.count) spilledag\(gameDays.count == 1 ? "" : "e")."
        ) {
            EmptyView()
        }
    }

    @ViewBuilder
    private func standingsCardChrome<FooterAccessory: View>(
        badge: String,
        title: String,
        subtitle: String,
        totals: [Seat: Int],
        emptyMessage: String?,
        footer: String,
        @ViewBuilder footerAccessory: () -> FooterAccessory
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(badge.uppercased())
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .tracking(0.6)
                Text(title)
                    .font(.title2.weight(.bold))
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)

            if let emptyMessage {
                Text(emptyMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            }

            VStack(spacing: 10) {
                ForEach(StandingsPresentation.rankedRows(scores: totals)) { row in
                    standingRow(row)
                }
            }
            .accessibilityLabel("\(title), rangliste efter point")

            footerAccessory()

            Text(footer)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private func standingRow(_ row: StandingsPresentation.Row) -> some View {
        HStack(spacing: 14) {
            rankBadge(row.rank)
            Text(row.seat.playerDisplayName)
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(scoreText(row.score))
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(scoreForeground(row.score))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.primary.opacity(0.045))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Rang \(row.rank), \(row.seat.playerDisplayName), \(scoreText(row.score)) point")
    }

    private func rankBadge(_ rank: Int) -> some View {
        Text("\(rank)")
            .font(.subheadline.weight(.bold))
            .monospacedDigit()
            .foregroundStyle(rankForeground(rank))
            .frame(width: 32, height: 32)
            .background {
                Circle()
                    .fill(rankBackground(rank))
            }
            .overlay {
                Circle()
                    .strokeBorder(rankBorder(rank), lineWidth: 1)
            }
            .accessibilityHidden(true)
    }

    private func rankBackground(_ rank: Int) -> Color {
        switch rank {
        case 1: return Color.yellow.opacity(0.35)
        case 2: return Color.secondary.opacity(0.18)
        case 3: return Color.orange.opacity(0.22)
        default: return Color.secondary.opacity(0.12)
        }
    }

    private func rankBorder(_ rank: Int) -> Color {
        switch rank {
        case 1: return Color.orange.opacity(0.45)
        case 2: return Color.secondary.opacity(0.35)
        case 3: return Color.orange.opacity(0.4)
        default: return Color.secondary.opacity(0.25)
        }
    }

    private func rankForeground(_ rank: Int) -> Color {
        switch rank {
        case 1: return Color(red: 0.45, green: 0.32, blue: 0.05)
        case 2: return Color.secondary
        case 3: return Color(red: 0.5, green: 0.28, blue: 0.08)
        default: return Color.secondary
        }
    }

    private func scoreText(_ value: Int) -> String {
        if value > 0 { return "+\(value)" }
        return "\(value)"
    }

    private func scoreForeground(_ value: Int) -> Color {
        switch value {
        case let x where x > 0:
            return Color(red: 0.05, green: 0.45, blue: 0.18)
        case let x where x < 0:
            return Color(red: 0.55, green: 0.08, blue: 0.1)
        default:
            return Color.secondary
        }
    }
}
