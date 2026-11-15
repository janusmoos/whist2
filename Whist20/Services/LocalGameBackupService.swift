import Foundation
import SwiftData

struct BackupSeatScorePayload: Codable, Equatable, Sendable {
    var seatRaw: Int
    var seatLabel: String
    var playerName: String
    var score: Int
}

struct BackupHandPayload: Codable, Equatable, Sendable {
    var id: UUID
    var handNumber: Int
    var playedAt: Date
    var kind: String
    var summary: String
    var scoresBySeat: [BackupSeatScorePayload]
    var noteTitle: String?
    var noteText: String?
    var noteCreatedAt: Date?
}

struct GameDayBackupPayload: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var exportedAt: Date
    var gameDayId: UUID
    var title: String
    var createdAt: Date
    var endedAt: Date?
    var handCount: Int
    var seatOrder: [BackupSeatScorePayload]
    var firstDealer: BackupSeatScorePayload
    var standings: [BackupSeatScorePayload]
    var hands: [BackupHandPayload]
    var pendingHandSummary: String?
    var pendingHandStep: String?
}

struct LocalBackupResult: Equatable, Sendable {
    var directoryURL: URL
    var latestJSONURL: URL
    var latestTextURL: URL
    var sessionJSONURL: URL
    var sessionTextURL: URL
    var exportedAt: Date
}

struct LocalBackupInfo: Equatable, Sendable {
    var latestJSONURL: URL
    var latestTextURL: URL
    var modifiedAt: Date
}

enum LocalGameBackupService {
    static let directoryName = "Whist20 Backups"
    static let latestJSONFilename = "latest-session.json"
    static let latestTextFilename = "latest-session.txt"

    private static let schemaVersion = 2

    static func writeBackup(for gameDay: GameDay) throws -> LocalBackupResult {
        try writeBackup(
            payload: makePayload(for: gameDay),
            title: gameDay.title,
            in: defaultBackupDirectory()
        )
    }

    static func shareFiles(for gameDay: GameDay) throws -> [URL] {
        let result = try writeBackup(for: gameDay)
        return [result.sessionTextURL, result.sessionJSONURL]
    }

    static func latestBackupInfo(for gameDay: GameDay) -> LocalBackupInfo? {
        latestBackupInfo(for: gameDay, in: try? defaultBackupDirectory())
    }

    static func makePayload(for gameDay: GameDay, exportedAt: Date = Date()) -> GameDayBackupPayload {
        let seats = gameDay.seatOrder
        let totals = gameDay.scoreStanding.totalsBySeat
        let standings = seats
            .map { seatScorePayload(seat: $0, score: totals[$0] ?? 0) }
            .sorted {
                if $0.score != $1.score { return $0.score > $1.score }
                return $0.seatRaw < $1.seatRaw
            }
        let hands = orderedHands(for: gameDay).map { hand in
            let scores = HandScorePersistence.decodeScores(hand.scoresBySeatJSON)
            return BackupHandPayload(
                id: hand.id,
                handNumber: hand.handNumber,
                playedAt: hand.playedAt,
                kind: displayKind(for: hand.kindRaw),
                summary: hand.displayResumeNarrative,
                scoresBySeat: seats.map { seatScorePayload(seat: $0, score: scores[$0] ?? 0) },
                noteTitle: hand.hasNote && !hand.trimmedNoteTitle.isEmpty ? hand.trimmedNoteTitle : nil,
                noteText: hand.hasNote && !hand.trimmedNoteText.isEmpty ? hand.trimmedNoteText : nil,
                noteCreatedAt: hand.hasNote ? hand.noteCreatedAt : nil
            )
        }
        let pending = pendingSummary(for: gameDay)

        return GameDayBackupPayload(
            schemaVersion: schemaVersion,
            exportedAt: exportedAt,
            gameDayId: gameDay.id,
            title: gameDay.title,
            createdAt: gameDay.createdAt,
            endedAt: gameDay.endedAt,
            handCount: hands.count,
            seatOrder: seats.map { seatScorePayload(seat: $0, score: 0) },
            firstDealer: seatScorePayload(seat: gameDay.firstDealerSeat, score: 0),
            standings: standings,
            hands: hands,
            pendingHandSummary: pending?.summary,
            pendingHandStep: pending?.step
        )
    }

