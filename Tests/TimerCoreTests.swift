import XCTest
@testable import StandUpCore

@MainActor
final class TimerCoreTests: XCTestCase {
    private func make() -> TimerCore {
        TimerCore(settings: TimerSettings(workDuration: 10, restDuration: 5,
                                         idleThreshold: 3, snoozeDuration: 2))
    }
    private func active(_ timer: TimerCore, _ time: Double) {
        timer.tick(now: time, idle: 0, available: true, newInput: true)
    }
    private func workUntilDue(_ timer: TimerCore) {
        for t in 0...10 { active(timer, Double(t)) }
    }
    func testStartupWaitsForNewInputNotRecentInput() {
        let timer = make()
        for t in 0...8 { timer.tick(now: Double(t), idle: 1, available: true, newInput: false) }
        XCTAssertEqual(timer.phase, .waiting)
        XCTAssertEqual(timer.state.elapsed, 0)
        active(timer, 9)
        active(timer, 10)
        XCTAssertEqual(timer.state.elapsed, 1)
    }
    func testThresholdRequiresConfirmationAndDoesNotCreditBreak() {
        let timer = make()
        workUntilDue(timer)
        XCTAssertEqual(timer.phase, .due)
        for t in 11...30 { active(timer, Double(t)) }
        XCTAssertEqual(timer.phase, .due)
        XCTAssertEqual(timer.state.completedBreaks, 0)
        XCTAssertEqual(timer.state.workSeconds, 10)
    }
    func testStandingInputDoesNotCancelRest() {
        let timer = make()
        workUntilDue(timer)
        timer.startBreak()
        for t in 11...15 { active(timer, Double(t)) }
        XCTAssertEqual(timer.phase, .resting)
        active(timer, 16)
        XCTAssertEqual(timer.phase, .ready)
        active(timer, 20)
        XCTAssertEqual(timer.state.completedBreaks, 1)
        timer.sitDown()
        active(timer, 21)
        XCTAssertEqual(timer.phase, .working)
        XCTAssertEqual(timer.state.elapsed, 0)
    }
    func testShortLockPreservesWorkAndInputCannotUnlock() {
        let timer = make()
        for t in 0...4 { active(timer, Double(t)) }
        timer.tick(now: 5, idle: 0, available: false, newInput: true)
        timer.tick(now: 6, idle: 0, available: false, newInput: true)
        XCTAssertEqual(timer.phase, .waiting)
        XCTAssertEqual(timer.state.elapsed, 4)
        active(timer, 7)
        active(timer, 8)
        XCTAssertEqual(timer.state.elapsed, 5)
    }
    func testLongAbsenceResetsCycleWithoutInventingStandingStats() {
        let timer = make()
        for t in 0...4 { active(timer, Double(t)) }
        timer.tick(now: 5, idle: 0, available: false, newInput: false)
        active(timer, 50)
        XCTAssertEqual(timer.state.elapsed, 4)
        XCTAssertEqual(timer.state.completedBreaks, 0)
        XCTAssertEqual(timer.phase, .waiting)
        active(timer, 51)
        XCTAssertEqual(timer.state.elapsed, 0)
        XCTAssertEqual(timer.phase, .working)
    }
    func testIdlePausesThenNewInputResumes() {
        let timer = make()
        for t in 0...2 { active(timer, Double(t)) }
        timer.tick(now: 3, idle: 1, available: true, newInput: false)
        timer.tick(now: 4, idle: 2, available: true, newInput: false)
        timer.tick(now: 5, idle: 3, available: true, newInput: false)
        XCTAssertEqual(timer.phase, .waiting)
        XCTAssertEqual(timer.state.elapsed, 5)
        active(timer, 6)
        XCTAssertEqual(timer.state.elapsed, 5)
        active(timer, 7)
        XCTAssertEqual(timer.state.elapsed, 6)
    }
    func testSnoozeAddsOnlyRequestedTimeAndIsLimited() {
        let timer = make()
        workUntilDue(timer)
        timer.snooze()
        XCTAssertEqual(timer.state.elapsed, 8)
        for t in 11...13 { active(timer, Double(t)) }
        XCTAssertEqual(timer.phase, .due)
        XCTAssertEqual(timer.state.workSeconds, 12)
        timer.snooze()
        XCTAssertEqual(timer.phase, .due)
    }
    func testManualPausePreservesPhaseAndDoesNotCountPauseTime() {
        let timer = make()
        active(timer, 0)
        active(timer, 1)
        timer.pause()
        active(timer, 100)
        XCTAssertEqual(timer.phase, .paused)
        timer.resume()
        active(timer, 101)
        active(timer, 102)
        XCTAssertEqual(timer.state.elapsed, 2)
    }
    func testRestPauseDoesNotCountPauseAsRest() {
        let timer = make()
        timer.startBreak()
        active(timer, 0)
        active(timer, 2)
        timer.pause()
        active(timer, 100)
        timer.resume()
        active(timer, 101)
        XCTAssertEqual(timer.state.elapsed, 2)
        active(timer, 104)
        XCTAssertEqual(timer.phase, .ready)
    }
    func testSkipAndEarlySitAreNotCompletedRest() {
        let timer = make()
        workUntilDue(timer)
        timer.skipBreak()
        timer.startBreak()
        active(timer, 11)
        active(timer, 12)
        timer.sitDown()
        XCTAssertEqual(timer.state.skippedBreaks, 2)
        XCTAssertEqual(timer.state.completedBreaks, 0)
    }
    func testSchedulerGapIsNotCountedAsWork() {
        let timer = make()
        active(timer, 0)
        active(timer, 1)
        active(timer, 3601)
        XCTAssertEqual(timer.state.elapsed, 1)
    }
    func testRestContinuesAcrossSleepOnlyAfterConfirmation() {
        let timer = make()
        timer.startBreak()
        active(timer, 0)
        timer.tick(now: 60, idle: 60, available: false, newInput: false)
        XCTAssertEqual(timer.phase, .resting)
        XCTAssertEqual(timer.state.elapsed, 0)
        XCTAssertEqual(timer.state.completedBreaks, 0)
        active(timer, 61)
        XCTAssertEqual(timer.phase, .resting)
        XCTAssertEqual(timer.state.elapsed, 1)
    }
    func testLongSleepGapDoesNotAdvanceRestCountdown() {
        let timer = make()
        timer.startBreak()
        active(timer, 0)
        active(timer, 1)
        timer.tick(now: 3601, idle: 3600, available: true, newInput: false)
        XCTAssertEqual(timer.phase, .resting)
        XCTAssertEqual(timer.state.elapsed, 1)
        active(timer, 3602)
        XCTAssertEqual(timer.state.elapsed, 2)
    }
    func testSavedStateRoundTripResumesWithoutOfflineCredit() throws {
        let timer = make()
        for t in 0...4 { active(timer, Double(t)) }
        let data = try JSONEncoder().encode(timer.state)
        let restored = try JSONDecoder().decode(TimerState.self, from: data)
        let next = TimerCore(settings: timer.settings, restored: restored)
        next.tick(now: 10000, idle: 0, available: true, newInput: false)
        XCTAssertEqual(next.phase, .waiting)
        XCTAssertEqual(next.state.elapsed, 4)
        active(next, 10001)
        active(next, 10002)
        XCTAssertEqual(next.state.elapsed, 5)
    }
    func testDailyRolloverKeepsCurrentCycle() {
        let timer = make()
        for t in 0...4 { active(timer, Double(t)) }
        timer.resetDailyTotals()
        XCTAssertEqual(timer.state.elapsed, 4)
        XCTAssertEqual(timer.state.workSeconds, 0)
    }
    func testResetCycleClearsCurrentPhaseButKeepsDailyTotals() {
        let timer = make()
        active(timer, 0)
        active(timer, 1)
        let total = timer.state.workSeconds
        timer.resetCycle()
        XCTAssertEqual(timer.phase, .waiting)
        XCTAssertEqual(timer.state.elapsed, 0)
        XCTAssertEqual(timer.state.workSeconds, total)
        XCTAssertEqual(timer.state.completedBreaks, 0)
    }
    func testRepeatedBreakActionDoesNotRestartRest() {
        let timer = make()
        timer.startBreak()
        active(timer, 0)
        active(timer, 2)
        timer.startBreak()
        XCTAssertEqual(timer.state.elapsed, 2)
    }
}

