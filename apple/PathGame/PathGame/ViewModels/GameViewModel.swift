//
//  GameViewModel.swift
//  PathGame
//
//  Main game logic and state management
//

import Foundation
import SwiftUI
import Combine

@MainActor
class GameViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var gameState: GameState
    @Published var isCalculatingOptimal = false
    @Published var showingGiveUpConfirmation = false
    @Published var showingUnlockModal = false
    @Published var showingArchiveModal = false
    @Published var showingShareSheet = false
    @Published var showConfetti = false
    @Published var toastMessage: String?
    
    // Archive
    @Published var archiveDate: Date?
    @Published var archivePuzzles: [ArchivePuzzle] = []
    
    // Settings
    @AppStorage("hapticFeedback") var hapticFeedback = true
    @AppStorage("soundEffects") var soundEffects = true
    
    // Services
    private let haptics = HapticsService.shared
    private let cloudKit = CloudKitService.shared
    
    // MARK: - Computed Properties
    var size: Int { gameState.size }
    var grid: [[Int]] { gameState.grid }
    var path: [Position] { gameState.path }
    var currentPos: Position { gameState.currentPos }
    var pathLength: Int { gameState.pathLength }
    var optimalLength: Int { gameState.optimalLength }
    var isGameOver: Bool { gameState.gameOver }
    var isPerfect: Bool { gameState.isPerfect }
    var gaveUp: Bool { gameState.gaveUp }
    var percentage: Int { gameState.percentage }
    var attempts: Int { gameState.attempts }
    
    var canUndo: Bool {
        guard path.count > 1, !isGameOver else { return false }
        
        if gameState.gridSize == .small {
            return gameState.consecutiveUndos < 1
        } else {
            let maxUndos = gameState.usedBonusUndo ? 1 : 2
            return gameState.consecutiveUndos < maxUndos
        }
    }
    
    var is7x7Unlocked: Bool {
        // Check if player has ever completed 5x5 with perfect score
        if let saved = load5x5CompletedState(), saved {
            return true
        }
        // Check if 7x7 state exists
        if loadGameState(for: .large, date: Date()) != nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: "is7x7Unlocked")
    }
    
    var statusMessage: String {
        if isGameOver {
            if gaveUp {
                return "Perfect path revealed: \(optimalLength) tiles"
            } else if isPerfect {
                return "\(gameState.tieredResponse) \(pathLength)/\(optimalLength)"
            } else if percentage >= 90 {
                return "\(gameState.tieredResponse) \(pathLength)/\(optimalLength) · \(percentage)%"
            } else {
                return "\(pathLength)/\(optimalLength) · \(percentage)%"
            }
        } else if path.count == 1 {
            return "Click an adjacent tile to begin your path"
        } else {
            return "Keep building your path..."
        }
    }
    
    var dateDisplayString: String {
        let date = archiveDate ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        let str = formatter.string(from: date).uppercased()
        return archiveDate != nil ? "📅 \(str)" : str
    }
    
    // MARK: - Initialization
    init() {
        self.gameState = GameState()
        loadTodaysGame()
    }
    
    // MARK: - Game Actions
    func startNewGame(gridSize: GridSize = .small) {
        gameState = GameState(gridSize: gridSize, date: archiveDate ?? Date())
        calculateOptimal()
        
        // Load saved state if exists
        if let saved = loadGameState(for: gridSize, date: archiveDate ?? Date()) {
            if saved.gameOver {
                gameState = saved
            }
        }
    }
    
    func loadTodaysGame() {
        archiveDate = nil
        let savedGridSize = UserDefaults.standard.integer(forKey: "currentGridSize")
        let gridSize: GridSize = savedGridSize == 7 ? .large : .small
        startNewGame(gridSize: gridSize)
    }
    
    func toggleGridSize() {
        if gameState.gridSize == .small && is7x7Unlocked {
            gameState = GameState(gridSize: .large, date: archiveDate ?? Date())
            UserDefaults.standard.set(7, forKey: "currentGridSize")
        } else {
            gameState = GameState(gridSize: .small, date: archiveDate ?? Date())
            UserDefaults.standard.set(5, forKey: "currentGridSize")
        }
        calculateOptimal()
        
        // Load saved state
        if let saved = loadGameState(for: gameState.gridSize, date: archiveDate ?? Date()) {
            if saved.gameOver {
                gameState = saved
            }
        }
    }
    
    func makeMove(to position: Position) {
        // Clicking current cell = undo
        if position == currentPos {
            undo()
            return
        }
        
        guard gameState.makeMove(to: position) else { return }
        
        if hapticFeedback {
            haptics.impact(.light)
        }
        
        // Check for game over
        if isGameOver {
            finishGame()
        }
        
        saveGameState()
    }
    
    func undo() {
        guard gameState.undo() else { return }
        
        if hapticFeedback {
            haptics.impact(.soft)
        }
        
        saveGameState()
    }
    
    func reset() {
        guard !gaveUp else { return }
        
        gameState.reset()
        
        if hapticFeedback {
            haptics.impact(.medium)
        }
        
        saveGameState()
    }
    
    func giveUp() {
        showingGiveUpConfirmation = false
        gameState.giveUp()
        
        if hapticFeedback {
            haptics.notification(.warning)
        }
        
        saveGameState()
    }
    
    func getValidMoves() -> [Position] {
        gameState.getValidMoves()
    }
    
    func isVisited(_ position: Position) -> Bool {
        path.contains(position)
    }
    
    func isCurrent(_ position: Position) -> Bool {
        position == currentPos
    }
    
    func isCenter(_ position: Position) -> Bool {
        let center = gameState.gridSize.n
        return position.row == center && position.col == center
    }
    
    func isValidMove(_ position: Position) -> Bool {
        gameState.isValidMove(to: position)
    }
    
    // MARK: - Game Completion
    private func finishGame() {
        // Check if better than calculated optimal
        if pathLength > optimalLength {
            gameState.optimalLength = pathLength
            gameState.optimalPath = path
        }
        
        if hapticFeedback {
            if isPerfect {
                haptics.notification(.success)
            } else {
                haptics.notification(.warning)
            }
        }
        
        if isPerfect {
            showConfetti = true
            
            // Unlock 7x7 if this was 5x5
            if gameState.gridSize == .small {
                save5x5CompletedState()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.showingUnlockModal = true
                }
            } else if archiveDate == nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.showingArchiveModal = true
                }
            }
        }
        
        saveGameState()
        
        // Report to Game Center
        Task {
            await GameCenterService.shared.reportScore(pathLength, gridSize: gameState.gridSize)
        }
        
        // Sync to iCloud
        Task {
            await cloudKit.saveGameResult(gameState)
        }
    }
    
    // MARK: - Optimal Path Calculation
    func calculateOptimal() {
        isCalculatingOptimal = true
        
        Task.detached(priority: .userInitiated) { [gameState] in
            let result = await self.findOptimalPath(state: gameState)
            
            await MainActor.run {
                self.gameState.optimalLength = result.length
                self.gameState.optimalPath = result.path
                self.isCalculatingOptimal = false
            }
        }
    }
    
    private func findOptimalPath(state: GameState) async -> (length: Int, path: [Position]) {
        let center = state.gridSize.n
        let size = state.size
        let grid = state.grid
        let totalCells = size * size
        
        let directions = [
            (-1, -1), (-1, 0), (-1, 1),
            (0, -1),          (0, 1),
            (1, -1),  (1, 0),  (1, 1)
        ]
        
        var visited = Array(repeating: Array(repeating: false, count: size), count: size)
        visited[center][center] = true
        
        var maxLength = 1
        var bestPath = [Position(row: center, col: center)]
        
        func dfs(row: Int, col: Int, currentPath: [Position]) {
            if currentPath.count > maxLength {
                maxLength = currentPath.count
                bestPath = currentPath
                
                if maxLength == totalCells {
                    return
                }
            }
            
            let currentVal = grid[row][col]
            var moves: [(Int, Int, Int)] = []
            
            for (dr, dc) in directions {
                let nr = row + dr
                let nc = col + dc
                
                guard nr >= 0, nr < size, nc >= 0, nc < size, !visited[nr][nc] else { continue }
                
                let nv = grid[nr][nc]
                guard abs(nv - currentVal) <= 1 else { continue }
                
                var futureCount = 0
                for (dr2, dc2) in directions {
                    let nr2 = nr + dr2
                    let nc2 = nc + dc2
                    if nr2 >= 0, nr2 < size, nc2 >= 0, nc2 < size, !visited[nr2][nc2] {
                        if abs(grid[nr2][nc2] - nv) <= 1 {
                            futureCount += 1
                        }
                    }
                }
                moves.append((nr, nc, futureCount))
            }
            
            moves.sort { $0.2 < $1.2 }
            
            for (nr, nc, _) in moves {
                let remaining = totalCells - currentPath.count
                guard currentPath.count + remaining > maxLength else { continue }
                
                visited[nr][nc] = true
                dfs(row: nr, col: nc, currentPath: currentPath + [Position(row: nr, col: nc)])
                visited[nr][nc] = false
                
                if maxLength == totalCells {
                    return
                }
            }
        }
        
        dfs(row: center, col: center, currentPath: [Position(row: center, col: center)])
        
        return (maxLength, bestPath)
    }
    
    // MARK: - Persistence
    private func storageKey(for gridSize: GridSize, date: Date) -> String {
        let dateStr = GameState.dateToString(date)
        return "game-\(dateStr)-\(gridSize.rawValue)"
    }
    
    func saveGameState() {
        let key = storageKey(for: gameState.gridSize, date: archiveDate ?? Date())
        if let data = try? JSONEncoder().encode(gameState) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    func loadGameState(for gridSize: GridSize, date: Date) -> GameState? {
        let key = storageKey(for: gridSize, date: date)
        guard let data = UserDefaults.standard.data(forKey: key),
              let state = try? JSONDecoder().decode(GameState.self, from: data) else {
            return nil
        }
        return state
    }
    
    private func save5x5CompletedState() {
        UserDefaults.standard.set(true, forKey: "is7x7Unlocked")
        let dateStr = GameState.dateToString(Date())
        UserDefaults.standard.set(true, forKey: "5x5-completed-\(dateStr)")
    }
    
    private func load5x5CompletedState() -> Bool? {
        let dateStr = GameState.dateToString(Date())
        if UserDefaults.standard.bool(forKey: "5x5-completed-\(dateStr)") {
            return true
        }
        return UserDefaults.standard.bool(forKey: "is7x7Unlocked")
    }
    
    // MARK: - Archive
    func loadArchive() {
        archivePuzzles = []
        let today = Date()
        
        for i in 1...7 {
            let date = Calendar.current.date(byAdding: .day, value: -i, to: today)!
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEE, MMM d"
            
            let completed5x5 = loadGameState(for: .small, date: date)
            let completed7x7 = loadGameState(for: .large, date: date)
            
            var status: ArchivePuzzle.Status = .new
            if let state = completed7x7, state.gameOver {
                status = .completed7x7
            } else if let state = completed5x5, state.gameOver {
                status = .completed5x5
            } else if completed5x5 != nil || completed7x7 != nil {
                status = .inProgress
            }
            
            archivePuzzles.append(ArchivePuzzle(
                date: date,
                displayDate: dateFormatter.string(from: date),
                status: status
            ))
        }
    }
    
    func loadArchivePuzzle(_ puzzle: ArchivePuzzle) {
        archiveDate = puzzle.date
        showingArchiveModal = false
        startNewGame(gridSize: .small)
    }
    
    // MARK: - Sharing
    func generateShareText() -> String {
        let date = archiveDate ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        let dateStr = formatter.string(from: date)
        
        let gridType = gameState.gridSize.displayName
        let totalCells = gameState.gridSize.totalCells
        
        var lines: [String] = []
        
        if isPerfect {
            lines.append("🧩 Path \(gridType) 🏆")
        } else {
            lines.append("🧩 Path \(gridType)")
        }
        
        lines.append("📅 \(dateStr)")
        lines.append("")
        
        if isPerfect {
            lines.append("✨ Perfect: \(pathLength)/\(totalCells)")
        } else {
            lines.append("📊 Score: \(pathLength)/\(totalCells) (\(percentage)%)")
        }
        
        if attempts == 1 {
            lines.append("🎯 First try!")
        } else {
            lines.append("🔄 Attempts: \(attempts)")
        }
        
        // Add emoji grid visualization
        lines.append("")
        lines.append(generateEmojiGrid())
        
        lines.append("")
        lines.append("https://nagusamecs.github.io/Path/")
        
        return lines.joined(separator: "\n")
    }
    
    /// Generates an emoji grid showing the path
    private func generateEmojiGrid() -> String {
        let size = gameState.size
        var gridLines: [String] = []
        
        for row in 0..<size {
            var rowEmojis: [String] = []
            for col in 0..<size {
                let pos = Position(row: row, col: col)
                
                if path.contains(pos) {
                    // Part of the path
                    if pos == path.first {
                        rowEmojis.append("🟢")  // Start
                    } else if pos == path.last {
                        rowEmojis.append("🏁")  // End
                    } else {
                        rowEmojis.append("🟦")  // Path
                    }
                } else {
                    // Not visited
                    rowEmojis.append("⬜")
                }
            }
            gridLines.append(rowEmojis.joined())
        }
        
        return gridLines.joined(separator: "\n")
    }
    
    func showToast(_ message: String) {
        toastMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.toastMessage = nil
        }
    }
}

// MARK: - Archive Puzzle
struct ArchivePuzzle: Identifiable {
    let id = UUID()
    let date: Date
    let displayDate: String
    let status: Status
    
    enum Status: String {
        case new = "⚪ New"
        case inProgress = "🟡 In Progress"
        case completed5x5 = "✅ 5×5"
        case completed7x7 = "✅ 7×7"
    }
}
