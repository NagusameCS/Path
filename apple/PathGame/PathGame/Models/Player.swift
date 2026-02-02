//
//  Player.swift
//  PathGame
//
//  Player profile model with Game Center integration
//

import Foundation
import GameKit

struct Player: Codable, Identifiable {
    let id: String
    var displayName: String
    var avatarURL: URL?
    var totalGamesPlayed: Int
    var perfectGames: Int
    var currentStreak: Int
    var longestStreak: Int
    var averageScore: Double
    var joinDate: Date
    var lastPlayedDate: Date?
    
    // Computed properties
    var perfectRate: Double {
        guard totalGamesPlayed > 0 else { return 0 }
        return Double(perfectGames) / Double(totalGamesPlayed) * 100
    }
    
    init(id: String = UUID().uuidString, displayName: String = "Player") {
        self.id = id
        self.displayName = displayName
        self.totalGamesPlayed = 0
        self.perfectGames = 0
        self.currentStreak = 0
        self.longestStreak = 0
        self.averageScore = 0
        self.joinDate = Date()
    }
    
    init(from gkPlayer: GKPlayer) {
        self.id = gkPlayer.gamePlayerID
        self.displayName = gkPlayer.displayName
        self.totalGamesPlayed = 0
        self.perfectGames = 0
        self.currentStreak = 0
        self.longestStreak = 0
        self.averageScore = 0
        self.joinDate = Date()
    }
    
    mutating func recordGame(score: Int, optimal: Int, isPerfect: Bool) {
        totalGamesPlayed += 1
        lastPlayedDate = Date()
        
        if isPerfect {
            perfectGames += 1
            currentStreak += 1
            longestStreak = max(longestStreak, currentStreak)
        } else {
            currentStreak = 0
        }
        
        // Update average score
        let percentage = Double(score) / Double(optimal) * 100
        averageScore = ((averageScore * Double(totalGamesPlayed - 1)) + percentage) / Double(totalGamesPlayed)
    }
}