@MainActor
final class HabitModelsTests: XCTestCase {
    func testLegacyDailySummaryUsesSixAsGoal() {
        let data = #"{"id":"2026-10-16","workSeconds":120,"completed":4,"skipped":0}"#.data(using: .utf8)!
        let summary = try! JSONDecoder().decode(DailySummary.self, from: data)
        XCTAssertEqual(summary.target, 6)
        XCTAssertFalse(summary.achieved)
    }
    func testDailySummaryUsesGoalAtThatTime() {
        let summary = DailySummary(id: "2026-10-16", completed: 5, goal: 5)
        XCTAssertTrue(summary.achieved)
        XCTAssertEqual(summary.target, 5)
    }
    func testTrainingLevelAdvancesAfterFiveQualifyingDays() {
        var habit = HabitStats()
        let settings = TimerSettings(workDuration: 2700, restDuration: 900)
        for index in 0..<5 {
            let day = DailySummary(id: String(format: "2026-10-%02d", index + 1), completed: 6, goal: 6)
            habit.credit(day, training: true, cycleLevel: 3)
        }
        XCTAssertEqual(habit.level, 4)
        XCTAssertEqual(habit.progressDays, 0)
        XCTAssertEqual(habit.rhythm(from: settings, training: true).restDuration, 1200)
    }
    func testDuplicateDayDoesNotAdvanceTrainingTwice() {
        var habit = HabitStats()
        let day = DailySummary(id: "2026-10-16", completed: 6, goal: 6)
        habit.credit(day, training: true, cycleLevel: 3)
        habit.credit(day, training: true, cycleLevel: 3)
        XCTAssertEqual(habit.progressDays, 1)
        XCTAssertEqual(habit.creditedDays.count, 1)
    }
    func testHabitRhythmLeavesCustomSettingsWhenTrainingIsOff() {
        let settings = TimerSettings(workDuration: 2400, restDuration: 1200, idleThreshold: 180)
        var habit = HabitStats(); habit.selectLevel(7)
        XCTAssertEqual(habit.rhythm(from: settings, training: false), settings)
    }
}
