package com.nagusamecs.pathgame.data.model

import java.time.LocalDate
import kotlin.math.abs

/**
 * Represents a position on the game grid
 */
data class Position(
    val row: Int,
    val col: Int
) {
    fun isAdjacentTo(other: Position): Boolean {
        val rowDiff = abs(row - other.row)
        val colDiff = abs(col - other.col)
        return rowDiff <= 1 && colDiff <= 1 && !(rowDiff == 0 && colDiff == 0)
    }
}

/**
 * Grid size options - n value matches web version (n=2 for 5x5, n=3 for 7x7)
 */
enum class GridSize(val size: Int, val n: Int, val displayName: String) {
    SMALL(5, 2, "5×5"),
    LARGE(7, 3, "7×7");
    
    val totalCells: Int get() = size * size
    val center: Int get() = n // Center is always n (2 for 5x5, 3 for 7x7)
}

/**
 * Seeded random number generator - MUST match web version exactly!
 * Web uses: seed = (seed * 1103515245 + 12345) & 0x7fffffff
 * Then: return seed / 0x7fffffff for next()
 * And: Math.floor(next() * (max - min + 1)) + min for nextInt
 */
class SeededRandom(seed: Long) {
    private var state = seed
    
    private fun next(): Double {
        state = (state * 1103515245L + 12345L) and 0x7FFFFFFFL
        return state.toDouble() / 0x7FFFFFFF.toDouble()
    }
    
    fun nextInt(min: Int, max: Int): Int {
        return (next() * (max - min + 1)).toInt() + min
    }
    
    companion object {
        /**
         * Generate seed from date - MUST match web version exactly!
         * Web uses: dateStr = "${year}-${month+1}-${day}" then hash
         */
        fun getDateSeed(date: LocalDate): Long {
            val dateStr = "${date.year}-${date.monthValue}-${date.dayOfMonth}"
            var hash = 0L
            for (char in dateStr) {
                val charValue = char.code.toLong()
                hash = ((hash shl 5) - hash) + charValue
                hash = hash and 0xFFFFFFFFL // Keep as 32-bit
            }
            return abs(hash)
        }
        
        fun forDate(date: LocalDate, gridSize: GridSize): SeededRandom {
            val baseSeed = getDateSeed(date)
            val seed = baseSeed + gridSize.n * 1000
            return SeededRandom(seed)
        }
    }
}

/**
 * Represents the complete state of a game
 */
