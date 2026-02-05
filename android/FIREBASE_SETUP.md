# Firebase Setup for Android - Path Game

This document contains all the configuration needed to set up Firebase on the Android version of Path Game.

## Prerequisites

1. Android Studio installed
2. Firebase project created (use existing project: `path-c5620`)
3. Google AdMob account for ads

## Step 1: Add Firebase to Android Project

### 1.1 Register Android App in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project `path-c5620`
3. Click "Add app" → Android
4. Enter package name: `com.nagusamecs.pathgame`
5. Download `google-services.json`
6. Place it in `android/PathGame/app/` directory

### 1.2 Add Firebase SDK to Gradle

Update `android/PathGame/build.gradle.kts`:

```kotlin
plugins {
    // ... existing plugins
    id("com.google.gms.google-services") version "4.4.2" apply false
}
```

Update `android/PathGame/app/build.gradle.kts`:

```kotlin
plugins {
    alias(libs.plugins.android.application)
    id("com.google.gms.google-services")
}

dependencies {
    // Firebase BOM
    implementation(platform("com.google.firebase:firebase-bom:33.0.0"))
    
    // Firebase services
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-database")
    implementation("com.google.firebase:firebase-messaging")
    
    // Google AdMob
    implementation("com.google.android.gms:play-services-ads:23.0.0")
    
    // Google Sign-In
    implementation("com.google.android.gms:play-services-auth:21.1.0")
}
```

## Step 2: Firebase Configuration

### 2.1 Web Config (for reference)
```javascript
const firebaseConfig = {
    apiKey: "AIzaSyBHzOKe9HFPi4j3GsNVmX0iaxwfgzjkFhM",
    authDomain: "path-c5620.firebaseapp.com",
    databaseURL: "https://path-c5620-default-rtdb.firebaseio.com",
    projectId: "path-c5620",
    storageBucket: "path-c5620.firebasestorage.app",
    messagingSenderId: "758386561005",
    appId: "1:758386561005:web:c8f5db0e605a3ac80ac3ff",
    measurementId: "G-6GV4J9DXWK"
};
```

### 2.2 Initialize Firebase in Application

Create `PathGameApplication.kt`:

```kotlin
package com.nagusamecs.pathgame

import android.app.Application
import com.google.firebase.FirebaseApp
import com.google.android.gms.ads.MobileAds

class PathGameApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        
        // Initialize Firebase
        FirebaseApp.initializeApp(this)
        
        // Initialize AdMob
        MobileAds.initialize(this) {}
    }
}
```

Update `AndroidManifest.xml`:
```xml
<application
    android:name=".PathGameApplication"
    ...>
```

## Step 3: Authentication Service

Create `AuthService.kt`:

```kotlin
package com.nagusamecs.pathgame.services

import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseUser
import com.google.firebase.firestore.FirebaseFirestore
import kotlinx.coroutines.tasks.await
import java.util.Locale

data class PathUser(
    val id: String,
    val displayName: String,
    val countryCode: String,
    val currentStreak: Int = 0,
    val longestStreak: Int = 0,
    val totalScore: Int = 0,
    val gamesPlayed: Int = 0,
    val perfectGames: Int = 0,
    val isAnonymous: Boolean = false
)

class AuthService {
    private val auth = FirebaseAuth.getInstance()
    private val db = FirebaseFirestore.getInstance()
    
    val currentFirebaseUser: FirebaseUser?
        get() = auth.currentUser
    
    suspend fun signInAnonymously(): PathUser? {
        return try {
            val result = auth.signInAnonymously().await()
            result.user?.let { createUserProfile(it, isAnonymous = true) }
        } catch (e: Exception) {
            null
        }
    }
    
    suspend fun signInWithGoogle(idToken: String): PathUser? {
        // Implement Google Sign-In
        return null
    }
    
    private suspend fun createUserProfile(user: FirebaseUser, isAnonymous: Boolean): PathUser {
        val countryCode = Locale.getDefault().country
        val pathUser = PathUser(
            id = user.uid,
            displayName = user.displayName ?: "Player",
            countryCode = countryCode,
            isAnonymous = isAnonymous
        )
        
        db.collection("users").document(user.uid).set(pathUser).await()
        return pathUser
    }
    
    fun signOut() {
        auth.signOut()
    }
}
```

## Step 4: Streak Service

Create `StreakService.kt`:

