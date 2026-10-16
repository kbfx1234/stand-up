import CoreGraphics
import Foundation

struct ActivityMonitor {
    private var lastInput: TimeInterval?
    private var rearmedAfterUnavailable = false

    mutating func resetAfterUnavailable() {
        lastInput = nil
        rearmedAfterUnavailable = true
    }

    mutating func sample(now: TimeInterval) -> (idle: TimeInterval, newInput: Bool) {
        let eventTypes: [CGEventType] = [
            .keyDown, .mouseMoved, .leftMouseDown, .rightMouseDown,
            .otherMouseDown, .scrollWheel, .flagsChanged
        ]
        let idle = eventTypes.map {
            CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: $0)
        }.min() ?? .infinity
        let eventTime = now - idle
        if rearmedAfterUnavailable {
            let newInput = idle < 1.5
            if newInput { rearmedAfterUnavailable = false }
            lastInput = eventTime
            return (idle, newInput)
        }
        let changed = lastInput.map { eventTime > $0 + 0.05 } ?? false
        lastInput = max(lastInput ?? eventTime, eventTime)
        return (idle, changed)
    }
}
