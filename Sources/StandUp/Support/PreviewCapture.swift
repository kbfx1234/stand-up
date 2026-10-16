#if DEBUG
import SwiftUI

@MainActor
enum PreviewCapture {
    static func render(store: TimerStore, directory: String) {
        do {
            try save(MenuBarView(store: store), size: NSSize(width: 346, height: 510),
                     path: directory + "/menu-light.png", dark: false)
            try save(MenuBarView(store: store), size: NSSize(width: 346, height: 510),
                     path: directory + "/menu-dark.png", dark: true)
            try save(SettingsView(store: store), size: NSSize(width: 820, height: 600),
                     path: directory + "/settings.png", dark: false)
            try bilingualPreviews(directory: directory)
        } catch { NSLog("Preview capture failed: %@", error.localizedDescription) }
        NSApp.terminate(nil)
    }
    private static func bilingualPreviews(directory: String) throws {
        for language in [AppLanguage.chinese, .english] {
            let store = TimerStore(previewLanguage: language)
            let suffix = language == .chinese ? "zh" : "en"
            for page in SettingsPage.allCases {
                try save(SettingsView(store: store, initialPage: page), size: NSSize(width: 820, height: 600),
                         path: directory + "/settings-\(page.rawValue)-\(suffix).png", dark: false)
            }
            try save(SettingsView(store: store), size: NSSize(width: 820, height: 600),
                     path: directory + "/settings-dark-\(suffix).png", dark: true)
            try save(MenuBarView(store: store), size: NSSize(width: 346, height: 510),
                     path: directory + "/menu-\(suffix).png", dark: false)
            try save(ProgressDashboardView(store: store), size: NSSize(width: 680, height: 720),
                     path: directory + "/progress-\(suffix).png", dark: false)
            try save(BreakPanelView(store: store, triggerID: UUID(), isPreview: true, onDismiss: {}),
                size: NSSize(width: 390, height: 154),
                path: directory + "/reminder-\(suffix).png", dark: false)
        }
    }
    private static func save<V: View>(_ view: V, size: NSSize, path: String, dark: Bool) throws {
        let host = NSHostingView(rootView: view
            .background(Color(nsColor: .windowBackgroundColor))
            .environment(\.colorScheme, dark ? .dark : .light))
        host.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size),
                              styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = host
        host.frame = NSRect(origin: .zero, size: size)
        host.layoutSubtreeIfNeeded()
        guard let bitmap = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { return }
        host.cacheDisplay(in: host.bounds, to: bitmap)
        if let png = bitmap.representation(using: .png, properties: [:]) {
            try png.write(to: URL(fileURLWithPath: path))
        }
    }
}
#endif
