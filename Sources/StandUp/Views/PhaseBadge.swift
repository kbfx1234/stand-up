import SwiftUI

struct PhaseBadge: View {
    let title: String
    let tint: Color

    var body: some View {
        HStack(spacing: 7) {
            Circle().fill(tint).frame(width: 7, height: 7)
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(tint.opacity(0.11), in: Capsule())
        .overlay(Capsule().stroke(tint.opacity(0.18), lineWidth: 0.5))
        .accessibilityElement(children: .combine)
    }
}
