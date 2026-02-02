package com.nagusamecs.pathgame

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import com.nagusamecs.pathgame.ui.navigation.PathGameNavigation
import com.nagusamecs.pathgame.ui.screens.SplashScreen
import com.nagusamecs.pathgame.ui.theme.PathGameTheme
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        
        setContent {
            PathGameTheme {
                var showSplash by remember { mutableStateOf(true) }
                
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    // Main content (behind splash)
                    AnimatedVisibility(
                        visible = !showSplash,
                        enter = fadeIn(),
                        exit = fadeOut()
                    ) {
                        PathGameNavigation()
                    }
                    
                    // Splash screen (on top)
                    AnimatedVisibility(
                        visible = showSplash,
                        enter = fadeIn(),
                        exit = fadeOut()
                    ) {
                        SplashScreen(
                            onComplete = { showSplash = false }
                        )
                    }
                }
            }
        }
    }
}
