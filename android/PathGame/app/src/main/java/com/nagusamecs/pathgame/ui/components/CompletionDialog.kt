package com.nagusamecs.pathgame.ui.components

import android.content.Intent
import androidx.compose.animation.*
import androidx.compose.foundation.background
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.nagusamecs.pathgame.R
import com.nagusamecs.pathgame.data.model.GameState
import com.nagusamecs.pathgame.data.model.GridSize
import com.nagusamecs.pathgame.ui.theme.*

@Composable
fun CompletionDialog(
    gameState: GameState,
    onDismiss: () -> Unit,
    onShare: () -> Unit,
    onNewGame: () -> Unit
) {
    val isPerfect = gameState.isPerfect
    val percentage = gameState.percentage
    
    val title = when {
        isPerfect -> "Perfect! ⭐"
        percentage >= 90 -> "Amazing! 🎯"
        percentage >= 75 -> "Great! ✨"
        percentage >= 50 -> "Good! 👍"
        else -> "Complete! 🎮"
    }
    
    val subtitle = when {
        isPerfect -> "You found the optimal path!"
        percentage >= 90 -> "So close to perfect!"
        percentage >= 75 -> "Nice job!"
        else -> "Keep practicing!"
    }
    
    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(
            dismissOnBackPress = true,
            dismissOnClickOutside = true
        )
    ) {
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            shape = RoundedCornerShape(8.dp),
            colors = CardDefaults.cardColors(
                containerColor = Color(0xFF222222)
            )
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                // Title
                Text(
                    text = title,
                    style = MaterialTheme.typography.headlineMedium.copy(
                        fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace
                    ),
                    fontWeight = FontWeight.Bold,
                    color = if (isPerfect) Color(0xFF9A9A9A) else Color.White
                )
                
                Spacer(modifier = Modifier.height(8.dp))
                
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.bodyLarge.copy(
                        fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace
                    ),
                    color = Color(0xFF888888),
                    textAlign = TextAlign.Center
                )
                
                Spacer(modifier = Modifier.height(24.dp))
                
                // Score display
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(4.dp))
                        .background(Color(0xFF2A2A2A))
                        .padding(20.dp),
                    horizontalArrangement = Arrangement.SpaceEvenly
                ) {
                    ScoreItem(
                        label = stringResource(R.string.result_your_path),
                        value = "${gameState.pathLength}"
                    )
                    
                    Box(
                        modifier = Modifier
                            .width(1.dp)
                            .height(40.dp)
                            .background(Color(0xFF444444))
                    )
                    
                    ScoreItem(
                        label = stringResource(R.string.game_optimal),
                        value = "${gameState.optimalLength}"
                    )
                    
                    Box(
                        modifier = Modifier
                            .width(1.dp)
                            .height(40.dp)
                            .background(Color(0xFF444444))
                    )
                    
                    ScoreItem(
                        label = stringResource(R.string.game_score),
                        value = "${percentage}%",
                        highlight = isPerfect
                    )
                }
                
                Spacer(modifier = Modifier.height(24.dp))
                
                // Action buttons
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    // Share button
                    OutlinedButton(
                        onClick = onShare,
                        modifier = Modifier.weight(1f),
                        colors = ButtonDefaults.outlinedButtonColors(
                            contentColor = Color(0xFFAAAAAA)
                        ),
                        border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFF555555)),
                        shape = RoundedCornerShape(4.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.Share,
                            contentDescription = null,
                            modifier = Modifier.size(18.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            stringResource(R.string.action_share),
                            style = MaterialTheme.typography.labelLarge.copy(
                                fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace
                            )
                        )
                    }
                    
                    // Try other size button
                    Button(
                        onClick = onNewGame,
                        modifier = Modifier.weight(1f),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = Color(0xFF3A3A3A),
                            contentColor = Color.White
                        ),
                        shape = RoundedCornerShape(4.dp)
                    ) {
                        Text(
                            text = stringResource(R.string.result_try_other_size, if (gameState.gridSize == GridSize.SMALL) "7×7" else "5×5"),
                            style = MaterialTheme.typography.labelLarge.copy(
                                fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace
                            )
                        )
                    }
                }
                
                Spacer(modifier = Modifier.height(8.dp))
                
                // Close button
                TextButton(
                    onClick = onDismiss,
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.textButtonColors(
                        contentColor = Color(0xFF888888)
                    )
                ) {
                    Text(
                        stringResource(R.string.result_close),
                        style = MaterialTheme.typography.labelLarge.copy(
                            fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace
                        )
                    )
                }
            }
        }
    }
}

@Composable
private fun ScoreItem(
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
                fontWeight = FontWeight.Bold,
                fontSize = 24.sp,
                fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace
            ),
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
