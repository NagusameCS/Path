package com.nagusamecs.pathgame.data.repository

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.*
import androidx.datastore.preferences.preferencesDataStore
import com.nagusamecs.pathgame.data.model.*
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.map
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.io.IOException
import java.time.LocalDate
import javax.inject.Inject
import javax.inject.Singleton

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "path_game_prefs")

@Singleton
class GameRepository @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val dataStore = context.dataStore
    
    companion object {
        // Preferences keys
        private val HAPTIC_FEEDBACK = booleanPreferencesKey("haptic_feedback")
        private val SOUND_ENABLED = booleanPreferencesKey("sound_enabled")
        private val DAILY_REMINDER = booleanPreferencesKey("daily_reminder")
        private val REMINDER_HOUR = intPreferencesKey("reminder_hour")
        private val REMINDER_MINUTE = intPreferencesKey("reminder_minute")
        private val DEFAULT_GRID_SIZE = stringPreferencesKey("default_grid_size")
        private val SHOW_OPTIMAL_HINT = booleanPreferencesKey("show_optimal_hint")
        private val HAS_COMPLETED_ONBOARDING = booleanPreferencesKey("has_completed_onboarding")
        private val DARK_MODE = stringPreferencesKey("dark_mode")
        
        // Stats keys
        private val GAMES_PLAYED = intPreferencesKey("games_played")
        private val PERFECT_GAMES = intPreferencesKey("perfect_games")
        private val CURRENT_STREAK = intPreferencesKey("current_streak")
        private val BEST_STREAK = intPreferencesKey("best_streak")
        private val TOTAL_PATH_LENGTH = intPreferencesKey("total_path_length")
        private val TOTAL_OPTIMAL_LENGTH = intPreferencesKey("total_optimal_length")
        private val GAMES_5X5 = intPreferencesKey("games_5x5")
        private val PERFECT_5X5 = intPreferencesKey("perfect_5x5")
        private val TOTAL_5X5_PATH = intPreferencesKey("total_5x5_path")
        private val TOTAL_5X5_OPTIMAL = intPreferencesKey("total_5x5_optimal")
        private val GAMES_7X7 = intPreferencesKey("games_7x7")
        private val PERFECT_7X7 = intPreferencesKey("perfect_7x7")
        private val TOTAL_7X7_PATH = intPreferencesKey("total_7x7_path")
        private val TOTAL_7X7_OPTIMAL = intPreferencesKey("total_7x7_optimal")
        private val LAST_PLAYED_DATE = stringPreferencesKey("last_played_date")
        private val GAME_RESULTS = stringPreferencesKey("game_results")
        
        // Game state keys
        private val SAVED_GAME_STATE = stringPreferencesKey("saved_game_state")
    }
    
    // User Preferences
    val userPreferences: Flow<UserPreferences> = dataStore.data
        .catch { exception ->
            if (exception is IOException) {
                emit(emptyPreferences())
            } else {
                throw exception
            }
        }
        .map { prefs ->
            UserPreferences(
                hapticFeedback = prefs[HAPTIC_FEEDBACK] ?: true,
                soundEnabled = prefs[SOUND_ENABLED] ?: true,
                dailyReminder = prefs[DAILY_REMINDER] ?: false,
                reminderHour = prefs[REMINDER_HOUR] ?: 9,
                reminderMinute = prefs[REMINDER_MINUTE] ?: 0,
                defaultGridSize = prefs[DEFAULT_GRID_SIZE]?.let { 
                    GridSize.entries.find { gs -> gs.name == it } 
                } ?: GridSize.SMALL,
                showOptimalHint = prefs[SHOW_OPTIMAL_HINT] ?: true,
                hasCompletedOnboarding = prefs[HAS_COMPLETED_ONBOARDING] ?: false,
                darkMode = prefs[DARK_MODE]?.let { 
                    DarkModePreference.entries.find { dm -> dm.name == it } 
                } ?: DarkModePreference.SYSTEM
            )
        }
    
    suspend fun updatePreferences(update: (UserPreferences) -> UserPreferences) {
        dataStore.edit { prefs ->
            val current = UserPreferences(
                hapticFeedback = prefs[HAPTIC_FEEDBACK] ?: true,
                soundEnabled = prefs[SOUND_ENABLED] ?: true,
                dailyReminder = prefs[DAILY_REMINDER] ?: false,
                reminderHour = prefs[REMINDER_HOUR] ?: 9,
                reminderMinute = prefs[REMINDER_MINUTE] ?: 0,
                defaultGridSize = prefs[DEFAULT_GRID_SIZE]?.let { 
                    GridSize.entries.find { gs -> gs.name == it } 
                } ?: GridSize.SMALL,
                showOptimalHint = prefs[SHOW_OPTIMAL_HINT] ?: true,
                hasCompletedOnboarding = prefs[HAS_COMPLETED_ONBOARDING] ?: false,
                darkMode = prefs[DARK_MODE]?.let { 
                    DarkModePreference.entries.find { dm -> dm.name == it } 
                } ?: DarkModePreference.SYSTEM
            )
            val updated = update(current)
            prefs[HAPTIC_FEEDBACK] = updated.hapticFeedback
            prefs[SOUND_ENABLED] = updated.soundEnabled
            prefs[DAILY_REMINDER] = updated.dailyReminder
            prefs[REMINDER_HOUR] = updated.reminderHour
            prefs[REMINDER_MINUTE] = updated.reminderMinute
            prefs[DEFAULT_GRID_SIZE] = updated.defaultGridSize.name
            prefs[SHOW_OPTIMAL_HINT] = updated.showOptimalHint
            prefs[HAS_COMPLETED_ONBOARDING] = updated.hasCompletedOnboarding
            prefs[DARK_MODE] = updated.darkMode.name
        }
    }
    
    // Game Stats
    val gameStats: Flow<GameStats> = dataStore.data
        .catch { exception ->
            if (exception is IOException) {
                emit(emptyPreferences())
            } else {
                throw exception
            }
        }
        .map { prefs ->
            GameStats(
                gamesPlayed = prefs[GAMES_PLAYED] ?: 0,
                perfectGames = prefs[PERFECT_GAMES] ?: 0,
                currentStreak = prefs[CURRENT_STREAK] ?: 0,
                bestStreak = prefs[BEST_STREAK] ?: 0,
                totalPathLength = prefs[TOTAL_PATH_LENGTH] ?: 0,
                totalOptimalLength = prefs[TOTAL_OPTIMAL_LENGTH] ?: 0,
                games5x5 = prefs[GAMES_5X5] ?: 0,
                perfect5x5 = prefs[PERFECT_5X5] ?: 0,
                total5x5PathLength = prefs[TOTAL_5X5_PATH] ?: 0,
                total5x5OptimalLength = prefs[TOTAL_5X5_OPTIMAL] ?: 0,
                games7x7 = prefs[GAMES_7X7] ?: 0,
                perfect7x7 = prefs[PERFECT_7X7] ?: 0,
                total7x7PathLength = prefs[TOTAL_7X7_PATH] ?: 0,
                total7x7OptimalLength = prefs[TOTAL_7X7_OPTIMAL] ?: 0,
                lastPlayedDate = prefs[LAST_PLAYED_DATE]?.let { LocalDate.parse(it) }
            )
        }
    
    suspend fun saveGameResult(result: GameResult) {
        dataStore.edit { prefs ->
            val stats = GameStats(
                gamesPlayed = prefs[GAMES_PLAYED] ?: 0,
                perfectGames = prefs[PERFECT_GAMES] ?: 0,
                currentStreak = prefs[CURRENT_STREAK] ?: 0,
                bestStreak = prefs[BEST_STREAK] ?: 0,
                totalPathLength = prefs[TOTAL_PATH_LENGTH] ?: 0,
                totalOptimalLength = prefs[TOTAL_OPTIMAL_LENGTH] ?: 0,
                games5x5 = prefs[GAMES_5X5] ?: 0,
                perfect5x5 = prefs[PERFECT_5X5] ?: 0,
                total5x5PathLength = prefs[TOTAL_5X5_PATH] ?: 0,
                total5x5OptimalLength = prefs[TOTAL_5X5_OPTIMAL] ?: 0,
                games7x7 = prefs[GAMES_7X7] ?: 0,
                perfect7x7 = prefs[PERFECT_7X7] ?: 0,
                total7x7PathLength = prefs[TOTAL_7X7_PATH] ?: 0,
                total7x7OptimalLength = prefs[TOTAL_7X7_OPTIMAL] ?: 0,
                lastPlayedDate = prefs[LAST_PLAYED_DATE]?.let { LocalDate.parse(it) }
            )
            
            val updated = stats.addResult(result)
            
            prefs[GAMES_PLAYED] = updated.gamesPlayed
            prefs[PERFECT_GAMES] = updated.perfectGames
            prefs[CURRENT_STREAK] = updated.currentStreak
            prefs[BEST_STREAK] = updated.bestStreak
            prefs[TOTAL_PATH_LENGTH] = updated.totalPathLength
            prefs[TOTAL_OPTIMAL_LENGTH] = updated.totalOptimalLength
            prefs[GAMES_5X5] = updated.games5x5
            prefs[PERFECT_5X5] = updated.perfect5x5
            prefs[TOTAL_5X5_PATH] = updated.total5x5PathLength
            prefs[TOTAL_5X5_OPTIMAL] = updated.total5x5OptimalLength
            prefs[GAMES_7X7] = updated.games7x7
            prefs[PERFECT_7X7] = updated.perfect7x7
            prefs[TOTAL_7X7_PATH] = updated.total7x7PathLength
            prefs[TOTAL_7X7_OPTIMAL] = updated.total7x7OptimalLength
            prefs[LAST_PLAYED_DATE] = updated.lastPlayedDate?.toString()
        }
    }
    
    suspend fun resetStats() {
        dataStore.edit { prefs ->
            prefs[GAMES_PLAYED] = 0
            prefs[PERFECT_GAMES] = 0
            prefs[CURRENT_STREAK] = 0
            prefs[BEST_STREAK] = 0
            prefs[TOTAL_PATH_LENGTH] = 0
            prefs[TOTAL_OPTIMAL_LENGTH] = 0
            prefs[GAMES_5X5] = 0
            prefs[PERFECT_5X5] = 0
            prefs[TOTAL_5X5_PATH] = 0
            prefs[TOTAL_5X5_OPTIMAL] = 0
            prefs[GAMES_7X7] = 0
            prefs[PERFECT_7X7] = 0
            prefs[TOTAL_7X7_PATH] = 0
            prefs[TOTAL_7X7_OPTIMAL] = 0
            prefs.remove(LAST_PLAYED_DATE)
            prefs.remove(GAME_RESULTS)
        }
    }
}
