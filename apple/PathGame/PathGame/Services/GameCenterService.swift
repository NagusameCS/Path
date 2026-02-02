//
//  GameCenterService.swift
//  PathGame
//
//  Game Center integration for leaderboards and achievements
//

import Foundation
import GameKit
import SwiftUI

@MainActor
class GameCenterService: ObservableObject {
    static let shared = GameCenterService()
    
    // MARK: - Published Properties
    @Published var isAuthenticated = false
    @Published var localPlayer: GKLocalPlayer?
    @Published var errorMessage: String?
    @Published var showingGameCenter = false
    
    // Leaderboard IDs
    private let leaderboard5x5 = "com.nagusamecs.pathgame.leaderboard.5x5"
    private let leaderboard7x7 = "com.nagusamecs.pathgame.leaderboard.7x7"
    private let leaderboardStreak = "com.nagusamecs.pathgame.leaderboard.streak"
    private let leaderboardPerfects = "com.nagusamecs.pathgame.leaderboard.perfects"
    
    // Achievement IDs (map to Game Center)
    private let achievementMapping: [String: String] = [
        "first_game": "com.nagusamecs.pathgame.achievement.first_game",
        "first_perfect": "com.nagusamecs.pathgame.achievement.first_perfect",
        "unlock_7x7": "com.nagusamecs.pathgame.achievement.unlock_7x7",
        "streak_7": "com.nagusamecs.pathgame.achievement.streak_7",
        "streak_30": "com.nagusamecs.pathgame.achievement.streak_30",
        "perfect_25": "com.nagusamecs.pathgame.achievement.perfect_25",
        "perfect_100": "com.nagusamecs.pathgame.achievement.perfect_100"
    ]
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Authentication
    func authenticatePlayer() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            Task { @MainActor in
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    self?.isAuthenticated = false
                    return
                }
                
