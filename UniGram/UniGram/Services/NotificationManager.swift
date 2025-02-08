//
//  NotificationManager.swift
//  UniGram
//
//  Created by speedy on 2/7/25.
//

import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {
        requestPermission()
    }
    
    private func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("❌ 알림 권한 요청 오류: \(error)")
            } else {
                print(granted ? "✅ 알림 권한 허용됨" : "❌ 알림 권한 거부됨")
            }
        }
    }
}
