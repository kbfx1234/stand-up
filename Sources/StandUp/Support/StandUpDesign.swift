import SwiftUI

enum StandUpDesign {
    static let accent = Color(red: 0.78, green: 0.28, blue: 0.20)
    static let hairline = Color.primary.opacity(0.09)
    static let muted = Color.secondary
    static let panel = Color.primary.opacity(0.045)
    static let panelStrong = Color.primary.opacity(0.075)
}

struct PressableButtonStyle: ButtonStyle {
    var fill: Color = StandUpDesign.panel
    var foreground: Color = .primary
    func makeBody(configuration: Configuration) -> some View {
        Surface(configuration: configuration, fill: fill, foreground: foreground)
    }
    private struct Surface: View {
        let configuration: ButtonStyle.Configuration
        let fill: Color
        let foreground: Color
        @State private var hovered = false
        @Environment(\.isEnabled) private var enabled
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @Environment(\.isFocused) private var focused
        var body: some View {
            configuration.label
                .foregroundStyle(foreground)
                .background(fill, in: RoundedRectangle(cornerRadius: 11))
                .overlay {
                    RoundedRectangle(cornerRadius: 11)
                        .fill(Color.primary.opacity(hovered && enabled ? 0.045 : 0))
                        .allowsHitTesting(false)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 11)
                        .stroke(focused ? Color.accentColor : .clear, lineWidth: 2)
                        .allowsHitTesting(false)
                }
                .opacity(enabled ? 1 : 0.4)
                .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
                .onHover { hovered = $0 }
                .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: configuration.isPressed)
                .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: hovered)
        }
    }
}