```kotlin
package com.nagusamecs.pathgame.services

import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import kotlinx.coroutines.tasks.await
import java.time.LocalDate
import java.time.temporal.ChronoUnit

data class StreakData(
    val currentStreak: Int = 0,
    val longestStreak: Int = 0,
    val lastPlayedDate: String? = null,
    val totalDaysPlayed: Int = 0,
    val lastRecoveryDate: String? = null
)

class StreakService {
    private val auth = FirebaseAuth.getInstance()
    private val db = FirebaseFirestore.getInstance()
    
    val canRecoverStreak: Boolean
        get() {
            // Can recover if no recovery in the last 7 days
            // Implement based on lastRecoveryDate
            return true
        }
    
    suspend fun loadStreak(): StreakData? {
        val userId = auth.currentUser?.uid ?: return null
        return try {
            val doc = db.collection("users").document(userId)
                .collection("streak").document("current").get().await()
            doc.toObject(StreakData::class.java)
        } catch (e: Exception) {
            null
        }
    }
    
    suspend fun recordGameCompletion() {
        val userId = auth.currentUser?.uid ?: return
        val today = LocalDate.now().toString()
        
        val currentData = loadStreak() ?: StreakData()
        val lastPlayed = currentData.lastPlayedDate?.let { LocalDate.parse(it) }
        
        val newStreak = when {
            lastPlayed == null -> 1
            ChronoUnit.DAYS.between(lastPlayed, LocalDate.now()) == 1L -> currentData.currentStreak + 1
            ChronoUnit.DAYS.between(lastPlayed, LocalDate.now()) == 0L -> currentData.currentStreak
            else -> 1 // Streak broken
        }
        
        val updatedData = currentData.copy(
            currentStreak = newStreak,
            longestStreak = maxOf(newStreak, currentData.longestStreak),
            lastPlayedDate = today,
            totalDaysPlayed = currentData.totalDaysPlayed + 1
        )
        
        db.collection("users").document(userId)
            .collection("streak").document("current")
            .set(updatedData).await()
    }
    
    suspend fun recoverStreak(): Boolean {
        // Similar implementation to recordGameCompletion
        // but restores previous streak and sets lastRecoveryDate
        return true
    }
}
```

## Step 5: Leaderboard Service

Create `LeaderboardService.kt`:

```kotlin
package com.nagusamecs.pathgame.services

import com.google.firebase.database.FirebaseDatabase
import com.google.firebase.database.ktx.snapshots
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

enum class LeaderboardRegion(val displayName: String) {
    GLOBAL("Global"),
    AMERICAS("Americas"),
    EUROPE("Europe"),
    ASIA("Asia"),
    AFRICA("Africa"),
    OCEANIA("Oceania");
    
    companion object {
        fun fromCountryCode(code: String): LeaderboardRegion {
            return when (code.uppercase()) {
                // Americas
                "US", "CA", "MX", "BR", "AR", "CL", "CO", "PE", "VE" -> AMERICAS
                // Europe
                "GB", "DE", "FR", "IT", "ES", "NL", "BE", "PL", "SE", "NO", "DK", "FI", "AT", "CH", "PT", "GR", "IE", "CZ", "HU", "RO", "UA", "RU" -> EUROPE
                // Asia
                "CN", "JP", "KR", "IN", "ID", "TH", "VN", "MY", "SG", "PH", "TW", "HK", "PK", "BD" -> ASIA
                // Africa
                "ZA", "NG", "EG", "KE", "MA", "GH", "TN", "ET", "TZ" -> AFRICA
                // Oceania
                "AU", "NZ", "FJ", "PG" -> OCEANIA
                else -> GLOBAL
            }
        }
    }
}

data class LeaderboardEntry(
    val id: String = "",
    val displayName: String = "",
    val countryCode: String = "",
    val score: Int = 0,
    val pathLength: Int = 0,
    val isPerfect: Boolean = false,
    val timestamp: Long = 0
)

class LeaderboardService {
    private val rtdb = FirebaseDatabase.getInstance()
    
    fun getDailyLeaderboard(region: LeaderboardRegion): Flow<List<LeaderboardEntry>> {
        val today = java.time.LocalDate.now().toString()
        val ref = if (region == LeaderboardRegion.GLOBAL) {
            rtdb.getReference("leaderboards/daily/$today")
        } else {
            rtdb.getReference("leaderboards/daily/$today/regions/${region.name.lowercase()}")
        }
        
        return ref.orderByChild("score").limitToFirst(100).snapshots.map { snapshot ->
            snapshot.children.mapNotNull { it.getValue(LeaderboardEntry::class.java) }
        }
    }
    
    suspend fun submitScore(entry: LeaderboardEntry) {
        val today = java.time.LocalDate.now().toString()
        
        // Submit to global
        rtdb.getReference("leaderboards/daily/$today/${entry.id}").setValue(entry)
        
        // Submit to regional
        val region = LeaderboardRegion.fromCountryCode(entry.countryCode)
        rtdb.getReference("leaderboards/daily/$today/regions/${region.name.lowercase()}/${entry.id}").setValue(entry)
    }
}
```

