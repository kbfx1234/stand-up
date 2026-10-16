import Foundation

public struct Achievement: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let detail: String
    public let symbol: String
    public let threshold: Int
    public let metric: Metric
    public enum Metric: Sendable { case breaks, streak, goals }
    public static let all: [Achievement] = [
        .init(id: "first-break", title: "First step", detail: "Complete your first break", symbol: "figure.stand", threshold: 1, metric: .breaks),
        .init(id: "first-goal", title: "A good day", detail: "Reach your first daily goal", symbol: "checkmark.seal", threshold: 1, metric: .goals),
        .init(id: "three-day-streak", title: "Finding rhythm", detail: "Reach your goal 3 days in a row", symbol: "flame", threshold: 3, metric: .streak),
        .init(id: "week-streak", title: "A steady week", detail: "Reach your goal 7 days in a row", symbol: "calendar", threshold: 7, metric: .streak),
        .init(id: "fifty-breaks", title: "Fifty moments", detail: "Complete 50 breaks in total", symbol: "star", threshold: 50, metric: .breaks),
        .init(id: "hundred-breaks", title: "A lasting habit", detail: "Complete 100 breaks in total", symbol: "trophy", threshold: 100, metric: .breaks)
    ]
}
