import Foundation
import SwiftData

// MARK: - Konfiguration (Info.plist + merge med genereret Info.plist)

enum LiveSessionSyncSettings {
    /// Base-URL uden trailing slash, fx `https://whist-live.vercel.app`
    static var baseURL: URL? {
        let raw = Bundle.main.object(forInfoDictionaryKey: "LiveSessionAPIBaseURL") as? String ?? ""
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let url = URL(string: trimmed) else { return nil }
        return url
    }

    static var bearerSecret: String? {
        let raw = Bundle.main.object(forInfoDictionaryKey: "LiveSessionAPISecret") as? String ?? ""
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    static var isConfigured: Bool {
        baseURL != nil && bearerSecret != nil
    }
}

// MARK: - Payload (spejler web-API)

/// Opsummering af én afsluttet kamp til brug i web-oversigten.
struct HandSummary: Encodable, Sendable {
    /// Kampnummer inden for spilledagen (#1, #2, …).
    var handNumber: Int
    /// `normal`, `sol` eller `duty`.
    var kind: String
    /// Kort resumétekst, fx «Peter meldte 9 alm. +1 → +4».
    var caption: String
    /// Point pr. plads, indekseret 0…3 (samme rækkefølge som `playerNamesBySeat`).
    var scoresBySeat: [Int]
}

struct LiveSessionPushPayload: Encodable, Sendable {
    /// Payload-schemaversion. Øges når der tilføjes felter, som breakende ændrer fortolkningen.
    var schemaVersion: Int = 2
    var sessionId: UUID
    var updatedAt: Date
    var title: String
    /// `active` eller `finished`
    var status: String
    var handCount: Int
    /// Navn pr. fysisk plads (Seat rawValue 0…3), samme rækkefølge som `totalsBySeat`.
    var playerNamesBySeat: [String]
    var totalsBySeat: [Int]
    var lastCompletedHandCaption: String?
    /// Alle afsluttede kampe i kronologisk rækkefølge (ældste først).
    var hands: [HandSummary]
    /// Struktureret plakat til «Aktivt spil» (pending kladde).
    var pendingPoster: WebPosterSnapshot?
    /// Struktureret plakat til «Seneste afsluttede spil».
    var lastHandPoster: WebPosterSnapshot?
    /// Nutids-beskrivelse af meldingen (kladde), fx «Christian melder 9 almindelige …».
    var pendingMeldingSummary: String?
    /// Kort status når resultattrinnet redigeres (stikfordeling).
    var pendingResultSummary: String?
    /// `melding`, `halve_trumf`, `resultat` eller `nil` når der ikke er kladde.
    var pendingStep: String?
    /// Offentlige noter (afkortet).
    var notesPublic: String
}

// MARK: - Snapshot fra SwiftData

enum LiveSessionSnapshotBuilder {
    private static let notesMaxLen = 500

    static func makePayload(from gameDay: GameDay) -> LiveSessionPushPayload? {
        guard LiveSessionSyncSettings.isConfigured else { return nil }

        let names = Seat.all.sorted { $0.rawValue < $1.rawValue }.map(\.playerDisplayName)
        let totalsMap = gameDay.scoreStanding.totalsBySeat
        let totals = Seat.all.sorted { $0.rawValue < $1.rawValue }.map { totalsMap[$0] ?? 0 }

        let lastHand = gameDay.hands.max { a, b in
            if a.handNumber >= 1, b.handNumber >= 1, a.handNumber != b.handNumber {
                return a.handNumber < b.handNumber
            }
            return a.playedAt < b.playedAt
        }

        let pendingInfo = pendingPayload(from: gameDay)

        let notes = gameDay.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let notesPublic = notes.count > notesMaxLen ? String(notes.prefix(notesMaxLen)) : notes

        let sortedHands = gameDay.hands.sorted {
            if $0.handNumber >= 1 && $1.handNumber >= 1 && $0.handNumber != $1.handNumber {
                return $0.handNumber < $1.handNumber
            }
            return $0.playedAt < $1.playedAt
        }
        let seatsOrdered = Seat.all.sorted { $0.rawValue < $1.rawValue }
        let handSummaries: [HandSummary] = sortedHands.map { h in
            let scoresDict = HandScorePersistence.decodeScores(h.scoresBySeatJSON)
            let scores = seatsOrdered.map { scoresDict[$0] ?? 0 }
            let cap = h.resumeCaption.trimmingCharacters(in: .whitespacesAndNewlines)
            return HandSummary(
                handNumber: h.handNumber,
                kind: h.kindRaw,
                caption: cap.isEmpty ? h.summaryLine : cap,
                scoresBySeat: scores
            )
        }

        return LiveSessionPushPayload(
            sessionId: gameDay.id,
            updatedAt: Date(),
            title: gameDay.title,
            status: gameDay.isActive ? "active" : "finished",
            handCount: gameDay.hands.count,
            playerNamesBySeat: names,
            totalsBySeat: totals,
            lastCompletedHandCaption: lastHand?.displayResumeNarrative,
            hands: handSummaries,
            pendingPoster: pendingPoster(from: gameDay),
            lastHandPoster: lastHand.flatMap { WebPosterSnapshotBuilder.fromHand($0) },
            pendingMeldingSummary: pendingInfo?.meldingLine,
            pendingResultSummary: pendingInfo?.resultLine,
            pendingStep: pendingInfo?.step,
            notesPublic: notesPublic
        )
    }