    static func renderTextBackup(_ payload: GameDayBackupPayload) -> String {
        var lines: [String] = []
        lines.append("Whistklubben backup")
        lines.append(payload.title)
        lines.append("Spilledag-id: \(payload.gameDayId.uuidString)")
        lines.append("Oprettet: \(formatDate(payload.createdAt))")
        if let endedAt = payload.endedAt {
            lines.append("Afsluttet: \(formatDate(endedAt))")
        } else {
            lines.append("Status: Aktiv")
        }
        lines.append("Kampe: \(payload.handCount)")
        lines.append("Dealer i spil 1: \(payload.firstDealer.playerName)")
        lines.append("")
        lines.append("Stilling")
        if payload.standings.isEmpty {
            lines.append("Ingen point endnu.")
        } else {
            for row in payload.standings {
                lines.append("\(row.playerName): \(formatScore(row.score))")
            }
        }
        lines.append("")
        lines.append("Kampe")
        if payload.hands.isEmpty {
            lines.append("Ingen gemte kampe endnu.")
        } else {
            for hand in payload.hands {
                let number = hand.handNumber > 0 ? "#\(hand.handNumber)" : "#?"
                lines.append("\(number) \(formatDate(hand.playedAt))")
                lines.append(hand.summary.isEmpty ? hand.kind : hand.summary)
                lines.append(hand.scoresBySeat.map { "\($0.playerName) \(formatScore($0.score))" }.joined(separator: ", "))
                if hand.noteTitle != nil || hand.noteText != nil {
                    lines.append("Note")
                    if let noteTitle = hand.noteTitle {
                        lines.append(noteTitle)
                    }
                    if let noteText = hand.noteText {
                        lines.append(noteText)
                    }
                    if let noteCreatedAt = hand.noteCreatedAt {
                        lines.append("Oprettet: \(formatDate(noteCreatedAt))")
                    }
                }
                lines.append("")
            }
        }
        if let pending = payload.pendingHandSummary {
            lines.append("Ikke afsluttet spil")
            lines.append(pending)
            if let step = payload.pendingHandStep {
                lines.append("Trin: \(step)")
            }
            lines.append("")
        }
        lines.append("Eksporteret: \(formatDate(payload.exportedAt))")
        return lines.joined(separator: "\n") + "\n"
    }

    static func sanitizedFilenameComponent(_ raw: String) -> String {
        let disallowed = CharacterSet(charactersIn: "/\\:?%*|\"<>")
            .union(.newlines)
            .union(.controlCharacters)
        let parts = raw
            .components(separatedBy: disallowed)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let joined = parts.joined(separator: "-")
        let collapsed = joined.replacingOccurrences(of: "--+", with: "-", options: .regularExpression)
        return collapsed.isEmpty ? "Spilledag" : String(collapsed.prefix(80))
    }

    static func writeBackup(for gameDay: GameDay, in directoryURL: URL, exportedAt: Date) throws -> LocalBackupResult {
        let payload = makePayload(for: gameDay, exportedAt: exportedAt)
        return try writeBackup(payload: payload, title: gameDay.title, in: directoryURL)
    }

