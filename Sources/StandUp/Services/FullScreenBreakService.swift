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
            Text("Time to move")
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            Text(TimeText.clock(store.snapshot.remaining))
                .font(.system(size: 58, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
            Text(suggestion.text)
                .font(.title3)
                .foregroundStyle(.white.opacity(0.76))
            HStack(spacing: 12) {
                Button("I’m standing") { store.startBreak() }
                    .buttonStyle(.borderedProminent)
                Button("Keep working") { store.resetCycle() }
                    .buttonStyle(.bordered)
            }
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

enum BreakSuggestion: CaseIterable {
    case walk, water, shoulders, eyes
    static var random: BreakSuggestion { allCases.randomElement() ?? .walk }
    var text: String {
        switch self {
        case .walk: return "Walk for a few minutes."
        case .water: return "Get some water and reset."
        case .shoulders: return "Roll your shoulders and stretch your back."
        case .eyes: return "Look away from the screen for 20 seconds."
        }
    }
}
