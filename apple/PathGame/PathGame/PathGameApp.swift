//
//  PathGameApp.swift
//  PathGame
//
//  A daily puzzle game where you find the longest path through a grid
//  Supports iOS, iPadOS, and macOS via SwiftUI
//

import SwiftUI
import GameKit

@main
struct PathGameApp: App {
    @StateObject private var gameViewModel = GameViewModel()
    @StateObject private var statsViewModel = StatsViewModel()
    @StateObject private var friendsViewModel = FriendsViewModel()
    @StateObject private var gameCenterService = GameCenterService.shared
    @StateObject private var cloudKitService = CloudKitService.shared
    
    @AppStorage("isDarkMode") private var isDarkMode = true
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showSplash = true
    
    init() {
        // Configure app appearance
        configureAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(gameViewModel)
                    .environmentObject(statsViewModel)
                    .environmentObject(friendsViewModel)
                    .environmentObject(gameCenterService)
                    .environmentObject(cloudKitService)
                    .preferredColorScheme(isDarkMode ? .dark : .light)
                    .onAppear {
                        // Authenticate Game Center
                        gameCenterService.authenticatePlayer()
                        
                        // Sync with iCloud
                        cloudKitService.syncData()
                    }
                    .opacity(showSplash ? 0 : 1)
                
                // Splash screen
                if showSplash {
                    SplashView {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showSplash = false
                        }
                        
                        // Show onboarding after splash if needed
                        if !hasSeenOnboarding {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                // Onboarding will be shown via sheet
                            }
                        }
                    }
                    .transition(.opacity)
                }
            }
            .sheet(isPresented: .constant(!hasSeenOnboarding && !showSplash)) {
                OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
            }
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 500, height: 800)
        #endif
        
        #if os(macOS)
        Settings {
            SettingsView()
                .environmentObject(gameViewModel)
                .environmentObject(statsViewModel)
        }
        #endif
    }
    
    private func configureAppearance() {
        #if os(iOS)
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        #endif
    }
}