    private struct PendingLines {
        var meldingLine: String?
        var resultLine: String?
        var step: String?
    }

    private static func pendingPoster(from gameDay: GameDay) -> WebPosterSnapshot? {
        guard let pending = gameDay.pendingHand,
              let snap = try? HandDraftPersistence.decode(pending.draftJSON) else {
            return nil
        }
        var draft = HandInputDraft()
        HandDraftPersistence.apply(snap, to: draft)
        return WebPosterSnapshotBuilder.fromPending(draft: draft)
    }

    private static func pendingPayload(from gameDay: GameDay) -> PendingLines? {
        guard let pending = gameDay.pendingHand,
              let snap = try? HandDraftPersistence.decode(pending.draftJSON) else {
            return nil
        }
        var draft = HandInputDraft()
        HandDraftPersistence.apply(snap, to: draft)

        let stepRaw = snap.navigationStep
        let step = apiStep(from: stepRaw)

        let meldingLine = HandResumeCaption.presentTenseLine(from: draft)

        let resultLine: String? = {
            guard stepRaw == HandDraftPersistence.stepResultat else { return nil }
            return Self.pendingResultLine(from: draft)
        }()

        return PendingLines(meldingLine: meldingLine, resultLine: resultLine, step: step)
    }

    private static func apiStep(from navigationStep: String) -> String? {
        switch navigationStep {
        case HandDraftPersistence.stepMelding:
            return "melding"
        case HandDraftPersistence.stepHalveTrumf:
            return "halve_trumf"
        case HandDraftPersistence.stepResultat:
            return "resultat"
        default:
            return "melding"
        }
    }

    private static func pendingResultLine(from draft: HandInputDraft) -> String {
        switch draft.kind {
        case .normal:
            let p = draft.partner?.playerDisplayName ?? "—"
            return "Registrerer resultat: \(draft.actualTricks) stik — makker \(p)"
        case .sol:
            let parts = draft.solTrickInputSeats.map { seat in
                "\(seat.playerDisplayName): \(draft.solTricks[seat] ?? 0)"
            }
            let joined = parts.joined(separator: ", ")
            return "Registrerer stik (sol): \(joined)"
        case .duty:
            return "Registrerer duestraf"
        }
    }
}

// MARK: - Netværk

private actor LiveSessionAPIClient {
    static let shared = LiveSessionAPIClient()

    func send(_ payload: LiveSessionPushPayload) async {
        guard let base = LiveSessionSyncSettings.baseURL,
              let secret = LiveSessionSyncSettings.bearerSecret else { return }

        let idLower = payload.sessionId.uuidString.lowercased()
        let url = base.appendingPathComponent("api/sessions/\(idLower)")

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(secret)", forHTTPHeaderField: "Authorization")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.withoutEscapingSlashes]

        do {
            request.httpBody = try encoder.encode(payload)
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                #if DEBUG
                print("[LiveSessionSync] HTTP \(http.statusCode) for \(url.absoluteString)")
                #endif
            }
        } catch {
            #if DEBUG
            print("[LiveSessionSync] Fejl: \(error.localizedDescription)")
            #endif
        }
    }
}

// MARK: - Synk-prioritet (styrer debounce-varighed)

