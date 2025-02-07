//
//  AppDelegate.swift
//  UniGram
//
//  Created by 이지안 on 2/7/25.
//

import UserNotifications

func requestNotificationPermission() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
        if granted {
            print("✅ 알림 권한 허용됨")
        } else {
            print("❌ 알림 권한 거부됨")
        }
    }
}
