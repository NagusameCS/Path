//
//  ContentView.swift
//  PathGame
//
//  Main navigation and tab structure
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var gameViewModel: GameViewModel
    @EnvironmentObject var statsViewModel: StatsViewModel
    @EnvironmentObject var friendsViewModel: FriendsViewModel
    @State private var selectedTab = 0
    
    // Track if user has played today
    private var hasPlayedToday: Bool {
        gameViewModel.isGameOver || gameViewModel.pathLength > 1
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            GameView()
                .tabItem {
                    Label(L10n.navPlay, systemImage: "gamecontroller.fill")
                }
                .tag(0)
                .badge(hasPlayedToday ? 0 : 1)  // Show badge if not played today
            
            StatsView()
                .tabItem {
                    Label(L10n.navStats, systemImage: "chart.bar.fill")
                }
                .tag(1)
            
            LeaderboardView()
                .tabItem {
                    Label(L10n.leaderboardTitle, systemImage: "trophy.fill")
                }
                .tag(2)
            
            FriendsView()
                .tabItem {
                    Label(L10n.navFriends, systemImage: "person.2.fill")
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Label(L10n.navSettings, systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(.primary)
        #if os(macOS)
        .frame(minWidth: 400, minHeight: 600)
        #endif
    }
}

#Preview {
    ContentView()
        .environmentObject(GameViewModel())
        .environmentObject(StatsViewModel())
        .environmentObject(FriendsViewModel())
}
