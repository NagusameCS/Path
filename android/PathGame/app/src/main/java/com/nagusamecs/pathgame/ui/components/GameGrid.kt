package com.nagusamecs.pathgame.ui.components

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.nagusamecs.pathgame.data.model.GameState
import com.nagusamecs.pathgame.data.model.Position
import com.nagusamecs.pathgame.ui.theme.*

@Composable
fun GameGrid(
    gameState: GameState,
    onCellClick: (Position) -> Unit,
    modifier: Modifier = Modifier
) {
    val gridSize = gameState.gridSize.size
    // Path line color - subtle gray matching web design
    val pathColor = Color(0xFF666666)
    
    Box(modifier = modifier) {
        // Path lines layer
        Canvas(modifier = Modifier.fillMaxSize()) {
            val cellWidth = size.width / gridSize
            val cellHeight = size.height / gridSize
            
            for (i in 0 until gameState.path.size - 1) {
                val from = gameState.path[i]
                val to = gameState.path[i + 1]
                
                val fromCenter = Offset(
                    (from.col + 0.5f) * cellWidth,
                    (from.row + 0.5f) * cellHeight
                )
                val toCenter = Offset(
                    (to.col + 0.5f) * cellWidth,
                    (to.row + 0.5f) * cellHeight
                )
                
                drawLine(
                    color = pathColor.copy(alpha = 0.4f),
                    start = fromCenter,
                    end = toCenter,
                    strokeWidth = 4.dp.toPx(),
                    cap = StrokeCap.Round
                )
            }
        }
        
        // Grid cells
        Column(
            modifier = Modifier.fillMaxSize(),
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            for (row in 0 until gridSize) {
                Row(
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    for (col in 0 until gridSize) {
                        val position = Position(row, col)
                        val value = gameState.grid.getOrNull(row)?.getOrNull(col) ?: 0
                        
                        GridCell(
                            value = value,
                            isInPath = gameState.isInPath(position),
                            isCurrent = gameState.isCurrent(position),
                            isStart = gameState.isStart(position),
                            isValid = gameState.isValidMove(position),
                            pathIndex = gameState.pathIndex(position),
                            onClick = { onCellClick(position) },
                            modifier = Modifier.weight(1f)
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun GridCell(
    value: Int,
    isInPath: Boolean,
    isCurrent: Boolean,
    isStart: Boolean,
    isValid: Boolean,
    pathIndex: Int,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val interactionSource = remember { MutableInteractionSource() }
    val isPressed by interactionSource.collectIsPressedAsState()
    
    val scale by animateFloatAsState(
        targetValue = if (isPressed) 0.95f else 1f,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = Spring.StiffnessLow
        ),
        label = "scale"
    )
    
    // Web-matching grayscale colors
    // Dark: default #252525, visited #3a3a3a, current #4a4a4a, valid #2d2d2d
    val backgroundColor by animateColorAsState(
        targetValue = when {
            isCurrent -> CellCurrentDark  // #4a4a4a
            isStart && !isCurrent -> CellVisitedDark  // #3a3a3a
            isInPath -> CellVisitedDark  // #3a3a3a
            isValid -> CellValidDark.copy(alpha = 0.8f)  // #2d2d2d
            else -> CellDefaultDark  // #252525
        },
        animationSpec = tween(durationMillis = 150),
        label = "backgroundColor"
    )
    
    // Text colors matching web: current=white, visited=#ccc, valid=#aaa, default=#999
    val textColor = when {
        isCurrent -> Color.White
        isInPath || isStart -> Color(0xFFCCCCCC)
        isValid -> Color(0xFFAAAAAA)
        else -> Color(0xFF999999)
    }
    
    Box(
        modifier = modifier
            .aspectRatio(1f)
            .scale(scale)
            .clip(RoundedCornerShape(2.dp))
            .background(backgroundColor)
            .clickable(
                interactionSource = interactionSource,
                indication = null,
                onClick = onClick
            ),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Text(
                text = "$value",
                style = MaterialTheme.typography.titleLarge.copy(
                    fontWeight = FontWeight.Medium,
                    fontSize = 22.sp,
                    fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace
                ),
                color = textColor
            )
            
            // Show path number for cells in path (subtle, web-style)
            if (isInPath && pathIndex >= 0) {
                Text(
                    text = "${pathIndex + 1}",
                    style = MaterialTheme.typography.labelSmall.copy(
                        fontSize = 9.sp,
                        fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace
                    ),
                    color = textColor.copy(alpha = 0.5f)
                )
            }
        }
    }
}
