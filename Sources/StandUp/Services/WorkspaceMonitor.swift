import AppKit
import CoreGraphics

@MainActor
final class WorkspaceMonitor {
    private var asleep = false
    private var screenAsleep = false
    private var sessionInactive = false
    private var locked = false
    private var observers: [(NotificationCenter, NSObjectProtocol)] = []
    var onChange: (() -> Void)?
    var isAvailable: Bool { !asleep && !screenAsleep && !sessionInactive && !locked }

    func start() {
        guard observers.isEmpty else { return }
        refreshSession()
        let workspace = NSWorkspace.shared.notificationCenter
        observe(workspace, NSWorkspace.willSleepNotification) { $0.asleep = true }
        observe(workspace, NSWorkspace.didWakeNotification) { $0.asleep = false }
        observe(workspace, NSWorkspace.screensDidSleepNotification) { $0.screenAsleep = true }
        observe(workspace, NSWorkspace.screensDidWakeNotification) { $0.screenAsleep = false }
        observe(workspace, NSWorkspace.sessionDidResignActiveNotification) { $0.sessionInactive = true }
        observe(workspace, NSWorkspace.sessionDidBecomeActiveNotification) { $0.sessionInactive = false }
        // These system notification names are not a documented Apple API contract.
        // Keep the adapter isolated and verify actual lock/unlock on each supported OS.
        let distributed = DistributedNotificationCenter.default()
        observe(distributed, .init("com.apple.screenIsLocked")) { $0.locked = true }
        observe(distributed, .init("com.apple.screenIsUnlocked")) { $0.locked = false }
    }
    func refreshSession() {
        guard let info = CGSessionCopyCurrentDictionary() as? [String: Any] else { return }
        // During wake the session dictionary can be temporarily incomplete.
        // Preserve the last known value until macOS publishes an explicit Bool.
        if let onConsole = info[kCGSessionOnConsoleKey as String] as? Bool {
            sessionInactive = !onConsole
        }
        // The key is present while the screen is locked and absent after unlock.
        // Reading it on every poll also covers systems where the distributed
        // notification arrives late or is coalesced during wake.
        locked = (info["CGSSessionScreenIsLocked"] as? Bool) ?? false
    }

    func recoverAfterWake() {
        asleep = false
        screenAsleep = false
        sessionInactive = false
        locked = false
        refreshSession()
    }
    func stop() {
        for (center, token) in observers { center.removeObserver(token) }
        observers.removeAll()
    }
    private func observe(_ center: NotificationCenter, _ name: Notification.Name,
                         change: @escaping @MainActor (WorkspaceMonitor) -> Void) {
        let token = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                change(self)
                self.onChange?()
            }
        }
        observers.append((center, token))
    }
}
