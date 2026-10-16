import SwiftUI
import StandUpCore

struct HistoryView: View {
    let records: [DailySummary]
    let language: AppLanguage
    private var recent: [DailySummary] { records.sorted { $0.id > $1.id }.prefix(7).map { $0 } }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            if recent.isEmpty {
                Text(AppCopy(language: language).noHistory)
                    .foregroundStyle(StandUpDesign.muted)
            } else {
                ForEach(recent) { day in
                    HStack(spacing: 10) {
                        Text(shortDate(day.id))
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.primary)
                            .frame(width: 47, alignment: .leading)
                        GeometryReader { proxy in
                            Capsule()
                                .fill(StandUpDesign.accent.opacity(0.13))
                                .overlay(alignment: .leading) {
                                    Capsule()
                                        .fill(StandUpDesign.accent.opacity(0.74))
                                        .frame(width: proxy.size.width * min(CGFloat(day.completed) / CGFloat(max(day.target, 1)), 1))
                                }
                        }
                        .frame(height: 7)
                        Text("\(day.completed)")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(StandUpDesign.muted)
                            .frame(width: 17, alignment: .trailing)
                    }
                }
            }
        }
        .padding(.top, 6)
    }

    private func shortDate(_ key: String) -> String {
        let parts = key.split(separator: "-")
        guard parts.count == 3 else { return key }
        return "\(parts[1])/\(parts[2])"
    }
}
