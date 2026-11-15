import XCTest
@testable import Whist20

final class Whist20Tests: XCTestCase {
    func testDealerRotationCanStartAfterFirstSeat() {
        let day = GameDay(
            title: "Dealer-test",
            seatOrderJSON: "[0,1,2,3]",
            firstDealerSeatRaw: Seat.east.rawValue
        )

        XCTAssertEqual(day.dealerSeat(forHandNumber: 1), .east)
        XCTAssertEqual(day.dealerSeat(forHandNumber: 2), .south)
        XCTAssertEqual(day.dealerSeat(forHandNumber: 3), .west)
        XCTAssertEqual(day.dealerSeat(forHandNumber: 4), .north)
        XCTAssertEqual(day.dealerSeat(forHandNumber: 5), .east)
    }

    func testPlaceholder() {
        XCTAssertTrue(true)
    }
}
