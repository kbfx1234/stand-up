import SwiftUI
import StandUpCore

@MainActor
final class TimerStore: ObservableObject {
    @Published private(set) var snapshot: TimerSnapshot
    @Published private(set) var settings: AppSettings
    @Published private(set) var history: [DailySummary]
    @Published private(set) var habit: HabitStats
    @Published private(set) var todayWorkSeconds: TimeInterval = 0
    @Published private(set) var systemAvailable = true
    @Published private(set) var notificationAvailability: NotificationAvailability = .notRequested
    var notificationStatus: String { notificationAvailability.text(language: language) }
    @Published var serviceError: String?
    @Published private(set) var loginEnabled = false
    let isDevelopmentMode: Bool
    private let core: TimerCore
    private let local: LocalStore
    private var activity = ActivityMonitor()
    private let workspace = WorkspaceMonitor()
    private let notifications = NotificationService()
    private let breakPanel = BreakPanelService()
    private let smartDeferral = SmartDeferralService()
    private let hotKeys = HotKeyService()
    private let fullScreenBreak = FullScreenBreakService()
    private let login = LaunchAtLoginService()
    private let origin = ContinuousClock.now
    private var pollTimer: Timer?
    private var day: String
    private var lastSave: TimeInterval = 0
    var timerSettings: TimerSettings { core.settings }
    var canSnooze: Bool { !core.state.snoozed }
    var trainingLevel: Int { habit.level }
    var language: AppLanguage { settings.language }
    var copy: AppCopy { AppCopy(language: settings.language) }
    init(previewLanguage: AppLanguage? = nil) {
        let dev = ProcessInfo.processInfo.arguments.contains("--dev")
        let storage = LocalStore(development: dev)
        var preferences = storage.settings()
        if let previewLanguage { preferences.language = previewLanguage }
        let saved = storage.session()
        isDevelopmentMode = dev
        local = storage
        settings = preferences
        history = saved?.history ?? []
        let savedHabit = saved?.habit ?? HabitStats()
        habit = savedHabit
        day = saved?.day ?? LocalStore.dayKey()
        core = TimerCore(settings: dev ? .development : savedHabit.rhythm(from: preferences.timerSettings,
                                                                         training: preferences.progressiveTraining),
                         restored: dev ? .init() : saved?.timer ?? .init())
        snapshot = core.snapshot
        todayWorkSeconds = core.state.workSeconds
    }
    private var now: TimeInterval {
        let value = origin.duration(to: .now).components
        return Double(value.seconds) + Double(value.attoseconds) / 1e18
    }
    func start() {
        guard pollTimer == nil else { return }
        notifications.onAction = { [weak self] action in
            switch action {
            case "START_BREAK": self?.startBreak()
            case "SNOOZE_BREAK": self?.snooze()
            default: break
            }
        }
        notifications.onError = { [weak self] message in self?.serviceError = message }
        notifications.configure(snooze: core.settings.snoozeDuration, language: language)
        workspace.onChange = { [weak self] in
            // Defer wake/sleep notifications until AppKit finishes its transition.
            Task { @MainActor in self?.handleWorkspaceChange() }
        }
        workspace.start()
        hotKeys.onTogglePause = { [weak self] in self?.pauseOrResume() }
        hotKeys.onStartBreak = { [weak self] in self?.startBreak() }
        hotKeys.start(enabled: settings.keyboardShortcutsEnabled)
        poll()
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.poll() }
        }
        RunLoop.main.add(timer, forMode: .common)
        pollTimer = timer
        refreshPermissions()
    }
    func stop() {
        pollTimer?.invalidate()
        pollTimer = nil
        workspace.stop()
        hotKeys.stop()
        save()
    }
    private func poll() {
        let time = now
        workspace.refreshSession()
        let available = workspace.isAvailable
        if !systemAvailable && available {
            activity.resetAfterUnavailable()
        }
        systemAvailable = available
        let sample = activity.sample(now: time)
        let deferred = smartDeferral.shouldDefer(settings: settings)
        rolloverDay()
        let oldPhase = core.phase
        core.tick(now: time, idle: sample.idle,
                  available: systemAvailable && !deferred,
                  newInput: sample.newInput)
        if core.phase == .due, oldPhase != .due, systemAvailable, settings.notificationsEnabled {
            notifications.sendBreakDue(restDuration: core.settings.restDuration,
                                       soundEnabled: settings.soundEnabled, language: language)
            if settings.floatingReminderEnabled { breakPanel.show(store: self) }
            if settings.fullScreenBreakEnabled { fullScreenBreak.show(store: self) }
        }
        if core.phase == .ready, oldPhase != .ready, systemAvailable, settings.notificationsEnabled {
            notifications.sendRestComplete(soundEnabled: settings.soundEnabled, language: language)
        }
        publish()
        if oldPhase != core.phase || time - lastSave >= 15 { save(); lastSave = time }
    }
    private func handleWorkspaceChange() {
        workspace.recoverAfterWake()
        activity.resetAfterUnavailable()
        poll()
    }
    func pauseOrResume() { act { core.phase == .paused ? core.resume() : core.pause() } }
    func resetCycle() { act { core.resetCycle() } }
    func beginWork() { act { core.beginWork() } }
    func startBreak() { act { core.startBreak() } }
    func sitDown() { act { core.sitDown() } }
    func skipBreak() { act { core.skipBreak() } }
    func snooze() { act { core.snooze() } }
    private func act(_ action: () -> Void) {
        // A click proves the user is back at the console. Clear transient wake
        // state before applying the action so it cannot be undone by the next tick.
        workspace.recoverAfterWake()
        poll()
        action()
        if core.phase != .due { breakPanel.dismiss() }
        if core.phase != .due { fullScreenBreak.dismiss() }
        notifications.clear()
        publish()
        save()
    }
    func update(settings value: AppSettings) {
        settings = value
        core.settings = isDevelopmentMode ? .development : habit.rhythm(from: value.timerSettings,
                                                                         training: value.progressiveTraining)
        local.save(settings: value)
        hotKeys.stop()
        hotKeys.start(enabled: value.keyboardShortcutsEnabled)
        notifications.configure(snooze: core.settings.snoozeDuration, language: language)
        publish()
        save()
    }
    func setLanguage(_ value: AppLanguage) {
        guard settings.language != value else { return }
        settings.language = value
        local.save(settings: settings)
        notifications.configure(snooze: core.settings.snoozeDuration, language: value)
    }
    func requestNotifications() {
        Task {
            do { try await notifications.requestAuthorization() }
            catch { serviceError = error.localizedDescription }
            notificationAvailability = await notifications.availability()
        }
    }
    func previewReminder() {
        if settings.floatingReminderEnabled { breakPanel.show(store: self, isPreview: true) }
        notifications.playPreview(soundEnabled: settings.soundEnabled, language: language)
    }
    func refreshPermissions() {
        loginEnabled = login.isEnabled
        Task { notificationAvailability = await notifications.availability() }
    }
    func setLogin(_ enabled: Bool) {
        do { try login.setEnabled(enabled) }
        catch { serviceError = copy.pair("登录启动设置失败：", "Launch at login failed: ") + error.localizedDescription }
        loginEnabled = login.isEnabled
    }
    private func publish() {
        snapshot = core.snapshot
        todayWorkSeconds = core.state.workSeconds
    }
    private func save() {
        recordDay()
        local.save(session: SavedSession(day: day, timer: core.state, history: history, habit: habit))
    }
    private func recordDay() {
        if let index = history.firstIndex(where: { $0.id == day }) {
            let old = history[index]
            history[index] = DailySummary(id: day, workSeconds: core.state.workSeconds,
                                          completed: core.state.completedBreaks,
                                          skipped: core.state.skippedBreaks,
                                          goal: old.goal ?? settings.dailyGoal)
        } else {
            history.append(DailySummary(id: day, workSeconds: core.state.workSeconds,
                                        completed: core.state.completedBreaks,
                                        skipped: core.state.skippedBreaks,
                                        goal: settings.dailyGoal))
        }
        updateHabitStats()
    }

    private func updateHabitStats() {
        guard let today = history.first(where: { $0.id == day }) else { return }
        let totalBreaks = history.reduce(0) { $0 + $1.completed }
        let unlocks: [(String, Bool)] = [
            ("first-break", totalBreaks >= 1),
            ("first-goal", habit.qualifyingDays >= 1),
            ("three-day-streak", habit.currentStreak >= 3),
            ("week-streak", habit.currentStreak >= 7),
            ("fifty-breaks", totalBreaks >= 50),
            ("hundred-breaks", totalBreaks >= 100)
        ]
        for (id, shouldUnlock) in unlocks where shouldUnlock && !habit.unlockedAchievements.contains(id) {
            habit.unlockedAchievements.append(id)
        }

        guard today.achieved, habit.lastQualifiedDay != day else { return }
        let previous = Calendar.current.date(byAdding: .day, value: -1, to: date(from: day))
            .map(LocalStore.dayKey)
        if previous == habit.lastQualifiedDay { habit.currentStreak += 1 }
        else { habit.currentStreak = 1 }
        habit.bestStreak = max(habit.bestStreak, habit.currentStreak)
        habit.qualifyingDays += 1
        habit.lastQualifiedDay = day
        let previousLevel = habit.level
        habit.credit(today, training: settings.progressiveTraining, cycleLevel: previousLevel)
        if habit.level != previousLevel {
            settings.applyTrainingLevel(habit.level)
            local.save(settings: settings)
            core.settings = habit.rhythm(from: settings.timerSettings, training: true)
        }
    }

    private func date(from key: String) -> Date {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        return Calendar.current.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2])) ?? Date()
    }
    private func rolloverDay() {
        let current = LocalStore.dayKey()
        guard current != day else { return }
        recordDay()
        core.resetDailyTotals()
        day = current
    }
    var phaseTitle: String {
        switch snapshot.phase {
        case .waiting: return copy.waiting
        case .working: return copy.working
        case .due: return copy.due
        case .resting: return copy.standingPhase
        case .ready: return copy.complete
        case .paused: return copy.paused
        }
    }
    var statusSymbol: String {
        switch snapshot.phase {
        case .working, .waiting: return "chair"
        case .due: return "figure.stand"
        case .resting, .ready: return "figure.walk"
        case .paused: return "pause.circle"
        }
    }
}
