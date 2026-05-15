import Foundation
import GoToSleepCore

@MainActor
final class SleepPreferences: ObservableObject {
    private enum Keys {
        static let windDownStartMinute = "windDown.startMinute"
        static let startMinute = "bedtime.startMinute"
        static let endMinute = "bedtime.endMinute"
    }

    private let calendar: Calendar
    private let defaults: UserDefaults
    private let formatter: DateFormatter

    @Published var windDownStartDate: Date {
        didSet {
            defaults.set(
                Self.minuteOfDay(for: windDownStartDate, calendar: calendar),
                forKey: Keys.windDownStartMinute
            )
        }
    }

    @Published var bedtimeStartDate: Date {
        didSet {
            defaults.set(Self.minuteOfDay(for: bedtimeStartDate, calendar: calendar), forKey: Keys.startMinute)
        }
    }

    @Published var bedtimeEndDate: Date {
        didSet {
            defaults.set(Self.minuteOfDay(for: bedtimeEndDate, calendar: calendar), forKey: Keys.endMinute)
        }
    }

    init(defaults: UserDefaults = .standard, calendar: Calendar = .current) {
        self.defaults = defaults
        self.calendar = calendar

        formatter = DateFormatter()
        formatter.locale = .current
        formatter.timeStyle = .short
        formatter.dateStyle = .none

        let windDownStartMinute = Self.readMinute(
            defaults: defaults,
            key: Keys.windDownStartMinute,
            fallback: 21 * 60 + 15
        )
        let bedtimeStartMinute = Self.readMinute(
            defaults: defaults,
            key: Keys.startMinute,
            fallback: 21 * 60 + 30
        )
        let bedtimeEndMinute = Self.readMinute(
            defaults: defaults,
            key: Keys.endMinute,
            fallback: 6 * 60
        )

        windDownStartDate = Self.date(forMinuteOfDay: windDownStartMinute, calendar: calendar)
        bedtimeStartDate = Self.date(forMinuteOfDay: bedtimeStartMinute, calendar: calendar)
        bedtimeEndDate = Self.date(forMinuteOfDay: bedtimeEndMinute, calendar: calendar)
    }

    var schedule: BedtimeSchedule {
        BedtimeSchedule(
            windDownStartMinute: Self.minuteOfDay(for: windDownStartDate, calendar: calendar),
            startMinute: Self.minuteOfDay(for: bedtimeStartDate, calendar: calendar),
            endMinute: Self.minuteOfDay(for: bedtimeEndDate, calendar: calendar)
        )
    }

    var bedtimeDescription: String {
        "\(formatter.string(from: bedtimeStartDate)) - \(formatter.string(from: bedtimeEndDate))"
    }

    var windDownDescription: String {
        "\(formatter.string(from: windDownStartDate)) - \(formatter.string(from: bedtimeStartDate))"
    }

    var scheduleDescription: String {
        "Wind down \(windDownDescription), bedtime \(bedtimeDescription)"
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