enum SyncPriority {
    /// Bruger-hændelse der ændrer vedvarende state: ny dag, gemt hånd, afslut/genoptag.
    /// Kort debounce — weboverblikktet bør opdateres hurtigt.
    case committed
    /// Opdatering af pending draft under meldingsflow (autosave, trin-skift).
    /// Længere debounce — spammer ikke serveren, mens brugeren trykker rundt.
    case pending

    var debounceNanoseconds: UInt64 {
        switch self {
        case .committed: return 200_000_000    // 200 ms
        case .pending:   return 1_000_000_000  // 1 s
        }
    }
}

// MARK: - Koordinator (debounce + fingerprint + genindlæs GameDay)

@MainActor
final class LiveSessionSyncCoordinator {
    static let shared = LiveSessionSyncCoordinator()

    private var tasks: [UUID: Task<Void, Never>] = [:]
    /// Seneste sendte fingerprint pr. spilledag — bruges til at undgå gentagelses-push.
    private var lastFingerprints: [UUID: String] = [:]

    /// Planlæg et push for `gameDayId`. Allerede planlagte tasks annulleres og erstattes.
    /// - Parameter priority: `.committed` (200 ms) ved gemt/afslut, `.pending` (1 s) ved draft-ændringer.
    func schedulePush(
        gameDayId: UUID,
        modelContext: ModelContext,
        priority: SyncPriority = .committed
    ) {
        guard LiveSessionSyncSettings.isConfigured else { return }
        tasks[gameDayId]?.cancel()
        tasks[gameDayId] = Task {
            try? await Task.sleep(nanoseconds: priority.debounceNanoseconds)
            guard !Task.isCancelled else { return }
            await pushNow(gameDayId: gameDayId, modelContext: modelContext)
            tasks[gameDayId] = nil
        }
    }

    private func pushNow(gameDayId: UUID, modelContext: ModelContext) async {
        var descriptor = FetchDescriptor<GameDay>(predicate: #Predicate { $0.id == gameDayId })
        descriptor.fetchLimit = 1
        guard let day = try? modelContext.fetch(descriptor).first,
              let payload = LiveSessionSnapshotBuilder.makePayload(from: day) else { return }

        let fp = makeFingerprint(payload)
        guard lastFingerprints[gameDayId] != fp else { return }
        lastFingerprints[gameDayId] = fp

        await LiveSessionAPIClient.shared.send(payload)
    }

    /// Sammenligner felter der er synlige på weboverblikktet.
    /// `updatedAt` er bevidst udeladt — den ændrer sig altid og er ikke web-relevant state.
    private func makeFingerprint(_ p: LiveSessionPushPayload) -> String {
        let totals = p.totalsBySeat.map(String.init).joined(separator: ",")
        return [
            p.status,
            String(p.handCount),
            totals,
            p.pendingStep ?? "",
            p.pendingMeldingSummary ?? "",
            p.pendingResultSummary ?? "",
            p.lastCompletedHandCaption ?? "",
            p.notesPublic,
            p.pendingPoster.map { $0.resumeLine } ?? "",
            p.lastHandPoster.map { $0.resumeLine } ?? "",
        ].joined(separator: "\u{1F}")
    }
}

// MARK: - Web-plakat (struktureret snapshot til web-UI)

struct WebPosterScoreItem: Encodable, Sendable {
    var name: String
    var score: Int
    /// `bidder`, `partner` eller `none`
    var role: String
}

struct WebPosterSnapshot: Encodable, Sendable {
    /// `trump`, `sol` eller `text`
    var posterKind: String
    var bidderName: String
    var actionText: String
    var bidTricks: Int?
    var gameType: String?
    var trumpSuit: String?
    var partnerAceSuit: String?
    var isTrumpPending: Bool
    var actualTricks: Int?
    var resultDelta: Int?
    /// `positive`, `negative` eller `neutral`
    var borderTone: String
    var solType: String?
    var allyNames: [String]
    var scoreItems: [WebPosterScoreItem]
    var resumeLine: String
}

enum WebPosterSnapshotBuilder {
    static func fromPending(draft: HandInputDraft) -> WebPosterSnapshot {
        let resumeLine = ActiveGamePosterText.resumeLine(for: draft)
        switch draft.kind {
        case .sol:
            return WebPosterSnapshot(
                posterKind: "sol",
                bidderName: draft.solBidder?.playerDisplayName ?? "Melder",
                actionText: "MELDER",
                bidTricks: nil,
                gameType: nil,
                trumpSuit: nil,
                partnerAceSuit: nil,
                isTrumpPending: false,
                actualTricks: nil,
                resultDelta: nil,
                borderTone: "neutral",
                solType: solTypeLabel(draft.solType),
                allyNames: draft.goingWith.sorted { $0.rawValue < $1.rawValue }.map(\.playerDisplayName),
                scoreItems: [],
                resumeLine: resumeLine
            )
        case .duty:
            return textPoster(
                name: draft.dutySeat?.playerDisplayName ?? "Spiller",
                actionText: "MELDER",
                resumeLine: resumeLine
            )
        case .normal:
            if draft.isDuty {
                return textPoster(
                    name: draft.dutySeat?.playerDisplayName ?? "Spiller",
                    actionText: "MELDER",
                    resumeLine: resumeLine
                )
            }
            let trump = draft.effectiveTrumpForScoring()
            let isTrumpPending = (draft.normalSubtype == .halve || draft.normalSubtype == .vip) && trump == nil
            return WebPosterSnapshot(
                posterKind: "trump",
                bidderName: draft.bidder?.playerDisplayName ?? "Melder",
                actionText: "MELDER",
                bidTricks: draft.bidTricks,
                gameType: normalSubtypeText(draft),
                trumpSuit: draft.normalSubtype == .sans ? nil : trump?.rawValue,
                partnerAceSuit: draft.partnerAceSuit?.rawValue,
                isTrumpPending: isTrumpPending,
                actualTricks: draft.kind == .normal ? draft.actualTricks : nil,
                resultDelta: nil,
                borderTone: "neutral",
                solType: nil,
                allyNames: [],
                scoreItems: [],
                resumeLine: resumeLine
            )
        }
    }

