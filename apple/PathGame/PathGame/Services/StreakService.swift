//
//  StreakService.swift
//  Path
//
//  Manages streak tracking with shield-based protection (earned by watching ads)
//

import Foundation
import FirebaseFirestore

// MARK: - Streak Data
struct StreakData: Codable {
    var currentStreak: Int
    var longestStreak: Int
    var lastPlayedDate: Date?
    var lastPerfectDate: Date?
    var lastStreakRecoveryDate: Date?
    var streakRecoveryCount: Int
    var totalDaysPlayed: Int
    var hasPlayedToday: Bool
    var shields: Int  // Number of streak protection shields
    
    init() {
        self.currentStreak = 0
        self.longestStreak = 0
        self.lastPlayedDate = nil
        self.lastPerfectDate = nil
        self.lastStreakRecoveryDate = nil
        self.streakRecoveryCount = 0
        self.totalDaysPlayed = 0
        self.hasPlayedToday = false
        self.shields = 0
    }
}

// MARK: - Streak Service
class StreakService: ObservableObject {
    static let shared = StreakService()
    
    @Published var streakData: StreakData? = nil
    @Published var canRecoverStreak = false
    @Published var streakBroken = false
    @Published var daysUntilRecoveryAvailable = 0
    @Published var nextRecoveryAvailable: Date? = nil
    @Published var shieldUsedToday = false  // Track if shield was auto-used
    
    private let db = FirebaseService.shared.db
    private let calendar = Calendar.current
    
    static let maxShields = 3  // Maximum shields a user can hold
    
    private init() {}
    
    // MARK: - Convenience Methods (use current user)
    func recordGameCompletion() async {
        guard let userId = AuthService.shared.currentUser?.id else { return }
        await recordGameCompletion(isPerfect: true, userId: userId)
    }
    
    func recoverStreak() async {
        guard let userId = AuthService.shared.currentUser?.id else { return }
        _ = await recoverStreak(userId: userId)
    }
    
    func loadCurrentUserStreak() async {
        guard let userId = AuthService.shared.currentUser?.id else { return }
        await loadStreak(for: userId)
    }
    
    // MARK: - Shield Management
    var canEarnShield: Bool {
        guard let data = streakData else { return true }
        return data.shields < Self.maxShields
    }
    
    var shieldCount: Int {
        streakData?.shields ?? 0
    }
    
    func addShield() async {
        guard let userId = AuthService.shared.currentUser?.id else { return }
        await addShield(userId: userId)
    }
    
    func addShield(userId: String) async {
        await MainActor.run {
            guard var data = streakData else { return }
            if data.shields < Self.maxShields {
                data.shields += 1
                self.streakData = data
            }
        }
        await saveStreak(for: userId)
        
        // Update widget
        updateWidget()
    }
    
    private func useShield() {
        guard var data = streakData, data.shields > 0 else { return }
        data.shields -= 1
        streakData = data
        shieldUsedToday = true
    }
    
    private func updateWidget() {
        guard let data = streakData else { return }
        WidgetService.shared.updateWidget(
            currentStreak: data.currentStreak,
            longestStreak: data.longestStreak,
            hasPlayedToday: data.hasPlayedToday,
            leaderboardRank: LeaderboardService.shared.userRank,
            totalScore: AuthService.shared.currentUser?.totalGamesPlayed ?? 0,
            shields: data.shields
        )
    }
    
    // MARK: - Load Streak
    func loadStreak(for userId: String) async {
        do {
            let document = try await db.collection("users").document(userId).collection("stats").document("streak").getDocument()
            
            if let data = document.data() {
                let loadedStreak = try Firestore.Decoder().decode(StreakData.self, from: data)
                await MainActor.run {
                    self.streakData = loadedStreak
                    self.checkStreakStatus()
                }
            } else {
                // No streak data yet, create new
                await MainActor.run {
                    self.streakData = StreakData()
                }
            }
        } catch {
            await MainActor.run {
                self.streakData = StreakData()
            }
        }
    }
    
    // MARK: - Save Streak
    func saveStreak(for userId: String) async {
        do {
            try db.collection("users").document(userId).collection("stats").document("streak").setData(from: streakData, merge: true)
        } catch {
            // Streak save failed
        }
    }
    
