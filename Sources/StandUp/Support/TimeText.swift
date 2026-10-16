import Foundation

enum TimeText {
    static func clock(_ value: TimeInterval) -> String {
        let seconds = max(0, Int(value.rounded(.up)))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
    static func shortEnglish(_ value: TimeInterval) -> String {
        value < 60 ? "\(Int(value))s" : "\(Int(value / 60))m"
    }
    static func duration(_ value: TimeInterval) -> String {
        if value < 60 { return "\(Int(value)) 秒" }
        return "\(Int(value / 60)) 分钟"
    }
}
