import Foundation
import GoToSleepCore

@MainActor
final class SleepPreferences: ObservableObject {
    private enum Keys {
        static let startMinute = "bedtime.startMinute"
        static let endMinute = "bedtime.endMinute"
    }

    private let calendar: Calendar
    private let defaults: UserDefaults
    private let formatter: DateFormatter

    @Published var startDate: Date {
        didSet {
            defaults.set(Self.minuteOfDay(for: startDate, calendar: calendar), forKey: Keys.startMinute)
        }
    }

    @Published var endDate: Date {
        didSet {
            defaults.set(Self.minuteOfDay(for: endDate, calendar: calendar), forKey: Keys.endMinute)
        }
    }

    init(defaults: UserDefaults = .standard, calendar: Calendar = .current) {
        self.defaults = defaults
        self.calendar = calendar

        formatter = DateFormatter()
        formatter.locale = .current
        formatter.timeStyle = .short
        formatter.dateStyle = .none

        let startMinute = Self.readMinute(
            defaults: defaults,
            key: Keys.startMinute,
            fallback: 22 * 60
        )
        let endMinute = Self.readMinute(
            defaults: defaults,
            key: Keys.endMinute,
            fallback: 7 * 60
        )

        startDate = Self.date(forMinuteOfDay: startMinute, calendar: calendar)
        endDate = Self.date(forMinuteOfDay: endMinute, calendar: calendar)
    }

    var schedule: BedtimeSchedule {
        BedtimeSchedule(
            startMinute: Self.minuteOfDay(for: startDate, calendar: calendar),
            endMinute: Self.minuteOfDay(for: endDate, calendar: calendar)
        )
    }

    var scheduleDescription: String {
        "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }

    private static func readMinute(defaults: UserDefaults, key: String, fallback: Int) -> Int {
        guard defaults.object(forKey: key) != nil else {
            return fallback
        }

        let minute = defaults.integer(forKey: key)
        return BedtimeSchedule.isValidMinute(minute) ? minute : fallback
    }

    private static func date(forMinuteOfDay minute: Int, calendar: Calendar) -> Date {
        let components = DateComponents(
            calendar: calendar,
            year: 2001,
            month: 1,
            day: 1,
            hour: minute / 60,
            minute: minute % 60
        )
        return calendar.date(from: components) ?? Date(timeIntervalSinceReferenceDate: 0)
    }

    private static func minuteOfDay(for date: Date, calendar: Calendar) -> Int {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }
}
