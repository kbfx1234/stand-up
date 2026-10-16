import AppKit
import SwiftUI

@MainActor
final class BreakPanelService {
    private var panel: NSPanel?
    private var hosting: NSHostingController<BreakPanelView>?

    func show(store: TimerStore, isPreview: Bool = false) {
        if let panel {
            hosting?.rootView = BreakPanelView(store: store, triggerID: UUID(), isPreview: isPreview,
                                                onDismiss: { [weak self] in self?.dismiss() })
            panel.orderFrontRegardless()
            return
        }
        let controller = NSHostingController(rootView: BreakPanelView(
            store: store, triggerID: UUID(), isPreview: isPreview,
            onDismiss: { [weak self] in self?.dismiss() }))
        let panel = NSPanel(contentViewController: controller)
        panel.styleMask = [.borderless, .nonactivatingPanel]
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.titleVisibility = .hidden
        panel.contentView?.wantsLayer = true
        panel.contentView?.layer?.cornerRadius = 18
        panel.contentView?.layer?.masksToBounds = true
        position(panel)
        hosting = controller
        self.panel = panel
        panel.orderFrontRegardless()
    }

    func dismiss() { panel?.orderOut(nil) }

    private func position(_ panel: NSPanel) {
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        let size = NSSize(width: 390, height: 154)
        panel.setContentSize(size)
        panel.setFrameOrigin(NSPoint(x: visible.midX - size.width / 2,
                                     y: visible.maxY - size.height - 28))
    }
}

struct BreakPanelView: View {
    @ObservedObject var store: TimerStore
    let triggerID: UUID
    let isPreview: Bool
    let onDismiss: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    @State private var iconPulse = false
    @State private var nudgeOffset: CGFloat = 0
    @State private var borderPulse = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "figure.stand")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(StandUpDesign.accent)
                    .scaleEffect(iconPulse ? 1.1 : 1)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Stand up for a moment")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                    Text("You have reached your work limit")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text(TimeText.shortEnglish(store.timerSettings.restDuration))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .monospacedDigit()
            }
            HStack(spacing: 8) {
                Button("I'm standing") { isPreview ? onDismiss() : store.startBreak() }
                    .buttonStyle(.borderedProminent)
                Button("Snooze") { isPreview ? onDismiss() : store.snooze() }
                    .buttonStyle(.bordered)
                Button("Skip") { isPreview ? onDismiss() : store.skipBreak() }
                    .buttonStyle(.borderless)
            }
            .controlSize(.small)
        }
        .padding(18)
        .frame(width: 390, height: 154, alignment: .leading)
        .background(.regularMaterial)
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(StandUpDesign.accent.opacity(borderPulse ? 0.72 : 0.18),
                        lineWidth: borderPulse ? 2.0 : 0.7)
        }
        .opacity(appeared || reduceMotion ? 1 : 0)
        .scaleEffect(appeared || reduceMotion ? 1 : 0.94)
        .offset(x: nudgeOffset, y: appeared || reduceMotion ? 0 : -18)
        .animation(reduceMotion ? nil : .spring(response: 0.42, dampingFraction: 0.82), value: appeared)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.1), value: nudgeOffset)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: borderPulse)
        .id(triggerID)
        .onAppear { startAttentionSequence() }
    }

    private func startAttentionSequence() {
        guard !reduceMotion else {
            appeared = true
            return
        }
        withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
            appeared = true
        }
        withAnimation(.spring(response: 0.24, dampingFraction: 0.38)) { iconPulse = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.45)) { self.iconPulse = false }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) {
            withAnimation(.easeInOut(duration: 0.16)) { self.borderPulse = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) {
                withAnimation(.easeInOut(duration: 0.16)) { self.borderPulse = false }
            }
            self.nudge(steps: [10, -10, 8, -6, 0], index: 0)
        }
    }

    private func nudge(steps: [CGFloat], index: Int) {
        guard index < steps.count else { return }
        withAnimation(.easeOut(duration: 0.1)) { nudgeOffset = steps[index] }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            self.nudge(steps: steps, index: index + 1)
        }
    }
}
