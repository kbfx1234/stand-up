import SwiftUI

struct SettingsSidebar: View {
    @Binding var selection: SettingsPage
    let copy: AppCopy

    var body: some View {
        List(selection: $selection) {
            Section {
                ForEach([SettingsPage.general, .rhythm, .reminders, .scenes, .shortcuts]) { page in
                    row(page).tag(page)
                }
            }
            Section {
                row(.about).tag(SettingsPage.about)
            } header: {
                Text(copy.appName).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 8) {
                Image(systemName: "figure.stand").foregroundStyle(StandUpDesign.accent)
                Text(copy.appName).font(.caption.weight(.semibold))
                Spacer()
            }.foregroundStyle(.secondary).padding(16)
        }
    }

    private func row(_ page: SettingsPage) -> some View {
        HStack(spacing: 10) {
            Image(systemName: page.symbol)
                .font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
                .frame(width: 27, height: 27)
                .background(color(page), in: RoundedRectangle(cornerRadius: 7))
            Text(title(for: page)).font(.system(size: 13, weight: .medium))
        }.padding(.vertical, 3)
    }
    private func color(_ page: SettingsPage) -> Color {
        switch page {
        case .general: return Color(red: 0.48, green: 0.49, blue: 0.52)
        case .rhythm: return StandUpDesign.accent
        case .reminders: return Color(red: 0.20, green: 0.45, blue: 0.92)
        case .scenes: return Color(red: 0.18, green: 0.58, blue: 0.56)
        case .shortcuts: return Color(red: 0.38, green: 0.30, blue: 0.78)
        case .about: return Color(red: 0.12, green: 0.60, blue: 0.72)
        }
    }

    private func title(for page: SettingsPage) -> String {
        switch page {
        case .general: return copy.general
        case .rhythm: return copy.rhythm
        case .reminders: return copy.reminders
        case .scenes: return copy.pair("场景增强", "Scenes")
        case .shortcuts: return copy.shortcuts
        case .about: return copy.about
        }
    }
}

