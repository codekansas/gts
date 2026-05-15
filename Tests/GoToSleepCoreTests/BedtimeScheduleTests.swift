import Foundation
import XCTest

@testable import GoToSleepCore

final class BedtimeScheduleTests: XCTestCase {
    func testOvernightScheduleContainsLateNightAndEarlyMorning() {
        let schedule = BedtimeSchedule(startMinute: 22 * 60, endMinute: 7 * 60)

        XCTAssertTrue(schedule.contains(minuteOfDay: 22 * 60))
        XCTAssertTrue(schedule.contains(minuteOfDay: 23 * 60 + 30))
        XCTAssertTrue(schedule.contains(minuteOfDay: 6 * 60 + 59))
        XCTAssertFalse(schedule.contains(minuteOfDay: 7 * 60))
        XCTAssertFalse(schedule.contains(minuteOfDay: 12 * 60))
    }

    func testSameDayScheduleContainsOnlyInteriorRange() {
        let schedule = BedtimeSchedule(startMinute: 13 * 60, endMinute: 15 * 60)

        XCTAssertFalse(schedule.contains(minuteOfDay: 12 * 60 + 59))
        XCTAssertTrue(schedule.contains(minuteOfDay: 13 * 60))
        XCTAssertTrue(schedule.contains(minuteOfDay: 14 * 60 + 59))
        XCTAssertFalse(schedule.contains(minuteOfDay: 15 * 60))
    }

    func testEqualStartAndEndMeansAllDay() {
        let schedule = BedtimeSchedule(startMinute: 0, endMinute: 0)

        XCTAssertTrue(schedule.contains(minuteOfDay: 0))
        XCTAssertTrue(schedule.contains(minuteOfDay: 12 * 60))
        XCTAssertTrue(schedule.contains(minuteOfDay: 23 * 60 + 59))
    }

    func testNormalizedMinuteWrapsAroundDayBounds() {
        XCTAssertEqual(BedtimeSchedule.normalizedMinute(0), 0)
        XCTAssertEqual(BedtimeSchedule.normalizedMinute(24 * 60), 0)
        XCTAssertEqual(BedtimeSchedule.normalizedMinute(-1), 23 * 60 + 59)
    }

    func testWindDownPhasePrecedesBedtime() {
        let schedule = BedtimeSchedule(
            windDownStartMinute: 21 * 60 + 15,
            startMinute: 21 * 60 + 30,
            endMinute: 6 * 60
        )

        XCTAssertEqual(schedule.phase(minuteOfDay: 21 * 60 + 14), .none)
        XCTAssertEqual(schedule.phase(minuteOfDay: 21 * 60 + 15), .windDown)
        XCTAssertEqual(schedule.phase(minuteOfDay: 21 * 60 + 29), .windDown)
        XCTAssertEqual(schedule.phase(minuteOfDay: 21 * 60 + 30), .bedtime)
        XCTAssertEqual(schedule.phase(minuteOfDay: 5 * 60 + 59), .bedtime)
        XCTAssertEqual(schedule.phase(minuteOfDay: 6 * 60), .none)
    }

    func testRoundedSleepLossMinutesTracksBedtimeOnly() {
        let schedule = BedtimeSchedule(
            windDownStartMinute: 21 * 60 + 15,
            startMinute: 21 * 60 + 30,
            endMinute: 6 * 60
        )

        XCTAssertNil(schedule.roundedSleepLossMinutes(minuteOfDay: 21 * 60 + 29))
        XCTAssertEqual(schedule.roundedSleepLossMinutes(minuteOfDay: 21 * 60 + 30), 0)
        XCTAssertEqual(schedule.roundedSleepLossMinutes(minuteOfDay: 21 * 60 + 37), 0)
        XCTAssertEqual(schedule.roundedSleepLossMinutes(minuteOfDay: 21 * 60 + 38), 15)
        XCTAssertEqual(schedule.roundedSleepLossMinutes(minuteOfDay: 22 * 60 + 44), 75)
        XCTAssertEqual(schedule.roundedSleepLossMinutes(minuteOfDay: 5 * 60 + 59), 510)
        XCTAssertNil(schedule.roundedSleepLossMinutes(minuteOfDay: 6 * 60))
    }
}
