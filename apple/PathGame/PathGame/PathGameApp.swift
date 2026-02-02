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

// MARK: - Onboarding View
struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    @State private var currentPage = 0
    
    var body: some View {
        VStack(spacing: 30) {
            TabView(selection: $currentPage) {
                OnboardingPage(
                    icon: "square.grid.3x3",
                    title: "Find the Path",
                    description: "Build the longest possible path through the grid, starting from the center."
                )
                .tag(0)
                
                OnboardingPage(
                    icon: "arrow.up.left.and.arrow.down.right",
                    title: "Move Freely",
                    description: "Move horizontally, vertically, or diagonally to adjacent tiles."
                )
                .tag(1)
                
                OnboardingPage(
                    icon: "number",
                    title: "Follow the Numbers",
                    description: "You can only move to tiles within ±1 of your current number."
                )
                .tag(2)
                
                OnboardingPage(
                    icon: "calendar",
                    title: "Daily Challenge",
                    description: "A new puzzle every day. Compete with friends and climb the leaderboard!"
                )
                .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            
            Button(action: {
                withAnimation {
                    if currentPage < 3 {
                        currentPage += 1
                    } else {
                        hasSeenOnboarding = true
                    }
                }
            }) {
                Text(currentPage < 3 ? "Next" : "Get Started")
                    .font(.system(.headline, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
}

struct OnboardingPage: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
            
            Text(title)
                .font(.system(.title, design: .monospaced))
                .fontWeight(.bold)
            
            Text(description)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            Spacer()
        }
    }
}
