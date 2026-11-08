import XCTest
@testable import Tidy

final class ProtectedPathsTests: XCTestCase {

    func testSystemPathsAreProtected() {
        let systemURLs = [
            URL(fileURLWithPath: "/System"),
            URL(fileURLWithPath: "/System/Library"),
            URL(fileURLWithPath: "/usr/bin"),
            URL(fileURLWithPath: "/bin/zsh"),
            URL(fileURLWithPath: "/sbin"),
            URL(fileURLWithPath: "/Library/Preferences"),
            URL(fileURLWithPath: "/Library/Extensions"),
            URL(fileURLWithPath: "/private/var/db")
        ]

        for url in systemURLs {
            XCTAssertTrue(ProtectedPaths.isProtected(url: url), "Path should be protected: \(url.path)")
        }
    }

    func testUserCriticalRootsAreProtected() {
        let home = FileManager.default.homeDirectoryForCurrentUser

        let roots = [
            URL(fileURLWithPath: "/"),
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/Library"),
            URL(fileURLWithPath: "/Users"),
            home,
            home.appendingPathComponent("Desktop"),
            home.appendingPathComponent("Documents"),
            home.appendingPathComponent("Downloads"),
            home.appendingPathComponent("Pictures"),
            home.appendingPathComponent("Library")
        ]

        for url in roots {
            XCTAssertTrue(ProtectedPaths.isProtected(url: url), "User root should be protected: \(url.path)")
        }
    }

    func testUserSensitiveLibraryPathsAreProtected() {
        let home = FileManager.default.homeDirectoryForCurrentUser

        let sensitive = [
            home.appendingPathComponent("Library/Keychains"),
            home.appendingPathComponent("Library/Keychains/login.keychain-db"),
            home.appendingPathComponent("Library/Messages"),
            home.appendingPathComponent("Library/Messages/chat.db"),
            home.appendingPathComponent("Library/Mail"),
            home.appendingPathComponent("Library/Mobile Documents") // iCloud Drive root
        ]

        for url in sensitive {
            XCTAssertTrue(ProtectedPaths.isProtected(url: url), "Sensitive path should be protected: \(url.path)")
        }
    }

    func testPhotosLibraryPackagesAreProtected() {
        let photosURL = URL(fileURLWithPath: "/Users/user/Pictures/Photos Library.photoslibrary")
        let innerPhotosURL = photosURL.appendingPathComponent("database/Photos.sqlite")

        XCTAssertTrue(ProtectedPaths.isProtected(url: photosURL))
        XCTAssertTrue(ProtectedPaths.isProtected(url: innerPhotosURL))
    }

    func testSafeTemporaryFilesAreNotProtected() {
        let tempFile = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("tidy_safe_test.txt")
        XCTAssertFalse(ProtectedPaths.isProtected(url: tempFile))
    }
}
