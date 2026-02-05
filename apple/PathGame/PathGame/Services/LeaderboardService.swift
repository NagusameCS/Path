//
//  LeaderboardService.swift
//  Path
//
//  Global and regional leaderboards using Firebase
//

import Foundation
import FirebaseFirestore
import FirebaseDatabase

// MARK: - Leaderboard Entry
struct LeaderboardEntry: Codable, Identifiable {
    var id: String { oderId }
    let oderId: String
    let displayName: String
    let countryCode: String
    let region: LeaderboardRegion
    let score: Int
    let pathLength: Int
    let gridSize: Int
    let isPerfect: Bool
    let date: Date
    let dateString: String
    
    init(userId: String, displayName: String, countryCode: String, score: Int, pathLength: Int, gridSize: Int, isPerfect: Bool, dateString: String) {
        self.oderId = userId
        self.displayName = displayName
        self.countryCode = countryCode
        self.region = LeaderboardRegion.region(for: countryCode)
        self.score = score
        self.pathLength = pathLength
        self.gridSize = gridSize
        self.isPerfect = isPerfect
        self.date = Date()
        self.dateString = dateString
    }
}

// MARK: - Leaderboard Stats
struct LeaderboardStats: Codable, Identifiable {
    var id: String { oderId }
    let oderId: String
    let displayName: String
    let countryCode: String
    let region: LeaderboardRegion
    var totalScore: Int
    var gamesPlayed: Int
    var perfectGames: Int
    var currentStreak: Int
    var longestStreak: Int
    var averageScore: Double
    var rank: Int?
    
    init(userId: String, displayName: String, countryCode: String) {
        self.oderId = userId
        self.displayName = displayName
        self.countryCode = countryCode
        self.region = LeaderboardRegion.region(for: countryCode)
        self.totalScore = 0
        self.gamesPlayed = 0
        self.perfectGames = 0
        self.currentStreak = 0
        self.longestStreak = 0
        self.averageScore = 0
        self.rank = nil
    }
}

// MARK: - Leaderboard Type
enum LeaderboardType: String, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case allTime = "allTime"
    case streak = "streak"
    
    var displayName: String {
        switch self {
        case .daily: return "Today"
        case .weekly: return "This Week"
        case .allTime: return "All Time"
        case .streak: return "Streaks"
        }
    }
}

// MARK: - Leaderboard Service
class LeaderboardService: ObservableObject {
    static let shared = LeaderboardService()
    
    @Published var dailyLeaderboard: [LeaderboardEntry] = []
    @Published var weeklyLeaderboard: [LeaderboardStats] = []
    @Published var allTimeLeaderboard: [LeaderboardStats] = []
    @Published var streakLeaderboard: [LeaderboardStats] = []
    
    @Published var currentRegion: LeaderboardRegion = .global
    @Published var currentType: LeaderboardType = .daily
    @Published var userRank: Int?
    @Published var isLoading = false
    
    private let db = FirebaseService.shared.db
    private let realtimeDB = FirebaseService.shared.realtimeDB
    
    private init() {}
    
    // MARK: - Submit Score
    func submitScore(userId: String, displayName: String, countryCode: String, pathLength: Int, optimalLength: Int, gridSize: Int, dateString: String) async {
        let score = calculateScore(pathLength: pathLength, optimalLength: optimalLength, gridSize: gridSize)
        let isPerfect = pathLength == optimalLength
        
        let entry = LeaderboardEntry(
            userId: userId,
            displayName: displayName,
            countryCode: countryCode,
            score: score,
            pathLength: pathLength,
            gridSize: gridSize,
            isPerfect: isPerfect,
            dateString: dateString
        )
        
        // Submit to daily leaderboard
        await submitToDailyLeaderboard(entry: entry)
        
        // Update user stats for weekly/all-time
        await updateUserStats(userId: userId, score: score, isPerfect: isPerfect)
    }
    
    // MARK: - Calculate Score
    private func calculateScore(pathLength: Int, optimalLength: Int, gridSize: Int) -> Int {
        // Score = (pathLength / optimalLength) * 100 * gridSizeMultiplier
        let percentage = Double(pathLength) / Double(optimalLength)
        let multiplier = gridSize == 5 ? 1.0 : 1.5 // 7x7 worth more
        return Int(percentage * 100 * multiplier)
    }
    
    // MARK: - Submit to Daily Leaderboard
    private func submitToDailyLeaderboard(entry: LeaderboardEntry) async {
        do {
            // Global daily
            try db.collection("leaderboards")
                .document("daily")
                .collection(entry.dateString)
                .document(entry.oderId)
                .setData(from: entry, merge: true)
            
            // Regional daily
            try db.collection("leaderboards")
                .document("daily_\(entry.region.rawValue)")
                .collection(entry.dateString)
                .document(entry.oderId)
                .setData(from: entry, merge: true)
            
            // Update realtime for live updates
            let realtimeData: [String: Any] = [
                "displayName": entry.displayName,
                "score": entry.score,
                "pathLength": entry.pathLength,
                "isPerfect": entry.isPerfect,
                "countryCode": entry.countryCode
            ]
            
            try await realtimeDB.child("daily").child(entry.dateString).child(entry.oderId).setValue(realtimeData)
            
        } catch {
            // Leaderboard submission failed
        }
    }
    
