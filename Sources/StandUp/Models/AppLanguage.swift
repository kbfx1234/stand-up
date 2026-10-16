import Foundation

enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case system
    case chinese
    case english
    var id: String { rawValue }
    var resolved: AppLanguage {
        guard self == .system else { return self }
        return Self.systemChoice(preferredLanguages: Locale.preferredLanguages)
    }
    static func systemChoice(preferredLanguages: [String]) -> AppLanguage {
        let code = preferredLanguages.first.map { Locale(identifier: $0).language.languageCode?.identifier }
        return code == "zh" ? .chinese : .english
    }
    var locale: Locale {
        Locale(identifier: resolved == .chinese ? "zh_Hans_CN" : "en_US")
    }
}

struct AppCopy {
    let language: AppLanguage
    private var zh: Bool { language.resolved == .chinese }
    func pair(_ chinese: String, _ english: String) -> String { zh ? chinese : english }
    var appName: String { "Stand Up" }
    var settings: String { pair("设置", "Settings") }
    var progress: String { pair("进度", "Progress") }
    var quit: String { pair("退出", "Quit") }
    var recentActivity: String { pair("最近记录", "Recent activity") }
    var dailyCount: String { pair("今日完成", "Daily count") }
    func breaksPerDay(_ value: Int) -> String { pair("每日 \(value) 次", "\(value) breaks / day") }
    var currentRhythm: String { pair("当前节奏", "Current rhythm") }
    var nextStand: String { pair("下一次起身", "Next stand") }
    var standingRemaining: String { pair("站立时间剩余", "Standing time remaining") }
    var standUpNow: String { pair("现在起身", "Stand up now") }
    var startTimer: String { pair("开始计时", "Start timer") }
    var standing: String { pair("我站起来了", "I'm standing") }
    var sitDown: String { pair("我坐下了", "Sit down") }
    var resume: String { pair("恢复计时", "Resume timer") }
    var pause: String { pair("暂停", "Pause") }
    var snooze: String { pair("顺延", "Snooze") }
    var skip: String { pair("跳过", "Skip") }
    var resetTimer: String { pair("重置当前计时", "Reset current timer") }
    var pauseTimerHint: String { pair("暂停计时", "Pause timer") }
    var level: String { pair("等级", "Level") }
    var noHistory: String { pair("完成一次休息后，这里会出现记录", "Complete a break to see your history here") }
    var standingTime: String { pair("站立时间剩余", "Standing time remaining") }
    var waiting: String { pair("等待工作", "Waiting") }
    var working: String { pair("工作中", "Working") }
    var due: String { pair("该起身了", "Stand up now") }
    var standingPhase: String { pair("站立中", "Standing") }
    var complete: String { pair("休息完成", "Break complete") }
    var paused: String { pair("已暂停", "Paused") }
    var workActive: String { pair("有效工作时间", "Active work time") }
    var workKept: String { pair("等待输入 · 保留本轮进度", "Waiting for input · progress is kept") }
    var systemPaused: String { pair("电脑不可用 · 工作计时暂停", "Mac unavailable · work timer paused") }
    var progressTitle: String { pair("进度", "Progress") }
    var progressSubtitle: String { pair("建立一个可以持续的节奏", "Build a rhythm that lasts") }
    var currentStreak: String { pair("当前连续", "Current streak") }
    var bestStreak: String { pair("最佳连续", "Best streak") }
    var qualifyingDays: String { pair("达标天数", "Qualifying days") }
    var achievements: String { pair("成就", "Achievements") }
    var workTracked: String { pair("累计工作", "Work tracked") }
    var breaksCompleted: String { pair("完成休息", "Breaks completed") }
    var goalCompletion: String { pair("目标完成率", "Goal completion") }
    var general: String { pair("通用", "General") }
    var rhythm: String { pair("坐站节奏", "Rhythm") }
    var reminders: String { pair("提醒", "Reminders") }
    var shortcuts: String { pair("快捷键", "Shortcuts") }
    var about: String { pair("关于", "About") }
    var languageLabel: String { pair("语言", "Language") }
    var systemLanguage: String { pair("跟随系统", "Follow System") }
    var chineseLanguage: String { "中文" }
    var englishLanguage: String { "English" }
    var launchAtLogin: String { pair("登录时自动启动", "Launch at login") }
    var notifications: String { pair("发送系统通知", "Send notifications") }
    var sound: String { pair("提醒播放声音", "Play reminder sound") }
    var floatingReminder: String { pair("显示屏幕提醒卡片", "Show floating reminder") }
    var fullScreen: String { pair("全屏休息提示", "Full-screen break prompt") }
    var meetingMode: String { pair("会议模式", "Meeting mode") }
    var smartDeferral: String { pair("智能延后会议提醒", "Smart meeting deferral") }
    var keyboardShortcuts: String { pair("启用快捷键", "Enable shortcuts") }
    var dailyGoal: String { pair("每日目标", "Daily goal") }
    var progressiveTraining: String { pair("渐进训练", "Progressive training") }
    var previewReminder: String { pair("预览提醒", "Preview reminder") }
    var requestPermission: String { pair("开启通知权限", "Enable notifications") }
    var save: String { pair("保存设置", "Save settings") }
    var saved: String { pair("已保存", "Saved") }
    var saveHint: String { pair("修改后保存，已累计的时间保留", "Save changes; current progress is kept") }
    var localOnly: String { pair("所有记录保存在本机，不读取输入内容，不连接网络。", "Everything stays on this Mac. No input contents are read and no network is required.") }
    var version: String { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Development" }
}
