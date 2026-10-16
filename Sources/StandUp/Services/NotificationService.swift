import AppKit
import UserNotifications

@MainActor
final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    private let center = UNUserNotificationCenter.current()
    private var language: AppLanguage = .system
    var onAction: ((String) -> Void)?
    var onError: ((String) -> Void)?
    func configure(snooze: TimeInterval, language: AppLanguage) {
        self.language = language
        center.delegate = self
        let copy = AppCopy(language: language)
        let start = UNNotificationAction(identifier: "START_BREAK", title: copy.standing, options: [])
        let later = UNNotificationAction(identifier: "SNOOZE_BREAK", title: "\(copy.snooze) \(TimeText.duration(snooze, language: language))", options: [])
        center.setNotificationCategories([UNNotificationCategory(
            identifier: "BREAK_CATEGORY", actions: [start, later], intentIdentifiers: [])])
    }
    func requestAuthorization() async throws {
        _ = try await center.requestAuthorization(options: [.alert, .sound])
    }
    func availability() async -> NotificationAvailability {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional:
            return settings.alertSetting == .enabled ? .allowed : .alertsDisabled
        case .denied: return .denied
        default: return .notRequested
        }
    }
    func sendBreakDue(restDuration: TimeInterval, soundEnabled: Bool, language: AppLanguage) {
        let copy = AppCopy(language: language)
        let rest = TimeText.duration(restDuration, language: language)
        send(id: "break-due", title: copy.pair("该起来活动一下了", "Time to stand up"),
             body: copy.pair("已到工作时限，站起来活动 \(rest) 吧。站立后点击确认。", "Your work interval is complete. Stand and move for \(rest), then confirm."),
             category: "BREAK_CATEGORY", sound: soundEnabled)
    }

    func playPreview(soundEnabled: Bool, language: AppLanguage) {
        let copy = AppCopy(language: language)
        let content = UNMutableNotificationContent()
        content.title = copy.previewReminder
        content.body = copy.pair("这是一条测试提醒，不会改变计时进度。", "This is a preview. Your running timer is unaffected.")
        center.add(UNNotificationRequest(identifier: "preview", content: content, trigger: nil))
        if soundEnabled { playSystemSound("Hero") }
    }
    func sendRestComplete(soundEnabled: Bool, language: AppLanguage) {
        let copy = AppCopy(language: language)
        send(id: "rest-complete", title: copy.pair("这段休息完成了", "Break complete"),
             body: copy.pair("可以继续站立；坐下时在菜单栏点击「我坐下了」。", "You can sit down when ready. Use the menu bar to start the next cycle."), sound: soundEnabled)
    }
    func clear() {
        center.removePendingNotificationRequests(withIdentifiers: ["break-due", "rest-complete"])
        center.removeDeliveredNotifications(withIdentifiers: ["break-due", "rest-complete"])
    }
    private func send(id: String, title: String, body: String, category: String = "", sound: Bool) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.categoryIdentifier = category
        if sound && id == "break-due" { playSystemSound("Hero") }
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: nil)) { [weak self] error in
            guard let message = error?.localizedDescription else { return }
            Task { @MainActor in
                guard let self else { return }
                let prefix = AppCopy(language: self.language).pair("通知发送失败：", "Notification failed: ")
                self.onError?(prefix + message)
            }
        }
    }

    private func playSystemSound(_ name: String) {
        let url = URL(fileURLWithPath: "/System/Library/Sounds/\(name).aiff")
        NSSound(contentsOf: url, byReference: true)?.play()
    }
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                           didReceive response: UNNotificationResponse) async {
        let action = response.actionIdentifier
        await MainActor.run { [weak self] in self?.onAction?(action) }
    }
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                           willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner]
    }
}