    // MARK: - Update User Stats
    private func updateUserStats(userId: String, score: Int, isPerfect: Bool) async {
        do {
            try await db.collection("userStats").document(userId).updateData([
                "totalScore": FieldValue.increment(Int64(score)),
                "gamesPlayed": FieldValue.increment(Int64(1)),
                "perfectGames": FieldValue.increment(Int64(isPerfect ? 1 : 0)),
                "lastUpdated": FieldValue.serverTimestamp()
            ])
        } catch {
            // Document might not exist, create it
            let document = try? await db.collection("userStats").document(userId).getDocument()
            if document?.exists != true {
                let user = AuthService.shared.currentUser
                let stats = LeaderboardStats(
                    userId: userId,
                    displayName: user?.displayName ?? "Player",
                    countryCode: user?.countryCode ?? "US"
                )
                try? db.collection("userStats").document(userId).setData(from: stats)
            }
        }
    }
    
    // MARK: - Load Leaderboard
    func loadLeaderboard(type: LeaderboardType, region: LeaderboardRegion) async {
        await MainActor.run {
            self.isLoading = true
            self.currentType = type
            self.currentRegion = region
        }
        
        switch type {
        case .daily:
            await loadDailyLeaderboard(region: region)
        case .weekly:
            await loadWeeklyLeaderboard(region: region)
        case .allTime:
            await loadAllTimeLeaderboard(region: region)
        case .streak:
            await loadStreakLeaderboard(region: region)
        }
        
        await MainActor.run {
            self.isLoading = false
        }
    }
    
    // MARK: - Load Daily Leaderboard
    private func loadDailyLeaderboard(region: LeaderboardRegion) async {
        let dateString = getCurrentDateString()
        let collectionPath = region == .global ? "daily" : "daily_\(region.rawValue)"
        
        do {
            let snapshot = try await db.collection("leaderboards")
                .document(collectionPath)
                .collection(dateString)
                .order(by: "score", descending: true)
                .limit(to: 100)
                .getDocuments()
            
            let entries = snapshot.documents.compactMap { doc -> LeaderboardEntry? in
                try? doc.data(as: LeaderboardEntry.self)
            }
            
            await MainActor.run {
                self.dailyLeaderboard = entries
                self.findUserRank(in: entries)
            }
        } catch {
            // Daily leaderboard load failed
        }
    }
    
    // MARK: - Load Weekly Leaderboard
    private func loadWeeklyLeaderboard(region: LeaderboardRegion) async {
        // Note: weekStart could be used to filter by date range in a more complete implementation
        _ = getWeekStartDate()
        
        var query = db.collection("userStats")
            .order(by: "totalScore", descending: true)
            .limit(to: 100)
        
        if region != .global {
            query = db.collection("userStats")
                .whereField("region", isEqualTo: region.rawValue)
                .order(by: "totalScore", descending: true)
                .limit(to: 100)
        }
        
        do {
            let snapshot = try await query.getDocuments()
            
            let stats = snapshot.documents.compactMap { doc -> LeaderboardStats? in
                try? doc.data(as: LeaderboardStats.self)
            }
            
            await MainActor.run {
                self.weeklyLeaderboard = stats
            }
        } catch {
            // Weekly leaderboard load failed
        }
    }
    
    // MARK: - Load All Time Leaderboard
    private func loadAllTimeLeaderboard(region: LeaderboardRegion) async {
        var query = db.collection("userStats")
            .order(by: "totalScore", descending: true)
            .limit(to: 100)
        
        if region != .global {
            query = db.collection("userStats")
                .whereField("region", isEqualTo: region.rawValue)
                .order(by: "totalScore", descending: true)
                .limit(to: 100)
        }
        
        do {
            let snapshot = try await query.getDocuments()
            
            var stats = snapshot.documents.compactMap { doc -> LeaderboardStats? in
                try? doc.data(as: LeaderboardStats.self)
            }
            
            // Add ranks
            for i in 0..<stats.count {
                stats[i].rank = i + 1
            }
            
            let finalStats = stats
            await MainActor.run {
                self.allTimeLeaderboard = finalStats
            }
        } catch {
            // All time leaderboard load failed
        }
    }
    
    // MARK: - Load Streak Leaderboard
    private func loadStreakLeaderboard(region: LeaderboardRegion) async {
        var query = db.collection("userStats")
            .order(by: "longestStreak", descending: true)
            .limit(to: 100)
        
        if region != .global {
            query = db.collection("userStats")
                .whereField("region", isEqualTo: region.rawValue)
                .order(by: "longestStreak", descending: true)
                .limit(to: 100)
        }
        
        do {
            let snapshot = try await query.getDocuments()
            
            var stats = snapshot.documents.compactMap { doc -> LeaderboardStats? in
                try? doc.data(as: LeaderboardStats.self)
            }
            
            for i in 0..<stats.count {
                stats[i].rank = i + 1
            }
            
            let finalStats = stats
            await MainActor.run {
                self.streakLeaderboard = finalStats
            }
        } catch {
            // Streak leaderboard load failed
        }
    }
    