    static func writeBackup(
        payload: GameDayBackupPayload,
        title: String,
        in directoryURL: URL
    ) throws -> LocalBackupResult {
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let jsonData = try encoder.encode(payload)
        let textData = Data(renderTextBackup(payload).utf8)

        let prefix = "\(sanitizedFilenameComponent(title))-\(payload.gameDayId.uuidString.prefix(8))"
        let latestJSONURL = directoryURL.appendingPathComponent(latestJSONFilename)
        let latestTextURL = directoryURL.appendingPathComponent(latestTextFilename)
        let sessionJSONURL = directoryURL.appendingPathComponent("\(prefix).json")
        let sessionTextURL = directoryURL.appendingPathComponent("\(prefix).txt")

        try jsonData.write(to: latestJSONURL, options: .atomic)
        try textData.write(to: latestTextURL, options: .atomic)
        try jsonData.write(to: sessionJSONURL, options: .atomic)
        try textData.write(to: sessionTextURL, options: .atomic)

        return LocalBackupResult(
            directoryURL: directoryURL,
            latestJSONURL: latestJSONURL,
            latestTextURL: latestTextURL,
            sessionJSONURL: sessionJSONURL,
            sessionTextURL: sessionTextURL,
            exportedAt: payload.exportedAt
        )
    }

    static func latestBackupInfo(for gameDay: GameDay, in directoryURL: URL?) -> LocalBackupInfo? {
        guard let directoryURL else { return nil }
        let prefix = "\(sanitizedFilenameComponent(gameDay.title))-\(gameDay.id.uuidString.prefix(8))"
        let jsonURL = directoryURL.appendingPathComponent("\(prefix).json")
        let textURL = directoryURL.appendingPathComponent("\(prefix).txt")
        guard FileManager.default.fileExists(atPath: jsonURL.path),
              FileManager.default.fileExists(atPath: textURL.path) else {
            return nil
        }
        let attrs = try? FileManager.default.attributesOfItem(atPath: textURL.path)
        let modifiedAt = attrs?[.modificationDate] as? Date ?? .distantPast
        return LocalBackupInfo(latestJSONURL: jsonURL, latestTextURL: textURL, modifiedAt: modifiedAt)
    }

    private static func defaultBackupDirectory() throws -> URL {
        let documents = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return documents.appendingPathComponent(directoryName, isDirectory: true)
    }

    private static func orderedHands(for gameDay: GameDay) -> [RecordedHand] {
        gameDay.hands.sorted { a, b in
            if a.handNumber > 0, b.handNumber > 0, a.handNumber != b.handNumber {
                return a.handNumber < b.handNumber
            }
            return a.playedAt < b.playedAt
        }
    }

    private static func seatScorePayload(seat: Seat, score: Int) -> BackupSeatScorePayload {
        BackupSeatScorePayload(
            seatRaw: seat.rawValue,
            seatLabel: seat.compassLabel,
            playerName: seat.playerDisplayName,
            score: score
        )
    }

    private static func pendingSummary(for gameDay: GameDay) -> (summary: String, step: String?)? {
        guard let pending = gameDay.pendingHand,
              let snapshot = try? HandDraftPersistence.decode(pending.draftJSON) else {
            return nil
        }
        let draft = HandInputDraft()
        HandDraftPersistence.apply(snapshot, to: draft)
        return (HandResumeCaption.presentTenseLine(from: draft), displayStep(for: snapshot.navigationStep))
    }

    private static func displayKind(for raw: String) -> String {
        switch raw {
        case "normal": return "Normal"
        case "sol": return "Sol"
        case "duty": return "Duestraf"
        default: return raw
        }
    }

    private static func displayStep(for raw: String) -> String {
        switch raw {
        case HandDraftPersistence.stepMelding: return "Melding"
        case HandDraftPersistence.stepHalveTrumf: return "Trumf"
        case HandDraftPersistence.stepResultat: return "Resultat"
        default: return raw
        }
    }

    private static func formatDate(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .shortened)
    }

    private static func formatScore(_ score: Int) -> String {
        score > 0 ? "+\(score)" : "\(score)"
    }
}

struct BackupDestinationStatus: Codable, Equatable, Sendable {
    var savedAt: Date
    var handNumber: Int
}

struct BackupSyncStatus: Codable, Equatable, Sendable {
    var local: BackupDestinationStatus?
    var server: BackupDestinationStatus?
    var serverError: String?
    var serverUploadPending: Bool

    static let empty = BackupSyncStatus(
        local: nil,
        server: nil,
        serverError: nil,
        serverUploadPending: false
    )
}

