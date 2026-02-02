package com.nagusamecs.pathgame.ui.screens

import android.content.Intent
import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.nagusamecs.pathgame.R
import com.nagusamecs.pathgame.data.model.GridSize
import com.nagusamecs.pathgame.ui.components.GameGrid
import com.nagusamecs.pathgame.ui.components.CompletionDialog
import com.nagusamecs.pathgame.ui.theme.*
import com.nagusamecs.pathgame.ui.viewmodel.GameViewModel

@OptIn(ExperimentalMaterial3Api::class, ExperimentalFoundationApi::class)
@Composable
fun GameScreen(
    viewModel: GameViewModel = hiltViewModel()
) {
    val gameState by viewModel.gameState.collectAsState()
    val preferences by viewModel.preferences.collectAsState()
    val isCalculating by viewModel.isCalculatingOptimal.collectAsState()
    val showCompletion by viewModel.showCompletionDialog.collectAsState()
    val showGiveUp by viewModel.showGiveUpDialog.collectAsState()
    
    val context = LocalContext.current
    val haptic = LocalHapticFeedback.current
    
    var selectedGridSize by remember { mutableStateOf(GridSize.SMALL) }
    
    // Tooltip states
    var showUndoTooltip by remember { mutableStateOf(false) }
    var showRestartTooltip by remember { mutableStateOf(false) }
    var showFinishTooltip by remember { mutableStateOf(false) }
    var showShareTooltip by remember { mutableStateOf(false) }
    var showGridTooltip by remember { mutableStateOf(false) }
    
    LaunchedEffect(preferences.defaultGridSize) {
        selectedGridSize = preferences.defaultGridSize
    }
    
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFF1A1A1A))
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Header - Web: "PATH" with letter-spacing
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = stringResource(R.string.app_name).uppercase(),
                style = MaterialTheme.typography.headlineLarge.copy(
                    fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace,
                    letterSpacing = 8.sp,
                    fontWeight = FontWeight.Light
                ),
                color = Color.White
            )
            
            // Grid size toggle - Web style
            TooltipBox(
                positionProvider = TooltipDefaults.rememberPlainTooltipPositionProvider(),
                tooltip = {
                    PlainTooltip {
                        Text(stringResource(R.string.tooltip_grid_toggle))
                    }
                },
                state = rememberTooltipState()
            ) {
                Row(
                    modifier = Modifier
                        .clip(RoundedCornerShape(3.dp))
                        .background(Color(0xFF2A2A2A))
                        .semantics { 
                            contentDescription = context.getString(R.string.tooltip_grid_toggle)
                        }
                ) {
                    GridSize.entries.forEach { size ->
                        val isSelected = selectedGridSize == size
                        TextButton(
                            onClick = {
                                selectedGridSize = size
                                viewModel.switchGridSize(size)
                                if (preferences.hapticFeedback) {
                                    haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                                }
                            },
                            modifier = Modifier
                                .clip(RoundedCornerShape(3.dp))
                                .background(
                                    if (isSelected) Color(0xFF3A3A3A)
                                    else Color.Transparent
                                ),
                            colors = ButtonDefaults.textButtonColors(
                                contentColor = if (isSelected) 
                                    Color.White 
                                else 
                                    Color(0xFF888888)
                            )
                        ) {
                            Text(
                                text = size.displayName,
                                style = MaterialTheme.typography.labelLarge.copy(
                                    fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace
                                )
                            )
                        }
                    }
                }
            }
        }
        
        Spacer(modifier = Modifier.height(8.dp))
        
        // Date - Web style: gray text
        Text(
            text = "${gameState.date.monthValue}/${gameState.date.dayOfMonth}/${gameState.date.year}",
            style = MaterialTheme.typography.bodyMedium.copy(
                fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace
            ),
            color = Color(0xFF888888)
        )
        
        Spacer(modifier = Modifier.height(16.dp))
        
        // Stats bar - Web style: dark background
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(4.dp))
                .background(Color(0xFF252525))
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            StatItem(
                label = stringResource(R.string.game_path_length),
                value = "${gameState.pathLength}"
            )
            
            if (!isCalculating && gameState.optimalLength > 0) {
                StatItem(
                    label = stringResource(R.string.game_optimal),
                    value = "${gameState.optimalLength}"
                )
                
                StatItem(
                    label = stringResource(R.string.game_score),
                    value = "${gameState.percentage}%",
                    highlight = gameState.isPerfect
                )
            } else if (isCalculating) {
                StatItem(
                    label = stringResource(R.string.game_optimal),
                    value = stringResource(R.string.game_calculating)
                )
            }
        }
        
        Spacer(modifier = Modifier.height(24.dp))
        
        // Game Grid
        Box(
            modifier = Modifier
                .weight(1f)
                .aspectRatio(1f),
            contentAlignment = Alignment.Center
        ) {
            GameGrid(
                gameState = gameState,
                onCellClick = { position ->
                    if (gameState.isValidMove(position)) {
                        viewModel.makeMove(position)
                        if (preferences.hapticFeedback) {
                            haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                        }
                    }
                }
            )
        }
        
        Spacer(modifier = Modifier.height(24.dp))
        
        // Action buttons with tooltips
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            // Undo button with tooltip
            TooltipBox(
                positionProvider = TooltipDefaults.rememberPlainTooltipPositionProvider(),
                tooltip = {
                    PlainTooltip {
                        Text(stringResource(R.string.tooltip_undo))
                    }
                },
                state = rememberTooltipState()
            ) {
                IconButton(
                    onClick = {
                        viewModel.undoMove()
                        if (preferences.hapticFeedback) {
                            haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                        }
                    },
                    enabled = gameState.canUndo(),
                    modifier = Modifier
                        .size(36.dp)
                        .clip(RoundedCornerShape(18.dp))
                        .background(Color(0xFF2A2A2A))
                        .semantics {
                            contentDescription = context.getString(R.string.a11y_undo_button)
                        }
                ) {
                    Icon(
                        imageVector = Icons.Default.Undo,
                        contentDescription = stringResource(R.string.action_undo),
                        tint = if (gameState.canUndo()) Color(0xFFAAAAAA) else Color(0xFF555555),
                        modifier = Modifier.size(18.dp)
                    )
                }
            }
            
            // Restart button with tooltip
            TooltipBox(
                positionProvider = TooltipDefaults.rememberPlainTooltipPositionProvider(),
                tooltip = {
                    PlainTooltip {
                        Text(stringResource(R.string.tooltip_restart))
                    }
                },
                state = rememberTooltipState()
            ) {
                IconButton(
                    onClick = {
                        viewModel.restartGame()
                        if (preferences.hapticFeedback) {
                            haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                        }
                    },
                    enabled = !gameState.gaveUp && !gameState.isComplete,
                    modifier = Modifier
                        .size(36.dp)
                        .clip(RoundedCornerShape(18.dp))
                        .background(Color(0xFF2A2A2A))
                        .semantics {
                            contentDescription = context.getString(R.string.a11y_restart_button)
                        }
                ) {
                    Icon(
                        imageVector = Icons.Default.Refresh,
                        contentDescription = stringResource(R.string.action_restart),
                        tint = if (!gameState.gaveUp && !gameState.isComplete) Color(0xFFAAAAAA) else Color(0xFF555555),
                        modifier = Modifier.size(18.dp)
                    )
                }
            }
            
            // Give Up button with tooltip
            TooltipBox(
                positionProvider = TooltipDefaults.rememberPlainTooltipPositionProvider(),
                tooltip = {
                    PlainTooltip {
                        Text(stringResource(R.string.tooltip_give_up))
                    }
                },
                state = rememberTooltipState()
            ) {
                IconButton(
                    onClick = {
                        viewModel.showGiveUpConfirmation()
                        if (preferences.hapticFeedback) {
                            haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                        }
                    },
                    enabled = !gameState.isComplete && !gameState.gaveUp && gameState.optimalLength > 0,
                    modifier = Modifier
                        .size(36.dp)
                        .clip(RoundedCornerShape(18.dp))
                        .background(Color(0xFF2A2A2A))
                        .semantics {
                            contentDescription = context.getString(R.string.a11y_give_up_button)
                        }
                ) {
                    Icon(
                        imageVector = Icons.Default.Flag,
                        contentDescription = stringResource(R.string.action_give_up),
                        tint = if (!gameState.isComplete && !gameState.gaveUp && gameState.optimalLength > 0) Color(0xFFAAAAAA) else Color(0xFF555555),
                        modifier = Modifier.size(18.dp)
                    )
                }
            }
            
            // Finish button with tooltip
            TooltipBox(
                positionProvider = TooltipDefaults.rememberPlainTooltipPositionProvider(),
                tooltip = {
                    PlainTooltip {
                        Text(stringResource(R.string.tooltip_finish))
                    }
                },
                },
                state = rememberTooltipState()
            ) {
                Button(
                    onClick = {
                        viewModel.finishGame()
                        if (preferences.hapticFeedback) {
                            haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                        }
                    },
                    enabled = gameState.pathLength > 1 && !gameState.isComplete,
                    colors = ButtonDefaults.buttonColors(
                        containerColor = Color(0xFF3A3A3A),
                        contentColor = Color.White,
                        disabledContainerColor = Color(0xFF2A2A2A),
                        disabledContentColor = Color(0xFF555555)
                    ),
                    shape = RoundedCornerShape(4.dp),
                    modifier = Modifier.semantics {
                        contentDescription = context.getString(R.string.a11y_finish_button)
                    }
                ) {
                    Text(
                        text = stringResource(R.string.action_finish),
                        style = MaterialTheme.typography.labelLarge.copy(
                            fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace
                        )
                    )
                }
            }
            
            // Share button with tooltip
            TooltipBox(
                positionProvider = TooltipDefaults.rememberPlainTooltipPositionProvider(),
                tooltip = {
                    PlainTooltip {
                        Text(stringResource(R.string.tooltip_share))
                    }
                },
                state = rememberTooltipState()
            ) {
                IconButton(
                    onClick = {
                        val shareText = viewModel.generateShareText()
                        val shareIntent = Intent().apply {
                            action = Intent.ACTION_SEND
                            putExtra(Intent.EXTRA_TEXT, shareText)
                            type = "text/plain"
                        }
                        context.startActivity(Intent.createChooser(shareIntent, context.getString(R.string.action_share)))
                    },
                    enabled = gameState.isComplete,
                    modifier = Modifier
                        .size(36.dp)
                        .clip(RoundedCornerShape(18.dp))
                        .background(Color(0xFF2A2A2A))
                        .semantics {
                            contentDescription = context.getString(R.string.a11y_share_button)
                        }
                ) {
                    Icon(
                        imageVector = Icons.Default.Share,
                        contentDescription = stringResource(R.string.action_share),
                        tint = if (gameState.isComplete) Color(0xFFAAAAAA) else Color(0xFF555555),
                        modifier = Modifier.size(18.dp)
                    )
                }
            }
        }
        
        // Valid moves hint - Web style: gray text
        if (!gameState.isComplete) {
            val validMoves = gameState.getValidMoves()
            Text(
                text = if (validMoves.isEmpty() && gameState.pathLength > 1) {
                    stringResource(R.string.game_no_valid_moves)
                } else {
                    stringResource(R.string.game_valid_moves, validMoves.size)
                },
                style = MaterialTheme.typography.bodySmall.copy(
                    fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace
                ),
                color = Color(0xFF888888),
                modifier = Modifier.padding(top = 8.dp)
            )
        }
    }
    
    // Completion Dialog
    if (showCompletion) {
        CompletionDialog(
            gameState = gameState,
            onDismiss = { viewModel.dismissCompletionDialog() },
            onShare = {
                val shareText = viewModel.generateShareText()
                val shareIntent = Intent().apply {
                    action = Intent.ACTION_SEND
                    putExtra(Intent.EXTRA_TEXT, shareText)
                    type = "text/plain"
                }
                context.startActivity(Intent.createChooser(shareIntent, context.getString(R.string.action_share)))
            },
            onNewGame = {
                viewModel.startNewGame(
                    if (gameState.gridSize == GridSize.SMALL) GridSize.LARGE else GridSize.SMALL
                )
            }
        )
    }
    
    // Give Up Confirmation Dialog
    if (showGiveUp) {
        AlertDialog(
            onDismissRequest = { viewModel.dismissGiveUpDialog() },
            title = { 
                Text(
                    stringResource(R.string.give_up_title),
                    fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace
                ) 
            },
            text = { 
                Text(
                    stringResource(R.string.give_up_message),
                    fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace
                ) 
            },
            confirmButton = {
                TextButton(
                    onClick = { viewModel.giveUp() },
                    colors = ButtonDefaults.textButtonColors(
                        contentColor = Color(0xFFFF6B6B)
                    )
                ) {
                    Text(
                        stringResource(R.string.give_up_confirm),
                        fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace
                    )
                }
            },
            dismissButton = {
                TextButton(
                    onClick = { viewModel.dismissGiveUpDialog() }
                ) {
                    Text(
                        stringResource(R.string.give_up_cancel),
                        fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace
                    )
                }
            },
            containerColor = Color(0xFF222222),
            titleContentColor = Color.White,
            textContentColor = Color(0xFF888888)
        )
    }
}

@Composable
fun StatItem(
    label: String,
    value: String,
    highlight: Boolean = false
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = value,
            style = MaterialTheme.typography.titleLarge.copy(
                fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace
            ),
            fontWeight = FontWeight.Bold,
            color = if (highlight) Color(0xFF9A9A9A) else Color.White
        )
        Text(
            text = label,
            style = MaterialTheme.typography.bodySmall.copy(
                fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace
            ),
            color = Color(0xFF888888)
        )
    }
}
