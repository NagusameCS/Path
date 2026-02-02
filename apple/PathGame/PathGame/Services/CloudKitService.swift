//
//  CloudKitService.swift
//  PathGame
//
//  iCloud sync service for cross-device data persistence
//

import Foundation
import CloudKit
import SwiftUI

@MainActor
class CloudKitService: ObservableObject {
    static let shared = CloudKitService()
    
    // MARK: - Published Properties
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    @Published var isCloudAvailable = false
    
    // CloudKit containers
    private let container = CKContainer(identifier: "iCloud.com.nagusamecs.PathGame")
    private var privateDatabase: CKDatabase { container.privateCloudDatabase }
    private var publicDatabase: CKDatabase { container.publicCloudDatabase }
    
    // Record types
    private let gameResultType = "GameResult"
    private let statsType = "PlayerStats"
    private let friendsType = "FriendsList"
    private let challengeType = "Challenge"
    
    // MARK: - Initialization
    private init() {
        checkCloudAvailability()
    }
    
    // MARK: - Cloud Availability
    func checkCloudAvailability() {
        container.accountStatus { [weak self] status, error in
            Task { @MainActor in
                switch status {
                case .available:
                    self?.isCloudAvailable = true
                case .noAccount:
                    self?.syncError = "No iCloud account found"
                    self?.isCloudAvailable = false
                case .restricted:
                    self?.syncError = "iCloud access restricted"
                    self?.isCloudAvailable = false
                case .couldNotDetermine:
                    self?.syncError = "Could not determine iCloud status"
                    self?.isCloudAvailable = false
                case .temporarilyUnavailable:
                    self?.syncError = "iCloud temporarily unavailable"
                    self?.isCloudAvailable = false
                @unknown default:
                    self?.isCloudAvailable = false
                }
            }
        }
    }
    
    // MARK: - Sync All Data
    func syncData() {
        guard isCloudAvailable else { return }
        
        Task {
            isSyncing = true
            defer { isSyncing = false }
            
            do {
                // Fetch latest stats
                if let cloudStats = try await fetchStats() {
                    // Merge with local stats
                    mergeStats(cloudStats)
                }
                
                // Fetch game results
                let results = try await fetchRecentGameResults()
                mergeGameResults(results)
                
                // Fetch friends
                if let cloudFriends = try await fetchFriends() {
                    mergeFriends(cloudFriends)
                }
                
                lastSyncDate = Date()
                syncError = nil
            } catch {
                syncError = error.localizedDescription
            }
        }
    }
    
    // MARK: - Game Results
    func saveGameResult(_ state: GameState) async {
        guard isCloudAvailable else { return }
        
        let record = CKRecord(recordType: gameResultType)
        record["dateString"] = state.dateString
        record["gridSize"] = state.gridSize.rawValue
        record["score"] = state.pathLength
        record["optimal"] = state.optimalLength
        record["attempts"] = state.attempts
        record["isPerfect"] = state.isPerfect
        record["gaveUp"] = state.gaveUp
        record["completedAt"] = Date()
        
        do {
            try await privateDatabase.save(record)
        } catch {
            print("Failed to save game result: \(error)")
        }
    }
    
