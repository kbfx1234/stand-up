import AppKit

@MainActor
struct SmartDeferralService {
    private let meetingApps = ["zoom.us", "Microsoft Teams", "Webex", "Slack", "FaceTime", "Google Meet"]
    private let mediaApps = ["QuickTime Player", "IINA", "VLC", "Spotify", "YouTube"]

    func shouldDefer(settings: AppSettings) -> Bool {
        if settings.meetingMode { return true }
        guard settings.smartMeetingDeferral else { return false }
        guard let name = NSWorkspace.shared.frontmostApplication?.localizedName else { return false }
        return meetingApps.contains { name.localizedCaseInsensitiveContains($0) }
    }

    func isMediaAppFrontmost() -> Bool {
        guard let name = NSWorkspace.shared.frontmostApplication?.localizedName else { return false }
        return mediaApps.contains { name.localizedCaseInsensitiveContains($0) }
    }
}
