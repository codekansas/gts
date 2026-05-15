import Foundation

public enum SleepPhase: Equatable, Sendable {
    case none
    case windDown
    case bedtime
}

public struct BedtimeSchedule: Equatable, Sendable {
    public static let minutesPerDay = 24 * 60

    public let windDownStartMinute: Int
    public let startMinute: Int
    public let endMinute: Int

    public init(startMinute: Int, endMinute: Int) {
        self.init(
            windDownStartMinute: startMinute,
            startMinute: startMinute,
            endMinute: endMinute
        )
    }

    public init(windDownStartMinute: Int, startMinute: Int, endMinute: Int) {
        precondition(Self.isValidMinute(windDownStartMinute), "windDownStartMinute must be in 0..<1440")
        precondition(Self.isValidMinute(startMinute), "startMinute must be in 0..<1440")
        precondition(Self.isValidMinute(endMinute), "endMinute must be in 0..<1440")
        self.windDownStartMinute = windDownStartMinute
        self.startMinute = startMinute
        self.endMinute = endMinute
    }

    public func contains(date: Date, calendar: Calendar = .current) -> Bool {
        contains(minuteOfDay: Self.minuteOfDay(for: date, calendar: calendar))
    }

    public func contains(minuteOfDay minute: Int) -> Bool {
        Self.intervalContains(
            minute,
            startMinute: startMinute,
            endMinute: endMinute,
            isFullDayWhenEqual: true
        )
    }

    public func phase(date: Date, calendar: Calendar = .current) -> SleepPhase {
        phase(minuteOfDay: Self.minuteOfDay(for: date, calendar: calendar))
    }

    public func phase(minuteOfDay minute: Int) -> SleepPhase {
        precondition(Self.isValidMinute(minute), "minute must be in 0..<1440")

        if contains(minuteOfDay: minute) {
            return .bedtime
        }

        if Self.intervalContains(
            minute,
            startMinute: windDownStartMinute,
            endMinute: startMinute,
            isFullDayWhenEqual: false
        ) {
            return .windDown
        }

        return .none
    }

    public static func minuteOfDay(for date: Date, calendar: Calendar = .current) -> Int {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        return hour * 60 + minute
    }

    public static func normalizedMinute(_ minute: Int) -> Int {
        let remainder = minute % minutesPerDay
        return remainder >= 0 ? remainder : remainder + minutesPerDay
    }

    public static func isValidMinute(_ minute: Int) -> Bool {
        0..<minutesPerDay ~= minute
    }

    private static func intervalContains(
        _ minute: Int,
        startMinute: Int,
        endMinute: Int,
        isFullDayWhenEqual: Bool
    ) -> Bool {
        precondition(Self.isValidMinute(minute), "minute must be in 0..<1440")

        if startMinute == endMinute {
            return isFullDayWhenEqual
        }

        if startMinute < endMinute {
            return startMinute <= minute && minute < endMinute
        }

        return startMinute <= minute || minute < endMinute
    }
}
