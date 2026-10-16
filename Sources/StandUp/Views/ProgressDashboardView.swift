import SwiftUI
import StandUpCore

struct ProgressDashboardView: View {
    @ObservedObject var store: TimerStore
    @State private var month = Date()
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                habitCards
                totals
                monthCalendar
                achievements
            }
            .padding(28)
        }
        .frame(width: 680, height: 720)
        .background(.regularMaterial)
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Progress")
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                Text("Build a rhythm that lasts")
                    .foregroundStyle(.secondary)
            }
            Spacer()
                Text("Level \(store.trainingLevel)")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(StandUpDesign.accent.opacity(0.12), in: Capsule())
        }
    }

    private var habitCards: some View {
        HStack(spacing: 12) {
            ProgressMetric(title: "Current streak", value: "\(store.habit.currentStreak) days", symbol: "flame.fill")
            ProgressMetric(title: "Best streak", value: "\(store.habit.bestStreak) days", symbol: "trophy.fill")
            ProgressMetric(title: "Qualifying days", value: "\(store.habit.qualifyingDays)", symbol: "checkmark.seal.fill")
        }
    }

    private var monthCalendar: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(month.formatted(.dateTime.month(.wide).year()))
                    .font(.headline)
                Spacer()
                Button { month = Calendar.current.date(byAdding: .month, value: -1, to: month) ?? month } label: { Image(systemName: "chevron.left") }
                Button { month = Calendar.current.date(byAdding: .month, value: 1, to: month) ?? month } label: { Image(systemName: "chevron.right") }
            }
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Calendar.current.shortWeekdaySymbols, id: \.self) { Text($0.prefix(2)).font(.caption).foregroundStyle(.secondary) }
                ForEach(calendarDays, id: \.self) { date in
                    CalendarDayCell(date: date, record: record(for: date), goal: store.settings.dailyGoal)
                }
            }
        }
        .padding(18)
        .background(StandUpDesign.panel, in: RoundedRectangle(cornerRadius: 16))
    }

    private var totals: some View {
        HStack(spacing: 12) {
            ProgressMetric(title: "Work tracked", value: duration(totalWork), symbol: "clock")
            ProgressMetric(title: "Breaks completed", value: "\(store.history.reduce(0) { $0 + $1.completed })", symbol: "figure.stand")
            ProgressMetric(title: "Goal completion", value: goalRate, symbol: "chart.line.uptrend.xyaxis")
        }
    }

    private var totalWork: TimeInterval {
        store.history.reduce(0) { $0 + $1.workSeconds }
    }

    private var goalRate: String {
        let eligible = store.history.filter { $0.completed > 0 }
        guard !eligible.isEmpty else { return "—" }
        let achieved = eligible.filter(\.achieved).count
        return "\(Int(Double(achieved) / Double(eligible.count) * 100))%"
    }

    private func duration(_ value: TimeInterval) -> String {
        let hours = Int(value / 3600)
        let minutes = Int(value.truncatingRemainder(dividingBy: 3600) / 60)
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }

    private var achievements: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Achievements").font(.headline)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                AchievementRow(title: "First break", detail: "Complete your first daily goal", unlocked: store.habit.unlockedAchievements.contains("first-break"), symbol: "figure.stand")
                AchievementRow(title: "Three-day rhythm", detail: "Hold a three-day streak", unlocked: store.habit.unlockedAchievements.contains("three-day-streak"), symbol: "flame.fill")
                AchievementRow(title: "Week warrior", detail: "Hold a seven-day streak", unlocked: store.habit.unlockedAchievements.contains("week-streak"), symbol: "calendar.badge.clock")
                AchievementRow(title: "50 breaks", detail: "Complete fifty breaks", unlocked: store.habit.unlockedAchievements.contains("fifty-breaks"), symbol: "star.fill")
            }
        }
    }

    private var calendarDays: [Date?] {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: month),
              let first = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) else { return [] }
        let offset = calendar.component(.weekday, from: first) - 1
        return Array(repeating: nil, count: offset) + range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: first) }
    }

    private func record(for date: Date?) -> DailySummary? {
        guard let date else { return nil }
        return store.history.first { $0.id == LocalStore.dayKey(date) }
    }
}

private struct ProgressMetric: View {
    let title: String
    let value: String
    let symbol: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol).foregroundStyle(StandUpDesign.accent)
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title3.weight(.semibold)).monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14).background(StandUpDesign.panel, in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct CalendarDayCell: View {
    let date: Date?
    let record: DailySummary?
    let goal: Int
    var body: some View {
        Group {
            if let date {
                VStack(spacing: 4) {
                    Text("\(Calendar.current.component(.day, from: date))")
                        .font(.caption.weight(.medium))
                    Circle().fill(color).frame(width: 7, height: 7)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 8)
                .background(record == nil ? Color.clear : StandUpDesign.panelStrong, in: RoundedRectangle(cornerRadius: 9))
            } else { Color.clear.frame(height: 38) }
        }
    }
    private var color: Color {
        guard let record else { return .clear }
        return record.completed >= goal ? .green : StandUpDesign.accent
    }
}

private struct AchievementRow: View {
    let title: String
    let detail: String
    let unlocked: Bool
    let symbol: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol).font(.title3).foregroundStyle(unlocked ? StandUpDesign.accent : .secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: unlocked ? "checkmark.circle.fill" : "lock.fill")
                .foregroundStyle(unlocked ? .green : .secondary)
        }
        .padding(12).background(StandUpDesign.panel, in: RoundedRectangle(cornerRadius: 12))
        .opacity(unlocked ? 1 : 0.62)
    }
}
