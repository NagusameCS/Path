package com.nagusamecs.pathgame.ui.screens

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.nagusamecs.pathgame.R
import com.nagusamecs.pathgame.ui.theme.*
import kotlinx.coroutines.launch

data class HelpPage(
    val icon: ImageVector,
    val iconColor: Color,
    val titleRes: Int,
    val descriptionRes: Int,
    val detailsRes: List<Int>,
    val showExample: Boolean = false
)

val helpPages = listOf(
    HelpPage(
        icon = Icons.Default.FilterTiltShift,
        iconColor = Color(0xFF2196F3),
        titleRes = R.string.help_page1_title,
        descriptionRes = R.string.help_page1_desc,
        detailsRes = listOf(
            R.string.help_page1_detail1,
            R.string.help_page1_detail2,
            R.string.help_page1_detail3
        )
    ),
    HelpPage(
        icon = Icons.Default.OpenWith,
        iconColor = Color(0xFF4CAF50),
        titleRes = R.string.help_page2_title,
        descriptionRes = R.string.help_page2_desc,
        detailsRes = listOf(
            R.string.help_page2_detail1,
            R.string.help_page2_detail2,
            R.string.help_page2_detail3
        ),
        showExample = true
    ),
    HelpPage(
        icon = Icons.Default.Star,
        iconColor = Color(0xFFFFC107),
        titleRes = R.string.help_page3_title,
        descriptionRes = R.string.help_page3_desc,
        detailsRes = listOf(
            R.string.help_page3_detail1,
            R.string.help_page3_detail2,
            R.string.help_page3_detail3
        )
    ),
    HelpPage(
        icon = Icons.Default.People,
        iconColor = Color(0xFF9C27B0),
        titleRes = R.string.help_page4_title,
        descriptionRes = R.string.help_page4_desc,
        detailsRes = listOf(
            R.string.help_page4_detail1,
            R.string.help_page4_detail2,
            R.string.help_page4_detail3
        )
    )
)

@OptIn(ExperimentalMaterial3Api::class, ExperimentalFoundationApi::class)
@Composable
fun HelpScreen(
    onDismiss: () -> Unit
) {
    val pagerState = rememberPagerState(pageCount = { helpPages.size + 1 }) // +1 for final page
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.help_title)) },
                navigationIcon = {
                    IconButton(onClick = onDismiss) {
                        Icon(
                            imageVector = Icons.Default.Close,
                            contentDescription = stringResource(R.string.cd_close)
                        )
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            HorizontalPager(
                state = pagerState,
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth()
            ) { page ->
                if (page < helpPages.size) {
                    HelpPageContent(page = helpPages[page])
                } else {
                    FinalHelpPage(onDismiss = onDismiss)
                }
            }
            
            // Page indicators
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                horizontalArrangement = Arrangement.Center
            ) {
                repeat(helpPages.size + 1) { index ->
                    Box(
                        modifier = Modifier
                            .padding(horizontal = 4.dp)
                            .size(
                                width = if (pagerState.currentPage == index) 24.dp else 8.dp,
                                height = 8.dp
                            )
                            .clip(CircleShape)
                            .background(
                                if (pagerState.currentPage == index)
                                    MaterialTheme.colorScheme.primary
                                else
                                    MaterialTheme.colorScheme.surfaceVariant
                            )
                    )
                }
            }
        }
    }
}

@Composable
fun HelpPageContent(page: HelpPage) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Spacer(modifier = Modifier.height(16.dp))
        
        // Icon
        Box(
            modifier = Modifier
                .size(100.dp)
                .clip(CircleShape)
                .background(page.iconColor.copy(alpha = 0.15f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = page.icon,
                contentDescription = null,
                modifier = Modifier.size(48.dp),
                tint = page.iconColor
            )
        }
        
        Spacer(modifier = Modifier.height(24.dp))
        
        // Title
        Text(
            text = stringResource(page.titleRes),
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Center
        )
        
        Spacer(modifier = Modifier.height(12.dp))
        
        // Description
        Text(
            text = stringResource(page.descriptionRes),
            style = MaterialTheme.typography.bodyLarge,
            textAlign = TextAlign.Center,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        
        // Example grid
        if (page.showExample) {
            Spacer(modifier = Modifier.height(24.dp))
            MovementExampleView()
        }
        
        Spacer(modifier = Modifier.height(24.dp))
        
        // Details
        Column(
            modifier = Modifier.fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            page.detailsRes.forEach { detailRes ->
                Row(
                    verticalAlignment = Alignment.Top,
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.CheckCircle,
                        contentDescription = null,
                        tint = Color(0xFF4CAF50),
                        modifier = Modifier.size(20.dp)
                    )
                    Text(
                        text = stringResource(detailRes),
                        style = MaterialTheme.typography.bodyMedium
                    )
                }
            }
        }
        
        Spacer(modifier = Modifier.height(32.dp))
    }
}

