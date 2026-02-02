//
//  Friend.swift
//  PathGame
//
//  Friend model for social features
//

import Foundation
import GameKit

struct Friend: Identifiable, Codable {
    let id: String
    var displayName: String
    var avatarURL: URL?
    var isOnline: Bool
    var lastScore: FriendScore?
    var friendship: FriendshipStatus
    var addedDate: Date
    
    init(id: String, displayName: String, avatarURL: URL? = nil) {
        self.id = id
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.isOnline = false
        self.friendship = .friend
        self.addedDate = Date()
    }
    
    init(from gkPlayer: GKPlayer) {
        self.id = gkPlayer.gamePlayerID
        self.displayName = gkPlayer.displayName
        self.isOnline = false
        self.friendship = .friend
        self.addedDate = Date()
    }
}

enum FriendshipStatus: String, Codable {
    case pending = "Pending"
    case friend = "Friend"
    case blocked = "Blocked"
}

struct FriendScore: Codable {
    let date: Date
    let gridSize: GridSize
    let score: Int
    let optimal: Int
    let attempts: Int
    let isPerfect: Bool
    
    var percentage: Int {
        guard optimal > 0 else { return 0 }
        return Int((Double(score) / Double(optimal)) * 100)
    }
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Friend Activity
struct FriendActivity: Identifiable {
    let id = UUID()
    let friend: Friend
    let activityType: ActivityType
    let timestamp: Date
    let details: String?
    
    enum ActivityType: String {
        case completedPuzzle = "completed"
        case perfectScore = "perfect"
        case newStreak = "streak"
        case achievement = "achievement"
    }
    
    var message: String {
        switch activityType {
        case .completedPuzzle:
            return "\(friend.displayName) completed today's puzzle"
        case .perfectScore:
            return "\(friend.displayName) got a perfect score! 🏆"
        case .newStreak:
            return "\(friend.displayName) is on a \(details ?? "")day streak!"
        case .achievement:
            return "\(friend.displayName) unlocked '\(details ?? "")'"
        }
    }
    
    var icon: String {
        switch activityType {
        case .completedPuzzle: return "checkmark.circle.fill"
        case .perfectScore: return "star.fill"
        case .newStreak: return "flame.fill"
        case .achievement: return "trophy.fill"
        }
    }
}

// MARK: - Challenge
struct FriendChallenge: Identifiable, Codable {
    let id: String
    let fromPlayerId: String
    let fromPlayerName: String
    let toPlayerId: String
    let gridSize: GridSize
    let challengerScore: Int
    let challengerOptimal: Int
    let dateString: String
    let createdAt: Date
    var status: ChallengeStatus
    var responderScore: Int?
    var responderOptimal: Int?
    var completedAt: Date?
    
    enum ChallengeStatus: String, Codable {
        case pending = "pending"
        case accepted = "accepted"
        case completed = "completed"
        case declined = "declined"
        case expired = "expired"
    }
    
    var isWinner: Bool? {
        guard let responderScore, status == .completed else { return nil }
        return responderScore > challengerScore
    }
}
