import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: TimerStore
    @State private var draft: AppSettings
    @State private var saved = false
    init(store: TimerStore) {
        self.store = store
        _draft = State(initialValue: store.settings)
    }
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "figure.stand")
                    .font(.title2).foregroundStyle(StandUpDesign.accent)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Stand Up").font(.system(size: 20, weight: .semibold, design: .rounded))
                    Text("设置适合你的坐站节奏").font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
            }.padding(24)
            Divider()
            Form {
            Section("坐站节奏") {
                Stepper("工作：\(draft.workMinutes) 分钟", value: $draft.workMinutes, in: 5...120)
                Stepper("站立 / 活动：\(draft.restMinutes) 分钟", value: $draft.restMinutes, in: 1...60)
                Stepper("无输入暂停：\(draft.idleSeconds) 秒", value: $draft.idleSeconds, in: 30...600, step: 30)
                Stepper("顺延：\(draft.snoozeMinutes) 分钟（每轮一次）",
                        value: $draft.snoozeMinutes, in: 1...min(15, draft.workMinutes))
                if store.isDevelopmentMode {
                    Text("当前固定为测试节奏：45 秒工作 / 15 秒站立，闲置 5 秒暂停。")
                        .foregroundStyle(.orange)
                }
            }
            Section("提醒") {
                Toggle("发送系统通知", isOn: $draft.notificationsEnabled)
                Toggle("提醒播放声音", isOn: $draft.soundEnabled)
                Toggle("显示屏幕提醒卡片", isOn: $draft.floatingReminderEnabled)
                Text(store.notificationStatus).font(.caption).foregroundStyle(.secondary)
                Button("开启通知权限") { store.requestNotifications() }
                Button("预览提醒") { store.previewReminder() }
            }
            Section("场景增强") {
                Toggle("会议模式", isOn: $draft.meetingMode)
                Toggle("智能延后会议提醒", isOn: $draft.smartMeetingDeferral)
                Toggle("全屏休息提示", isOn: $draft.fullScreenBreakEnabled)
                Toggle("启用快捷键", isOn: $draft.keyboardShortcutsEnabled)
                Text("快捷键：⌥⌘P 暂停 / 恢复，⌥⌘S 立即开始站立。会议模式会暂时暂停有效工作计时。")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("启动") {
                Toggle("登录时自动启动", isOn: Binding(
                    get: { store.loginEnabled }, set: { store.setLogin($0) }))
                Text("此开关立即生效；若系统要求批准，请到系统设置的登录项中允许。")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("习惯训练") {
                Stepper("每日目标：\(draft.dailyGoal) 次", value: $draft.dailyGoal, in: 1...20)
                Toggle("开启渐进训练", isOn: $draft.progressiveTraining)
                Text(draft.progressiveTraining ? "每完成 5 个达标日自动升一级，工作 / 站立节奏按等级逐步变化。" : "关闭后使用上面的固定工作 / 站立时长。")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Text("短暂离开保留工作进度；连续离开达到休息时长后，回来开始新一轮。站着使用电脑时，点击「Stand up now」。")
                .font(.caption).foregroundStyle(.secondary)
            Text("所有记录保存在本机，不读取输入内容，不连接网络。")
                .font(.caption).foregroundStyle(.secondary)
            if let error = store.serviceError {
                Text(error).font(.caption).foregroundStyle(.orange).textSelection(.enabled)
            }
        }
            .formStyle(.grouped)
            Divider()
            HStack {
                Text(saved ? "已保存" : "修改后保存，已累计的时间保留")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button("保存设置") {
                    draft.snoozeMinutes = min(draft.snoozeMinutes, draft.workMinutes)
                    store.update(settings: draft)
                    saved = true
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }.padding(20)
        }
        .frame(width: 480, height: 700)
        .onAppear { draft = store.settings; store.refreshPermissions() }
        .onChange(of: draft) { _, _ in saved = false }
    }
}
