import XCTest
@testable import Tidy

final class DeletionServiceTests: XCTestCase {

    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("TidyDeletionTests_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    func testDryRunDoesNotRemoveFiles() async throws {
        let testFile = tempDirectory.appendingPathComponent("test_dryrun.txt")
        try "Protected simulation content".data(using: .utf8)!.write(to: testFile)

        let report = await DeletionService.shared.delete(urls: [testFile], mode: .trash, dryRun: true)

        XCTAssertEqual(report.mode, .dryRun)
        XCTAssertEqual(report.succeededURLs.count, 1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: testFile.path), "Dry run must never delete physical files")
    }

    func testProtectedPathIsRefused() async throws {
        let protectedURL = URL(fileURLWithPath: "/System")

        let report = await DeletionService.shared.delete(urls: [protectedURL], mode: .trash)

        XCTAssertFalse(report.isCompleteSuccess)
        XCTAssertEqual(report.failedItems.count, 1)
        XCTAssertTrue(report.succeededURLs.isEmpty)
    }

    func testRecyclingMovesFile() async throws {
        let testFile = tempDirectory.appendingPathComponent("test_recycle.txt")
        try "Ready for trash".data(using: .utf8)!.write(to: testFile)

        let report = await DeletionService.shared.delete(urls: [testFile], mode: .trash, dryRun: false)

        XCTAssertEqual(report.succeededURLs.count, 1)
        XCTAssertFalse(FileManager.default.fileExists(atPath: testFile.path), "File should no longer be at original path")
    }
}