data class GameState(
    val gridSize: GridSize = GridSize.SMALL,
    val grid: List<List<Int>> = emptyList(),
    val path: List<Position> = emptyList(),
    val isComplete: Boolean = false,
    val optimalLength: Int = 0,
    val optimalPath: List<Position> = emptyList(),
    val date: LocalDate = LocalDate.now(),
    val attempts: Int = 1,
    val gaveUp: Boolean = false,
    val consecutiveUndos: Int = 0,
    val usedBonusUndo: Boolean = false
) {
    val currentPosition: Position?
        get() = path.lastOrNull()
    
    val currentValue: Int?
        get() = currentPosition?.let { grid[it.row][it.col] }
    
    val pathLength: Int
        get() = path.size
    
    val percentage: Int
        get() = if (optimalLength > 0) (pathLength * 100) / optimalLength else 0
    
    val isPerfect: Boolean
        get() = pathLength >= optimalLength && optimalLength > 0 && !gaveUp
    
    /**
     * Generate a new grid with seeded random values
     * Values are 1-5 to match web version exactly
     */
    fun generateGrid(): GameState {
        val random = SeededRandom.forDate(date, gridSize)
        val newGrid = List(gridSize.size) { _ ->
            List(gridSize.size) { _ ->
                random.nextInt(1, 5) // 1-5 like web version
            }
        }
        
        val center = gridSize.center
        val startPosition = Position(center, center)
        
        return copy(
            grid = newGrid,
            path = listOf(startPosition),
            isComplete = false
        )
    }
    
    /**
     * Check if a move to the given position is valid
     */
    fun isValidMove(position: Position): Boolean {
        // Check bounds
        if (position.row < 0 || position.row >= gridSize.size ||
            position.col < 0 || position.col >= gridSize.size) {
            return false
        }
        
        // Check if already visited
        if (path.contains(position)) {
            return false
        }
        
        // Check adjacency
        val current = currentPosition ?: return false
        if (!current.isAdjacentTo(position)) {
            return false
        }
        
        // Check value constraint (within ±1)
        val currentVal = currentValue ?: return false
        val targetVal = grid[position.row][position.col]
        return kotlin.math.abs(targetVal - currentVal) <= 1
    }
    
    /**
     * Get all valid moves from current position
     */
    fun getValidMoves(): List<Position> {
        val current = currentPosition ?: return emptyList()
        val moves = mutableListOf<Position>()
        
        for (dRow in -1..1) {
            for (dCol in -1..1) {
                if (dRow == 0 && dCol == 0) continue
                val newPos = Position(current.row + dRow, current.col + dCol)
                if (isValidMove(newPos)) {
                    moves.add(newPos)
                }
            }
        }
        
        return moves
    }
    
    /**
     * Make a move to the given position
     */
    fun makeMove(position: Position): GameState {
        if (!isValidMove(position)) return this
        return copy(
            path = path + position,
            consecutiveUndos = 0  // Reset consecutive undos on move
        )
    }
    
    /**
     * Undo the last move - with limits matching web/iOS
     * 5x5: Max 1 consecutive undo
     * 7x7: Max 2 consecutive undos (then 1 after bonus used)
     */
    fun undoMove(): GameState {
        if (path.size <= 1) return this
        if (isComplete || gaveUp) return this
        
        // Check undo limits
        val maxUndos = when (gridSize) {
            GridSize.SMALL -> 1
            GridSize.LARGE -> if (usedBonusUndo) 1 else 2
        }
        
        if (consecutiveUndos >= maxUndos) return this
        
        val newUsedBonusUndo = if (gridSize == GridSize.LARGE && consecutiveUndos == 1) true else usedBonusUndo
        
        return copy(
            path = path.dropLast(1),
            consecutiveUndos = consecutiveUndos + 1,
            usedBonusUndo = newUsedBonusUndo
        )
    }
    
    /**
     * Check if undo is available
     */
    fun canUndo(): Boolean {
        if (path.size <= 1) return false
        if (isComplete || gaveUp) return false
        
        val maxUndos = when (gridSize) {
            GridSize.SMALL -> 1
            GridSize.LARGE -> if (usedBonusUndo) 1 else 2
        }
        
        return consecutiveUndos < maxUndos
    }
    
    /**
     * Reset the game to the starting position
     */
    fun restart(): GameState {
        if (gaveUp) return this  // Can't restart after giving up
        
        val center = gridSize.center
        return copy(
            path = listOf(Position(center, center)),
            isComplete = false,
            attempts = attempts + 1,
            consecutiveUndos = 0,
            usedBonusUndo = false
        )
    }
    
    /**
     * Give up and reveal the optimal path
     */
    fun giveUp(): GameState {
        return copy(
            gaveUp = true,
            isComplete = true,
            path = optimalPath.ifEmpty { path }
        )
    }
    
    /**
     * Check if the cell at position is part of the path
     */
    fun isInPath(position: Position): Boolean = path.contains(position)
    
    /**
     * Check if the cell at position is the current cell
     */
    fun isCurrent(position: Position): Boolean = currentPosition == position
    
    /**
     * Check if the cell at position is the start cell
     */
    fun isStart(position: Position): Boolean = path.firstOrNull() == position
    
    /**
     * Get the index of a position in the path (for drawing path lines)
     */
    fun pathIndex(position: Position): Int = path.indexOf(position)
}
