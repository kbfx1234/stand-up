import SwiftUI
import StandUpCore

struct DailyGoalCard: View {
    let completed: Int
    let goal: Int

    var body: some View {
        VStack(spacing: 7) {
            ZStack {
                Circle().stroke(StandUpDesign.accent.opacity(0.13), lineWidth: 5)
                Circle()
                    .trim(from: 0, to: min(CGFloat(completed) / CGFloat(max(goal, 1)), 1))
                    .stroke(StandUpDesign.accent, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(completed)/\(goal)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .monospacedDigit()
            }
            .frame(width: 55, height: 55)
            Text("Daily count")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(StandUpDesign.muted)
            Text("\(goal) breaks / day").font(.system(size: 10)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 125)
        .background(StandUpDesign.panel, in: RoundedRectangle(cornerRadius: 13))
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(StandUpDesign.hairline, lineWidth: 0.5))
    }
}

struct RhythmCard: View {
    let work: TimeInterval
    let rest: TimeInterval

    var body: some View {
        VStack(spacing: 7) {
            ZStack {
                Circle().fill(StandUpDesign.accent.opacity(0.12))
                Image(systemName: "figure.stand")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(StandUpDesign.accent)
            }
            .frame(width: 55, height: 55)
            Text("Current rhythm")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(StandUpDesign.muted)
            Text("\(TimeText.shortEnglish(work)) / \(TimeText.shortEnglish(rest))")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 125)
        .background(StandUpDesign.panel, in: RoundedRectangle(cornerRadius: 13))
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(StandUpDesign.hairline, lineWidth: 0.5))
    }
}

