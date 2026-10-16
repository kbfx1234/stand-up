import Foundation
import StandUpCore

struct SavedSession: Codable {
    var day: String
    var timer: TimerState
    var history: [DailySummary]
    var habit: HabitStats?
}
struct LocalStore {
    let defaults = UserDefaults.standard
    private let prefix: String
    init(development: Bool) {
        prefix = development ? "development." : ""
    }
    func settings() -> AppSettings {
        decode(AppSettings.self, key: "settings.v2") ?? AppSettings()
    }
    func session() -> SavedSession? { decode(SavedSession.self, key: "session.v2") }
    func save(settings: AppSettings) { encode(settings, key: "settings.v2") }
    func save(session: SavedSession) { encode(session, key: "session.v2") }
    private func decode<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = defaults.data(forKey: prefix + key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
    private func encode<T: Encodable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: prefix + key)
    }
    static func dayKey(_ date: Date = Date()) -> String {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year!, parts.month!, parts.day!)
    }
}
