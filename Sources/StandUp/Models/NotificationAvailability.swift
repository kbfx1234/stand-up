import Foundation

enum NotificationAvailability {
    case notRequested, denied, alertsDisabled, allowed
    func text(language: AppLanguage) -> String {
        let copy = AppCopy(language: language)
        switch self {
        case .allowed: return copy.pair("系统通知已允许", "System notifications allowed")
        case .alertsDisabled: return copy.pair("横幅未开启，请检查系统通知设置", "Banners disabled; check system notification settings")
        case .denied: return copy.pair("系统通知已关闭，菜单栏仍可提醒", "Notifications denied; menu bar reminders remain available")
        case .notRequested: return copy.pair("尚未开启系统通知", "System notifications not enabled yet")
        }
    }
}
