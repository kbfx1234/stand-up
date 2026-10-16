import XCTest
@testable import StandUp
import StandUpCore

final class LocalizationTests: XCTestCase {
    func testOldSettingsKeepUserChoicesWhenLanguageIsMissing() throws {
        let data = Data(#"{"workMinutes":37,"restMinutes":12,"idleSeconds":180,"snoozeMinutes":3,"dailyGoal":4,"progressiveTraining":true,"soundEnabled":false,"floatingReminderEnabled":false,"fullScreenBreakEnabled":true,"meetingMode":true,"smartMeetingDeferral":false,"keyboardShortcutsEnabled":false,"notificationsEnabled":false}"#.utf8)
        let settings = try JSONDecoder().decode(AppSettings.self, from: data)
        XCTAssertEqual(settings.language, .system)
        XCTAssertEqual(settings.workMinutes, 37)
        XCTAssertEqual(settings.restMinutes, 12)
        XCTAssertEqual(settings.idleSeconds, 180)
        XCTAssertEqual(settings.dailyGoal, 4)
        XCTAssertTrue(settings.meetingMode)
        XCTAssertFalse(settings.soundEnabled)
        XCTAssertFalse(settings.floatingReminderEnabled)
        XCTAssertFalse(settings.notificationsEnabled)
    }
    func testLanguagePreferenceRoundTripsWithAllOtherSettings() throws {
        for language in AppLanguage.allCases {
            var settings = AppSettings()
            settings.language = language
            settings.workMinutes = 42
            settings.soundEnabled = false
            let restored = try JSONDecoder().decode(AppSettings.self, from: JSONEncoder().encode(settings))
            XCTAssertEqual(restored, settings)
        }
    }
    func testChineseVariantsFollowChineseAndUnsupportedLanguagesUseEnglish() {
        for code in ["zh-Hans-CN", "zh-Hant-TW", "zh-HK"] {
            XCTAssertEqual(AppLanguage.systemChoice(preferredLanguages: [code, "en-US"]), .chinese)
        }
        XCTAssertEqual(AppLanguage.systemChoice(preferredLanguages: ["en-US", "zh-CN"]), .english)
        XCTAssertEqual(AppLanguage.systemChoice(preferredLanguages: ["fr-FR"]), .english)
        XCTAssertEqual(AppLanguage.systemChoice(preferredLanguages: []), .english)
    }
    func testDurationLanguageMatchesExplicitSelection() {
        XCTAssertEqual(TimeText.duration(900, language: .english), "15 min")
        XCTAssertEqual(TimeText.duration(900, language: .chinese), "15 分钟")
        XCTAssertEqual(TimeText.compact(45, language: .chinese), "45秒")
        XCTAssertEqual(TimeText.compact(900, language: .english), "15m")
    }
}
