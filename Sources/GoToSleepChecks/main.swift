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

print("GoToSleepChecks passed")
