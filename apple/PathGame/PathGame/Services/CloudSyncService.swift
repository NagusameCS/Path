//
//  CloudSyncService.swift
//  Path
//
//  Syncs puzzle progress and game data with Firebase
//

import Foundation
import FirebaseFirestore

// MARK: - Puzzle Progress
struct PuzzleProgress: Codable, Identifiable {
    var id: String { "\(dateString)_\(gridSize)" }
    let dateString: String
    let gridSize: Int
    var grid: [[Int]]
    var path: [[Int]] // Array of [row, col]
    var currentPos: [Int] // [row, col]
    var gameOver: Bool
    var gaveUp: Bool
    var pathLength: Int
    var optimalLength: Int
    var attempts: Int
    var lastUpdated: Date
    var isPerfect: Bool
    
    init(from gameState: GameState) {
        self.dateString = gameState.dateString
        self.gridSize = gameState.size
        self.grid = gameState.grid
        self.path = gameState.path.map { [$0.row, $0.col] }
        self.currentPos = [gameState.currentPos.row, gameState.currentPos.col]
        self.gameOver = gameState.gameOver
        self.gaveUp = gameState.gaveUp
        self.pathLength = gameState.pathLength
        self.optimalLength = gameState.optimalLength
        self.attempts = gameState.attempts
        self.lastUpdated = Date()
        self.isPerfect = gameState.isPerfect
    }
    
    func toGameState() -> GameState {
        var state = GameState(gridSize: gridSize == 5 ? .small : .large)
        state.grid = grid
        state.path = path.map { Position(row: $0[0], col: $0[1]) }
        state.currentPos = Position(row: currentPos[0], col: currentPos[1])
        state.gameOver = gameOver
        state.gaveUp = gaveUp
        state.optimalLength = optimalLength
        state.attempts = attempts
        state.dateString = dateString
        return state
    }
}

// MARK: - Cloud Sync Service
class CloudSyncService: ObservableObject {
    static let shared = CloudSyncService()
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var errorMessage: String?
    
    private let db = FirebaseService.shared.db
    
    private init() {}
    
    // MARK: - Save Progress
    func saveProgress(gameState: GameState, userId: String) async {
        let progress = PuzzleProgress(from: gameState)
        
        do {
            try db.collection("users")
                .document(userId)
                .collection("puzzles")
                .document(progress.id)
                .setData(from: progress, merge: true)
            
            await MainActor.run {
                self.lastSyncDate = Date()
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    // MARK: - Load Progress
    func loadProgress(dateString: String, gridSize: Int, userId: String) async -> PuzzleProgress? {
        let id = "\(dateString)_\(gridSize)"
        
        do {
            let document = try await db.collection("users")
                .document(userId)
                .collection("puzzles")
                .document(id)
                .getDocument()
            
            if document.exists {
                return try document.data(as: PuzzleProgress.self)
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
        
        return nil
    }
    
    // MARK: - Load All Progress for Today
    func loadTodayProgress(userId: String) async -> [PuzzleProgress] {
        let today = getCurrentDateString()
        
        do {
            let snapshot = try await db.collection("users")
                .document(userId)
                .collection("puzzles")
                .whereField("dateString", isEqualTo: today)
                .getDocuments()
            
            return snapshot.documents.compactMap { doc in
                try? doc.data(as: PuzzleProgress.self)
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
        
        return []
    }
    
    // MARK: - Sync All Data
    func syncAllData(userId: String) async {
        await MainActor.run {
            self.isSyncing = true
        }
        
        // Load user's puzzle history
        do {
            let snapshot = try await db.collection("users")
                .document(userId)
                .collection("puzzles")
                .order(by: "lastUpdated", descending: true)
                .limit(to: 30) // Last 30 puzzles
                .getDocuments()
            
            let puzzles = snapshot.documents.compactMap { doc in
                try? doc.data(as: PuzzleProgress.self)
            }
            
            // Store locally for offline access
            savePuzzlesLocally(puzzles)
            
            await MainActor.run {
                self.lastSyncDate = Date()
                self.isSyncing = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isSyncing = false
            }
        }
    }
    
    // MARK: - Check Continuity
    func checkPuzzleContinuity(userId: String) async -> Bool {
        // Check if user has completed yesterday's puzzle
        let yesterday = getYesterdayDateString()
        
        do {
            let snapshot = try await db.collection("users")
                .document(userId)
                .collection("puzzles")
                .whereField("dateString", isEqualTo: yesterday)
                .whereField("gameOver", isEqualTo: true)
                .getDocuments()
            
            return !snapshot.documents.isEmpty
        } catch {
            return false
        }
    }
    
    // MARK: - Local Storage
    private func savePuzzlesLocally(_ puzzles: [PuzzleProgress]) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(puzzles) {
            UserDefaults.standard.set(data, forKey: "cachedPuzzles")
        }
    }
    
    func loadPuzzlesLocally() -> [PuzzleProgress] {
        guard let data = UserDefaults.standard.data(forKey: "cachedPuzzles"),
              let puzzles = try? JSONDecoder().decode([PuzzleProgress].self, from: data) else {
            return []
        }
        return puzzles
    }
    
    // MARK: - Helpers
    private func getCurrentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-M-d"
        return formatter.string(from: Date())
    }
    
    private func getYesterdayDateString() -> String {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-M-d"
        return formatter.string(from: yesterday)
    }
}
