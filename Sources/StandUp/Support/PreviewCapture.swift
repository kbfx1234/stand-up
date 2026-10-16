#if DEBUG
import SwiftUI

@MainActor
enum PreviewCapture {
    static func render(store: TimerStore, directory: String) {
        do {
            try save(MenuBarView(store: store), size: NSSize(width: 346, height: 450),
                     path: directory + "/menu-light.png", dark: false)
            try save(MenuBarView(store: store), size: NSSize(width: 346, height: 450),
                     path: directory + "/menu-dark.png", dark: true)
            try save(SettingsView(store: store), size: NSSize(width: 480, height: 700),
                     path: directory + "/settings.png", dark: false)
        } catch { NSLog("Preview capture failed: %@", error.localizedDescription) }
        NSApp.terminate(nil)
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
