import Foundation

public enum TimerPhase: String, Codable, Sendable {
    case waiting, working, due, resting, ready, paused
}

public struct TimerSettings: Codable, Equatable, Sendable {
    public var workDuration: TimeInterval
    public var restDuration: TimeInterval
    public var idleThreshold: TimeInterval
    public var snoozeDuration: TimeInterval
    public init(workDuration: TimeInterval = 2700, restDuration: TimeInterval = 900,
                idleThreshold: TimeInterval = 90, snoozeDuration: TimeInterval = 300) {
        self.workDuration = max(1, workDuration)
        self.restDuration = max(1, restDuration)
        self.idleThreshold = max(1, idleThreshold)
        self.snoozeDuration = max(1, snoozeDuration)
    }
    public static let development = TimerSettings(workDuration: 45, restDuration: 15,
                                                  idleThreshold: 5, snoozeDuration: 5)
}

public struct TimerSnapshot: Equatable, Sendable {
    public let phase: TimerPhase
    public let elapsed: TimeInterval
    public let duration: TimeInterval
    public let completedBreaks: Int
    public let skippedBreaks: Int
    public var remaining: TimeInterval { max(0, duration - elapsed) }
    public var progress: Double { min(1, max(0, elapsed / max(1, duration))) }
}

@MainActor
public final class TimerCore {
    public private(set) var state: TimerState
    public var settings: TimerSettings
    private var lastTick: TimeInterval?
    private var previousIdle: TimeInterval = 0
    private var awaySince: TimeInterval?
    private var wasAvailable = false
    public init(settings: TimerSettings = .init(), restored: TimerState = .init()) {
        self.settings = settings
        self.state = restored
        if state.phase == .working { state.phase = .waiting }
    }
    public var phase: TimerPhase { state.phase }
    public var snapshot: TimerSnapshot {
        let rest = phase == .resting || phase == .ready
        return TimerSnapshot(phase: phase, elapsed: state.elapsed,
                             duration: rest ? settings.restDuration : settings.workDuration,
                             completedBreaks: state.completedBreaks, skippedBreaks: state.skippedBreaks)
    }
    // `now` is monotonic seconds. Wall-clock changes must not change a cycle.
    public func tick(now: TimeInterval, idle: TimeInterval, available: Bool, newInput: Bool) {
        let delta = lastTick.map { max(0, now - $0) } ?? 0
        defer { lastTick = now; previousIdle = idle; wasAvailable = available }
        guard phase != .paused else { return }

        // A sleeping Mac can stop delivering timer callbacks and then resume
        // with a large monotonic gap. That gap is away/sleep time, never work
        // or standing time. Keep the current phase and resume on the next tick.
        if delta > 5 {
            if phase == .working {
                state.phase = .waiting
                awaySince = now - delta
            }
            return
        }

        if !available || idle >= settings.idleThreshold {
            if awaySince == nil { awaySince = available ? now - idle : now }
            if phase == .working {
                if available, wasAvailable {
                    addWork(min(delta, max(0, settings.idleThreshold - previousIdle)))
                }
                if phase == .working { state.phase = .waiting }
            }
            return
        }

        if phase == .resting {
            state.elapsed = min(settings.restDuration, state.elapsed + delta)
            if state.elapsed >= settings.restDuration {
                state.completedBreaks += 1
                state.phase = .ready
            }
            return
        }
        guard phase != .ready else { return }
        if let awaySince, newInput {
            if now - awaySince >= settings.restDuration {
                state.elapsed = 0
                state.phase = .waiting
                state.snoozed = false
            }
            self.awaySince = nil
        }
        if phase == .waiting, newInput { state.phase = .working; return }
        if phase == .working, wasAvailable, delta <= 5 { addWork(delta) }
    }
    private func addWork(_ seconds: TimeInterval) {
        state.workSeconds += seconds
        state.elapsed = min(settings.workDuration, state.elapsed + seconds)
        if state.elapsed >= settings.workDuration { state.phase = .due }
    }
    public func pause() {
        guard phase != .paused else { return }
        state.beforePause = phase
        state.phase = .paused
    }
    public func beginWork() {
        guard phase == .waiting else { return }
        state.phase = .working
        lastTick = nil
        awaySince = nil
    }
    public func resetCycle() {
        state.phase = .waiting
        state.beforePause = .waiting
        state.elapsed = 0
        state.snoozed = false
        lastTick = nil
        awaySince = nil
        previousIdle = 0
        wasAvailable = false
    }
    public func resume() {
        guard phase == .paused else { return }
        state.phase = state.beforePause == .working ? .waiting : state.beforePause
        lastTick = nil
        awaySince = nil
    }
    public func startBreak() {
        guard [.working, .waiting, .due].contains(phase) else { return }
        state.phase = .resting
        state.elapsed = 0
        awaySince = nil
        lastTick = nil
    }
    public func sitDown() {
        guard phase == .resting || phase == .ready else { return }
        if phase == .resting { state.skippedBreaks += 1 }
        state.phase = .waiting
        state.elapsed = 0
        state.snoozed = false
        lastTick = nil
    }
    public func skipBreak() {
        guard phase == .due else { return }
        state.skippedBreaks += 1
        state.elapsed = 0
        state.phase = .waiting
        state.snoozed = false
        lastTick = nil
    }
    public func snooze() {
        guard phase == .due, !state.snoozed else { return }
        state.snoozed = true
        state.phase = .waiting
        state.elapsed = max(0, settings.workDuration - settings.snoozeDuration)
        lastTick = nil
    }
    public func resetDailyTotals() {
        state.workSeconds = 0; state.completedBreaks = 0; state.skippedBreaks = 0
    }
}
