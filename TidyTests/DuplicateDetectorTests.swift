import XCTest
@testable import Tidy

final class DuplicateDetectorTests: XCTestCase {

    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("TidyDuplicateTests_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    func testHashingIdenticalFilesYieldsMatchingHash() throws {
        let content = "Tidy - High performance clean system test data 1234567890".data(using: .utf8)!

        let fileA = tempDirectory.appendingPathComponent("fileA.txt")
        let fileB = tempDirectory.appendingPathComponent("fileB.txt")
        let fileDifferent = tempDirectory.appendingPathComponent("fileDiff.txt")

        try content.write(to: fileA)
        try content.write(to: fileB)
        try "Different content data".data(using: .utf8)!.write(to: fileDifferent)

        let hashA = FileHasher.fullHash(for: fileA)
        let hashB = FileHasher.fullHash(for: fileB)
        let hashDiff = FileHasher.fullHash(for: fileDifferent)

        XCTAssertNotNil(hashA)
        XCTAssertNotNil(hashB)
        XCTAssertEqual(hashA, hashB, "Identical files must produce identical SHA-256")
        XCTAssertNotEqual(hashA, hashDiff, "Different files must produce distinct hashes")
    }

    func testPartialHashingForFastPreFiltering() throws {
        let largeData = Data(repeating: 0x42, count: 64 * 1024) // 64 KB

        let file1 = tempDirectory.appendingPathComponent("large1.bin")
        let file2 = tempDirectory.appendingPathComponent("large2.bin")

        try largeData.write(to: file1)
        try largeData.write(to: file2)

        let pHash1 = FileHasher.partialHash(for: file1)
        let pHash2 = FileHasher.partialHash(for: file2)

        XCTAssertNotNil(pHash1)
        XCTAssertEqual(pHash1, pHash2)
    }

    func testDuplicateGroupAutoRecommendation() {
        let oldDate = Date().addingTimeInterval(-86400 * 10)
        let newDate = Date()

        let item1 = FileItem(
            url: URL(fileURLWithPath: "/Users/test/Documents/photo.jpg"),
            size: 5000,
            modificationDate: oldDate,
            category: .image
        )

        let item2 = FileItem(
            url: URL(fileURLWithPath: "/Users/test/Downloads/photo_copy.jpg"),
            size: 5000,
            modificationDate: newDate,
            category: .image
        )

        let group = DuplicateGroup(
            hash: "dummy_hash",
            fileSize: 5000,
            files: [item1, item2]
        )

        // Rule prefers Documents over Downloads and older over newer
        XCTAssertEqual(group.recommendedKeepURL, item1.url)
        XCTAssertEqual(group.wastedBytes, 5000)
    }
}
