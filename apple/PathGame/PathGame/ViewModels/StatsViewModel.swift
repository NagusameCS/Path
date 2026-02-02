//
//  StatsViewModel.swift
//  PathGame
//
//  Statistics management and tracking
//

import Foundation
import SwiftUI
import Combine

@MainActor
class StatsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var stats: GameStats
    @Published var achievements: [Achievement]
    @Published var selectedCategory: AchievementCategory?
    
    // Distribution for charts
    @Published var scoreDistribution: [String: Int] = [:]
    
    private let storageKey = "player-stats"
    private let achievementsKey = "player-achievements"
    
    // MARK: - Computed Properties
    var totalGamesPlayed: Int { stats.totalGamesPlayed }
    var totalPerfectGames: Int { stats.totalPerfectGames }
    var currentStreak: Int { stats.currentStreak }
    var longestStreak: Int { stats.longestStreak }
    var perfectRate: Double { stats.perfectRate }
    var averageScore: Double { stats.averageScore }
    
    var unlockedAchievements: [Achievement] {
        achievements.filter { $0.isUnlocked }
    }
    
    var lockedAchievements: [Achievement] {
        achievements.filter { !$0.isUnlocked }
    }
    
    var achievementProgress: Double {
        guard !achievements.isEmpty else { return 0 }
        return Double(unlockedAchievements.count) / Double(achievements.count) * 100
    }
    
    var filteredAchievements: [Achievement] {
        if let category = selectedCategory {
            return achievements.filter { $0.category == category }
        }
        return achievements
    }
    
    // MARK: - Initialization
    init() {
        self.stats = GameStats()
        self.achievements = AchievementDefinitions.all
        loadStats()
        loadAchievements()
        calculateDistribution()
    }
    
    // MARK: - Game Recording
    func recordGame(from gameState: GameState) {
        stats.recordGame(
            gridSize: gameState.gridSize,
            score: gameState.pathLength,
            optimal: gameState.optimalLength,
            attempts: gameState.attempts,
            gaveUp: gameState.gaveUp
        )
        
        checkAchievements(gameState: gameState)
        saveStats()
        calculateDistribution()
    }
    
    // MARK: - Achievement Tracking
    func checkAchievements(gameState: GameState) {
        let isPerfect = gameState.isPerfect
        
        // First game
        updateAchievement("first_game", progress: 1)
        
        // First perfect
        if isPerfect {
            updateAchievement("first_perfect", progress: 1)
        }
        
        // Unlock 7x7
        if gameState.gridSize == .small && isPerfect {
            updateAchievement("unlock_7x7", progress: 1)
        }
        
        // Streak achievements
        updateAchievement("streak_3", progress: stats.currentStreak)
        updateAchievement("streak_7", progress: stats.currentStreak)
        updateAchievement("streak_30", progress: stats.currentStreak)
        updateAchievement("streak_100", progress: stats.currentStreak)
        
        // Perfect achievements
        updateAchievement("perfect_5", progress: stats.totalPerfectGames)
        updateAchievement("perfect_25", progress: stats.totalPerfectGames)
        updateAchievement("perfect_100", progress: stats.totalPerfectGames)
        
        // First try perfects
        if isPerfect && gameState.attempts == 1 {
            let firstTryCount = stats.stats5x5.firstTryPerfects + stats.stats7x7.firstTryPerfects
            updateAchievement("first_try_10", progress: firstTryCount)
        }
        
        // Comeback achievement (perfect after 5+ attempts)
        if isPerfect && gameState.attempts >= 5 {
            updateAchievement("comeback", progress: 1)
        }
        
        // Time-based achievements
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 6 && isPerfect {
            updateAchievement("early_bird", progress: 1)
        }
        if hour >= 0 && hour < 4 && isPerfect {
            updateAchievement("night_owl", progress: 1)
        }
        
        saveAchievements()
    }
    
    func updateAchievement(_ id: String, progress: Int) {
        guard let index = achievements.firstIndex(where: { $0.id == id }) else { return }
        achievements[index].updateProgress(progress)
    }
    
    func recordShare() {
        updateAchievement("share_first", progress: 1)
        saveAchievements()
    }
    
    func recordFriendAdded(totalFriends: Int) {
        updateAchievement("add_friend", progress: 1)
        updateAchievement("friends_5", progress: totalFriends)
        saveAchievements()
    }
    
    func recordBeatFriend() {
        updateAchievement("beat_friend", progress: 1)
        saveAchievements()
    }
    
    // MARK: - Distribution Calculation
    func calculateDistribution() {
        var distribution: [String: Int] = [
            "Perfect": 0,
            "90-99%": 0,
            "70-89%": 0,
            "50-69%": 0,
            "<50%": 0
        ]
        
        for result in stats.dailyHistory {
            switch result.percentage {
            case 100:
                distribution["Perfect"]! += 1
            case 90...99:
                distribution["90-99%"]! += 1
            case 70...89:
                distribution["70-89%"]! += 1
            case 50...69:
                distribution["50-69%"]! += 1
            default:
                distribution["<50%"]! += 1
            }
        }
        
        scoreDistribution = distribution
    }
    
    // MARK: - Persistence
    func saveStats() {
        if let data = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
        
        // Sync to iCloud
        Task {
            await CloudKitService.shared.saveStats(stats)
        }
    }
    
    func loadStats() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode(GameStats.self, from: data) {
            stats = saved
        }
    }
    
    func saveAchievements() {
        if let data = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(data, forKey: achievementsKey)
        }
    }
    
    func loadAchievements() {
        if let data = UserDefaults.standard.data(forKey: achievementsKey),
           let saved = try? JSONDecoder().decode([Achievement].self, from: data) {
            // Merge with definitions to get any new achievements
            var merged = saved
            for definition in AchievementDefinitions.all {
                if !merged.contains(where: { $0.id == definition.id }) {
                    merged.append(definition)
                }
            }
            achievements = merged
        }
    }
    
    // MARK: - Reset
    func resetStats() {
        stats = GameStats()
        saveStats()
        calculateDistribution()
    }
    
    func resetAchievements() {
        achievements = AchievementDefinitions.all
        saveAchievements()
    }
}