    static func fromHand(_ hand: RecordedHand) -> WebPosterSnapshot {
        let resumeLine = ActiveGamePosterText.resultResumeLine(for: hand)
        let scoreItems = scoreItems(for: hand)
        let borderTone = borderTone(for: hand, scoreItems: scoreItems)

        if hand.kindRaw == "sol" {
            return WebPosterSnapshot(
                posterKind: "sol",
                bidderName: Seat(rawValue: hand.bidderSeatRaw)?.playerDisplayName ?? "Melder",
                actionText: "MELDTE",
                bidTricks: nil,
                gameType: nil,
                trumpSuit: nil,
                partnerAceSuit: nil,
                isTrumpPending: false,
                actualTricks: nil,
                resultDelta: parseDelta(from: hand.resumeCaption),
                borderTone: borderTone,
                solType: parseSolType(from: hand.displayResumeNarrative),
                allyNames: solAllies(for: hand).map(\.playerDisplayName),
                scoreItems: scoreItems,
                resumeLine: resumeLine
            )
        }

        if hand.kindRaw == "normal", let bidTricks = parseBidTricks(from: hand.displayResumeNarrative) {
            return WebPosterSnapshot(
                posterKind: "trump",
                bidderName: Seat(rawValue: hand.bidderSeatRaw)?.playerDisplayName ?? "Melder",
                actionText: "MELDTE",
                bidTricks: bidTricks,
                gameType: parseGameType(from: hand.displayResumeNarrative),
                trumpSuit: parseTrump(from: hand.displayResumeNarrative)?.rawValue,
                partnerAceSuit: parsePartnerAce(from: hand)?.rawValue,
                isTrumpPending: false,
                actualTricks: parseActualTricks(bidTricks: bidTricks, resumeCaption: hand.resumeCaption),
                resultDelta: parseDelta(from: hand.resumeCaption),
                borderTone: borderTone,
                solType: nil,
                allyNames: [],
                scoreItems: scoreItems,
                resumeLine: resumeLine
            )
        }

        return textPoster(
            name: Seat(rawValue: hand.bidderSeatRaw)?.playerDisplayName ?? "Spil",
            actionText: "MELDTE",
            resumeLine: resumeLine,
            borderTone: borderTone,
            scoreItems: scoreItems
        )
    }

    private static func textPoster(
        name: String,
        actionText: String,
        resumeLine: String,
        borderTone: String = "neutral",
        scoreItems: [WebPosterScoreItem] = []
    ) -> WebPosterSnapshot {
        WebPosterSnapshot(
            posterKind: "text",
            bidderName: name,
            actionText: actionText,
            bidTricks: nil,
            gameType: nil,
            trumpSuit: nil,
            partnerAceSuit: nil,
            isTrumpPending: false,
            actualTricks: nil,
            resultDelta: nil,
            borderTone: borderTone,
            solType: nil,
            allyNames: [],
            scoreItems: scoreItems,
            resumeLine: resumeLine
        )
    }

