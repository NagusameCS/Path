package com.nagusamecs.pathgame.data.model

import java.time.LocalDate

/**
 * Represents a completed game result
 */
data class GameResult(
    val id: String = java.util.UUID.randomUUID().toString(),
    val date: LocalDate,
    val gridSize: GridSize,
    val pathLength: Int,
    val optimalLength: Int,
    val percentage: Int,
    val isPerfect: Boolean,
    val gaveUp: Boolean = false,
    val attempts: Int = 1,
    val completedAt: Long = System.currentTimeMillis()
) {
    val dateString: String
        get() = "${date.monthValue}/${date.dayOfMonth}/${date.year}"
}

/**
 * Player statistics
 */
data class GameStats(
    // Overall stats
    val gamesPlayed: Int = 0,
    val perfectGames: Int = 0,
    val currentStreak: Int = 0,
    val bestStreak: Int = 0,
    val totalPathLength: Int = 0,
    val totalOptimalLength: Int = 0,
    
    // 5x5 specific
    val games5x5: Int = 0,
    val perfect5x5: Int = 0,
    val total5x5PathLength: Int = 0,
    val total5x5OptimalLength: Int = 0,
    
    // 7x7 specific
    val games7x7: Int = 0,
    val perfect7x7: Int = 0,
    val total7x7PathLength: Int = 0,
    val total7x7OptimalLength: Int = 0,
    
    // Tracking
    val lastPlayedDate: LocalDate? = null,
    val results: List<GameResult> = emptyList()
) {
    val averagePercentage: Int
        get() = if (totalOptimalLength > 0) (totalPathLength * 100) / totalOptimalLength else 0
    
    val average5x5Percentage: Int
        get() = if (total5x5OptimalLength > 0) (total5x5PathLength * 100) / total5x5OptimalLength else 0
    
    val average7x7Percentage: Int
        get() = if (total7x7OptimalLength > 0) (total7x7PathLength * 100) / total7x7OptimalLength else 0
    
    val perfectPercentage: Int
        get() = if (gamesPlayed > 0) (perfectGames * 100) / gamesPlayed else 0
    
    /**
     * Add a new game result to stats
     */
    fun addResult(result: GameResult): GameStats {
        val today = LocalDate.now()
        val isConsecutive = lastPlayedDate?.let { 
            it == today.minusDays(1) || it == today 
        } ?: true
        
        val newStreak = if (isConsecutive) currentStreak + 1 else 1
        
        return when (result.gridSize) {
            GridSize.SMALL -> copy(
                gamesPlayed = gamesPlayed + 1,
                perfectGames = if (result.isPerfect) perfectGames + 1 else perfectGames,
                currentStreak = newStreak,
                bestStreak = maxOf(bestStreak, newStreak),
                totalPathLength = totalPathLength + result.pathLength,
                totalOptimalLength = totalOptimalLength + result.optimalLength,
                games5x5 = games5x5 + 1,
                perfect5x5 = if (result.isPerfect) perfect5x5 + 1 else perfect5x5,
                total5x5PathLength = total5x5PathLength + result.pathLength,
                total5x5OptimalLength = total5x5OptimalLength + result.optimalLength,
                lastPlayedDate = today,
                results = (listOf(result) + results).take(100)
            )
            GridSize.LARGE -> copy(
                gamesPlayed = gamesPlayed + 1,
                perfectGames = if (result.isPerfect) perfectGames + 1 else perfectGames,
                currentStreak = newStreak,
                bestStreak = maxOf(bestStreak, newStreak),
                totalPathLength = totalPathLength + result.pathLength,
                totalOptimalLength = totalOptimalLength + result.optimalLength,
                games7x7 = games7x7 + 1,
                perfect7x7 = if (result.isPerfect) perfect7x7 + 1 else perfect7x7,
                total7x7PathLength = total7x7PathLength + result.pathLength,
                total7x7OptimalLength = total7x7OptimalLength + result.optimalLength,
                lastPlayedDate = today,
                results = (listOf(result) + results).take(100)
            )
        }
    }
}

/**
 * User preferences
 */
data class UserPreferences(
    val hapticFeedback: Boolean = true,
    val soundEnabled: Boolean = true,
    val dailyReminder: Boolean = false,
    val reminderHour: Int = 9,
    val reminderMinute: Int = 0,
    val defaultGridSize: GridSize = GridSize.SMALL,
    val showOptimalHint: Boolean = true,
    val hasCompletedOnboarding: Boolean = false,
    val darkMode: DarkModePreference = DarkModePreference.SYSTEM
)

enum class DarkModePreference {
    SYSTEM, LIGHT, DARK
}
