# Firebase Setup for iOS - Path Game

This document outlines the Firebase configuration already implemented and steps to complete the setup.

## Current Implementation Status

### ✅ Completed Services

1. **FirebaseService.swift** - Firebase initialization and configuration
2. **AuthService.swift** - Sign in with Apple + anonymous auth
3. **StreakService.swift** - Daily streak tracking with weekly ad recovery
4. **LeaderboardService.swift** - Global + 5 regional leaderboards
5. **AdService.swift** - Google AdMob rewarded ads
6. **CloudSyncService.swift** - Puzzle progress sync
7. **PushNotificationService.swift** - FCM push notifications
8. **WidgetService.swift** - Widget data management

### ✅ Completed Views

1. **GlobalLeaderboardView.swift** - Regional/global leaderboard display
2. **AccountView.swift** - User profile, streak display, sign in

## Step 1: Add Swift Package Dependencies

In Xcode:
1. File → Add Package Dependencies
2. Add the following packages:

### Firebase iOS SDK
```
https://github.com/firebase/firebase-ios-sdk
```
Select these products:
- FirebaseAuth
- FirebaseFirestore
- FirebaseDatabase
- FirebaseMessaging
- FirebaseAnalytics

### Google Mobile Ads SDK
```
https://github.com/googleads/swift-package-manager-google-mobile-ads
```
Select:
- GoogleMobileAds

## Step 2: Configure Signing & Capabilities

In Xcode, select your target and add these capabilities:

### Required Capabilities
1. **Sign in with Apple** - For authentication
2. **Push Notifications** - For FCM
3. **App Groups** - For widget data sharing
   - Add group: `group.com.nagusamecs.pathgame`
4. **Background Modes**
   - Remote notifications

## Step 3: Info.plist Configuration

Add to your Info.plist:

```xml
<!-- AdMob App ID -->
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX</string>

<!-- AdMob allows user tracking (required for iOS 14+) -->
<key>NSUserTrackingUsageDescription</key>
<string>This allows us to show you personalized ads.</string>
```

## Step 4: Widget Extension Setup

### 4.1 Create Widget Target
1. File → New → Target
2. Select "Widget Extension"
3. Name: PathGameWidgets
4. Include Live Activity: No
5. Include Configuration Intent: No

### 4.2 Configure Widget Target
- Set deployment target to iOS 16.0
- Add to same App Group: `group.com.nagusamecs.pathgame`

### 4.3 Copy Widget Files
Copy the file `PathGameWidgets/PathGameWidgets.swift` to your widget target.

## Step 5: Entitlements Configuration

Ensure your `.entitlements` file includes:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>aps-environment</key>
    <string>development</string>
    <key>com.apple.developer.applesignin</key>
    <array>
        <string>Default</string>
    </array>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.nagusamecs.pathgame</string>
    </array>
</dict>
</plist>
```

## Step 6: Firebase Console Setup

### 6.1 Enable Services
1. Go to Firebase Console → Authentication
2. Enable Sign in with Apple
3. Enable Anonymous sign-in

### 6.2 Configure Firestore
Create the following collections:
- `users` - User profiles
- `users/{userId}/streak` - Streak data
- `users/{userId}/puzzles` - Puzzle progress

### 6.3 Configure Realtime Database
Structure:
```
leaderboards/
  daily/
    {date}/
      {userId}: LeaderboardEntry
      regions/
        americas/
        europe/
        asia/
        africa/
        oceania/
  weekly/
  allTime/
  streak/
```

### 6.4 Security Rules

Firestore Rules:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      match /streak/{doc} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      match /puzzles/{doc} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

Realtime Database Rules:
```json
{
  "rules": {
    "leaderboards": {
      ".read": true,
      "$type": {
        "$date": {
          "$userId": {
            ".write": "$userId === auth.uid"
          },
          "regions": {
            "$region": {
              "$userId": {
                ".write": "$userId === auth.uid"
              }
            }
          }
        }
      }
    }
  }
}
```

## Step 7: AdMob Setup

### 7.1 Create AdMob Account
1. Go to [AdMob](https://admob.google.com/)
2. Create account and verify payment info
3. Link to your bank/debit card

### 7.2 Create Ad Units
1. Create a new app for iOS
2. Create a Rewarded Ad unit for streak recovery
3. Replace test ad unit ID in `AdService.swift` with production ID

### Test Ad Unit IDs (for development):
- Rewarded: `ca-app-pub-3940256099942544/1712485313`

## Step 8: Push Notification Setup

### 8.1 Create APNs Key
1. Go to Apple Developer → Keys
2. Create a new key with Apple Push Notifications service (APNs)
3. Download the .p8 file

### 8.2 Upload to Firebase
1. Firebase Console → Project Settings → Cloud Messaging
2. Upload the APNs authentication key
3. Enter Key ID and Team ID

## Step 9: Testing Checklist

- [ ] Sign in with Apple works
- [ ] Anonymous sign-in works
- [ ] Streak increments on game completion
- [ ] Streak recovery shows after ad watch
- [ ] Leaderboard loads entries
- [ ] Regional filtering works
- [ ] Push notifications received
- [ ] Widgets display correct data
- [ ] Widget updates when game completed

## Step 10: Production Checklist

- [ ] Replace test AdMob IDs with production IDs
- [ ] Switch APNs environment to production
- [ ] Enable App Check in Firebase
- [ ] Test on physical device
- [ ] Review App Store privacy labels
- [ ] Submit app for review

## Troubleshooting

### Firebase not initializing
- Ensure `GoogleService-Info.plist` is in the correct location
- Check bundle ID matches Firebase configuration

### Ads not loading
- Verify AdMob app ID in Info.plist
- Check internet connection
- Use test ad IDs during development

### Push notifications not working
- Verify APNs key is uploaded to Firebase
- Check entitlements include `aps-environment`
- Test on physical device (not simulator)

### Widgets not updating
- Ensure App Group is configured on both targets
- Call `WidgetCenter.shared.reloadAllTimelines()` after data changes
