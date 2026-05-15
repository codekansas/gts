import Foundation

public struct BedtimeSchedule: Equatable, Sendable {
    public static let minutesPerDay = 24 * 60

    public let startMinute: Int
    public let endMinute: Int

    public init(startMinute: Int, endMinute: Int) {
        precondition(Self.isValidMinute(startMinute), "startMinute must be in 0..<1440")
        precondition(Self.isValidMinute(endMinute), "endMinute must be in 0..<1440")
        self.startMinute = startMinute
        self.endMinute = endMinute
    }

    public func contains(date: Date, calendar: Calendar = .current) -> Bool {
        contains(minuteOfDay: Self.minuteOfDay(for: date, calendar: calendar))
    }

    public func contains(minuteOfDay minute: Int) -> Bool {
        precondition(Self.isValidMinute(minute), "minute must be in 0..<1440")

        if startMinute == endMinute {
            return true
        }

        if startMinute < endMinute {
            return startMinute <= minute && minute < endMinute
        }

        return startMinute <= minute || minute < endMinute
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
}