    private static func scoreItems(for hand: RecordedHand) -> [WebPosterScoreItem] {
        let scores = HandScorePersistence.decodeScores(hand.scoresBySeatJSON)
        let seats = hand.gameDay?.seatOrder ?? Seat.all.sorted { $0.rawValue < $1.rawValue }
        let bidder = Seat(rawValue: hand.bidderSeatRaw)
        let partner = hand.kindRaw == "normal" ? Seat(rawValue: hand.partnerSeatRaw) : nil
        let solAllies = hand.kindRaw == "sol" ? Set(solAllies(for: hand)) : []
        return seats.map { seat in
            let score = scores[seat] ?? 0
            let role: String
            if hand.kindRaw == "sol", solAllies.contains(seat), seat != bidder {
                role = "partner"
            } else if seat == bidder {
                role = "bidder"
            } else if hand.kindRaw == "normal", let partner, partner != bidder, seat == partner {
                role = "partner"
            } else {
                role = "none"
            }
            return WebPosterScoreItem(name: seat.playerDisplayName, score: score, role: role)
        }
    }

    private static func borderTone(for hand: RecordedHand, scoreItems: [WebPosterScoreItem]) -> String {
        let bidderScore = scoreItems.first { $0.role == "bidder" }?.score ?? 0
        if bidderScore > 0 { return "positive" }
        if bidderScore < 0 { return "negative" }
        return "neutral"
    }

    private static func normalSubtypeText(_ draft: HandInputDraft) -> String {
        if draft.normalSubtype == .vip {
            switch draft.vipLevel {
            case .single: return "VIP i første"
            case .double: return "VIP i anden"
            case .triple: return "VIP i tredje"
            }
        }
        return draft.normalSubtype.title
    }

    private static func solTypeLabel(_ type: SolType) -> String {
        switch type {
        case .normal: return "Sol"
        case .pure: return "Ren sol"
        case .halfDealer: return "½ bordlægger"
        case .dealer: return "Bordlægger"
        }
    }

    private static func solAllies(for hand: RecordedHand) -> [Seat] {
        guard let data = hand.solAlliesSeatsJSON.data(using: .utf8),
              let rawSeats = try? JSONDecoder().decode([Int].self, from: data) else {
            return []
        }
        return rawSeats.compactMap { Seat(rawValue: $0) }
    }

    private static func parseBidTricks(from narrative: String) -> Int? {
        for marker in ["meldte ", "melder "] {
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
        if lower.contains("vip") { return "VIP i første" }
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
        return lastSuit(in: String(narrative[..<range.lowerBound]))
    }

    private static func parsePartnerAce(from hand: RecordedHand) -> Suit? {
        if let range = hand.displayResumeNarrative.range(of: "som makker-es", options: .caseInsensitive) {
            return lastSuit(in: String(hand.displayResumeNarrative[..<range.lowerBound]))
        }
        return hand.partnerAceSuitRaw.flatMap { Suit(rawValue: $0) }
    }

    private static func parseSolType(from narrative: String) -> String {
        let lower = narrative.lowercased()
        if lower.contains("halv bordlægger") { return "½ bordlægger" }
        if lower.contains("bordlægger") { return "Bordlægger" }
        if lower.contains("ren sol") { return "Ren sol" }
        return "Sol"
    }

    private static func parseActualTricks(bidTricks: Int, resumeCaption: String) -> Int? {
        guard let delta = parseDelta(from: resumeCaption) else { return nil }
        return max(0, min(13, bidTricks + delta))
    }

    private static func parseDelta(from resumeCaption: String) -> Int? {
        if let range = resumeCaption.range(of: "||") {
            let token = resumeCaption[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
            return Int(token)
        }
        if let open = resumeCaption.lastIndex(of: "("),
           let close = resumeCaption.lastIndex(of: ")"),
           open < close {
            let token = resumeCaption[resumeCaption.index(after: open)..<close]
            return Int(token)
        }
        return nil
    }

    private static func lastSuit(in text: String) -> Suit? {
        text.compactMap { char -> Suit? in
            switch char {
            case "♠": return .spades
            case "♥": return .hearts
            case "♦": return .diamonds
            case "♣": return .clubs
            default: return nil
            }
        }.last
    }
}
