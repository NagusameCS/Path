//
//  Achievement.swift
//  PathGame
//
//  Achievement definitions and tracking
//

import Foundation

struct Achievement: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let category: AchievementCategory
    let requirement: Int
    var progress: Int
    var isUnlocked: Bool
    var unlockedDate: Date?
    
    var progressPercentage: Double {
        guard requirement > 0 else { return 0 }
        return min(Double(progress) / Double(requirement) * 100, 100)
    }
    
    mutating func updateProgress(_ value: Int) {
        progress = value
        if progress >= requirement && !isUnlocked {
            isUnlocked = true
            unlockedDate = Date()
        }
    }
}

enum AchievementCategory: String, Codable, CaseIterable {
    case beginner = "Beginner"
    case streak = "Streak"
    case mastery = "Mastery"
    case social = "Social"
    case special = "Special"
    
    var color: String {
        switch self {
        case .beginner: return "green"
        case .streak: return "orange"
        case .mastery: return "purple"
        case .social: return "blue"
        case .special: return "yellow"
        }
    }
}

// MARK: - Achievement Definitions
struct AchievementDefinitions {
    static let all: [Achievement] = [
        // Beginner
        Achievement(id: "first_game", title: "First Steps", description: "Complete your first puzzle", icon: "figure.walk", category: .beginner, requirement: 1, progress: 0, isUnlocked: false),
        Achievement(id: "first_perfect", title: "Perfect Start", description: "Get your first perfect score", icon: "star.fill", category: .beginner, requirement: 1, progress: 0, isUnlocked: false),
        Achievement(id: "unlock_7x7", title: "Level Up", description: "Unlock the 7×7 grid", icon: "arrow.up.circle.fill", category: .beginner, requirement: 1, progress: 0, isUnlocked: false),
        
        // Streak
        Achievement(id: "streak_3", title: "Hat Trick", description: "Get a 3-day streak", icon: "flame.fill", category: .streak, requirement: 3, progress: 0, isUnlocked: false),
        Achievement(id: "streak_7", title: "Week Warrior", description: "Get a 7-day streak", icon: "flame.fill", category: .streak, requirement: 7, progress: 0, isUnlocked: false),
        Achievement(id: "streak_30", title: "Monthly Master", description: "Get a 30-day streak", icon: "flame.fill", category: .streak, requirement: 30, progress: 0, isUnlocked: false),
        Achievement(id: "streak_100", title: "Century Legend", description: "Get a 100-day streak", icon: "crown.fill", category: .streak, requirement: 100, progress: 0, isUnlocked: false),
        
        // Mastery
        Achievement(id: "perfect_5", title: "Skilled", description: "Get 5 perfect scores", icon: "star.circle.fill", category: .mastery, requirement: 5, progress: 0, isUnlocked: false),
        Achievement(id: "perfect_25", title: "Expert", description: "Get 25 perfect scores", icon: "star.circle.fill", category: .mastery, requirement: 25, progress: 0, isUnlocked: false),
        Achievement(id: "perfect_100", title: "Grandmaster", description: "Get 100 perfect scores", icon: "crown.fill", category: .mastery, requirement: 100, progress: 0, isUnlocked: false),
        Achievement(id: "first_try_10", title: "Precision", description: "Get 10 first-try perfects", icon: "target", category: .mastery, requirement: 10, progress: 0, isUnlocked: false),
        Achievement(id: "both_grids", title: "Dual Master", description: "Get perfect on both grids in one day", icon: "square.grid.2x2.fill", category: .mastery, requirement: 1, progress: 0, isUnlocked: false),
        
        // Social
        Achievement(id: "share_first", title: "Sharing is Caring", description: "Share your first result", icon: "square.and.arrow.up.fill", category: .social, requirement: 1, progress: 0, isUnlocked: false),
        Achievement(id: "add_friend", title: "Friendly", description: "Add your first friend", icon: "person.2.fill", category: .social, requirement: 1, progress: 0, isUnlocked: false),
        Achievement(id: "friends_5", title: "Social Butterfly", description: "Have 5 friends", icon: "person.3.fill", category: .social, requirement: 5, progress: 0, isUnlocked: false),
        Achievement(id: "beat_friend", title: "Competitive", description: "Beat a friend's score", icon: "trophy.fill", category: .social, requirement: 1, progress: 0, isUnlocked: false),
        
        // Special
        Achievement(id: "weekend_warrior", title: "Weekend Warrior", description: "Play every weekend for a month", icon: "calendar.circle.fill", category: .special, requirement: 8, progress: 0, isUnlocked: false),
        Achievement(id: "early_bird", title: "Early Bird", description: "Complete a puzzle before 6 AM", icon: "sunrise.fill", category: .special, requirement: 1, progress: 0, isUnlocked: false),
        Achievement(id: "night_owl", title: "Night Owl", description: "Complete a puzzle after midnight", icon: "moon.stars.fill", category: .special, requirement: 1, progress: 0, isUnlocked: false),
        Achievement(id: "comeback", title: "Never Give Up", description: "Get perfect after 5+ attempts", icon: "arrow.counterclockwise.circle.fill", category: .special, requirement: 1, progress: 0, isUnlocked: false),
    ]
}