                if viewController != nil {
                    // Present the authentication view controller
                    // In SwiftUI, we'd typically show a sheet or alert
                    self?.isAuthenticated = false
                } else if GKLocalPlayer.local.isAuthenticated {
                    self?.isAuthenticated = true
                    self?.localPlayer = GKLocalPlayer.local
                    self?.errorMessage = nil
                    
                    // Register for Game Center notifications
                    GKLocalPlayer.local.register(self!)
                }
            }
        }
    }
    
    // MARK: - Leaderboards
    func reportScore(_ score: Int, gridSize: GridSize) async {
        guard isAuthenticated else { return }
        
        let leaderboardID = gridSize == .small ? leaderboard5x5 : leaderboard7x7
        
        do {
            try await GKLeaderboard.submitScore(
                score,
                context: 0,
                player: GKLocalPlayer.local,
                leaderboardIDs: [leaderboardID]
            )
        } catch {
            print("Failed to report score: \(error)")
        }
    }
    
    func reportStreak(_ streak: Int) async {
        guard isAuthenticated else { return }
        
        do {
            try await GKLeaderboard.submitScore(
                streak,
                context: 0,
                player: GKLocalPlayer.local,
                leaderboardIDs: [leaderboardStreak]
            )
        } catch {
            print("Failed to report streak: \(error)")
        }
    }
    
    func reportPerfectCount(_ count: Int) async {
        guard isAuthenticated else { return }
        
        do {
            try await GKLeaderboard.submitScore(
                count,
                context: 0,
                player: GKLocalPlayer.local,
                leaderboardIDs: [leaderboardPerfects]
            )
        } catch {
            print("Failed to report perfect count: \(error)")
        }
    }
    
    func loadLeaderboard(gridSize: GridSize) async -> [(rank: Int, player: String, score: Int)] {
        guard isAuthenticated else { return [] }
        
        let leaderboardID = gridSize == .small ? leaderboard5x5 : leaderboard7x7
        
        do {
            let leaderboards = try await GKLeaderboard.loadLeaderboards(IDs: [leaderboardID])
            guard let leaderboard = leaderboards.first else { return [] }
            
            let (_, entries, _) = try await leaderboard.loadEntries(for: .global, timeScope: .today, range: 1...10)
            
            return entries.map { entry in
                (entry.rank, entry.player.displayName, entry.score)
            }
        } catch {
            print("Failed to load leaderboard: \(error)")
            return []
        }
    }
    
    func loadFriendsLeaderboard(gridSize: GridSize) async -> [(rank: Int, player: String, score: Int)] {
        guard isAuthenticated else { return [] }
        
        let leaderboardID = gridSize == .small ? leaderboard5x5 : leaderboard7x7
        
        do {
            let leaderboards = try await GKLeaderboard.loadLeaderboards(IDs: [leaderboardID])
            guard let leaderboard = leaderboards.first else { return [] }
            
            let (_, entries, _) = try await leaderboard.loadEntries(for: .friends, timeScope: .today, range: 1...25)
            
            return entries.map { entry in
                (entry.rank, entry.player.displayName, entry.score)
            }
        } catch {
            print("Failed to load friends leaderboard: \(error)")
            return []
        }
    }
    
    // MARK: - Achievements
    func reportAchievement(_ achievementId: String, percentComplete: Double = 100.0) async {
        guard isAuthenticated else { return }
        guard let gcAchievementId = achievementMapping[achievementId] else { return }
        
        let achievement = GKAchievement(identifier: gcAchievementId)
        achievement.percentComplete = percentComplete
        achievement.showsCompletionBanner = true
        
        do {
            try await GKAchievement.report([achievement])
        } catch {
            print("Failed to report achievement: \(error)")
        }
    }
    
    func loadAchievements() async -> [GKAchievement] {
        guard isAuthenticated else { return [] }
        
        do {
            return try await GKAchievement.loadAchievements()
        } catch {
            print("Failed to load achievements: \(error)")
            return []
        }
    }
    
    // MARK: - Game Center UI
    func showGameCenterDashboard() {
        #if os(iOS)
        let viewController = GKGameCenterViewController(state: .dashboard)
        viewController.gameCenterDelegate = GameCenterDelegateHandler.shared
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(viewController, animated: true)
        }
        #elseif os(macOS)
        GKDialogController.shared().parentWindow = NSApplication.shared.mainWindow
        let viewController = GKGameCenterViewController(state: .dashboard)
        viewController.gameCenterDelegate = GameCenterDelegateHandler.shared
        GKDialogController.shared().present(viewController)
        #endif
    }
    
    func showLeaderboard(for gridSize: GridSize) {
        let leaderboardID = gridSize == .small ? leaderboard5x5 : leaderboard7x7
        
        #if os(iOS)
        let viewController = GKGameCenterViewController(leaderboardID: leaderboardID, playerScope: .global, timeScope: .today)
        viewController.gameCenterDelegate = GameCenterDelegateHandler.shared
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(viewController, animated: true)
        }
        #elseif os(macOS)
        GKDialogController.shared().parentWindow = NSApplication.shared.mainWindow
        let viewController = GKGameCenterViewController(leaderboardID: leaderboardID, playerScope: .global, timeScope: .today)
        viewController.gameCenterDelegate = GameCenterDelegateHandler.shared
        GKDialogController.shared().present(viewController)
        #endif
    }
    
    func showAchievements() {
        #if os(iOS)
        let viewController = GKGameCenterViewController(state: .achievements)
        viewController.gameCenterDelegate = GameCenterDelegateHandler.shared
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(viewController, animated: true)
        }
        #elseif os(macOS)
        GKDialogController.shared().parentWindow = NSApplication.shared.mainWindow
        let viewController = GKGameCenterViewController(state: .achievements)
        viewController.gameCenterDelegate = GameCenterDelegateHandler.shared
        GKDialogController.shared().present(viewController)
        #endif
    }
}

// MARK: - GKLocalPlayerListener
extension GameCenterService: GKLocalPlayerListener {
    nonisolated func player(_ player: GKPlayer, didAccept invite: GKInvite) {
        // Handle game invites
    }
    
    nonisolated func player(_ player: GKPlayer, didRequestMatchWithRecipients recipientPlayers: [GKPlayer]) {
        // Handle match requests
    }
}

// MARK: - Delegate Handler
class GameCenterDelegateHandler: NSObject, GKGameCenterControllerDelegate {
    static let shared = GameCenterDelegateHandler()
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        #if os(iOS)
        gameCenterViewController.dismiss(animated: true)
        #elseif os(macOS)
        GKDialogController.shared().dismiss(gameCenterViewController)
        #endif
    }
}
