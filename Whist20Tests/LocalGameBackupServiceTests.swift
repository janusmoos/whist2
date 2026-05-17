import XCTest
@testable import Whist20

final class LocalGameBackupServiceTests: XCTestCase {
    private let exportedAt = Date(timeIntervalSince1970: 1_800_000_000)

    func testEmptyGameDayProducesValidPayloadAndText() {
        let day = GameDay(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            title: "Fredagswhist"
        )

        let payload = LocalGameBackupService.makePayload(for: day, exportedAt: exportedAt)
        let text = LocalGameBackupService.renderTextBackup(payload)

        XCTAssertEqual(payload.handCount, 0)
        XCTAssertTrue(payload.hands.isEmpty)
        XCTAssertTrue(text.contains("Fredagswhist"))
        XCTAssertTrue(text.contains("Ingen gemte kampe endnu."))
        XCTAssertFalse(text.contains("{"))
    }

    func testMultipleHandsProduceCorrectStandingsAndHandNumberOrder() {
        let day = GameDay(title: "Pointaften")
        let newerLowNumber = RecordedHand(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            playedAt: Date(timeIntervalSince1970: 1_700_000_200),
            kindRaw: "normal",
            summaryLine: "Spil 1",
            scoresBySeatJSON: HandScorePersistence.encodeScores([.north: 4, .east: 4, .south: -4, .west: -4]),
            handNumber: 1,
            gameDay: day
        )
        let olderHighNumber = RecordedHand(
            id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            playedAt: Date(timeIntervalSince1970: 1_700_000_100),
            kindRaw: "duty",
            summaryLine: "Spil 2",
            scoresBySeatJSON: HandScorePersistence.encodeScores([.north: 24, .east: 24, .south: 24, .west: -72]),
            handNumber: 2,
            gameDay: day
        )
        day.hands = [olderHighNumber, newerLowNumber]

        let payload = LocalGameBackupService.makePayload(for: day, exportedAt: exportedAt)

        XCTAssertEqual(payload.hands.map(\.handNumber), [1, 2])
        XCTAssertEqual(payload.standings.first?.playerName, Seat.north.playerDisplayName)
        XCTAssertEqual(payload.standings.first?.score, 28)
        XCTAssertEqual(payload.standings.first(where: { $0.seatRaw == Seat.west.rawValue })?.score, -76)
    }

    func testPendingHandIsIncludedButNotCountedInStandings() throws {
        let day = GameDay(title: "Aktiv aften")
        let hand = RecordedHand(
            kindRaw: "normal",
            summaryLine: "Gemt spil",
            scoresBySeatJSON: HandScorePersistence.encodeScores([.north: 2, .east: 2, .south: -2, .west: -2]),
            handNumber: 1,
            gameDay: day
        )
        day.hands = [hand]

        let draft = HandInputDraft()
        draft.bidder = .north
        draft.bidTricks = 8
        draft.trumpAlm = .clubs
        draft.partnerAceSuit = .spades
        let json = try HandDraftPersistence.encode(draft, navigationStep: HandDraftPersistence.stepMelding)
        day.pendingHand = PendingHand(draftJSON: json, gameDay: day)

        let payload = LocalGameBackupService.makePayload(for: day, exportedAt: exportedAt)
        let text = LocalGameBackupService.renderTextBackup(payload)

        XCTAssertEqual(payload.handCount, 1)
        XCTAssertEqual(payload.standings.first(where: { $0.seatRaw == Seat.north.rawValue })?.score, 2)
        XCTAssertNotNil(payload.pendingHandSummary)
        XCTAssertTrue(text.contains("Ikke afsluttet spil"))
        XCTAssertTrue(text.contains("Trin: Melding"))
    }

    func testTextRenderingContainsPlayersTotalsHandNumbersAndExportDate() {
        let day = GameDay(title: "Teksttest")
        let hand = RecordedHand(
            playedAt: Date(timeIntervalSince1970: 1_700_000_000),
            kindRaw: "normal",
            summaryLine: "Christian melder 8 almindelige",
            scoresBySeatJSON: HandScorePersistence.encodeScores([.north: 2, .east: 2, .south: -2, .west: -2]),
            handNumber: 7,
            gameDay: day
        )
        day.hands = [hand]

        let text = LocalGameBackupService.renderTextBackup(
            LocalGameBackupService.makePayload(for: day, exportedAt: exportedAt)
        )

        XCTAssertTrue(text.contains("Christian"))
        XCTAssertTrue(text.contains("+2"))
        XCTAssertTrue(text.contains("#7"))
        XCTAssertTrue(text.contains("Eksporteret:"))
        XCTAssertFalse(text.contains("kindRaw"))
        XCTAssertFalse(text.contains("scoresBySeatJSON"))
    }

    func testFileWritingCreatesLatestAndSessionFilesAndSanitizesFilename() throws {
        let day = GameDay(
            id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
            title: "Fredag/Finale: runde\n1"
        )
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let result = try LocalGameBackupService.writeBackup(for: day, in: directory, exportedAt: exportedAt)

        XCTAssertTrue(FileManager.default.fileExists(atPath: result.latestJSONURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.latestTextURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.sessionJSONURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.sessionTextURL.path))
        XCTAssertFalse(result.sessionJSONURL.lastPathComponent.contains("/"))
        XCTAssertFalse(result.sessionJSONURL.lastPathComponent.contains(":"))
        XCTAssertFalse(result.sessionJSONURL.lastPathComponent.contains("\n"))
        XCTAssertTrue(result.sessionJSONURL.lastPathComponent.contains("Fredag-Finale-runde-1"))

        let info = LocalGameBackupService.latestBackupInfo(for: day, in: directory)
        XCTAssertNotNil(info)
    }
}