## Step 6: AdMob Integration

### 6.1 Add AdMob App ID

In `AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"/>
```

### 6.2 Create AdService

```kotlin
package com.nagusamecs.pathgame.services

import android.app.Activity
import android.content.Context
import com.google.android.gms.ads.AdError
import com.google.android.gms.ads.AdRequest
import com.google.android.gms.ads.FullScreenContentCallback
import com.google.android.gms.ads.LoadAdError
import com.google.android.gms.ads.rewarded.RewardedAd
import com.google.android.gms.ads.rewarded.RewardedAdLoadCallback

class AdService(private val context: Context) {
    private var rewardedAd: RewardedAd? = null
    
    // Test ad unit ID - replace with real ID for production
    private val adUnitId = "ca-app-pub-3940256099942544/5224354917"
    
    fun loadRewardedAd() {
        val adRequest = AdRequest.Builder().build()
        
        RewardedAd.load(context, adUnitId, adRequest, object : RewardedAdLoadCallback() {
            override fun onAdLoaded(ad: RewardedAd) {
                rewardedAd = ad
            }
            
            override fun onAdFailedToLoad(error: LoadAdError) {
                rewardedAd = null
            }
        })
    }
    
    fun showRewardedAd(activity: Activity, onRewarded: () -> Unit) {
        rewardedAd?.let { ad ->
            ad.fullScreenContentCallback = object : FullScreenContentCallback() {
                override fun onAdDismissedFullScreenContent() {
                    rewardedAd = null
                    loadRewardedAd() // Load next ad
                }
                
                override fun onAdFailedToShowFullScreenContent(error: AdError) {
                    rewardedAd = null
                }
            }
            
            ad.show(activity) { _ ->
                onRewarded()
            }
        }
    }
    
    val isAdReady: Boolean
        get() = rewardedAd != null
}
```

## Step 7: Push Notifications

### 7.1 Create Notification Service

```kotlin
package com.nagusamecs.pathgame.services

import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import androidx.core.app.NotificationCompat
import com.nagusamecs.pathgame.R

class PathNotificationService : FirebaseMessagingService() {
    
    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }
    
    override fun onMessageReceived(message: RemoteMessage) {
        message.notification?.let { notification ->
            showNotification(notification.title ?: "", notification.body ?: "")
        }
    }
    
    override fun onNewToken(token: String) {
        // Send token to your server
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "daily_puzzle",
                "Daily Puzzle",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Notifications for daily puzzle reminders"
            }
            
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }
    
    private fun showNotification(title: String, body: String) {
        val notification = NotificationCompat.Builder(this, "daily_puzzle")
            .setSmallIcon(R.drawable.ic_launcher_foreground)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .build()
        
        val manager = getSystemService(NotificationManager::class.java)
        manager.notify(1, notification)
    }
}
```

### 7.2 Register in Manifest

```xml
<service
    android:name=".services.PathNotificationService"
    android:exported="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT"/>
    </intent-filter>
</service>
```

## Step 8: Widgets

For Android widgets, create a widget provider:

### 8.1 Create Widget Layout

`res/layout/widget_streak.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:padding="16dp"
    android:background="@drawable/widget_background">
    
    <TextView
        android:id="@+id/streak_value"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:textSize="48sp"
        android:textStyle="bold"
        android:textColor="#FF6B00" />
    
    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="day streak"
        android:textSize="14sp" />
        
</LinearLayout>
```

### 8.2 Create Widget Provider

```kotlin
package com.nagusamecs.pathgame.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import com.nagusamecs.pathgame.R

class StreakWidget : AppWidgetProvider() {
    
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }
    
    companion object {
        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences("widget_data", Context.MODE_PRIVATE)
            val streak = prefs.getInt("current_streak", 0)
            
            val views = RemoteViews(context.packageName, R.layout.widget_streak)
            views.setTextViewText(R.id.streak_value, streak.toString())
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
```

### 8.3 Register Widget in Manifest

```xml
<receiver android:name=".widgets.StreakWidget"
    android:exported="true">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE"/>
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/streak_widget_info"/>
</receiver>
```

## Step 9: Testing

1. Use test ad unit IDs during development
2. Enable Firebase debug mode: `adb shell setprop debug.firebase.analytics.app com.nagusamecs.pathgame`
3. Test on physical device for ads and notifications

## Step 10: Production Checklist

- [ ] Replace test AdMob IDs with production IDs
- [ ] Enable App Check in Firebase Console
- [ ] Set up Firebase Security Rules
- [ ] Configure Firestore indexes
- [ ] Test all regions for leaderboards
- [ ] Verify push notification topics
- [ ] Test widget updates
- [ ] Submit for Google Play review
