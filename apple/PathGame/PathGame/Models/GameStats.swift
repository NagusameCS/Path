//
//  GameStats.swift
//  PathGame
//
//  Statistics tracking model for gameplay metrics
//

import Foundation

struct GameStats: Codable {
    // Overall stats
    var totalGamesPlayed: Int = 0
    var totalPerfectGames: Int = 0
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastPlayedDate: Date?
    
    // Grid-specific stats
    var stats5x5: GridStats = GridStats()
    var stats7x7: GridStats = GridStats()
    
    // Daily history (last 30 days)
    var dailyHistory: [DailyResult] = []
    
    // Achievement tracking
    var unlockedAchievements: Set<String> = []
    
    // Computed properties
    var perfectRate: Double {
        guard totalGamesPlayed > 0 else { return 0 }
        return Double(totalPerfectGames) / Double(totalGamesPlayed) * 100
    }
    
    var averageScore: Double {
        let all5x5 = stats5x5.averagePercentage
        let all7x7 = stats7x7.averagePercentage
        let count5x5 = stats5x5.gamesPlayed
        let count7x7 = stats7x7.gamesPlayed
        
        guard count5x5 + count7x7 > 0 else { return 0 }
        return (all5x5 * Double(count5x5) + all7x7 * Double(count7x7)) / Double(count5x5 + count7x7)
    }
    
    mutating func recordGame(gridSize: GridSize, score: Int, optimal: Int, attempts: Int, gaveUp: Bool) {
        let isPerfect = score == optimal && !gaveUp
        let percentage = Double(score) / Double(optimal) * 100
        
        totalGamesPlayed += 1
        lastPlayedDate = Date()
        
        // Update streak
        if isPerfect {
            totalPerfectGames += 1
            currentStreak += 1
            longestStreak = max(longestStreak, currentStreak)
        } else {
            currentStreak = 0
        }
        
        // Update grid-specific stats
        switch gridSize {
        case .small:
            stats5x5.recordGame(score: score, optimal: optimal, attempts: attempts, isPerfect: isPerfect)
        case .large:
            stats7x7.recordGame(score: score, optimal: optimal, attempts: attempts, isPerfect: isPerfect)
        }
        
        // Add to daily history
        let result = DailyResult(
            date: Date(),
            gridSize: gridSize,
            score: score,
            optimal: optimal,
            attempts: attempts,
            isPerfect: isPerfect,
            gaveUp: gaveUp
        )
        dailyHistory.insert(result, at: 0)
        
        // Keep only last 30 days
        if dailyHistory.count > 30 {
            dailyHistory = Array(dailyHistory.prefix(30))
        }
    }
}

// MARK: - Grid Stats
struct GridStats: Codable {
    var gamesPlayed: Int = 0
    var perfectGames: Int = 0
    var bestScore: Int = 0
    var totalScore: Int = 0
    var totalOptimal: Int = 0
    var totalAttempts: Int = 0
    var firstTryPerfects: Int = 0
    var fastestPerfect: TimeInterval?
    
    var averagePercentage: Double {
        guard totalOptimal > 0 else { return 0 }
        return Double(totalScore) / Double(totalOptimal) * 100
    }
    
    var averageAttempts: Double {
        guard gamesPlayed > 0 else { return 0 }
        return Double(totalAttempts) / Double(gamesPlayed)
    }
    
    mutating func recordGame(score: Int, optimal: Int, attempts: Int, isPerfect: Bool) {
        gamesPlayed += 1
        totalScore += score
        totalOptimal += optimal
        totalAttempts += attempts
        bestScore = max(bestScore, score)
        
        if isPerfect {
            perfectGames += 1
            if attempts == 1 {
                firstTryPerfects += 1
            }
        }
    }
}

// MARK: - Daily Result
struct DailyResult: Codable, Identifiable {
    var id: String { dateString + gridSize.displayName }
    let date: Date
    let gridSize: GridSize
    let score: Int
    let optimal: Int
    let attempts: Int
    let isPerfect: Bool
    let gaveUp: Bool
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    var percentage: Int {
        guard optimal > 0 else { return 0 }
        return Int((Double(score) / Double(optimal)) * 100)
    }
}

// MARK: - Stats Distribution
struct StatsDistribution {
    var perfect: Int = 0
    var excellent: Int = 0  // 90-99%
    var good: Int = 0       // 70-89%
    var fair: Int = 0       // 50-69%
    var poor: Int = 0       // <50%
    
    mutating func add(percentage: Int) {
        switch percentage {
        case 100: perfect += 1
        case 90...99: excellent += 1
        case 70...89: good += 1
        case 50...69: fair += 1
        default: poor += 1
        }
    }
}
