package com.nagusamecs.pathgame.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.nagusamecs.pathgame.R
import com.nagusamecs.pathgame.data.model.DarkModePreference
import com.nagusamecs.pathgame.data.model.GridSize
import com.nagusamecs.pathgame.ui.viewmodel.SettingsViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    viewModel: SettingsViewModel = hiltViewModel()
) {
    val preferences by viewModel.preferences.collectAsState()
    val stats by viewModel.stats.collectAsState()
    
    var showResetDialog by remember { mutableStateOf(false) }
    var showHelpSheet by remember { mutableStateOf(false) }
    var showAboutSheet by remember { mutableStateOf(false) }
    
    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        item {
            Text(
                text = stringResource(R.string.settings_title),
                style = MaterialTheme.typography.headlineLarge,
                fontWeight = FontWeight.Bold
            )
        }
        
        // Game Section
        item {
            SettingsSection(title = stringResource(R.string.settings_game)) {
                // Default grid size
                SettingsItem(
                    icon = Icons.Default.GridOn,
                    title = stringResource(R.string.settings_default_grid),
                    subtitle = stringResource(R.string.settings_default_grid)
                ) {
                    Row(
                        modifier = Modifier
                            .clip(RoundedCornerShape(8.dp))
                    ) {
                        GridSize.entries.forEach { size ->
                            FilterChip(
                                selected = preferences.defaultGridSize == size,
                                onClick = { viewModel.setDefaultGridSize(size) },
                                label = { Text(size.displayName) },
                                modifier = Modifier.padding(end = 8.dp)
                            )
                        }
                    }
                }
                
                // Show optimal hint
                SettingsToggle(
                    icon = Icons.Default.Lightbulb,
                    title = stringResource(R.string.settings_show_optimal),
                    subtitle = stringResource(R.string.settings_show_optimal_desc),
                    checked = preferences.showOptimalHint,
                    onCheckedChange = { viewModel.setShowOptimalHint(it) }
                )
            }
        }
        
        // Feedback Section
        item {
            SettingsSection(title = stringResource(R.string.settings_feedback)) {
                SettingsToggle(
                    icon = Icons.Default.Vibration,
                    title = stringResource(R.string.settings_haptic),
                    subtitle = stringResource(R.string.settings_haptic_desc),
                    checked = preferences.hapticFeedback,
                    onCheckedChange = { viewModel.setHapticFeedback(it) }
                )
                
                SettingsToggle(
                    icon = Icons.Default.VolumeUp,
                    title = stringResource(R.string.settings_sound),
                    subtitle = stringResource(R.string.settings_sound_desc),
                    checked = preferences.soundEnabled,
                    onCheckedChange = { viewModel.setSoundEnabled(it) }
                )
            }
        }
        
        // Notifications Section
        item {
            SettingsSection(title = stringResource(R.string.settings_notifications)) {
                SettingsToggle(
                    icon = Icons.Default.Notifications,
                    title = stringResource(R.string.settings_daily_reminder),
                    subtitle = stringResource(R.string.settings_daily_reminder_desc),
                    checked = preferences.dailyReminder,
                    onCheckedChange = { viewModel.setDailyReminder(it) }
                )
            }
        }
        
        // Appearance Section
        item {
            SettingsSection(title = stringResource(R.string.settings_appearance)) {
                SettingsItem(
                    icon = Icons.Default.DarkMode,
                    title = stringResource(R.string.settings_theme),
                    subtitle = when (preferences.darkMode) {
                        DarkModePreference.SYSTEM -> stringResource(R.string.settings_theme_system)
                        DarkModePreference.LIGHT -> stringResource(R.string.settings_theme_light)
                        DarkModePreference.DARK -> stringResource(R.string.settings_theme_dark)
                    }
                ) {
                    Row {
                        DarkModePreference.entries.forEach { mode ->
                            FilterChip(
                                selected = preferences.darkMode == mode,
                                onClick = { viewModel.setDarkMode(mode) },
                                label = { 
                                    Text(
                                        when (mode) {
                                            DarkModePreference.SYSTEM -> stringResource(R.string.settings_theme_system)
                                            DarkModePreference.LIGHT -> stringResource(R.string.settings_theme_light)
                                            DarkModePreference.DARK -> stringResource(R.string.settings_theme_dark)
                                        }
                                    ) 
                                },
                                modifier = Modifier.padding(end = 8.dp)
                            )
                        }
                    }
                }
            }
        }
        
        // Data Section
        item {
            SettingsSection(title = stringResource(R.string.settings_data)) {
                SettingsButton(
                    icon = Icons.Default.Delete,
                    title = stringResource(R.string.settings_reset_stats),
                    subtitle = stringResource(R.string.settings_reset_stats_desc),
                    isDestructive = true,
                    onClick = { showResetDialog = true }
                )
            }
        }
        
        // About Section
        item {
            SettingsSection(title = stringResource(R.string.settings_about)) {
                SettingsButton(
                    icon = Icons.Default.Help,
                    title = stringResource(R.string.settings_how_to_play),
                    subtitle = stringResource(R.string.help_title),
                    onClick = { showHelpSheet = true }
                )
                
                SettingsButton(
                    icon = Icons.Default.Info,
                    title = stringResource(R.string.settings_about),
                    subtitle = stringResource(R.string.settings_about_path),
                    onClick = { showAboutSheet = true }
                )
            }
        }
        
        // Footer
        item {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 24.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = stringResource(R.string.app_name),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = "© 2024 Nagusamecs",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
    
    // Reset confirmation dialog
    if (showResetDialog) {
        AlertDialog(
            onDismissRequest = { showResetDialog = false },
            title = { Text(stringResource(R.string.reset_title)) },
            text = { 
                Text(stringResource(R.string.reset_message)) 
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        viewModel.resetStats()
                        showResetDialog = false
                    },
                    colors = ButtonDefaults.textButtonColors(
                        contentColor = MaterialTheme.colorScheme.error
                    )
                ) {
                    Text(stringResource(R.string.reset_confirm))
                }
            },
            dismissButton = {
                TextButton(onClick = { showResetDialog = false }) {
                    Text(stringResource(R.string.reset_cancel))
                }
            }
        )
    }
    
    // Help screen
    if (showHelpSheet) {
        HelpScreen(
            onDismiss = { showHelpSheet = false }
        )
    }
    
    // About bottom sheet
    if (showAboutSheet) {
        ModalBottomSheet(
            onDismissRequest = { showAboutSheet = false }
        ) {
            AboutContent()
        }
    }
}

