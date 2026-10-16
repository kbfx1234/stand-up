import AppKit
import UserNotifications

@MainActor
final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    private let center = UNUserNotificationCenter.current()
    var onAction: ((String) -> Void)?
    var onError: ((String) -> Void)?
    func configure(snooze: String) {
        center.delegate = self
        let start = UNNotificationAction(identifier: "START_BREAK", title: "我站起来了", options: [])
        let later = UNNotificationAction(identifier: "SNOOZE_BREAK", title: "顺延 \(snooze)", options: [])
        center.setNotificationCategories([UNNotificationCategory(
            identifier: "BREAK_CATEGORY", actions: [start, later], intentIdentifiers: [])])
    }
    func requestAuthorization() async throws {
        _ = try await center.requestAuthorization(options: [.alert, .sound])
    }
    func statusText() async -> String {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional:
            return settings.alertSetting == .enabled ? "系统通知已允许" : "通知横幅未开启，请检查系统设置"
        case .denied: return "系统通知被关闭，菜单栏仍会显示提醒"
        default: return "尚未开启通知，菜单栏仍会显示提醒"
        }
    }
    func sendBreakDue(rest: String, soundEnabled: Bool) {
        send(id: "break-due", title: "该起来活动一下了",
             body: "已到工作时限，站起来活动 \(rest) 吧。站立后点击确认。",
             category: "BREAK_CATEGORY", sound: soundEnabled)
    }

    func playPreview(soundEnabled: Bool) {
        let content = UNMutableNotificationContent()
        content.title = "提醒预览"
        content.body = "Stand Up 会在到点时发出这个提醒。"
        center.add(UNNotificationRequest(identifier: "preview", content: content, trigger: nil))
        if soundEnabled { playSystemSound("Hero") }
    }
    func sendRestComplete(soundEnabled: Bool) {
        send(id: "rest-complete", title: "这段休息完成了",
             body: "可以继续站立；坐下时在菜单栏点击「我坐下了」。", sound: soundEnabled)
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
            Task { @MainActor in self?.onError?("通知发送失败：\(message)") }
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
