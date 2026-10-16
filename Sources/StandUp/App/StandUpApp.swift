import SwiftUI

@main
struct StandUpApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    var body: some Scene {
        MenuBarExtra {
            MenuBarView(store: delegate.store)
        } label: {
            MenuBarLabel(store: delegate.store)
        }
        .menuBarExtraStyle(.window)
        Settings { SettingsView(store: delegate.store) }
        Window("Progress", id: "progress") {
            ProgressDashboardView(store: delegate.store)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let store = TimerStore()
    private var previewing = false
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "--preview"), arguments.count > index + 1 {
            previewing = true
            PreviewCapture.render(store: store, directory: arguments[index + 1])
            return
        }
        if arguments.contains("--preview-reminder") {
            previewing = true
            store.start()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.store.previewReminder()
            }
            return
        }
        #endif
        store.start()
    }
    func applicationWillTerminate(_ notification: Notification) {
        if !previewing { store.stop() }
    }
}

struct MenuBarLabel: View {
    @ObservedObject var store: TimerStore
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: store.statusSymbol)
                .font(.system(size: 12, weight: .medium))
            Text(menuTime)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .fixedSize(horizontal: true, vertical: false)
        .padding(.horizontal, 1)
        .accessibilityLabel("Stand Up, \(store.phaseTitle), \(TimeText.duration(store.snapshot.remaining))")
    }

    private var menuTime: String {
        switch store.snapshot.phase {
        case .due: return "Stand"
        case .ready: return "Done"
        case .paused: return "Pause"
        default: return TimeText.clock(store.snapshot.remaining)
        }
    }
}
