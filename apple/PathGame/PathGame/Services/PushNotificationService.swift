//
//  PushNotificationService.swift
//  Path
//
//  Firebase Cloud Messaging for push notifications
//

import Foundation
import FirebaseMessaging
import FirebaseFirestore
import UserNotifications

#if os(iOS)
import UIKit
#endif

// MARK: - Notification Types
enum PathNotificationType: String {
    case dailyReminder = "daily_reminder"
    case streakWarning = "streak_warning"
    case leaderboardUpdate = "leaderboard_update"
    case friendActivity = "friend_activity"
}

// MARK: - Push Notification Service
class PushNotificationService: NSObject, ObservableObject {
    static let shared = PushNotificationService()
    
    @Published var fcmToken: String?
    @Published var isAuthorized = false
    @Published var pendingNotifications: [UNNotification] = []
    
    override init() {
        super.init()
        Messaging.messaging().delegate = self
    }
    
    // MARK: - Request Authorization
    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            
            await MainActor.run {
                self.isAuthorized = granted
            }
            
            if granted {
                await registerForRemoteNotifications()
            }
            
            return granted
        } catch {
            return false
        }
    }
    
    // MARK: - Register for Remote Notifications
    @MainActor
    private func registerForRemoteNotifications() async {
        #if os(iOS)
        UIApplication.shared.registerForRemoteNotifications()
        #endif
    }
    
    // MARK: - Subscribe to Topics
    func subscribeToTopics(region: LeaderboardRegion) {
        // Daily puzzle reminder
        Messaging.messaging().subscribe(toTopic: "daily_puzzle") { _ in
            // Subscribed to daily_puzzle
        }
        
        // Regional updates
        Messaging.messaging().subscribe(toTopic: "region_\(region.rawValue)") { _ in
            // Subscribed to region
        }
    }
    
    // MARK: - Unsubscribe from Topics
    func unsubscribeFromTopics() {
        Messaging.messaging().unsubscribe(fromTopic: "daily_puzzle")
        
        for region in LeaderboardRegion.allCases {
            Messaging.messaging().unsubscribe(fromTopic: "region_\(region.rawValue)")
        }
    }
    
    // MARK: - Schedule Local Notifications
    func scheduleDailyReminder(at hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()
        
        // Remove existing reminders
        center.removePendingNotificationRequests(withIdentifiers: ["daily_reminder"])
        
        let content = UNMutableNotificationContent()
        content.title = "Daily Puzzle Ready!"
        content.body = "A new Path puzzle is waiting for you. Keep your streak alive!"
        content.sound = .default
        content.badge = 1
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_reminder", content: content, trigger: trigger)
        
        center.add(request) { _ in
            // Daily reminder scheduled
        }
    }
    
    // MARK: - Schedule Streak Warning
    func scheduleStreakWarning() {
        let center = UNUserNotificationCenter.current()
        
        // Remove existing warnings
        center.removePendingNotificationRequests(withIdentifiers: ["streak_warning"])
        
        let content = UNMutableNotificationContent()
        content.title = "Don't lose your streak!"
        content.body = "You haven't played today's puzzle yet. Your streak is at risk!"
        content.sound = .default
        content.badge = 1
        
        // Schedule for 8 PM if not played
        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: "streak_warning", content: content, trigger: trigger)
        
        center.add(request) { _ in
            // Streak warning scheduled
        }
    }
    
    // MARK: - Cancel Streak Warning (when user plays)
    func cancelStreakWarning() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["streak_warning"])
    }
    
    // MARK: - Update FCM Token on Server
    func updateTokenOnServer(userId: String) async {
        guard let token = fcmToken else { return }
        
        let db = FirebaseService.shared.db
        
        do {
            try await db.collection("users").document(userId).updateData([
                "fcmToken": token,
                "lastTokenUpdate": FieldValue.serverTimestamp()
            ])
        } catch {
            // FCM token update failed
        }
    }
    
    // MARK: - Clear Badge
    func clearBadge() {
        #if os(iOS)
        Task {
            do {
                try await UNUserNotificationCenter.current().setBadgeCount(0)
            } catch {
                // Badge clear failed
            }
        }
        #endif
    }
}

// MARK: - MessagingDelegate
extension PushNotificationService: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        self.fcmToken = fcmToken
        
        // Update token on server if user is logged in
        if let userId = AuthService.shared.currentUser?.id {
            Task {
                await updateTokenOnServer(userId: userId)
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension PushNotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        // Show notification even when app is in foreground
        return [.banner, .sound, .badge]
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo
        
        // Handle notification tap
        if let type = userInfo["type"] as? String {
            await handleNotificationTap(type: type, userInfo: userInfo)
        }
    }
    
    private func handleNotificationTap(type: String, userInfo: [AnyHashable: Any]) async {
        // Handle different notification types
        switch type {
        case "daily_reminder":
            // Open game view
            break
        case "streak_warning":
            // Open game view with emphasis on streak
            break
        case "leaderboard_update":
            // Open leaderboard
            break
        case "friend_activity":
            // Open friends view
            break
        default:
            break
        }
    }
}
