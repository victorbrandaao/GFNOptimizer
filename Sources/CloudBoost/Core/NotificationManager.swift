import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    func requestIfNeeded() {
        guard Preferences.notificationsEnabled else { return }
        guard Bundle.main.bundlePath.hasSuffix(".app") else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func notify(title: String, body: String) {
        guard Preferences.notificationsEnabled else { return }
        guard Bundle.main.bundlePath.hasSuffix(".app") else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}
