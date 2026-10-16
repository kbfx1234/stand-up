import Foundation
import StandUpCore

struct AppSettings: Codable, Equatable {
    var workMinutes = 45
    var restMinutes = 15
    var idleSeconds = 90
    var snoozeMinutes = 5
    var dailyGoal = 6
    var progressiveTraining = false
    var soundEnabled = true
    var floatingReminderEnabled = true
    var fullScreenBreakEnabled = false
    var meetingMode = false
    var smartMeetingDeferral = true
    var keyboardShortcutsEnabled = true
    var notificationsEnabled = true
    var timerSettings: TimerSettings {
        TimerSettings(workDuration: Double(workMinutes * 60),
                      restDuration: Double(restMinutes * 60),
                      idleThreshold: Double(idleSeconds),
                      snoozeDuration: Double(snoozeMinutes * 60))
    }

    var trainingLevel: Int {
        min(max(restMinutes / 5, 1), 11)
    }

    mutating func applyTrainingLevel(_ level: Int) {
        let clamped = min(max(level, 1), 11)
        restMinutes = clamped * 5
        workMinutes = 60 - restMinutes
    }

    init() {}
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        workMinutes = try values.decodeIfPresent(Int.self, forKey: .workMinutes) ?? 45
        restMinutes = try values.decodeIfPresent(Int.self, forKey: .restMinutes) ?? 15
        idleSeconds = try values.decodeIfPresent(Int.self, forKey: .idleSeconds) ?? 90
        snoozeMinutes = try values.decodeIfPresent(Int.self, forKey: .snoozeMinutes) ?? 5
        dailyGoal = try values.decodeIfPresent(Int.self, forKey: .dailyGoal) ?? 6
        progressiveTraining = try values.decodeIfPresent(Bool.self, forKey: .progressiveTraining) ?? false
        soundEnabled = try values.decodeIfPresent(Bool.self, forKey: .soundEnabled) ?? true
        floatingReminderEnabled = try values.decodeIfPresent(Bool.self, forKey: .floatingReminderEnabled) ?? true
        fullScreenBreakEnabled = try values.decodeIfPresent(Bool.self, forKey: .fullScreenBreakEnabled) ?? false
        meetingMode = try values.decodeIfPresent(Bool.self, forKey: .meetingMode) ?? false
        smartMeetingDeferral = try values.decodeIfPresent(Bool.self, forKey: .smartMeetingDeferral) ?? true
        keyboardShortcutsEnabled = try values.decodeIfPresent(Bool.self, forKey: .keyboardShortcutsEnabled) ?? true
        notificationsEnabled = try values.decodeIfPresent(Bool.self, forKey: .notificationsEnabled) ?? true
    }
}
