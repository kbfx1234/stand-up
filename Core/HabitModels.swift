import Foundation

public struct DailySummary: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public var workSeconds: Double
    public var completed: Int
    public var skipped: Int
    // Missing in v0.1 records: the old UI used a fixed goal of six.
    public var goal: Int?
    public var target: Int { max(1, goal ?? 6) }
    public var achieved: Bool { completed >= target }
    public init(id: String, workSeconds: Double = 0, completed: Int = 0,
                skipped: Int = 0, goal: Int? = nil) {
        self.id = id; self.workSeconds = workSeconds
        self.completed = completed; self.skipped = skipped; self.goal = goal
    }
}

public struct HabitStats: Codable, Equatable, Sendable {
    public var level = 3
    public var progressDays = 0
    public var creditedDays: Set<String> = []
    public var currentStreak = 0
    public var bestStreak = 0
    public var qualifyingDays = 0
    public var lastQualifiedDay: String?
    public var unlockedAchievements: [String] = []
    public init() {}
    public mutating func selectLevel(_ value: Int) {
        let next = min(max(value, 1), 11)
        if level != next { level = next; progressDays = 0 }
    }
    public func rhythm(from custom: TimerSettings, training: Bool) -> TimerSettings {
        guard training else { return custom }
        let rest = Double(min(max(level, 1), 11) * 5 * 60)
        return TimerSettings(workDuration: 3600 - rest, restDuration: rest,
                             idleThreshold: custom.idleThreshold,
                             snoozeDuration: min(custom.snoozeDuration, 3600 - rest))
    }
    public mutating func credit(_ day: DailySummary, training: Bool, cycleLevel: Int?) {
        guard training, cycleLevel == level, day.achieved,
              !creditedDays.contains(day.id), level < 11 else { return }
        creditedDays.insert(day.id)
        progressDays += 1
        if progressDays == 5 { level += 1; progressDays = 0 }
    }
}