enum BackupStatusStore {
    static let didChange = Notification.Name("BackupStatusStore.didChange")

    private static let keyPrefix = "Whist20.BackupStatus."

    static func status(for gameDayId: UUID) -> BackupSyncStatus {
        guard let data = UserDefaults.standard.data(forKey: keyPrefix + gameDayId.uuidString),
              let status = try? JSONDecoder().decode(BackupSyncStatus.self, from: data) else {
            return .empty
        }
        return status
    }

    static func markLocalSaved(gameDayId: UUID, handNumber: Int, savedAt: Date) {
        update(gameDayId: gameDayId) { status in
            status.local = BackupDestinationStatus(savedAt: savedAt, handNumber: handNumber)
        }
    }

    static func markServerPending(gameDayId: UUID) {
        update(gameDayId: gameDayId) { status in
            status.serverUploadPending = true
            status.serverError = nil
        }
    }

    static func markServerSaved(gameDayId: UUID, handNumber: Int, savedAt: Date) {
        update(gameDayId: gameDayId) { status in
            status.server = BackupDestinationStatus(savedAt: savedAt, handNumber: handNumber)
            status.serverUploadPending = false
            status.serverError = nil
        }
    }

    static func markServerFailed(gameDayId: UUID, message: String) {
        update(gameDayId: gameDayId) { status in
            status.serverUploadPending = false
            status.serverError = message
        }
    }

    private static func update(
        gameDayId: UUID,
        mutation: (inout BackupSyncStatus) -> Void
    ) {
        var status = status(for: gameDayId)
        mutation(&status)
        if let data = try? JSONEncoder().encode(status) {
            UserDefaults.standard.set(data, forKey: keyPrefix + gameDayId.uuidString)
        }
        NotificationCenter.default.post(name: didChange, object: gameDayId)
    }
}

@MainActor
enum GameBackupCoordinator {
    static func scheduleAfterSavedGame(
        gameDay: GameDay,
        modelContext: ModelContext
    ) {
        let payload = LocalGameBackupService.makePayload(for: gameDay)
        let title = gameDay.title
        let gameDayId = gameDay.id
        let handNumber = payload.hands.map(\.handNumber).max() ?? payload.handCount

        Task.detached(priority: .utility) {
            do {
                let directory = try FileManager.default.url(
                    for: .documentDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: true
                ).appendingPathComponent(LocalGameBackupService.directoryName, isDirectory: true)
                let result = try LocalGameBackupService.writeBackup(
                    payload: payload,
                    title: title,
                    in: directory
                )
                BackupStatusStore.markLocalSaved(
                    gameDayId: gameDayId,
                    handNumber: handNumber,
                    savedAt: result.exportedAt
                )
            } catch {
                #if DEBUG
                print("[LocalGameBackup] Fejl: \(error.localizedDescription)")
                #endif
            }
        }

        if LiveSessionSyncSettings.isConfigured {
            BackupStatusStore.markServerPending(gameDayId: gameDayId)
            LiveSessionSyncCoordinator.shared.schedulePush(
                gameDayId: gameDayId,
                modelContext: modelContext,
                priority: .committed
            )
        }
    }

    static func resumeLatestBackupIfNeeded(
        gameDays: [GameDay],
        modelContext: ModelContext
    ) {
        guard let gameDay = GameDay.activeDay(in: gameDays)
                ?? GameDay.focusForStandings(in: gameDays) else { return }
        let latestHandNumber = gameDay.hands.map(\.handNumber).max() ?? gameDay.hands.count
        guard latestHandNumber > 0 else { return }

        let status = BackupStatusStore.status(for: gameDay.id)
        let localIsBehind = (status.local?.handNumber ?? 0) < latestHandNumber
        let serverIsBehind = LiveSessionSyncSettings.isConfigured
            && (status.server?.handNumber ?? 0) < latestHandNumber
        guard localIsBehind || serverIsBehind else { return }

        scheduleAfterSavedGame(gameDay: gameDay, modelContext: modelContext)
    }
}
