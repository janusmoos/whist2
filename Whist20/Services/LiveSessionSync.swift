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

struct LiveSessionPushPayload: Encodable, Sendable {
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

        return LiveSessionPushPayload(
            sessionId: gameDay.id,
            updatedAt: Date(),
            title: gameDay.title,
            status: gameDay.isActive ? "active" : "finished",
            handCount: gameDay.hands.count,
            playerNamesBySeat: names,
            totalsBySeat: totals,
            lastCompletedHandCaption: lastHand?.displayResumeNarrative,
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

// MARK: - Koordinator (debounce + genindlæs GameDay)

@MainActor
final class LiveSessionSyncCoordinator {
    static let shared = LiveSessionSyncCoordinator()

    private var tasks: [UUID: Task<Void, Never>] = [:]
    private let debounceNs: UInt64 = 120_000_000

    func schedulePush(gameDayId: UUID, modelContext: ModelContext) {
        guard LiveSessionSyncSettings.isConfigured else { return }
        tasks[gameDayId]?.cancel()
        tasks[gameDayId] = Task {
            try? await Task.sleep(nanoseconds: debounceNs)
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
        await LiveSessionAPIClient.shared.send(payload)
    }
}
