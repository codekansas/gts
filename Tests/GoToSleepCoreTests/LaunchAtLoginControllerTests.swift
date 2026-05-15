import Foundation
import GoToSleepCore
import XCTest

final class LaunchAtLoginControllerTests: XCTestCase {
    private var launchAgentDirectoryURL: URL!

    override func setUpWithError() throws {
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        launchAgentDirectoryURL = temporaryDirectoryURL.appendingPathComponent(
            "GoToSleepLaunchAtLoginTests.\(UUID().uuidString)",
            isDirectory: true
        )
    }

    override func tearDownWithError() throws {
        if let launchAgentDirectoryURL {
            try? FileManager.default.removeItem(at: launchAgentDirectoryURL)
        }

        launchAgentDirectoryURL = nil
    }

    func testCurrentStatusIsUnavailableOutsideAppBundle() {
        let controller = makeController(
            bundleURL: launchAgentDirectoryURL.deletingLastPathComponent(),
            executableURL: launchAgentDirectoryURL.appendingPathComponent("GoToSleep")
        )

        XCTAssertEqual(
            controller.currentStatus(),
            LaunchAtLoginStatus(isEnabled: false, isAvailable: false)
        )
    }

    func testSetEnabledWritesLaunchAgentPlist() throws {
        let bundleURL = launchAgentDirectoryURL.appendingPathComponent("Go To Sleep.app", isDirectory: true)
        let executableURL = bundleURL.appendingPathComponent("Contents/MacOS/GoToSleep")
        let controller = makeController(bundleURL: bundleURL, executableURL: executableURL)

        let status = try controller.setEnabled(true)

        XCTAssertEqual(status, LaunchAtLoginStatus(isEnabled: true, isAvailable: true))

        let propertyList = NSDictionary(contentsOf: launchAgentFileURL) as? [String: Any]
        XCTAssertEqual(propertyList?["Label"] as? String, "com.benbolte.gotosleep")
        XCTAssertEqual(
            propertyList?["ProgramArguments"] as? [String],
            [executableURL.path, LaunchAtLoginController.launchArgument]
        )
        XCTAssertEqual(propertyList?["RunAtLoad"] as? Bool, true)
    }

    func testSetDisabledRemovesLaunchAgentPlist() throws {
        let bundleURL = launchAgentDirectoryURL.appendingPathComponent("Go To Sleep.app", isDirectory: true)
        let executableURL = bundleURL.appendingPathComponent("Contents/MacOS/GoToSleep")
        let controller = makeController(bundleURL: bundleURL, executableURL: executableURL)

        _ = try controller.setEnabled(true)
        _ = try controller.setEnabled(false)

        XCTAssertFalse(FileManager.default.fileExists(atPath: launchAgentFileURL.path))
    }

    func testSyncRegistrationIfNeededRewritesExistingLaunchAgent() throws {
        let originalBundleURL = launchAgentDirectoryURL.appendingPathComponent(
            "Old/Go To Sleep.app",
            isDirectory: true
        )
        let originalExecutableURL = originalBundleURL.appendingPathComponent("Contents/MacOS/GoToSleep")
        let originalController = makeController(
            bundleURL: originalBundleURL,
            executableURL: originalExecutableURL
        )
        _ = try originalController.setEnabled(true)

        let updatedBundleURL = launchAgentDirectoryURL.appendingPathComponent(
            "New/Go To Sleep.app",
            isDirectory: true
        )
        let updatedExecutableURL = updatedBundleURL.appendingPathComponent("Contents/MacOS/GoToSleep")
        let updatedController = makeController(
            bundleURL: updatedBundleURL,
            executableURL: updatedExecutableURL
        )

        _ = try updatedController.syncRegistrationIfNeeded()

        let propertyList = NSDictionary(contentsOf: launchAgentFileURL) as? [String: Any]
        XCTAssertEqual(
            propertyList?["ProgramArguments"] as? [String],
            [updatedExecutableURL.path, LaunchAtLoginController.launchArgument]
        )
    }

    private var launchAgentFileURL: URL {
        launchAgentDirectoryURL.appendingPathComponent("com.benbolte.gotosleep.plist")
    }

    private func makeController(
        bundleURL: URL,
        executableURL: URL
    ) -> LaunchAtLoginController {
        LaunchAtLoginController(
            fileManager: .default,
            launchAgentDirectoryURL: launchAgentDirectoryURL,
            bundleURLProvider: { bundleURL },
            executableURLProvider: { executableURL },
            bundleIdentifierProvider: { "com.benbolte.gotosleep" }
        )
    }
}
