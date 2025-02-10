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
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            if let error = error {
                print("❌ 알림 권한 요청 오류: \(error)")
            } else {
                print(granted ? "✅ 알림 권한 허용됨" : "❌ 알림 권한 거부됨")
            }
        }
    }
    
    func scheduleNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 1,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ 알림 예약 실패: \(error)")
            }
        }
    }
}

