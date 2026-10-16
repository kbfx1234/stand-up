import AppKit

@MainActor
final class HotKeyService {
    private var monitor: Any?
    var onTogglePause: (() -> Void)?
    var onStartBreak: (() -> Void)?

    func start(enabled: Bool) {
        guard enabled, monitor == nil else { return }
        monitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard event.modifierFlags.contains([.command, .option]) else { return }
            switch event.keyCode {
            case 35: self?.onTogglePause?() // Cmd+Option+P
            case 1: self?.onStartBreak?()  // Cmd+Option+S
            default: break
            }
        }
    }

    func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }
}