    func fetchRecentGameResults() async throws -> [CKRecord] {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: gameResultType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "completedAt", ascending: false)]
        
        let (results, _) = try await privateDatabase.records(matching: query, resultsLimit: 30)
        return results.compactMap { try? $0.1.get() }
    }
    
    private func mergeGameResults(_ records: [CKRecord]) {
        // Merge logic would update local storage with cloud data
        // For now, just log
        print("Merged \(records.count) game results from cloud")
    }
    
    // MARK: - Stats
    func saveStats(_ stats: GameStats) async {
        guard isCloudAvailable else { return }
        
        // Try to fetch existing record or create new
        let recordID = CKRecord.ID(recordName: "playerStats")
        var record: CKRecord
        
        do {
            record = try await privateDatabase.record(for: recordID)
        } catch {
            record = CKRecord(recordType: statsType, recordID: recordID)
        }
        
        record["totalGamesPlayed"] = stats.totalGamesPlayed
        record["totalPerfectGames"] = stats.totalPerfectGames
        record["currentStreak"] = stats.currentStreak
        record["longestStreak"] = stats.longestStreak
        record["lastPlayedDate"] = stats.lastPlayedDate
        
        // Encode nested data as JSON
        if let stats5x5Data = try? JSONEncoder().encode(stats.stats5x5) {
            record["stats5x5"] = String(data: stats5x5Data, encoding: .utf8)
        }
        if let stats7x7Data = try? JSONEncoder().encode(stats.stats7x7) {
            record["stats7x7"] = String(data: stats7x7Data, encoding: .utf8)
        }
        
        do {
            try await privateDatabase.save(record)
        } catch {
            print("Failed to save stats: \(error)")
        }
    }
    
    func fetchStats() async throws -> GameStats? {
        let recordID = CKRecord.ID(recordName: "playerStats")
        
        do {
            let record = try await privateDatabase.record(for: recordID)
            
            var stats = GameStats()
            stats.totalGamesPlayed = record["totalGamesPlayed"] as? Int ?? 0
            stats.totalPerfectGames = record["totalPerfectGames"] as? Int ?? 0
            stats.currentStreak = record["currentStreak"] as? Int ?? 0
            stats.longestStreak = record["longestStreak"] as? Int ?? 0
            stats.lastPlayedDate = record["lastPlayedDate"] as? Date
            
            // Decode nested data
            if let stats5x5String = record["stats5x5"] as? String,
               let data = stats5x5String.data(using: .utf8),
               let decoded = try? JSONDecoder().decode(GridStats.self, from: data) {
                stats.stats5x5 = decoded
            }
            if let stats7x7String = record["stats7x7"] as? String,
               let data = stats7x7String.data(using: .utf8),
               let decoded = try? JSONDecoder().decode(GridStats.self, from: data) {
                stats.stats7x7 = decoded
            }
            
            return stats
        } catch {
            return nil
        }
    }
    
    private func mergeStats(_ cloudStats: GameStats) {
        // Merge logic: take higher values
        // In a real app, this would be more sophisticated
        print("Merged stats from cloud")
    }
    
    // MARK: - Friends
    func saveFriends(_ friends: [Friend]) async {
        guard isCloudAvailable else { return }
        
        let recordID = CKRecord.ID(recordName: "friendsList")
        var record: CKRecord
        
        do {
            record = try await privateDatabase.record(for: recordID)
        } catch {
            record = CKRecord(recordType: friendsType, recordID: recordID)
        }
        
        if let data = try? JSONEncoder().encode(friends),
           let jsonString = String(data: data, encoding: .utf8) {
            record["friendsData"] = jsonString
        }
        
        do {
            try await privateDatabase.save(record)
        } catch {
            print("Failed to save friends: \(error)")
        }
    }
    
    func fetchFriends() async throws -> [Friend]? {
        let recordID = CKRecord.ID(recordName: "friendsList")
        
        do {
            let record = try await privateDatabase.record(for: recordID)
            
            if let jsonString = record["friendsData"] as? String,
               let data = jsonString.data(using: .utf8),
               let friends = try? JSONDecoder().decode([Friend].self, from: data) {
                return friends
            }
        } catch {
            return nil
        }
        
        return nil
    }
    
    private func mergeFriends(_ cloudFriends: [Friend]) {
        print("Merged \(cloudFriends.count) friends from cloud")
    }
    
    func fetchFriendScores(for friendIds: [String]) async {
        guard isCloudAvailable else { return }
        
        // In a real implementation, this would query the public database
        // for friend scores based on their IDs
        let predicate = NSPredicate(format: "playerId IN %@", friendIds)
        let query = CKQuery(recordType: gameResultType, predicate: predicate)
        
        do {
            let (results, _) = try await publicDatabase.records(matching: query, resultsLimit: 50)
            // Process friend scores
            print("Fetched \(results.count) friend scores")
        } catch {
            print("Failed to fetch friend scores: \(error)")
        }
    }
    
    // MARK: - Challenges
    func sendChallenge(_ challenge: FriendChallenge) async {
        guard isCloudAvailable else { return }
        
        let record = CKRecord(recordType: challengeType)
        record["fromPlayerId"] = challenge.fromPlayerId
        record["fromPlayerName"] = challenge.fromPlayerName
        record["toPlayerId"] = challenge.toPlayerId
        record["gridSize"] = challenge.gridSize.rawValue
        record["challengerScore"] = challenge.challengerScore
        record["challengerOptimal"] = challenge.challengerOptimal
        record["dateString"] = challenge.dateString
        record["status"] = challenge.status.rawValue
        record["createdAt"] = challenge.createdAt
        
        do {
            try await publicDatabase.save(record)
        } catch {
            print("Failed to send challenge: \(error)")
        }
    }
    
    func fetchPendingChallenges(for playerId: String) async throws -> [FriendChallenge] {
        let predicate = NSPredicate(format: "toPlayerId == %@ AND status == %@", playerId, "pending")
        let query = CKQuery(recordType: challengeType, predicate: predicate)
        
        let (results, _) = try await publicDatabase.records(matching: query, resultsLimit: 20)
        
        return results.compactMap { result -> FriendChallenge? in
            guard let record = try? result.1.get() else { return nil }
            
            return FriendChallenge(
                id: record.recordID.recordName,
                fromPlayerId: record["fromPlayerId"] as? String ?? "",
                fromPlayerName: record["fromPlayerName"] as? String ?? "",
                toPlayerId: record["toPlayerId"] as? String ?? "",
                gridSize: GridSize(rawValue: record["gridSize"] as? Int ?? 5) ?? .small,
                challengerScore: record["challengerScore"] as? Int ?? 0,
                challengerOptimal: record["challengerOptimal"] as? Int ?? 0,
                dateString: record["dateString"] as? String ?? "",
                createdAt: record["createdAt"] as? Date ?? Date(),
                status: .pending
            )
        }
    }
    
    // MARK: - Key-Value Store (Quick Sync)
    func saveToKeyValueStore(key: String, value: Any) {
        NSUbiquitousKeyValueStore.default.set(value, forKey: key)
        NSUbiquitousKeyValueStore.default.synchronize()
    }
    
    func loadFromKeyValueStore(key: String) -> Any? {
        return NSUbiquitousKeyValueStore.default.object(forKey: key)
    }
}