@Composable
fun MovementExampleView() {
    Column(
        modifier = Modifier
            .clip(RoundedCornerShape(16.dp))
            .background(MaterialTheme.colorScheme.surfaceVariant)
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // 3x3 grid example
        Column(
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                ExampleCell(value = 6, state = CellState.SELECTABLE)
                ExampleCell(value = 8, state = CellState.NORMAL)
                ExampleCell(value = 2, state = CellState.NORMAL)
            }
            Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                ExampleCell(value = 4, state = CellState.NORMAL)
                ExampleCell(value = 5, state = CellState.CURRENT)
                ExampleCell(value = 6, state = CellState.SELECTABLE)
            }
            Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                ExampleCell(value = 3, state = CellState.NORMAL)
                ExampleCell(value = 4, state = CellState.SELECTABLE)
                ExampleCell(value = 7, state = CellState.NORMAL)
            }
        }
        
        Spacer(modifier = Modifier.height(12.dp))
        
        // Legend
        Row(
            horizontalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            LegendItem(
                color = Color(0xFF2196F3).copy(alpha = 0.3f),
                label = stringResource(R.string.help_legend_current)
            )
            LegendItem(
                color = Color(0xFF4CAF50).copy(alpha = 0.3f),
                label = stringResource(R.string.help_legend_valid)
            )
        }
    }
}

enum class CellState {
    NORMAL, CURRENT, SELECTABLE
}

@Composable
fun ExampleCell(value: Int, state: CellState) {
    val backgroundColor = when (state) {
        CellState.NORMAL -> MaterialTheme.colorScheme.surface
        CellState.CURRENT -> Color(0xFF2196F3).copy(alpha = 0.3f)
        CellState.SELECTABLE -> Color(0xFF4CAF50).copy(alpha = 0.3f)
    }
    
    val borderColor = when (state) {
        CellState.CURRENT -> Color(0xFF2196F3)
        CellState.SELECTABLE -> Color(0xFF4CAF50)
        else -> Color.Transparent
    }
    
    Box(
        modifier = Modifier
            .size(56.dp)
            .clip(RoundedCornerShape(8.dp))
            .background(backgroundColor)
            .then(
                if (state != CellState.NORMAL) {
                    Modifier.background(
                        color = Color.Transparent,
                        shape = RoundedCornerShape(8.dp)
                    )
                } else Modifier
            ),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = value.toString(),
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.Bold
        )
    }
}

@Composable
fun LegendItem(color: Color, label: String) {
    Row(
        horizontalArrangement = Arrangement.spacedBy(6.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(16.dp)
                .clip(RoundedCornerShape(4.dp))
                .background(color)
        )
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
fun FinalHelpPage(onDismiss: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            imageVector = Icons.Default.Verified,
            contentDescription = null,
            modifier = Modifier.size(80.dp),
            tint = Color(0xFF4CAF50)
        )
        
        Spacer(modifier = Modifier.height(24.dp))
        
        Text(
            text = stringResource(R.string.help_ready_title),
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Center
        )
        
        Spacer(modifier = Modifier.height(12.dp))
        
        Text(
            text = stringResource(R.string.help_ready_desc),
            style = MaterialTheme.typography.bodyLarge,
            textAlign = TextAlign.Center,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        
        Spacer(modifier = Modifier.height(32.dp))
        
        Button(
            onClick = onDismiss,
            modifier = Modifier
                .fillMaxWidth()
                .height(56.dp),
            shape = RoundedCornerShape(16.dp),
            colors = ButtonDefaults.buttonColors(
                containerColor = MaterialTheme.colorScheme.primary
            )
        ) {
            Text(
                text = stringResource(R.string.help_start_playing),
                style = MaterialTheme.typography.titleMedium
            )
        }
    }
}
