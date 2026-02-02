//
//  GameState.swift
//  PathGame
//
//  Core game state model with Codable support for persistence
//

import Foundation

// MARK: - Position
struct Position: Codable, Equatable, Hashable {
    let row: Int
    let col: Int
    
    static func == (lhs: Position, rhs: Position) -> Bool {
        lhs.row == rhs.row && lhs.col == rhs.col
    }
}

// MARK: - Grid Size
enum GridSize: Int, Codable, CaseIterable {
    case small = 5
    case large = 7
    
    var n: Int {
        switch self {
        case .small: return 2
        case .large: return 3
        }
    }
    
    var displayName: String {
        "\(rawValue)×\(rawValue)"
    }
    
    var totalCells: Int {
        rawValue * rawValue
    }
}

// MARK: - Game State
struct GameState: Codable {
    var grid: [[Int]]
    var path: [Position]
    var currentPos: Position
    var gridSize: GridSize
    var gameOver: Bool
    var gaveUp: Bool
    var optimalLength: Int
    var optimalPath: [Position]
    var attempts: Int
    var dateString: String
    var consecutiveUndos: Int
    var usedBonusUndo: Bool
    
    var size: Int { gridSize.rawValue }
    var pathLength: Int { path.count }
    var isPerfect: Bool { pathLength == optimalLength && !gaveUp }
    
    // MARK: - Initialization
    init(gridSize: GridSize = .small, date: Date = Date()) {
        self.gridSize = gridSize
        self.grid = []
        self.path = []
        self.gameOver = false
        self.gaveUp = false
        self.optimalLength = 1
        self.optimalPath = []
        self.attempts = 1
        self.dateString = Self.dateToString(date)
        self.consecutiveUndos = 0
        self.usedBonusUndo = false
        
        // Generate grid
        let seed = Self.getDateSeed(from: date) + gridSize.n * 1000
        var rng = SeededRandom(seed: seed)
        
        let size = gridSize.rawValue
        for _ in 0..<size {
            var row: [Int] = []
            for _ in 0..<size {
                row.append(rng.nextInt(min: 1, max: 5))
            }
            self.grid.append(row)
        }
        
        // Start from center
        let center = gridSize.n
        self.currentPos = Position(row: center, col: center)
        self.path = [currentPos]
    }
    
    // MARK: - Date Helpers
    static func dateToString(_ date: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(components.year!)-\(components.month!)-\(components.day!)"
    }
    
    static func getDateSeed(from date: Date) -> Int {
        let dateStr = dateToString(date)
        var hash = 0
        for char in dateStr.unicodeScalars {
            let charValue = Int(char.value)
            hash = ((hash << 5) &- hash) &+ charValue
        }
        return abs(hash)
    }
    
    // MARK: - Move Validation
    func isValidMove(to position: Position) -> Bool {
        guard !gameOver else { return false }
        guard position.row >= 0, position.row < size,
              position.col >= 0, position.col < size else { return false }
        
        // Check if already visited
        guard !path.contains(position) else { return false }
        
        // Check if adjacent
        let dr = abs(position.row - currentPos.row)
        let dc = abs(position.col - currentPos.col)
        guard dr <= 1, dc <= 1, !(dr == 0 && dc == 0) else { return false }
        
        // Check value constraint
        let currentVal = grid[currentPos.row][currentPos.col]
        let targetVal = grid[position.row][position.col]
        guard abs(targetVal - currentVal) <= 1 else { return false }
        
        return true
    }
    
    func getValidMoves() -> [Position] {
        let directions = [
            (-1, -1), (-1, 0), (-1, 1),
            (0, -1),          (0, 1),
            (1, -1),  (1, 0),  (1, 1)
        ]
        
        return directions.compactMap { dr, dc in
            let pos = Position(row: currentPos.row + dr, col: currentPos.col + dc)
            return isValidMove(to: pos) ? pos : nil
        }
    }
    
    // MARK: - Move Execution
    mutating func makeMove(to position: Position) -> Bool {
        guard isValidMove(to: position) else { return false }
        
        consecutiveUndos = 0
        currentPos = position
        path.append(position)
        
        // Check if no more valid moves
        if getValidMoves().isEmpty {
            gameOver = true
        }
        
        return true
    }
    
    mutating func undo() -> Bool {
        guard path.count > 1, !gameOver else { return false }
        
        // Check undo limits
        if gridSize == .small {
            guard consecutiveUndos < 1 else { return false }
        } else {
            let maxUndos = usedBonusUndo ? 1 : 2
            guard consecutiveUndos < maxUndos else { return false }
            if consecutiveUndos == 1 {
                usedBonusUndo = true
            }
        }
        
        consecutiveUndos += 1
        path.removeLast()
        currentPos = path.last!
        
        return true
    }
    
    mutating func reset() {
        guard !gaveUp else { return }
        
        attempts += 1
        path = [Position(row: gridSize.n, col: gridSize.n)]
        currentPos = path[0]
        gameOver = false
        consecutiveUndos = 0
        usedBonusUndo = false
    }
    
    mutating func giveUp() {
        gaveUp = true
        gameOver = true
        path = optimalPath
        currentPos = optimalPath.last ?? currentPos
    }
    
    // MARK: - Percentage & Scoring
    var percentage: Int {
        guard optimalLength > 0 else { return 0 }
        return Int((Double(pathLength) / Double(optimalLength)) * 100)
    }
    
    var tieredResponse: String {
        let responses5x5: [Int: String] = [
            13: "Novice Navigator!",
            14: "Path Finder!",
            15: "Route Ranger!",
            16: "Trail Blazer!",
            17: "Way Maker!",
            18: "Journey Master!",
            19: "Expedition Expert!",
            20: "Odyssey Oracle!",
            21: "Path Perfection!"
        ]
        
        let responses7x7: [Int: String] = [
            25: "Beginner Pathfinder!",
            30: "Master Trailblazer!",
            35: "Cosmic Navigator!",
            40: "Omnipotent Pathfinder!",
            45: "Absolute Perfection!"
        ]
        
        if gridSize == .small {
            return responses5x5[pathLength] ?? (pathLength > 21 ? "Impossible Achievement!" : "Keep exploring!")
        } else {
            for (threshold, response) in responses7x7.sorted(by: { $0.key > $1.key }) {
                if pathLength >= threshold {
                    return response
                }
            }
            return "Keep pushing!"
        }
    }
}

// MARK: - Seeded Random
struct SeededRandom {
    var seed: Int
    
    mutating func next() -> Double {
        seed = (seed &* 1103515245 &+ 12345) & 0x7fffffff
        return Double(seed) / Double(0x7fffffff)
    }
    
    mutating func nextInt(min: Int, max: Int) -> Int {
        Int(next() * Double(max - min + 1)) + min
    }
}
