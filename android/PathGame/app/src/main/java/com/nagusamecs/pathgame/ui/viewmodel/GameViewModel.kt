package com.nagusamecs.pathgame.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.nagusamecs.pathgame.data.model.*
import com.nagusamecs.pathgame.data.repository.GameRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.time.LocalDate
import javax.inject.Inject

@HiltViewModel
class GameViewModel @Inject constructor(
    private val repository: GameRepository
) : ViewModel() {
    
    private val _gameState = MutableStateFlow(GameState())
    val gameState: StateFlow<GameState> = _gameState.asStateFlow()
    
    private val _isCalculatingOptimal = MutableStateFlow(false)
    val isCalculatingOptimal: StateFlow<Boolean> = _isCalculatingOptimal.asStateFlow()
    
    private val _showCompletionDialog = MutableStateFlow(false)
    val showCompletionDialog: StateFlow<Boolean> = _showCompletionDialog.asStateFlow()
    
    private val _showGiveUpDialog = MutableStateFlow(false)
    val showGiveUpDialog: StateFlow<Boolean> = _showGiveUpDialog.asStateFlow()
    
    val preferences = repository.userPreferences.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = UserPreferences()
    )
    
    val stats = repository.gameStats.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = GameStats()
    )
    
    init {
        viewModelScope.launch {
            preferences.collect { prefs ->
                if (_gameState.value.grid.isEmpty()) {
                    startNewGame(prefs.defaultGridSize)
                }
            }
        }
    }
    
    fun startNewGame(gridSize: GridSize) {
        val newState = GameState(
            gridSize = gridSize,
            date = LocalDate.now()
        ).generateGrid()
        
        _gameState.value = newState
        _showCompletionDialog.value = false
        
        // Calculate optimal path in background
        calculateOptimalPath(newState)
    }
    
    fun makeMove(position: Position) {
        val currentState = _gameState.value
        if (currentState.isValidMove(position)) {
            _gameState.value = currentState.makeMove(position)
        }
    }
    
    fun undoMove() {
        _gameState.value = _gameState.value.undoMove()
    }
    
    fun restartGame() {
        _gameState.value = _gameState.value.restart()
        _showCompletionDialog.value = false
    }
    
    fun finishGame() {
        val state = _gameState.value
        if (state.pathLength > 1) {
            _gameState.value = state.copy(isComplete = true)
            _showCompletionDialog.value = true
            
            // Save result
            val result = GameResult(
                date = state.date,
                gridSize = state.gridSize,
                pathLength = state.pathLength,
                optimalLength = state.optimalLength,
                percentage = state.percentage,
                isPerfect = state.isPerfect,
                gaveUp = false,
                attempts = state.attempts
            )
            
            viewModelScope.launch {
                repository.saveGameResult(result)
            }
        }
    }
    
    fun dismissCompletionDialog() {
        _showCompletionDialog.value = false
    }
    
    fun showGiveUpConfirmation() {
        _showGiveUpDialog.value = true
    }
    
    fun dismissGiveUpDialog() {
        _showGiveUpDialog.value = false
    }
    
    fun giveUp() {
        _showGiveUpDialog.value = false
        val state = _gameState.value
        _gameState.value = state.giveUp()
        _showCompletionDialog.value = true
        
        // Save result (gave up)
        val result = GameResult(
            date = state.date,
            gridSize = state.gridSize,
            pathLength = state.pathLength,
            optimalLength = state.optimalLength,
            percentage = state.percentage,
            isPerfect = false,
            gaveUp = true,
            attempts = state.attempts
        )
        
        viewModelScope.launch {
            repository.saveGameResult(result)
        }
    }
    
    fun switchGridSize(gridSize: GridSize) {
        startNewGame(gridSize)
    }
    
    private fun calculateOptimalPath(state: GameState) {
        viewModelScope.launch {
            _isCalculatingOptimal.value = true
            
            val (optimal, optimalPath) = withContext(Dispatchers.Default) {
                findOptimalPathWithPath(state)
            }
            
            _gameState.value = _gameState.value.copy(
                optimalLength = optimal,
                optimalPath = optimalPath
            )
            _isCalculatingOptimal.value = false
        }
    }
    
    /**
     * Find the optimal (longest) path using DFS - returns length and path
     */
    private fun findOptimalPathWithPath(state: GameState): Pair<Int, List<Position>> {
        val grid = state.grid
        val size = state.gridSize.size
        val center = state.gridSize.center
        
        var maxLength = 1
        var bestPath = listOf(Position(center, center))
        val visited = Array(size) { BooleanArray(size) }
        val currentPath = mutableListOf<Position>()
        
        fun dfs(row: Int, col: Int, length: Int) {
            currentPath.add(Position(row, col))
            
            if (length > maxLength) {
                maxLength = length
                bestPath = currentPath.toList()
            }
            
            // Early termination if we've visited all cells
            if (length == size * size) {
                currentPath.removeLast()
                return
            }
            
            val currentVal = grid[row][col]
            
            for (dRow in -1..1) {
                for (dCol in -1..1) {
                    if (dRow == 0 && dCol == 0) continue
                    
                    val newRow = row + dRow
                    val newCol = col + dCol
                    
                    if (newRow in 0 until size && 
                        newCol in 0 until size && 
                        !visited[newRow][newCol]) {
                        
                        val targetVal = grid[newRow][newCol]
                        if (kotlin.math.abs(targetVal - currentVal) <= 1) {
                            visited[newRow][newCol] = true
                            dfs(newRow, newCol, length + 1)
                            visited[newRow][newCol] = false
                        }
                    }
                }
            }
            
            currentPath.removeLast()
        }
        
        visited[center][center] = true
        dfs(center, center, 1)
        
        return Pair(maxLength, bestPath)
    }
    
    /**
     * Generate share text for the game result
     */
    fun generateShareText(): String {
        val state = _gameState.value
        val emoji = when {
            state.gaveUp -> "🏳️"
            state.isPerfect -> "⭐"
            state.percentage >= 90 -> "🎯"
            state.percentage >= 75 -> "✨"
            else -> "🎮"
        }
        
        return buildString {
            append("Path ${state.date.monthValue}/${state.date.dayOfMonth}/${state.date.year}\n")
            append("${state.gridSize.displayName} $emoji\n")
            append("${state.pathLength}/${state.optimalLength} (${state.percentage}%)")
            
            // Add attempts info
            if (state.attempts == 1 && !state.gaveUp) {
                append(" - First try!")
            } else if (state.attempts > 1) {
                append(" - ${state.attempts} attempts")
            }
            append("\n\n")
            
            // Generate grid visualization
            for (row in 0 until state.gridSize.size) {
                for (col in 0 until state.gridSize.size) {
                    val pos = Position(row, col)
                    val inPath = state.isInPath(pos)
                    append(if (inPath) "🟦" else "⬜")
                }
                append("\n")
            }
            
            append("\nPlay at: https://nagusamecs.github.io/Path/")
        }
    }
    
    fun completeOnboarding() {
        viewModelScope.launch {
            repository.updatePreferences { it.copy(hasCompletedOnboarding = true) }
        }
    }
}