    // MARK: - Record Game Completion
    func recordGameCompletion(isPerfect: Bool, userId: String) async {
        let today = calendar.startOfDay(for: Date())
        
        await MainActor.run {
            var data = streakData ?? StreakData()
            
            // Check if already played today
            if let lastPlayed = data.lastPlayedDate,
               calendar.isDate(lastPlayed, inSameDayAs: today) {
                // Already played today, just update if perfect
                if isPerfect && data.lastPerfectDate != today {
                    data.lastPerfectDate = today
                }
                data.hasPlayedToday = true
                self.streakData = data
                return
            }
            
            // Check streak continuity
            if let lastPlayed = data.lastPlayedDate {
                let daysSinceLastPlay = calendar.dateComponents([.day], from: calendar.startOfDay(for: lastPlayed), to: today).day ?? 0
                
                if daysSinceLastPlay > 1 {
                    // Streak broken!
                    self.streakBroken = true
                    data.currentStreak = 0
                }
            }
            
            // Update streak
            if isPerfect {
                data.currentStreak += 1
                data.longestStreak = max(data.longestStreak, data.currentStreak)
                data.lastPerfectDate = today
            }
            
            data.lastPlayedDate = today
            data.totalDaysPlayed += 1
            data.hasPlayedToday = true
            self.streakData = data
            self.checkStreakStatus()
        }
        
        await saveStreak(for: userId)
        await updateUserStats(userId: userId)
    }
    
    // MARK: - Check Streak Status
    private func checkStreakStatus() {
        guard var data = streakData else { return }
        
        let today = calendar.startOfDay(for: Date())
        
        // Check if played today
        if let lastPlayed = data.lastPlayedDate {
            data.hasPlayedToday = calendar.isDate(lastPlayed, inSameDayAs: today)
        } else {
            data.hasPlayedToday = false
        }
        
        // Check if streak would be broken
        if let lastPlayed = data.lastPlayedDate {
            let daysSinceLastPlay = calendar.dateComponents([.day], from: calendar.startOfDay(for: lastPlayed), to: today).day ?? 0
            
            if daysSinceLastPlay > 1 && data.currentStreak > 0 {
                // Check if we have a shield to use
                if data.shields > 0 {
                    // Use shield to protect streak
                    data.shields -= 1
                    shieldUsedToday = true
                    streakBroken = false
                    // Keep the streak intact
                } else {
                    streakBroken = true
                }
            }
        }
        
        // Check if recovery is available (once per week) - only if streak is broken and no shields
        if streakBroken {
            if let lastRecovery = data.lastStreakRecoveryDate {
                let daysSinceRecovery = calendar.dateComponents([.day], from: calendar.startOfDay(for: lastRecovery), to: today).day ?? 0
                
                canRecoverStreak = daysSinceRecovery >= 7
                daysUntilRecoveryAvailable = max(0, 7 - daysSinceRecovery)
                
                if daysSinceRecovery < 7 {
                    nextRecoveryAvailable = calendar.date(byAdding: .day, value: 7 - daysSinceRecovery, to: today)
                } else {
                    nextRecoveryAvailable = nil
                }
            } else {
                canRecoverStreak = true
                daysUntilRecoveryAvailable = 0
                nextRecoveryAvailable = nil
            }
        } else {
            canRecoverStreak = false
            daysUntilRecoveryAvailable = 0
            nextRecoveryAvailable = nil
        }
        
        streakData = data
    }
    
    // MARK: - Recover Streak (After Watching Ad)
    func recoverStreak(userId: String) async -> Bool {
        guard canRecoverStreak else { return false }
        
        await MainActor.run {
            guard var data = streakData else { return }
            
            // Restore streak to 1 (they get credit for today)
            data.currentStreak = 1
            data.lastStreakRecoveryDate = Date()
            data.streakRecoveryCount += 1
            data.hasPlayedToday = true
            self.streakData = data
            self.streakBroken = false
            self.canRecoverStreak = false
            self.daysUntilRecoveryAvailable = 7
            self.nextRecoveryAvailable = Calendar.current.date(byAdding: .day, value: 7, to: Date())
        }
        
        await saveStreak(for: userId)
        return true
    }
    
    // MARK: - Update User Stats
    private func updateUserStats(userId: String) async {
        guard let data = streakData else { return }
        
        do {
            try await db.collection("users").document(userId).updateData([
                "currentStreak": data.currentStreak,
                "longestStreak": data.longestStreak,
                "lastActiveAt": FieldValue.serverTimestamp()
            ])
        } catch {
            // Stats update failed
        }
    }
    
    // MARK: - Get Streak Message
    var streakMessage: String {
        guard let data = streakData else {
            return "Start your streak today!"
        }
        
        if streakBroken && canRecoverStreak {
            return "Streak lost! Watch an ad to recover"
        } else if streakBroken && !canRecoverStreak {
            return "Streak lost. Recovery in \(daysUntilRecoveryAvailable) days"
        } else if data.currentStreak > 0 {
            return "\(data.currentStreak) day streak!"
        } else {
            return "Start your streak today!"
        }
    }
}
