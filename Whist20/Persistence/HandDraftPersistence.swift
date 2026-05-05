import Foundation
import SwiftData

/// Gemmer/loader et påbegyndt spil (melding → resultat) som JSON på `GameDay.pendingHand`.
enum HandDraftPersistence {
    /// Brugeren er stadig på meldingssiden (gemmes ikke automatisk under redigering).
    static let stepMelding = "melding"
    /// Halve: melding afsluttet; brugeren vælger trumf før resultat.
    static let stepHalveTrumf = "halve_trumf"
    /// Brugeren er på resultat (eller appen kan være crashet dér).
    static let stepResultat = "resultat"

    struct Snapshot: Codable {
        var formatVersion: Int = 1
        var navigationStep: String

        var kindRaw: String
        var bidderRaw: Int?
        var bidTricks: Int
        var normalSubtypeRaw: String
        var trumpAlmRaw: String?
        var partnerAceSuitRaw: String?

        var solTypeRaw: String
        var solBidderRaw: Int?
        var goingWithRaw: [Int]

        var partnerRaw: Int?
        var actualTricks: Int
        var trumpAfterPlayRaw: String?
        var vipLevelRaw: String
        var vip3IsClubs: Bool

        var isDuty: Bool
        var dutySeatRaw: Int?
        var solTricksRaw: [String: Int]
    }

    static func makeSnapshot(from draft: HandInputDraft, navigationStep: String) -> Snapshot {
        let solTricks = Dictionary(uniqueKeysWithValues: Seat.all.map { seat in
            (String(seat.rawValue), draft.solTricks[seat] ?? 0)
        })
        return Snapshot(
            navigationStep: navigationStep,
            kindRaw: draft.kind.rawValue,
            bidderRaw: draft.bidder?.rawValue,
            bidTricks: draft.bidTricks,
            normalSubtypeRaw: draft.normalSubtype.rawValue,
            trumpAlmRaw: draft.trumpAlm?.rawValue,
            partnerAceSuitRaw: draft.partnerAceSuit?.rawValue,
            solTypeRaw: draft.solType.persistenceKey,
            solBidderRaw: draft.solBidder?.rawValue,
            goingWithRaw: draft.goingWith.map(\.rawValue).sorted(),
            partnerRaw: draft.partner?.rawValue,
            actualTricks: draft.actualTricks,
            trumpAfterPlayRaw: draft.trumpAfterPlay?.rawValue,
            vipLevelRaw: draft.vipLevel.rawValue,
            vip3IsClubs: draft.vipTripleClubsDoubleActive,
            isDuty: draft.isDuty,
            dutySeatRaw: draft.dutySeat?.rawValue,
            solTricksRaw: solTricks
        )
    }

    static func apply(_ snapshot: Snapshot, to draft: HandInputDraft) {
        draft.kind = AddHandKind(rawValue: snapshot.kindRaw) ?? .normal
        draft.bidder = snapshot.bidderRaw.flatMap { Seat(rawValue: $0) }
        draft.bidTricks = snapshot.bidTricks
        draft.normalSubtype = NormalBidSubtype(rawValue: snapshot.normalSubtypeRaw) ?? .alm
        draft.trumpAlm = snapshot.trumpAlmRaw.flatMap { Suit(rawValue: $0) }
        draft.partnerAceSuit = snapshot.partnerAceSuitRaw.flatMap { Suit(rawValue: $0) }

        draft.solType = SolType(persistenceKey: snapshot.solTypeRaw)
        draft.solBidder = snapshot.solBidderRaw.flatMap { Seat(rawValue: $0) }
        draft.goingWith = Set(snapshot.goingWithRaw.compactMap { Seat(rawValue: $0) })

        draft.partner = snapshot.partnerRaw.flatMap { Seat(rawValue: $0) }
        draft.actualTricks = snapshot.actualTricks
        draft.trumpAfterPlay = snapshot.trumpAfterPlayRaw.flatMap { Suit(rawValue: $0) }
        draft.vipLevel = VipLevel(rawValue: snapshot.vipLevelRaw) ?? .single
        /// Afledes nu af VIP (3.) + klør som trumf (ældre snapshots’ toggle ignoreres).
        draft.vip3IsClubs =
            draft.normalSubtype == .vip && draft.vipLevel == .triple && draft.trumpAfterPlay == .clubs
        draft.isDuty = snapshot.isDuty
        draft.dutySeat = snapshot.dutySeatRaw.flatMap { Seat(rawValue: $0) }

        var tricks: [Seat: Int] = [:]
        for seat in Seat.all {
            let key = String(seat.rawValue)
            tricks[seat] = snapshot.solTricksRaw[key] ?? 0
        }
        draft.solTricks = tricks
    }

    static func encode(_ draft: HandInputDraft, navigationStep: String) throws -> String {
        let snap = makeSnapshot(from: draft, navigationStep: navigationStep)
        let data = try JSONEncoder().encode(snap)
        guard let str = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return str
    }

    static func decode(_ json: String) throws -> Snapshot {
        guard let data = json.data(using: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return try JSONDecoder().decode(Snapshot.self, from: data)
    }

    static func upsertPending(context: ModelContext, gameDay: GameDay, draft: HandInputDraft, navigationStep: String) {
        guard let json = try? encode(draft, navigationStep: navigationStep) else { return }
        if let existing = gameDay.pendingHand {
            existing.draftJSON = json
            existing.updatedAt = Date()
        } else {
            let pending = PendingHand(draftJSON: json, gameDay: gameDay)
            gameDay.pendingHand = pending
            context.insert(pending)
        }
        try? context.save()
    }

    static func deletePending(context: ModelContext, gameDay: GameDay) {
        guard let pending = gameDay.pendingHand else { return }
        // Ryd både forward- og invers-referencen FØR vi sletter, så SwiftData
        // ikke kan ende i en mellemtilstand hvor `gameDay.pendingHand` stadig
        // peger på et soft-deleted objekt mens UI’en re-renderer.
        gameDay.pendingHand = nil
        pending.gameDay = nil
        context.delete(pending)
        try? context.save()
    }
}

private extension SolType {
    var persistenceKey: String {
        switch self {
        case .normal: return "normal"
        case .pure: return "pure"
        case .halfDealer: return "halfDealer"
        case .dealer: return "dealer"
        }
    }

    init(persistenceKey: String) {
        switch persistenceKey {
        case "pure": self = .pure
        case "halfDealer": self = .halfDealer
        case "dealer": self = .dealer
        default: self = .normal
        }
    }
}
