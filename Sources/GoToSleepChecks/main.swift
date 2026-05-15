import Foundation
import GoToSleepCore

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fatalError(message)
    }
}

let overnightSchedule = BedtimeSchedule(startMinute: 22 * 60, endMinute: 7 * 60)
expect(overnightSchedule.contains(minuteOfDay: 22 * 60), "overnight schedule includes start")
expect(overnightSchedule.contains(minuteOfDay: 23 * 60 + 30), "overnight schedule includes late night")
expect(overnightSchedule.contains(minuteOfDay: 6 * 60 + 59), "overnight schedule includes early morning")
expect(!overnightSchedule.contains(minuteOfDay: 7 * 60), "overnight schedule excludes end")
expect(!overnightSchedule.contains(minuteOfDay: 12 * 60), "overnight schedule excludes midday")

let sameDaySchedule = BedtimeSchedule(startMinute: 13 * 60, endMinute: 15 * 60)
expect(!sameDaySchedule.contains(minuteOfDay: 12 * 60 + 59), "same-day schedule excludes before start")
expect(sameDaySchedule.contains(minuteOfDay: 13 * 60), "same-day schedule includes start")
expect(sameDaySchedule.contains(minuteOfDay: 14 * 60 + 59), "same-day schedule includes interior")
expect(!sameDaySchedule.contains(minuteOfDay: 15 * 60), "same-day schedule excludes end")

let allDaySchedule = BedtimeSchedule(startMinute: 0, endMinute: 0)
expect(allDaySchedule.contains(minuteOfDay: 0), "all-day schedule includes midnight")
expect(allDaySchedule.contains(minuteOfDay: 12 * 60), "all-day schedule includes midday")
expect(allDaySchedule.contains(minuteOfDay: 23 * 60 + 59), "all-day schedule includes final minute")

expect(BedtimeSchedule.normalizedMinute(0) == 0, "normalizes zero")
expect(BedtimeSchedule.normalizedMinute(24 * 60) == 0, "normalizes next midnight")
expect(BedtimeSchedule.normalizedMinute(-1) == 23 * 60 + 59, "normalizes previous minute")

let phasedSchedule = BedtimeSchedule(
    windDownStartMinute: 21 * 60 + 15,
    startMinute: 21 * 60 + 30,
    endMinute: 6 * 60
)
expect(phasedSchedule.phase(minuteOfDay: 21 * 60 + 14) == .none, "phase excludes before wind-down")
expect(phasedSchedule.phase(minuteOfDay: 21 * 60 + 15) == .windDown, "phase includes wind-down start")
expect(phasedSchedule.phase(minuteOfDay: 21 * 60 + 29) == .windDown, "phase includes wind-down interior")
expect(phasedSchedule.phase(minuteOfDay: 21 * 60 + 30) == .bedtime, "phase includes bedtime start")
expect(phasedSchedule.phase(minuteOfDay: 5 * 60 + 59) == .bedtime, "phase includes early morning")
expect(phasedSchedule.phase(minuteOfDay: 6 * 60) == .none, "phase excludes wake time")

let temporaryDirectoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(
    "GoToSleepChecks.\(UUID().uuidString)",
    isDirectory: true
)
defer {
    try? FileManager.default.removeItem(at: temporaryDirectoryURL)
}

let unavailableLaunchAtLoginController = LaunchAtLoginController(
    launchAgentDirectoryURL: temporaryDirectoryURL,
    bundleURLProvider: { temporaryDirectoryURL.deletingLastPathComponent() },
    executableURLProvider: { temporaryDirectoryURL.appendingPathComponent("GoToSleep") },
    bundleIdentifierProvider: { "com.benbolte.gotosleep" }
)
expect(
    unavailableLaunchAtLoginController.currentStatus() == LaunchAtLoginStatus(
        isEnabled: false,
        isAvailable: false
    ),
    "launch-at-login is unavailable outside an app bundle"
)

let bundleURL = temporaryDirectoryURL.appendingPathComponent("Go To Sleep.app", isDirectory: true)
let executableURL = bundleURL.appendingPathComponent("Contents/MacOS/GoToSleep")
let launchAtLoginController = LaunchAtLoginController(
    launchAgentDirectoryURL: temporaryDirectoryURL,
    bundleURLProvider: { bundleURL },
    executableURLProvider: { executableURL },
    bundleIdentifierProvider: { "com.benbolte.gotosleep" }
)
let enabledStatus = try launchAtLoginController.setEnabled(true)
expect(
    enabledStatus == LaunchAtLoginStatus(isEnabled: true, isAvailable: true),
    "launch-at-login can be enabled for an app bundle"
)

let launchAgentURL = temporaryDirectoryURL.appendingPathComponent("com.benbolte.gotosleep.plist")
let propertyList = NSDictionary(contentsOf: launchAgentURL) as? [String: Any]
expect(propertyList?["Label"] as? String == "com.benbolte.gotosleep", "launch agent has expected label")
expect(
    propertyList?["ProgramArguments"] as? [String] == [
        executableURL.path,
        LaunchAtLoginController.launchArgument,
    ],
    "launch agent points at bundled executable"
)

let disabledStatus = try launchAtLoginController.setEnabled(false)
expect(
    disabledStatus == LaunchAtLoginStatus(isEnabled: false, isAvailable: true),
    "launch-at-login can be disabled for an app bundle"
)
expect(!FileManager.default.fileExists(atPath: launchAgentURL.path), "launch agent is removed")

print("GoToSleepChecks passed")
