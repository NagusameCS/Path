//
//  WidgetService.swift
//  Path
//
//  Service to update widget data from the main app
//

import Foundation
import WidgetKit

class WidgetService: ObservableObject {
    static let shared = WidgetService()
    
    private let sharedDefaults = UserDefaults(suiteName: "group.com.nagusamecs.pathgame")
    
    private init() {}
    
    // MARK: - Widget Data Structure
    struct WidgetData: Codable {
        var currentStreak: Int
        var longestStreak: Int
        var hasPlayedToday: Bool
        var leaderboardRank: Int?
        var totalScore: Int
        var shields: Int
        var lastUpdated: Date
    }
    
    // MARK: - Update Widget
    func updateWidget(
        currentStreak: Int,
        longestStreak: Int,
        hasPlayedToday: Bool,
        leaderboardRank: Int? = nil,
        totalScore: Int,
        shields: Int = 0
    ) {
        let data = WidgetData(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            hasPlayedToday: hasPlayedToday,
            leaderboardRank: leaderboardRank,
            totalScore: totalScore,
            shields: shields,
            lastUpdated: Date()
        )
        
        if let encoded = try? JSONEncoder().encode(data) {
            sharedDefaults?.set(encoded, forKey: "widgetData")
        }
        
        // Refresh widgets
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // MARK: - Update from Services
    func updateFromServices(
        streakService: StreakService,
        authService: AuthService,
        leaderboardService: LeaderboardService
    ) {
        let streakData = streakService.streakData
        let user = authService.currentUser
        
        updateWidget(
            currentStreak: streakData?.currentStreak ?? 0,
            longestStreak: streakData?.longestStreak ?? 0,
            hasPlayedToday: streakData?.hasPlayedToday ?? false,
            leaderboardRank: leaderboardService.userRank,
            totalScore: user?.totalGamesPlayed ?? 0,
            shields: streakData?.shields ?? 0
        )
    }
    
    // MARK: - Quick Updates
    func updateStreak(currentStreak: Int, longestStreak: Int, hasPlayedToday: Bool) {
        // Load existing data and update only streak info
        if let data = sharedDefaults?.data(forKey: "widgetData"),
           var widgetData = try? JSONDecoder().decode(WidgetData.self, from: data) {
            widgetData.currentStreak = currentStreak
            widgetData.longestStreak = longestStreak
            widgetData.hasPlayedToday = hasPlayedToday
            widgetData.lastUpdated = Date()
            
            if let encoded = try? JSONEncoder().encode(widgetData) {
                sharedDefaults?.set(encoded, forKey: "widgetData")
            }
        } else {
            // Create new data
            updateWidget(
                currentStreak: currentStreak,
                longestStreak: longestStreak,
                hasPlayedToday: hasPlayedToday,
                totalScore: 0
            )
        }
        
        WidgetCenter.shared.reloadTimelines(ofKind: "StreakWidget")
    }
    
    func updateLeaderboardRank(_ rank: Int?) {
        // Load existing data and update only rank
        if let data = sharedDefaults?.data(forKey: "widgetData"),
           var widgetData = try? JSONDecoder().decode(WidgetData.self, from: data) {
            widgetData.leaderboardRank = rank
            widgetData.lastUpdated = Date()
            
            if let encoded = try? JSONEncoder().encode(widgetData) {
                sharedDefaults?.set(encoded, forKey: "widgetData")
            }
        }
        
        WidgetCenter.shared.reloadTimelines(ofKind: "LeaderboardWidget")
    }
    
    func updateTotalScore(_ score: Int) {
        // Load existing data and update only score
        if let data = sharedDefaults?.data(forKey: "widgetData"),
           var widgetData = try? JSONDecoder().decode(WidgetData.self, from: data) {
            widgetData.totalScore = score
            widgetData.lastUpdated = Date()
            
            if let encoded = try? JSONEncoder().encode(widgetData) {
                sharedDefaults?.set(encoded, forKey: "widgetData")
            }
        }
        
        WidgetCenter.shared.reloadAllTimelines()
    }
}
