//
//  NotificationService.swift
//  PathGame
//
//  Local notifications for daily puzzle reminders
//

import Foundation
import UserNotifications
import SwiftUI

class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var isAuthorized = false
    @Published var reminderEnabled = false
    @Published var reminderTime: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private let dailyReminderID = "daily-puzzle-reminder"
    private let streakReminderID = "streak-reminder"
    
    private init() {
        checkAuthorizationStatus()
        loadSettings()
    }
    
    // MARK: - Authorization
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                self.isAuthorized = granted
            }
            return granted
        } catch {
            print("Failed to request notification authorization: \(error)")
            return false
        }
    }
    
    func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { settings in
            Task { @MainActor in
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Daily Reminder
    func scheduleDailyReminder(at time: Date) async {
        guard isAuthorized else {
            let granted = await requestAuthorization()
            if !granted { return }
        }
        
        // Cancel existing reminder
        cancelDailyReminder()
        
        // Create new notification
        let content = UNMutableNotificationContent()
        content.title = "🧩 Daily Path Puzzle"
        content.body = "A new puzzle is waiting for you! Can you find the perfect path?"
        content.sound = .default
        content.badge = 1
        
        // Get hour and minute from the time
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        
        var dateComponents = DateComponents()
        dateComponents.hour = components.hour
        dateComponents.minute = components.minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: dailyReminderID, content: content, trigger: trigger)
        
        do {
            try await notificationCenter.add(request)
            await MainActor.run {
                self.reminderEnabled = true
                self.reminderTime = time
                self.saveSettings()
            }
        } catch {
            print("Failed to schedule daily reminder: \(error)")
        }
    }
    
    func cancelDailyReminder() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [dailyReminderID])
        reminderEnabled = false
        saveSettings()
    }
    
    // MARK: - Streak Reminder
    func scheduleStreakReminder(currentStreak: Int) async {
        guard isAuthorized, currentStreak > 0 else { return }
        
        // Cancel existing streak reminder
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [streakReminderID])
        
        // Schedule reminder for 8 PM if puzzle not completed
        let content = UNMutableNotificationContent()
        content.title = "🔥 Don't Break Your Streak!"
        content.body = "You have a \(currentStreak)-day streak. Complete today's puzzle to keep it going!"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: streakReminderID, content: content, trigger: trigger)
        
        do {
            try await notificationCenter.add(request)
        } catch {
            print("Failed to schedule streak reminder: \(error)")
        }
    }
    
    func cancelStreakReminder() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [streakReminderID])
    }
    
    // MARK: - Badge Management
    func clearBadge() {
        #if os(iOS)
        Task { @MainActor in
            UNUserNotificationCenter.current().setBadgeCount(0)
        }
        #endif
    }
    
    // MARK: - Perfect Score Celebration
    func schedulePerfectCelebration() async {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🏆 Amazing!"
        content.body = "You got a perfect score! Share your achievement with friends!"
        content.sound = UNNotificationSound(named: UNNotificationSoundName("celebration.wav"))
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "perfect-celebration", content: content, trigger: trigger)
        
        do {
            try await notificationCenter.add(request)
        } catch {
            print("Failed to schedule celebration: \(error)")
        }
    }
    
    // MARK: - Settings Persistence
    private let settingsKey = "notification-settings"
    
    private func saveSettings() {
        let settings: [String: Any] = [
            "reminderEnabled": reminderEnabled,
            "reminderTime": reminderTime.timeIntervalSince1970
        ]
        UserDefaults.standard.set(settings, forKey: settingsKey)
    }
    
    private func loadSettings() {
        guard let settings = UserDefaults.standard.dictionary(forKey: settingsKey) else { return }
        
        reminderEnabled = settings["reminderEnabled"] as? Bool ?? false
        if let timeInterval = settings["reminderTime"] as? TimeInterval {
            reminderTime = Date(timeIntervalSince1970: timeInterval)
        }
    }
    
    // MARK: - Pending Notifications
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }
    
    // MARK: - Convenience Methods for SwiftUI (fire-and-forget)
    func requestPermission() {
        Task {
            _ = await requestAuthorization()
        }
    }
    
    func scheduleReminder(at time: Date) {
        Task {
            await scheduleDailyReminder(at: time)
        }
    }
    
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        reminderEnabled = false
        saveSettings()
    }
}

// MARK: - SwiftUI View Modifier
struct NotificationReminderModifier: ViewModifier {
    @StateObject private var notificationService = NotificationService.shared
    @State private var showingTimePicker = false
    
    func body(content: Content) -> some View {
        content
            .onChange(of: notificationService.reminderTime) { _, newTime in
                if notificationService.reminderEnabled {
                    Task {
                        await notificationService.scheduleDailyReminder(at: newTime)
                    }
                }
            }
    }
}

extension View {
    func withNotificationReminder() -> some View {
        modifier(NotificationReminderModifier())
    }
}
