//
//  FriendsViewModel.swift
//  PathGame
//
//  Friends management and social features
//

import Foundation
import SwiftUI
import GameKit
import Combine

@MainActor
class FriendsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var friends: [Friend] = []
    @Published var friendActivities: [FriendActivity] = []
    @Published var pendingChallenges: [FriendChallenge] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingAddFriend = false
    @Published var selectedFriend: Friend?
    
    private let storageKey = "friends-list"
    private let challengesKey = "friend-challenges"
    
    // MARK: - Computed Properties
    var activeFriends: [Friend] {
        friends.filter { $0.friendship == .friend }
    }
    
    var pendingRequests: [Friend] {
        friends.filter { $0.friendship == .pending }
    }
    
    var todaysFriendScores: [(friend: Friend, score: FriendScore)] {
        let today = Date()
        return friends.compactMap { friend in
            guard let score = friend.lastScore,
                  Calendar.current.isDateInToday(score.date) else { return nil }
            return (friend, score)
        }.sorted { $0.score.percentage > $1.score.percentage }
    }
    
    // MARK: - Initialization
    init() {
        loadFriends()
        loadChallenges()
    }
    
    // MARK: - Friend Management
    func loadGameCenterFriends() async {
        guard GKLocalPlayer.local.isAuthenticated else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let gkFriends = try await GKLocalPlayer.local.loadFriends()
            
            for gkPlayer in gkFriends {
                if !friends.contains(where: { $0.id == gkPlayer.gamePlayerID }) {
                    let friend = Friend(from: gkPlayer)
                    friends.append(friend)
                }
            }
            
            saveFriends()
        } catch {
            errorMessage = "Failed to load friends: \(error.localizedDescription)"
        }
    }
    
    func addFriend(displayName: String) {
        let friend = Friend(id: UUID().uuidString, displayName: displayName)
        friends.append(friend)
        saveFriends()
    }
    
    func removeFriend(_ friend: Friend) {
        friends.removeAll { $0.id == friend.id }
        saveFriends()
    }
    
    func blockFriend(_ friend: Friend) {
        if let index = friends.firstIndex(where: { $0.id == friend.id }) {
            friends[index].friendship = .blocked
            saveFriends()
        }
    }
    
    // MARK: - Score Comparison
    func updateFriendScore(_ friendId: String, score: FriendScore) {
        if let index = friends.firstIndex(where: { $0.id == friendId }) {
            friends[index].lastScore = score
            saveFriends()
            
            // Add activity
            let activity = FriendActivity(
                friend: friends[index],
                activityType: score.isPerfect ? .perfectScore : .completedPuzzle,
                timestamp: score.date,
                details: nil
            )
            friendActivities.insert(activity, at: 0)
            
            // Keep only last 50 activities
            if friendActivities.count > 50 {
                friendActivities = Array(friendActivities.prefix(50))
            }
        }
    }
    
    func compareTodaysScores(myScore: Int, myOptimal: Int) -> [(friend: Friend, comparison: ScoreComparison)] {
        return todaysFriendScores.map { item in
            let myPercentage = Double(myScore) / Double(myOptimal) * 100
            let theirPercentage = Double(item.score.percentage)
            
            let comparison: ScoreComparison
            if myPercentage > theirPercentage {
                comparison = .better(difference: Int(myPercentage - theirPercentage))
            } else if myPercentage < theirPercentage {
                comparison = .worse(difference: Int(theirPercentage - myPercentage))
            } else {
                comparison = .tied
            }
            
            return (item.friend, comparison)
        }
    }
    
    // MARK: - Challenges
    func sendChallenge(to friend: Friend, gameState: GameState) {
        let challenge = FriendChallenge(
            id: UUID().uuidString,
            fromPlayerId: "local",
            fromPlayerName: GKLocalPlayer.local.displayName,
            toPlayerId: friend.id,
            gridSize: gameState.gridSize,
            challengerScore: gameState.pathLength,
            challengerOptimal: gameState.optimalLength,
            dateString: gameState.dateString,
            createdAt: Date(),
            status: .pending
        )
        
        pendingChallenges.append(challenge)
        saveChallenges()
        
        // In a real app, this would send via CloudKit
        Task {
            await CloudKitService.shared.sendChallenge(challenge)
        }
    }
    
    func respondToChallenge(_ challenge: FriendChallenge, score: Int, optimal: Int) {
        if let index = pendingChallenges.firstIndex(where: { $0.id == challenge.id }) {
            pendingChallenges[index].status = .completed
            pendingChallenges[index].responderScore = score
            pendingChallenges[index].responderOptimal = optimal
            pendingChallenges[index].completedAt = Date()
            saveChallenges()
        }
    }
    
    func declineChallenge(_ challenge: FriendChallenge) {
        if let index = pendingChallenges.firstIndex(where: { $0.id == challenge.id }) {
            pendingChallenges[index].status = .declined
            saveChallenges()
        }
    }
    
    // MARK: - Persistence
    func saveFriends() {
        if let data = try? JSONEncoder().encode(friends) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
        
        // Sync to iCloud
        Task {
            await CloudKitService.shared.saveFriends(friends)
        }
    }
    
    func loadFriends() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([Friend].self, from: data) {
            friends = saved
        }
    }
    
    func saveChallenges() {
        if let data = try? JSONEncoder().encode(pendingChallenges) {
            UserDefaults.standard.set(data, forKey: challengesKey)
        }
    }
    
    func loadChallenges() {
        if let data = UserDefaults.standard.data(forKey: challengesKey),
           let saved = try? JSONDecoder().decode([FriendChallenge].self, from: data) {
            pendingChallenges = saved.filter { $0.status == .pending }
        }
    }
    
    // MARK: - Refresh
    func refresh() async {
        await loadGameCenterFriends()
        
        // Fetch friend scores from CloudKit
        await CloudKitService.shared.fetchFriendScores(for: friends.map { $0.id })
    }
}

// MARK: - Score Comparison
enum ScoreComparison {
    case better(difference: Int)
    case worse(difference: Int)
    case tied
    
    var description: String {
        switch self {
        case .better(let diff):
            return "+\(diff)%"
        case .worse(let diff):
            return "-\(diff)%"
        case .tied:
            return "Tied!"
        }
    }
    
    var color: Color {
        switch self {
        case .better: return .green
        case .worse: return .red
        case .tied: return .gray
        }
    }
}
