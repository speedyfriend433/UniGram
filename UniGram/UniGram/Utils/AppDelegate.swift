import UIKit
import BackgroundTasks
import UserNotifications
import SwiftUI

class AppDelegate: UIResponder, UIApplicationDelegate {

    let backgroundAppRefreshTaskIdentifier = "com.speedy67.UniGram.apprefresh"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        requestNotificationAuthorization()

        registerBackgroundTasks()

        return true
    }

    // MARK: - UISceneSession Lifecycle
    // something was in there...
    
    
    // MARK: - User Notifications
    func requestNotificationAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("❌ Notification authorization error: \(error.localizedDescription)")
            } else if granted {
                print("✅ Notification permission granted.")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("⚠️ Notification permission denied.")
            }
        }
    }

    // MARK: - Background Tasks
    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundAppRefreshTaskIdentifier, using: nil) { task in
             self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        print("✅ Background task registered.")
    }

    func scheduleAppRefresh() {
       let request = BGAppRefreshTaskRequest(identifier: backgroundAppRefreshTaskIdentifier)
       request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)

       do {
          try BGTaskScheduler.shared.submit(request)
          print("✅ Background App Refresh scheduled")
       } catch {
          print("❌ Could not schedule app refresh: \(error)")
       }
    }

    func handleAppRefresh(task: BGAppRefreshTask) {
        scheduleAppRefresh()

        print("⏳ Handling background app refresh task...")
        let fetcher = NoticeFetcher()
        _ = NotificationManager.shared

        fetcher.refreshNotices()


        /*
        fetcher.fetchNotices(boardId: "notice02") { result in // Use an appropriate boardId
            switch result {
            case .success(let notices):
                print("✅ Background fetch successful. \(notices.count) notices found.")
                // --- Logic to detect new notices ---
                // 1. Get the ID/Link of the latest notice the user knows about (e.g., from UserDefaults)
                let lastKnownNoticeLink = UserDefaults.standard.string(forKey: "lastKnownNoticeLink_notice02") ?? ""

                // 2. Find the newest notice in the fetched list
                if let newestNotice = notices.first { // Assuming notices are sorted newest first
                    // 3. Compare with the last known notice
                    if newestNotice.link != lastKnownNoticeLink && !lastKnownNoticeLink.isEmpty { // Check if it's different and not the first launch
                        print("✨ New notice found: \(newestNotice.title)")
                        // 4. Schedule a notification
                        notificationManager.scheduleNewPostNotification(title: "새 공지사항", body: newestNotice.title)

                        // 5. Update the last known notice link
                        UserDefaults.standard.set(newestNotice.link, forKey: "lastKnownNoticeLink_notice02")
                        print("💾 Updated last known notice link: \(newestNotice.link)")

                    } else if lastKnownNoticeLink.isEmpty {
                         // First time fetching, just store the latest
                         UserDefaults.standard.set(newestNotice.link, forKey: "lastKnownNoticeLink_notice02")
                         print("💾 Stored initial last known notice link: \(newestNotice.link)")
                    } else {
                         print("ℹ️ No new notices found.")
                    }
                } else {
                     print("ℹ️ No notices fetched in background.")
                }

                // Mark the task as completed successfully
                task.setTaskCompleted(success: true)

            case .failure(let error):
                print("❌ Background fetch failed: \(error.localizedDescription)")
                // Mark the task as completed with failure
                task.setTaskCompleted(success: false)
            }
        }
        */

        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
             print("ℹ️ Placeholder: Background task 'completed' (actual logic needs implementation).")
             task.setTaskCompleted(success: true)
        }


        task.expirationHandler = {
            print("⚠️ Background task expired.")
            task.setTaskCompleted(success: false)
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        scheduleAppRefresh()
    }
}

extension TextAlignment {
    var frameAlignment: Alignment {
        switch self {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }
}
