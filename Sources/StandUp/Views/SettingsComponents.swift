import SwiftUI

struct SettingsGroup<Content: View>: View {
    let title: String
    let symbol: String
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Label(title, systemImage: symbol).font(.headline).padding(.bottom, 10)
            VStack(spacing: 0) { content }
                .background(StandUpDesign.panel, in: RoundedRectangle(cornerRadius: 14))
        }
    }
}

struct SettingsToggleRow: View {
    let title: String
    let detail: String
    @Binding var isOn: Bool
    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) { Text(title); Text(detail).font(.caption).foregroundStyle(.secondary) }
            Spacer(minLength: 12)
            Toggle(title, isOn: $isOn).labelsHidden().toggleStyle(.switch).controlSize(.small)
        }.padding(.horizontal, 16).padding(.vertical, 14)
            .overlay(alignment: .bottom) { Divider().padding(.horizontal, 16).opacity(0.5) }
    }
}

struct SettingsStepperRow: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    var step = 1
    let suffix: String
    var body: some View {
        HStack(spacing: 12) {
            Text(title)
            Spacer()
            Text("\(value) \(suffix)").monospacedDigit().foregroundStyle(.secondary)
            Stepper(title, value: $value, in: range, step: step).labelsHidden()
                .fixedSize().accessibilityValue("\(value) \(suffix)")
        }.padding(.horizontal, 16).padding(.vertical, 14)
            .overlay(alignment: .bottom) { Divider().padding(.horizontal, 16).opacity(0.5) }
    }
}

struct SettingsPickerRow<Selection: Hashable, Content: View>: View {
    let title: String
    let detail: String
    @Binding var selection: Selection
    @ViewBuilder let content: Content
    var body: some View {
        HStack { VStack(alignment: .leading, spacing: 3) { Text(title); Text(detail).font(.caption).foregroundStyle(.secondary) }; Spacer(); Picker("", selection: $selection) { content }.labelsHidden().frame(width: 150) }
            .padding(.horizontal, 16).padding(.vertical, 12)
    }
}

struct SettingsActionRow: View {
    let title: String
    let symbol: String
    let action: () -> Void
    var body: some View { Button(action: action) { Label(title, systemImage: symbol).frame(maxWidth: .infinity, alignment: .leading) }.buttonStyle(.borderless).padding(16) }
}

struct SettingsInfoRow: View {
    let text: String
    var body: some View { Text(text).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true).padding(16) }
}

struct ShortcutRow: View {
    let keys: String
    let title: String
    var body: some View { HStack { Text(title); Spacer(); Text(keys).font(.system(.body, design: .monospaced)).foregroundStyle(.secondary) }.padding(16) }
}
