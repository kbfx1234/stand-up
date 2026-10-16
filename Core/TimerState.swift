import Foundation

public struct TimerState: Codable, Equatable, Sendable {
    public var phase: TimerPhase = .waiting
    public var beforePause: TimerPhase = .waiting
    public var elapsed: TimeInterval = 0
    public var snoozed = false
    public var workSeconds: TimeInterval = 0
    public var completedBreaks = 0
    public var skippedBreaks = 0
    public init() {}
}
