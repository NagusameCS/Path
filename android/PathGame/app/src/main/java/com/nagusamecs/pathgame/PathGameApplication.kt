package com.nagusamecs.pathgame

import android.app.Application
import dagger.hilt.android.HiltAndroidApp

@HiltAndroidApp
class PathGameApplication : Application() {
    
    override fun onCreate() {
        super.onCreate()
        // Initialize any app-wide configurations here
    }
}
