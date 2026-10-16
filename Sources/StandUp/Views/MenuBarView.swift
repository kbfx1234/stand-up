import SwiftUI
import StandUpCore

struct MenuBarView: View {
    @ObservedObject var store: TimerStore
    @Environment(\.openWindow) private var openWindow
    @State private var historyExpanded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var tint: Color {
        switch store.snapshot.phase {
        case .resting, .ready: return .green
        case .due: return StandUpDesign.accent
        case .paused: return .secondary
        default: return .primary
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            dailyStrip
            phaseBanner
            primaryAction
            history
            footer
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .frame(width: 346)
        .background(.regularMaterial)
        .environment(\.locale, store.language.locale)
        .onAppear { store.refreshPermissions() }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "figure.stand")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
            Text(store.copy.appName)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .tracking(-0.2)
            if store.isDevelopmentMode {
                Text("DEV")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(StandUpDesign.accent)
            }
            Spacer()
            PhaseBadge(title: store.phaseTitle, tint: tint)
        }
        .padding(.bottom, 17)
    }
    private var phaseBanner: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(tint.opacity(0.12))
                Image(systemName: store.statusSymbol)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(tint)
            }
            .frame(width: 54, height: 54)
            VStack(alignment: .leading, spacing: 4) {
                Text(eyebrow)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(StandUpDesign.muted)
                Text(TimeText.clock(store.snapshot.remaining))
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .tracking(-0.7)
                    .contentTransition(.numericText())
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(StandUpDesign.panel, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(StandUpDesign.hairline, lineWidth: 0.5))
        .padding(.bottom, 11)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(eyebrow), \(TimeText.clock(store.snapshot.remaining))")
        .help(detail)
    }

    private var primaryAction: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if store.snapshot.phase == .working || store.snapshot.phase == .resting {
                    Button { store.pauseOrResume() } label: {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 12, weight: .bold))
                            .frame(width: 42, height: 42)
                    }
                    .buttonStyle(PressableButtonStyle(fill: StandUpDesign.panelStrong))
                    .accessibilityLabel(store.copy.pauseTimerHint)
                }
                Button(action: primaryActionTapped) {
                    HStack(spacing: 10) {
                        Image(systemName: primaryActionIcon)
                            .font(.system(size: 13, weight: .semibold))
                        Text(primaryActionTitle)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 11, weight: .bold))
                            .opacity(0.65)
                    }
                    .padding(.horizontal, 14)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                }
                .buttonStyle(PressableButtonStyle(fill: actionFill, foreground: actionForeground))
                .keyboardShortcut(.defaultAction)
            }
            .accessibilityHint(primaryActionHint)

            if store.snapshot.phase == .due {
                HStack(spacing: 8) {
                    Button { store.snooze() } label: {
                        Text("\(store.copy.snooze) \(TimeText.compact(store.timerSettings.snoozeDuration, language: store.language))")
                            .padding(.horizontal, 12).padding(.vertical, 8)
                    }
                        .disabled(!store.canSnooze)
                    Button { store.skipBreak() } label: {
                        Text(store.copy.skip).padding(.horizontal, 12).padding(.vertical, 8)
                    }
                }
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .buttonStyle(PressableButtonStyle())
                .controlSize(.small)
            }
        }
        .padding(.bottom, 18)
    }

    private var dailyStrip: some View {
        HStack(spacing: 10) {
            DailyGoalCard(completed: store.snapshot.completedBreaks, goal: store.settings.dailyGoal, language: store.language)
            RhythmCard(work: store.timerSettings.workDuration, rest: store.timerSettings.restDuration, language: store.language)
        }
        .padding(.bottom, 12)
    }

    private var history: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(reduceMotion ? nil : .snappy(duration: 0.22)) { historyExpanded.toggle() }
            } label: {
                HStack {
                    Label(store.copy.recentActivity, systemImage: "calendar")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                    Spacer()
                    Image(systemName: historyExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(StandUpDesign.muted)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.vertical, 11)
            if historyExpanded {
                HistoryView(records: store.history, language: store.language)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .padding(.bottom, 10)
            }
        }
        .overlay(alignment: .top) { Rectangle().fill(StandUpDesign.hairline).frame(height: 1) }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 16) {
                SettingsLink {
                    Label(store.copy.settings, systemImage: "slider.horizontal.3")
                }
                .simultaneousGesture(TapGesture().onEnded { NSApp.activate(ignoringOtherApps: true) })
                Spacer()
                if store.notificationAvailability != .allowed {
                    Image(systemName: "bell.slash")
                        .foregroundStyle(StandUpDesign.muted)
                        .help(store.notificationStatus)
                }
                Button(store.copy.quit) { NSApp.terminate(nil) }
            }
            Button {
                openWindow(id: "progress")
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                Label(store.copy.progress, systemImage: "chart.bar.xaxis")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(StandUpDesign.muted)
            Button {
                store.resetCycle()
            } label: {
                Label(store.copy.resetTimer, systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(StandUpDesign.muted)
        }
        .font(.system(size: 11, weight: .medium, design: .rounded))
        .buttonStyle(.borderless)
        .foregroundStyle(StandUpDesign.muted)
        .padding(.top, 11)
    }

    private var eyebrow: String {
        switch store.snapshot.phase {
        case .resting: return store.copy.standingRemaining
        case .ready: return store.copy.complete
        case .due: return store.copy.standUpNow
        case .paused: return store.copy.paused
        default: return store.copy.nextStand
        }
    }
    private var detail: String {
        if !store.systemAvailable { return store.copy.systemPaused }
        switch store.snapshot.phase {
        case .waiting: return store.copy.workKept
        case .working: return store.copy.workActive
        case .due: return store.copy.pair("站起来后点击下方按钮开始休息", "Stand up, then confirm below to start the break")
        case .resting: return store.copy.pair("站着使用电脑也可以", "You can keep using the Mac while standing")
        case .ready: return store.copy.pair("坐下后开始新一轮", "Sit down to start a new cycle")
        case .paused: return store.copy.pair("恢复后继续当前节奏", "Resume to continue the current rhythm")
        }
    }
    private var primaryActionTitle: String {
        switch store.snapshot.phase {
        case .working: return store.copy.standUpNow
        case .waiting: return store.copy.startTimer
        case .due: return store.copy.standing
        case .resting, .ready: return store.copy.sitDown
        case .paused: return store.copy.resume
        }
    }

    private var primaryActionIcon: String {
        switch store.snapshot.phase {
        case .working, .due: return "figure.stand"
        case .waiting: return "play.fill"
        case .resting, .ready: return "arrow.down"
        case .paused: return "play.fill"
        }
    }

    private var primaryActionHint: String {
        switch store.snapshot.phase {
        case .waiting: return store.copy.pair("开始有效工作计时", "Start active work timing")
        case .resting, .ready: return store.copy.pair("结束站立阶段并开始新的工作周期", "End standing and start a new work cycle")
        case .paused: return store.copy.pair("继续计时", "Continue timing")
        default: return store.copy.pair("开始站立阶段", "Start the standing phase")
        }
    }

    private var actionFill: Color {
        store.snapshot.phase == .due ? StandUpDesign.accent : StandUpDesign.panelStrong
    }

    private var actionForeground: Color {
        store.snapshot.phase == .due ? .white : .primary
    }

    private func primaryActionTapped() {
        switch store.snapshot.phase {
        case .resting, .ready: store.sitDown()
        case .paused: store.pauseOrResume()
        case .waiting: store.beginWork()
        default: store.startBreak()
        }
    }

}

