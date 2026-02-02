package com.nagusamecs.pathgame.ui.screens

import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.foundation.Canvas
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.StrokeCap
import com.nagusamecs.pathgame.R
import com.nagusamecs.pathgame.ui.theme.*
import kotlinx.coroutines.delay
import kotlin.random.Random

@Composable
fun SplashScreen(
    onComplete: () -> Unit
) {
    var showTitle by remember { mutableStateOf(false) }
    var showTagline by remember { mutableStateOf(false) }
    var showDots by remember { mutableStateOf(false) }
    
    // Icon animation
    val iconScale by animateFloatAsState(
        targetValue = if (showTitle) 1f else 0.8f,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = Spring.StiffnessLow
        ),
        label = "iconScale"
    )
    
    // Glow animation
    val infiniteTransition = rememberInfiniteTransition(label = "glow")
    val glowAlpha by infiniteTransition.animateFloat(
        initialValue = 0.3f,
        targetValue = 0.7f,
        animationSpec = infiniteRepeatable(
            animation = tween(1500, easing = EaseInOut),
            repeatMode = RepeatMode.Reverse
        ),
        label = "glowAlpha"
    )
    
    // Path drawing animation
    val pathProgress by animateFloatAsState(
        targetValue = if (showTitle) 1f else 0f,
        animationSpec = tween(1500, easing = EaseInOut),
        label = "pathProgress"
    )
    
    // Title fade
    val titleAlpha by animateFloatAsState(
        targetValue = if (showTitle) 1f else 0f,
        animationSpec = tween(500),
        label = "titleAlpha"
    )
    
    // Tagline fade
    val taglineAlpha by animateFloatAsState(
        targetValue = if (showTagline) 1f else 0f,
        animationSpec = tween(500),
        label = "taglineAlpha"
    )
    
    LaunchedEffect(Unit) {
        delay(300)
        showTitle = true
        delay(500)
        showTagline = true
        showDots = true
        delay(1700)
        onComplete()
    }
    
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.linearGradient(
                    colors = listOf(
                        Color(0xFF1A1A2E),
                        Color(0xFF0D0D15)
                    )
                )
            ),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Spacer(modifier = Modifier.weight(1f))
            
            // Animated grid background
            Box(
                modifier = Modifier.size(200.dp),
                contentAlignment = Alignment.Center
            ) {
                // Background grid cells
                AnimatedGridBackground()
                
                // App icon with glow
                Box(
                    modifier = Modifier.scale(iconScale),
                    contentAlignment = Alignment.Center
                ) {
                    // Glow effect
                    Box(
                        modifier = Modifier
                            .size(140.dp)
                            .clip(RoundedCornerShape(32.dp))
                            .background(
                                Brush.linearGradient(
                                    colors = listOf(
                                        Primary.copy(alpha = glowAlpha * 0.5f),
                                        PrimaryVariant.copy(alpha = glowAlpha * 0.5f)
                                    )
                                )
                            )
                    )
                    
                    // Main icon
                    Box(
                        modifier = Modifier
                            .size(120.dp)
                            .clip(RoundedCornerShape(32.dp))
                            .background(
                                Brush.linearGradient(
                                    colors = listOf(Primary, PrimaryVariant)
                                )
                            ),
                        contentAlignment = Alignment.Center
                    ) {
                        // Animated path inside
                        AnimatedPathDrawing(progress = pathProgress)
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(40.dp))
            
            // Title
            Text(
                text = "Path",
                fontSize = 48.sp,
                fontWeight = FontWeight.Bold,
                color = Color.White,
                modifier = Modifier.alpha(titleAlpha)
            )
            
            Spacer(modifier = Modifier.height(12.dp))
            
            // Tagline
            Text(
                text = stringResource(R.string.app_tagline),
                fontSize = 16.sp,
                color = Color.Gray,
                modifier = Modifier.alpha(taglineAlpha)
            )
            
            Spacer(modifier = Modifier.weight(1f))
            
            // Loading dots
            if (showDots) {
                LoadingDots()
            }
            
            Spacer(modifier = Modifier.height(60.dp))
        }
    }
}

@Composable
fun AnimatedGridBackground() {
    val gridSize = 5
    val cellOpacities = remember {
        mutableStateListOf<Float>().apply {
            repeat(gridSize * gridSize) { add(0.1f) }
        }
    }
    
    LaunchedEffect(Unit) {
        while (true) {
            val index = Random.nextInt(gridSize * gridSize)
            cellOpacities[index] = Random.nextFloat() * 0.3f + 0.1f
            delay(150)
            cellOpacities[index] = 0.1f
        }
    }
    
    Column(
        verticalArrangement = Arrangement.spacedBy(4.dp),
        modifier = Modifier.alpha(0.3f)
    ) {
        for (row in 0 until gridSize) {
            Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                for (col in 0 until gridSize) {
                    Box(
                        modifier = Modifier
                            .size(20.dp)
                            .clip(RoundedCornerShape(4.dp))
                            .background(Color.White.copy(alpha = cellOpacities[row * gridSize + col]))
                    )
                }
            }
        }
    }
}

@Composable
fun AnimatedPathDrawing(progress: Float) {
    Canvas(
        modifier = Modifier
            .size(72.dp)
            .padding(8.dp)
    ) {
        val points = listOf(
            Offset(size.width * 0.5f, size.height * 0.5f),
            Offset(size.width * 0.65f, size.height * 0.35f),
            Offset(size.width * 0.85f, size.height * 0.15f),
            Offset(size.width * 0.85f, size.height * 0.5f),
            Offset(size.width * 0.55f, size.height * 0.55f),
            Offset(size.width * 0.35f, size.height * 0.75f),
            Offset(size.width * 0.15f, size.height * 0.85f),
            Offset(size.width * 0.15f, size.height * 0.45f),
            Offset(size.width * 0.4f, size.height * 0.15f)
        )
        
        val totalPoints = (points.size * progress).toInt().coerceAtLeast(1)
        
        val path = Path().apply {
            if (points.isNotEmpty()) {
                moveTo(points[0].x, points[0].y)
                for (i in 1 until totalPoints.coerceAtMost(points.size)) {
                    lineTo(points[i].x, points[i].y)
                }
                
                // Partial line for smooth animation
                if (totalPoints < points.size && totalPoints > 0) {
                    val fraction = (points.size * progress) - (totalPoints - 1)
                    val fromPoint = points[totalPoints - 1]
                    val toPoint = points[totalPoints]
                    val partialX = fromPoint.x + (toPoint.x - fromPoint.x) * fraction
                    val partialY = fromPoint.y + (toPoint.y - fromPoint.y) * fraction
                    lineTo(partialX, partialY)
                }
            }
        }
        
        drawPath(
            path = path,
            color = Color.White,
            style = Stroke(width = 6f, cap = StrokeCap.Round)
        )
    }
}

@Composable
fun LoadingDots() {
    val infiniteTransition = rememberInfiniteTransition(label = "dots")
    
    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        repeat(3) { index ->
            val offsetY by infiniteTransition.animateFloat(
                initialValue = 0f,
                targetValue = -8f,
                animationSpec = infiniteRepeatable(
                    animation = tween(400, easing = EaseInOut, delayMillis = index * 150),
                    repeatMode = RepeatMode.Reverse
                ),
                label = "dot$index"
            )
            
            Box(
                modifier = Modifier
                    .offset(y = offsetY.dp)
                    .size(8.dp)
                    .clip(CircleShape)
                    .background(Color.White.copy(alpha = 0.6f))
            )
        }
    }
}
