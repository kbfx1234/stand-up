import Foundation

public enum HabitCalendar {
    public static var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = .current
        value.firstWeekday = 2
        return value
    }
    public static func key(_ date: Date) -> String {
        let p = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", p.year!, p.month!, p.day!)
    }
    public static func date(_ key: String) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3,
              let result = calendar.date(from: DateComponents(year: parts[0], month: parts[1],
                                                               day: parts[2], hour: 12)),
              self.key(result) == key else { return nil }
        return result
    }
    public static func previous(_ key: String) -> String? {
        guard let date = date(key), let previous = calendar.date(byAdding: .day, value: -1, to: date) else { return nil }
        return self.key(previous)
    }
}
