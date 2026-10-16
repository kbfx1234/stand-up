import SwiftUI

struct SettingsDetail: View {
    let page: SettingsPage
    @Binding var draft: AppSettings
    @ObservedObject var store: TimerStore
    @Binding var saved: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title).font(.system(size: 26, weight: .semibold, design: .rounded))
                Spacer()
                if saved {
                    Label(store.copy.saved, systemImage: "checkmark.circle.fill")
                        .font(.caption).foregroundStyle(.green)
                }
            }
            .padding(.horizontal, 28).padding(.vertical, 22)
            Divider()
            ScrollView {
                pageContent.padding(28)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            Divider()
            HStack {
                Text(store.copy.pair("语言即时生效，其他修改请保存", "Language applies instantly; save other changes"))
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button(store.copy.save) {
                    draft.snoozeMinutes = min(draft.snoozeMinutes, draft.workMinutes)
                    store.update(settings: draft)
                    saved = true
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(draft == store.settings)
            }
            .padding(.horizontal, 28).padding(.vertical, 16)
        }
        .overlay(alignment: .bottomLeading) {
            if let error = store.serviceError {
                Text(error).font(.caption).foregroundStyle(.red).padding(12)
                    .offset(y: -64)
            }
        }
    }

    private var title: String {
        switch page {
        case .general: return store.copy.general
        case .rhythm: return store.copy.rhythm
        case .reminders: return store.copy.reminders
        case .scenes: return store.copy.pair("场景增强", "Scenes")
        case .shortcuts: return store.copy.shortcuts
        case .about: return store.copy.about
        }
    }

    @ViewBuilder private var pageContent: some View {
        switch page {
        case .general: generalPage
        case .rhythm: rhythmPage
        case .reminders: remindersPage
        case .scenes: scenesPage
        case .shortcuts: shortcutsPage
        case .about: aboutPage
        }
    }

    private var generalPage: some View {
        SettingsGroup(title: store.copy.pair("外观与启动", "Appearance & startup"), symbol: "gearshape") {
            SettingsPickerRow(title: store.copy.languageLabel, detail: store.copy.pair("即时生效，无需重启", "Applies immediately; no restart required"), selection: $draft.language) {
                Text(store.copy.systemLanguage).tag(AppLanguage.system)
                Text(store.copy.chineseLanguage).tag(AppLanguage.chinese)
                Text(store.copy.englishLanguage).tag(AppLanguage.english)
            }
            SettingsToggleRow(title: store.copy.launchAtLogin, detail: store.copy.pair("登录后自动在菜单栏运行", "Start in the menu bar after login"), isOn: Binding(get: { store.loginEnabled }, set: { store.setLogin($0) }))
        }
    }

    private var rhythmPage: some View {
        VStack(alignment: .leading, spacing: 18) {
            SettingsGroup(title: store.copy.pair("工作与休息", "Work & rest"), symbol: "timer") {
                SettingsStepperRow(title: store.copy.pair("工作时长", "Work duration"), value: $draft.workMinutes, range: 5...120, suffix: store.copy.pair("分钟", "min"))
                SettingsStepperRow(title: store.copy.pair("站立 / 活动", "Stand / move"), value: $draft.restMinutes, range: 1...60, suffix: store.copy.pair("分钟", "min"))
                SettingsStepperRow(title: store.copy.pair("无输入后暂停", "Idle pause"), value: $draft.idleSeconds, range: 30...600, step: 30, suffix: store.copy.pair("秒", "sec"))
                SettingsStepperRow(title: store.copy.pair("顺延时长", "Snooze duration"), value: $draft.snoozeMinutes, range: 1...min(15, draft.workMinutes), suffix: store.copy.pair("分钟", "min"))
            }
            SettingsGroup(title: store.copy.pair("每日目标", "Daily goal"), symbol: "target") {
                SettingsStepperRow(title: store.copy.dailyGoal, value: $draft.dailyGoal, range: 1...20, suffix: store.copy.pair("次完成休息", "breaks"))
                SettingsToggleRow(title: store.copy.progressiveTraining, detail: store.copy.pair("每 5 个达标日逐步增加站立时间", "Increase standing time after every 5 qualifying days"), isOn: $draft.progressiveTraining)
            }
        }
    }

    private var remindersPage: some View {
        SettingsGroup(title: store.copy.pair("到点提醒", "Break reminders"), symbol: "bell") {
            SettingsToggleRow(title: store.copy.notifications, detail: store.copy.pair("显示 macOS 通知横幅", "Show macOS notification banners"), isOn: $draft.notificationsEnabled)
            SettingsToggleRow(title: store.copy.sound, detail: store.copy.pair("播放系统提示音", "Play a system alert sound"), isOn: $draft.soundEnabled)
            SettingsToggleRow(title: store.copy.floatingReminder, detail: store.copy.pair("显示顶部悬浮提醒卡片", "Show the floating reminder card"), isOn: $draft.floatingReminderEnabled)
            SettingsToggleRow(title: store.copy.fullScreen, detail: store.copy.pair("在所有屏幕显示动作建议", "Show movement guidance on every screen"), isOn: $draft.fullScreenBreakEnabled)
            SettingsInfoRow(text: store.notificationStatus)
            SettingsActionRow(title: store.copy.previewReminder, symbol: "play.circle") { store.previewReminder() }
            SettingsActionRow(title: store.copy.requestPermission, symbol: "bell.badge") { store.requestNotifications() }
        }
    }

    private var scenesPage: some View {
        SettingsGroup(title: store.copy.pair("会议与专注", "Meetings & focus"), symbol: "rectangle.inset.filled.and.person.filled") {
            SettingsToggleRow(title: store.copy.meetingMode, detail: store.copy.pair("手动暂停有效工作计时", "Pause effective work time manually"), isOn: $draft.meetingMode)
            SettingsToggleRow(title: store.copy.smartDeferral, detail: store.copy.pair("识别常见会议应用并延后提醒", "Defer reminders for common meeting apps"), isOn: $draft.smartMeetingDeferral)
            SettingsInfoRow(text: store.copy.pair("当前会识别 Zoom、Teams、Webex、Slack、FaceTime 和 Google Meet。", "Currently recognizes Zoom, Teams, Webex, Slack, FaceTime, and Google Meet."))
            SettingsInfoRow(text: store.copy.pair("视频播放、阅读和编译等待暂不自动判断，避免影响深度工作。", "Video playback, reading, and compile waits are not inferred automatically to avoid interrupting deep work."))
        }
    }

    private var shortcutsPage: some View {
        SettingsGroup(title: store.copy.pair("键盘快捷键", "Keyboard shortcuts"), symbol: "keyboard") {
            SettingsToggleRow(title: store.copy.keyboardShortcuts, detail: store.copy.pair("允许全局快捷键", "Allow global shortcuts"), isOn: $draft.keyboardShortcutsEnabled)
            ShortcutRow(keys: "⌥⌘P", title: store.copy.pair("暂停 / 恢复", "Pause / resume"))
            ShortcutRow(keys: "⌥⌘S", title: store.copy.pair("立即开始站立", "Start a standing break"))
            SettingsInfoRow(text: store.copy.pair("全局快捷键可能需要在系统设置中允许输入监控权限。", "Global shortcuts may require Input Monitoring permission in System Settings."))
        }
    }

    private var aboutPage: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable().scaledToFit().frame(width: 72, height: 72)
                VStack(alignment: .leading, spacing: 4) {
                    Text(store.copy.appName).font(.title2.weight(.semibold))
                    Text("\(store.copy.pair("版本", "Version")) \(store.copy.version)")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            SettingsGroup(title: store.copy.pair("隐私", "Privacy"), symbol: "lock.shield") {
                SettingsInfoRow(text: store.copy.localOnly)
            }
            HStack(spacing: 18) {
                Link(store.copy.pair("源代码", "Source code"), destination: URL(string: "https://github.com/kbfx1234/stand-up")!)
                Link(store.copy.pair("反馈问题", "Report an issue"), destination: URL(string: "https://github.com/kbfx1234/stand-up/issues")!)
                Link(store.copy.pair("隐私说明", "Privacy"), destination: URL(string: "https://github.com/kbfx1234/stand-up/blob/master/PRIVACY.md")!)
            }.font(.subheadline)
        }
    }
}

