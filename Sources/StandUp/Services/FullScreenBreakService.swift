import AppKit
import SwiftUI

@MainActor
final class FullScreenBreakService {
    private var windows: [NSWindow] = []

    func show(store: TimerStore) {
        dismiss()
        for screen in NSScreen.screens {
            let window = NSWindow(contentRect: screen.frame, styleMask: [.borderless],
                                  backing: .buffered, defer: false, screen: screen)
            window.level = .screenSaver
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            window.isOpaque = false
            window.backgroundColor = .black.withAlphaComponent(0.88)
            window.contentView = NSHostingView(rootView: FullScreenBreakView(store: store))
            window.makeKeyAndOrderFront(nil)
            windows.append(window)
        }
    }

    func dismiss() {
        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
    }
}

struct FullScreenBreakView: View {
    @ObservedObject var store: TimerStore
    @State private var suggestion = BreakSuggestion.random
    var body: some View {
        VStack(spacing: 22) {
            Image(systemName: "figure.walk.motion")
                .font(.system(size: 46, weight: .medium))
                .foregroundStyle(StandUpDesign.accent)
            Text(store.copy.pair("该起来活动一下了", "Time to move"))
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            Text(TimeText.clock(store.snapshot.remaining))
                .font(.system(size: 58, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
            Text(suggestion.text(language: store.language))
                .font(.title3)
                .foregroundStyle(.white.opacity(0.76))
            HStack(spacing: 12) {
                Button(store.copy.standing) { store.startBreak() }
                    .buttonStyle(.borderedProminent)
                Button(store.copy.pair("继续工作", "Keep working")) { store.resetCycle() }
                    .buttonStyle(.bordered)
            }
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .environment(\.locale, store.language.locale)
    }
}

enum BreakSuggestion: CaseIterable {
    case walk, water, shoulders, eyes
    static var random: BreakSuggestion { allCases.randomElement() ?? .walk }
    func text(language: AppLanguage) -> String {
        let copy = AppCopy(language: language)
        switch self {
        case .walk: return copy.pair("站起来走动几分钟。", "Walk for a few minutes.")
        case .water: return copy.pair("喝点水，放松一下。", "Get some water and reset.")
        case .shoulders: return copy.pair("轻轻活动肩膀，舒展背部。", "Roll your shoulders and stretch your back.")
        case .eyes: return copy.pair("离开屏幕看远处 20 秒。", "Look away from the screen for 20 seconds.")
        }
    }
}
