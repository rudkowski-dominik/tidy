import XCTest
@testable import Tidy

final class ByteFormatterTests: XCTestCase {

    func testZeroAndNegativeBytes() {
        XCTAssertEqual(ByteFormatter.string(from: 0), "0 B")
        XCTAssertEqual(ByteFormatter.string(from: -100), "0 B")
    }

    func testPositiveByteSizes() {
        let kb: Int64 = 1024
        let mb: Int64 = 1024 * 1024
        let gb: Int64 = 1024 * 1024 * 1024

        XCTAssertFalse(ByteFormatter.string(from: kb).isEmpty)
        XCTAssertFalse(ByteFormatter.string(from: mb).isEmpty)
        XCTAssertFalse(ByteFormatter.string(from: gb).isEmpty)
    }

    func testPercentString() {
        XCTAssertEqual(ByteFormatter.percentString(part: 50, total: 100), "50.0%")
        XCTAssertEqual(ByteFormatter.percentString(part: 0, total: 100), "0.0%")
        XCTAssertEqual(ByteFormatter.percentString(part: 10, total: 0), "0%")
    }
}