@Composable
fun SettingsSection(
    title: String,
    content: @Composable ColumnScope.() -> Unit
) {
    Column {
        Text(
            text = title,
            style = MaterialTheme.typography.labelLarge,
            color = MaterialTheme.colorScheme.primary,
            modifier = Modifier.padding(bottom = 8.dp)
        )
        
        Card(
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.surfaceVariant
            )
        ) {
            Column(
                modifier = Modifier.padding(4.dp)
            ) {
                content()
            }
        }
    }
}

@Composable
fun SettingsItem(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    title: String,
    subtitle: String,
    trailing: @Composable () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.size(24.dp)
        )
        
        Spacer(modifier = Modifier.width(16.dp))
        
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = title,
                style = MaterialTheme.typography.bodyLarge
            )
            Text(
                text = subtitle,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            trailing()
        }
    }
}

@Composable
fun SettingsToggle(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    title: String,
    subtitle: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.size(24.dp)
        )
        
        Spacer(modifier = Modifier.width(16.dp))
        
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = title,
                style = MaterialTheme.typography.bodyLarge
            )
            Text(
                text = subtitle,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        
        Switch(
            checked = checked,
            onCheckedChange = onCheckedChange
        )
    }
}

@Composable
fun SettingsButton(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    title: String,
    subtitle: String,
    isDestructive: Boolean = false,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = if (isDestructive) 
                MaterialTheme.colorScheme.error 
            else 
                MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.size(24.dp)
        )
        
        Spacer(modifier = Modifier.width(16.dp))
        
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = title,
                style = MaterialTheme.typography.bodyLarge,
                color = if (isDestructive) 
                    MaterialTheme.colorScheme.error 
                else 
                    MaterialTheme.colorScheme.onSurface
            )
            Text(
                text = subtitle,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
        
        IconButton(onClick = onClick) {
            Icon(
                imageVector = Icons.Default.ChevronRight,
                contentDescription = null
            )
        }
    }
}

@Composable
fun HelpContent() {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(24.dp)
    ) {
        Text(
            text = "How to Play",
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        HelpStep(
            number = "1",
            title = "Start from the center",
            description = "Your journey begins at the center cell of the grid."
        )
        
        HelpStep(
            number = "2",
            title = "Move to adjacent cells",
            description = "Tap any adjacent cell (including diagonals) that has a value within ±1 of your current cell."
        )
        
        HelpStep(
            number = "3",
            title = "Find the longest path",
            description = "Try to visit as many cells as possible without repeating any cell."
        )
        
        HelpStep(
            number = "4",
            title = "Achieve perfection",
            description = "Match the optimal path length to earn a perfect score!"
        )
        
        Spacer(modifier = Modifier.height(24.dp))
    }
}

@Composable
fun HelpStep(
    number: String,
    title: String,
    description: String
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp)
    ) {
        Surface(
            shape = RoundedCornerShape(20.dp),
            color = MaterialTheme.colorScheme.primary,
            modifier = Modifier.size(32.dp)
        ) {
            Box(
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = number,
                    style = MaterialTheme.typography.labelLarge,
                    color = MaterialTheme.colorScheme.onPrimary
                )
            }
        }
        
        Spacer(modifier = Modifier.width(16.dp))
        
        Column {
            Text(
                text = title,
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Medium
            )
            Text(
                text = description,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
fun AboutContent() {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = "Path",
            style = MaterialTheme.typography.headlineLarge,
            fontWeight = FontWeight.Bold
        )
        
        Spacer(modifier = Modifier.height(8.dp))
        
        Text(
            text = "A Daily Puzzle Game",
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        
        Spacer(modifier = Modifier.height(24.dp))
        
        Text(
            text = "Find the longest path through the grid, starting from the center. Move to adjacent cells with values within ±1 of your current cell.",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        
        Spacer(modifier = Modifier.height(24.dp))
        
        HorizontalDivider()
        
        Spacer(modifier = Modifier.height(24.dp))
        
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(
                text = "Version",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Text(
                text = "1.0.0",
                style = MaterialTheme.typography.bodyMedium
            )
        }
        
        Spacer(modifier = Modifier.height(12.dp))
        
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(
                text = "Developer",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Text(
                text = "Nagusamecs",
                style = MaterialTheme.typography.bodyMedium
            )
        }
        
        Spacer(modifier = Modifier.height(24.dp))
    }
}