    // MARK: - Find User Rank
    private func findUserRank(in entries: [LeaderboardEntry]) {
        guard let userId = AuthService.shared.currentUser?.id else { return }
        
        if let index = entries.firstIndex(where: { $0.oderId == userId }) {
            userRank = index + 1
        } else {
            userRank = nil
        }
    }
    
    // MARK: - Helpers
    private func getCurrentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-M-d"
        return formatter.string(from: Date())
    }
    
    private func getWeekStartDate() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        return calendar.date(from: components) ?? Date()
    }
    
    // MARK: - Listen for Live Updates
    func startListeningForUpdates(dateString: String) {
        realtimeDB.child("daily").child(dateString).observe(.value) { [weak self] snapshot in
            guard let _ = self else { return }
            guard let data = snapshot.value as? [String: [String: Any]] else { return }
            
            // Parse and update daily leaderboard
            // This could be expanded to create LeaderboardEntry objects
            for (_, userData) in data {
                // Process user data for real-time updates
                _ = userData["displayName"] as? String
                _ = userData["score"] as? Int
                _ = userData["pathLength"] as? Int
                _ = userData["isPerfect"] as? Bool
                _ = userData["countryCode"] as? String
            }
        }
    }
    
    func stopListeningForUpdates() {
        let dateString = getCurrentDateString()
        realtimeDB.child("daily").child(dateString).removeAllObservers()
    }
    
    // MARK: - Populate Sample Data (for development/testing)
    func populateSampleLeaderboard() async {
        let dateString = getCurrentDateString()
        
        let sampleNames = [
            "PathMaster", "GridWalker", "PuzzlePro", "TileChamp", "MazeRunner",
            "PathFinder", "GridGuru", "PuzzleKing", "CellStar", "RouteWiz",
            "TrailBlazer", "SquareAce", "BoardBoss", "WalkMaster", "PathSeeker",
            "GridHero", "TileWizard", "PuzzleStar", "MazeKing", "CellPro",
            "RouteKing", "TrailPro", "SquareStar", "BoardAce", "WalkHero",
            "PathAce", "GridStar", "TileHero", "PuzzleAce", "MazeStar",
            "CellChamp", "RouteHero", "TrailStar", "SquarePro", "BoardStar",
            "WalkAce", "PathPro", "GridAce", "TileAce", "PuzzleHero",
            "MazePro", "CellAce", "RouteStar", "TrailAce", "SquareHero",
            "BoardPro", "WalkStar", "PathStar", "GridPro", "TileKing"
        ]
        
        let countryCodes = ["US", "GB", "CA", "AU", "DE", "FR", "JP", "KR", "BR", "MX"]
        
        for i in 0..<100 {
            let nameIndex = i % sampleNames.count
            let userId = "sample_user_\(i)"
            let displayName = "\(sampleNames[nameIndex])\(i > 49 ? "\(i - 49)" : "")"
            let countryCode = countryCodes[i % countryCodes.count]
            
            // Generate realistic scores
            let isPerfect = i < 15 // Top 15 get perfect scores
            let optimalLength = 25
            let pathLength = isPerfect ? optimalLength : max(18, optimalLength - (i / 5))
            let score = calculateScore(pathLength: pathLength, optimalLength: optimalLength, gridSize: 7)
            
            // Create daily leaderboard entry
            let entry = LeaderboardEntry(
                userId: userId,
                displayName: displayName,
                countryCode: countryCode,
                score: score,
                pathLength: pathLength,
                gridSize: 7,
                isPerfect: isPerfect,
                dateString: dateString
            )
            
            do {
                try db.collection("leaderboards")
                    .document("daily")
                    .collection(dateString)
                    .document(userId)
                    .setData(from: entry, merge: true)
            } catch {
                // Sample data upload failed
            }
            
            // Create user stats entry for streak/all-time leaderboards
            let longestStreak = max(1, 100 - i + Int.random(in: 0...10)) // Top players have longer streaks
            let currentStreak = min(longestStreak, Int.random(in: 1...max(1, longestStreak)))
            let gamesPlayed = 50 + Int.random(in: 0...200)
            let perfectGames = Int(Double(gamesPlayed) * Double.random(in: 0.3...0.9))
            let totalScore = gamesPlayed * Int.random(in: 80...150)
            
            var stats = LeaderboardStats(
                userId: userId,
                displayName: displayName,
                countryCode: countryCode
            )
            stats.longestStreak = longestStreak
            stats.currentStreak = currentStreak
            stats.gamesPlayed = gamesPlayed
            stats.perfectGames = perfectGames
            stats.totalScore = totalScore
            stats.averageScore = Double(totalScore) / Double(gamesPlayed)
            
            do {
                try db.collection("userStats")
                    .document(userId)
                    .setData(from: stats, merge: true)
            } catch {
                // User stats upload failed
            }
        }
    }
}
