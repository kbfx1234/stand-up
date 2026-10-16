import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: TimerStore
    @State private var draft: AppSettings
    @State private var selection: SettingsPage = .general
    @State private var saved = false

    init(store: TimerStore, initialPage: SettingsPage = .general) {
        self.store = store
        _draft = State(initialValue: store.settings)
        _selection = State(initialValue: initialPage)
    }

    var body: some View {
        NavigationSplitView {
            SettingsSidebar(selection: $selection, copy: store.copy)
                .navigationSplitViewColumnWidth(min: 190, ideal: 200, max: 220)
        } detail: {
            SettingsDetail(page: selection, draft: $draft, store: store, saved: $saved)
        }
        .navigationSplitViewStyle(.balanced)
        .toolbar(removing: .sidebarToggle)
        .frame(width: 820, height: 600)
        .environment(\.locale, store.language.locale)
        .navigationTitle("Stand Up · \(store.copy.settings)")
        .onAppear {
            draft = store.settings
            store.refreshPermissions()
        }
        .onChange(of: draft) { _, _ in saved = false }
        .onChange(of: draft.language) { _, value in store.setLanguage(value) }
    }
}
enum SettingsPage: String, CaseIterable, Identifiable {
    case general, rhythm, reminders, scenes, shortcuts, about
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .general: return "gearshape"
        case .rhythm: return "arrow.triangle.2.circlepath"
        case .reminders: return "bell"
        case .scenes: return "person.2.fill"
        case .shortcuts: return "keyboard"
        case .about: return "info.circle"
        }
    }
}
