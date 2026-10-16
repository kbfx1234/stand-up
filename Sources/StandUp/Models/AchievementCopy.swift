import StandUpCore

extension AppCopy {
    func achievementTitle(_ item: Achievement) -> String {
        let chinese: String
        switch item.id {
        case "first-break": chinese = "迈出第一步"
        case "first-goal": chinese = "充实的一天"
        case "three-day-streak": chinese = "找到节奏"
        case "week-streak": chinese = "稳定一周"
        case "fifty-breaks": chinese = "五十次起身"
        case "hundred-breaks": chinese = "持久习惯"
        default: chinese = item.title
        }
        return pair(chinese, item.title)
    }
    func achievementDetail(_ item: Achievement) -> String {
        let chinese: String
        switch item.id {
        case "first-break": chinese = "完成第一次休息"
        case "first-goal": chinese = "首次完成每日目标"
        case "three-day-streak": chinese = "连续 3 天完成每日目标"
        case "week-streak": chinese = "连续 7 天完成每日目标"
        case "fifty-breaks": chinese = "累计完成 50 次休息"
        case "hundred-breaks": chinese = "累计完成 100 次休息"
        default: chinese = item.detail
        }
        return pair(chinese, item.detail)
    }
}
