import UserNotifications

class NotificationManager {

    static let shared = NotificationManager()

    private init() {
        requestPermission()
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            if let error = error {
                print("❌ Notification authorization error: \(error.localizedDescription)")
            } else {
                print(granted ? "✅ Notification permission granted." : "⚠️ Notification permission denied.")
            }
        }
    }

    func scheduleNewPostNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling new post notification: \(error.localizedDescription)")
            } else {
                print("✅ New post notification scheduled: \(title) - \(body)")
            }
        }
    }

    func scheduleGeneralNotification(title: String, body: String, timeInterval: TimeInterval = 1) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInterval,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling general notification: \(error.localizedDescription)")
            } else {
                 print("✅ General notification scheduled: \(title) - \(body)")
            }
        }
    }
}