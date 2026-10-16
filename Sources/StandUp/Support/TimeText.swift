import Foundation

enum TimeText {
    static func clock(_ value: TimeInterval) -> String {
        let seconds = max(0, Int(value.rounded(.up)))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
    static func shortEnglish(_ value: TimeInterval) -> String {
        value < 60 ? "\(Int(value))s" : "\(Int(value / 60))m"
    }
    static func compact(_ value: TimeInterval, language: AppLanguage) -> String {
        guard language.resolved == .chinese else { return shortEnglish(value) }
        return value < 60 ? "\(Int(value))秒" : "\(Int(value / 60))分"
    }
    static func duration(_ value: TimeInterval) -> String {
        if value < 60 { return "\(Int(value)) 秒" }
        return "\(Int(value / 60)) 分钟"
    }
    static func duration(_ value: TimeInterval, language: AppLanguage) -> String {
        let copy = AppCopy(language: language)
        if value < 60 { return copy.pair("\(Int(value)) 秒", "\(Int(value)) sec") }
        return copy.pair("\(Int(value / 60)) 分钟", "\(Int(value / 60)) min")
    }
    static func total(_ value: TimeInterval, language: AppLanguage) -> String {
        let copy = AppCopy(language: language)
        let hours = Int(value / 3600), minutes = Int(value.truncatingRemainder(dividingBy: 3600) / 60)
        return hours > 0 ? copy.pair("\(hours) 小时 \(minutes) 分", "\(hours)h \(minutes)m")
                        : copy.pair("\(minutes) 分钟", "\(minutes)m")
    }
}
