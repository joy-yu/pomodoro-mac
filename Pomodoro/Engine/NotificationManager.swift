import AppKit
import Foundation
import UserNotifications

@MainActor
final class NotificationManager: NSObject, @preconcurrency UNUserNotificationCenterDelegate {
    private let center = UNUserNotificationCenter.current()
    override init() {
        super.init()
        center.delegate = self
    }

    func requestAuthorizationIfNeeded() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func sendPhaseFinishedNotification(for phase: PomodoroPhase, nextPhase: PomodoroPhase, playSound: Bool) {
        let content = UNMutableNotificationContent()
        content.title = phase.notificationTitle
        content.body = phase == .work
            ? String(format: String(localized: "notification.focusBody"), nextPhase.title)
            : String(localized: "notification.breakBody")
        content.sound = playSound ? .default : nil
        content.interruptionLevel = .timeSensitive
        content.userInfo = ["playSound": playSound]

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        center.add(request)
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        Task { @MainActor in
            let play = notification.request.content.userInfo["playSound"] as? Bool ?? true
            completionHandler(play ? [.banner, .sound, .list] : [.banner, .list])
        }
    }
}
