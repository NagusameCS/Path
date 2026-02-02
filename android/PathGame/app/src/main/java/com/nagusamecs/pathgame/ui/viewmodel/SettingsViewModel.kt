package com.nagusamecs.pathgame.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.nagusamecs.pathgame.data.model.DarkModePreference
import com.nagusamecs.pathgame.data.model.GridSize
import com.nagusamecs.pathgame.data.model.UserPreferences
import com.nagusamecs.pathgame.data.repository.GameRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val repository: GameRepository
) : ViewModel() {
    
    val preferences: StateFlow<UserPreferences> = repository.userPreferences.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = UserPreferences()
    )
    
    val stats = repository.gameStats.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000),
        initialValue = com.nagusamecs.pathgame.data.model.GameStats()
    )
    
    fun setHapticFeedback(enabled: Boolean) {
        viewModelScope.launch {
            repository.updatePreferences { it.copy(hapticFeedback = enabled) }
        }
    }
    
    fun setSoundEnabled(enabled: Boolean) {
        viewModelScope.launch {
            repository.updatePreferences { it.copy(soundEnabled = enabled) }
        }
    }
    
    fun setDailyReminder(enabled: Boolean) {
        viewModelScope.launch {
            repository.updatePreferences { it.copy(dailyReminder = enabled) }
        }
    }
    
    fun setReminderTime(hour: Int, minute: Int) {
        viewModelScope.launch {
            repository.updatePreferences { 
                it.copy(reminderHour = hour, reminderMinute = minute) 
            }
        }
    }
    
    fun setDefaultGridSize(gridSize: GridSize) {
        viewModelScope.launch {
            repository.updatePreferences { it.copy(defaultGridSize = gridSize) }
        }
    }
    
    fun setShowOptimalHint(enabled: Boolean) {
        viewModelScope.launch {
            repository.updatePreferences { it.copy(showOptimalHint = enabled) }
        }
    }
    
    fun setDarkMode(mode: DarkModePreference) {
        viewModelScope.launch {
            repository.updatePreferences { it.copy(darkMode = mode) }
        }
    }
    
    fun resetStats() {
        viewModelScope.launch {
            repository.resetStats()
        }
    }
}
