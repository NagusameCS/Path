//
//  LeaderboardView.swift
//  PathGame
//
//  Game Center leaderboards
//

import SwiftUI
import GameKit

struct LeaderboardView: View {
    @EnvironmentObject var gameCenterService: GameCenterService
    @State private var selectedLeaderboard = 0
    @State private var selectedTimeScope = GKLeaderboard.TimeScope.allTime
    @State private var entries: [LeaderboardEntry] = []
    @State private var isLoading = false
    @State private var playerRank: Int? = nil
    @State private var playerScore: Int? = nil
    
    let leaderboards = [
        ("5x5 Best", "com.nagusamecs.pathgame.leaderboard.5x5"),
        ("7x7 Best", "com.nagusamecs.pathgame.leaderboard.7x7"),
        ("Streak", "com.nagusamecs.pathgame.leaderboard.streak"),
        ("Perfects", "com.nagusamecs.pathgame.leaderboard.perfects")
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !gameCenterService.isAuthenticated {
                    NotSignedInView()
                } else {
                    // Leaderboard Picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(leaderboards.enumerated()), id: \.offset) { index, board in
                                LeaderboardTab(
                                    title: board.0,
                                    isSelected: selectedLeaderboard == index
                                ) {
                                    selectedLeaderboard = index
                                    Task { await loadLeaderboard() }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 12)
                    
                    // Time Scope Picker
                    Picker("Time", selection: $selectedTimeScope) {
                        Text("Today").tag(GKLeaderboard.TimeScope.today)
                        Text("Week").tag(GKLeaderboard.TimeScope.week)
                        Text("All Time").tag(GKLeaderboard.TimeScope.allTime)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .onChange(of: selectedTimeScope) { _, _ in
                        Task { await loadLeaderboard() }
                    }
                    
                    // Your Rank Banner
                    if let rank = playerRank, let score = playerScore {
                        PlayerRankBanner(rank: rank, score: score)
                    }
                    
                    // Leaderboard List
                    if isLoading {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.2)
                        Spacer()
                    } else if entries.isEmpty {
                        EmptyLeaderboardView()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                                    LeaderboardEntryRow(entry: entry, rank: index + 1)
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        gameCenterService.showGameCenterDashboard()
                    } label: {
                        Image(systemName: "gamecontroller.fill")
                    }
                }
            }
            .onAppear {
                if gameCenterService.isAuthenticated {
                    Task { await loadLeaderboard() }
                }
            }
        }
    }
    
    func loadLeaderboard() async {
        isLoading = true
        defer { isLoading = false }
        
        // Simulated data - in real implementation, use GKLeaderboard
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        entries = (1...25).map { i in
            LeaderboardEntry(
                id: UUID().uuidString,
                playerName: "Player \(i)",
                score: max(100 - i * 3, 10),
                isCurrentPlayer: i == 5
            )
        }
        
        playerRank = 5
        playerScore = 85
    }
}

struct LeaderboardEntry: Identifiable {
    let id: String
    let playerName: String
    let score: Int
    var isCurrentPlayer: Bool = false
}

struct LeaderboardTab: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .bold : .regular, design: .monospaced))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.blue : Color.secondary.opacity(0.1))
                )
        }
    }
}

struct PlayerRankBanner: View {
    let rank: Int
    let score: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Rank")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.secondary)
                HStack(spacing: 8) {
                    Text("#\(rank)")
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text("\(score)%")
                        .font(.system(size: 18, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: rankIcon(for: rank))
                .font(.system(size: 28))
                .foregroundColor(rankColor(for: rank))
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    func rankIcon(for rank: Int) -> String {
        switch rank {
        case 1: return "crown.fill"
        case 2...3: return "medal.fill"
        case 4...10: return "star.fill"
        default: return "person.fill"
        }
    }
    
    func rankColor(for rank: Int) -> Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .blue
        }
    }
}

struct LeaderboardEntryRow: View {
    let entry: LeaderboardEntry
    let rank: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank
            ZStack {
                if rank <= 3 {
                    Circle()
                        .fill(rankColor(for: rank))
                        .frame(width: 36, height: 36)
                } else {
                    Circle()
                        .fill(Color.secondary.opacity(0.1))
                        .frame(width: 36, height: 36)
                }
                
                if rank == 1 {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                } else {
                    Text("\(rank)")
                        .font(.system(size: 14, weight: rank <= 3 ? .bold : .medium, design: .monospaced))
                        .foregroundColor(rank <= 3 ? .white : .primary)
                }
            }
            
            // Player name
            Text(entry.playerName)
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(entry.isCurrentPlayer ? .blue : .primary)
            
            if entry.isCurrentPlayer {
                Text("YOU")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue)
                    .cornerRadius(4)
            }
            
            Spacer()
            
            // Score
            Text("\(entry.score)%")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(entry.isCurrentPlayer ? Color.blue.opacity(0.1) : Color.secondary.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(entry.isCurrentPlayer ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
    
    func rankColor(for rank: Int) -> Color {
        switch rank {
        case 1: return .yellow
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.8)
        case 3: return .orange
        default: return .clear
        }
    }
}

struct NotSignedInView: View {
    @EnvironmentObject var gameCenterService: GameCenterService
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "trophy.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Sign in to Game Center")
                .font(.system(size: 20, weight: .bold, design: .monospaced))
            
            Text("View leaderboards and compete with players worldwide")
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                gameCenterService.authenticatePlayer()
            } label: {
                HStack {
                    Image(systemName: "gamecontroller.fill")
                    Text("Sign In")
                }
                .font(.system(size: 16, design: .monospaced))
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(Color.blue)
                .cornerRadius(12)
            }
            
            Spacer()
        }
    }
}

struct EmptyLeaderboardView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "list.number")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No entries yet")
                .font(.system(size: 16, design: .monospaced))
                .foregroundColor(.secondary)
            
            Text("Be the first to set a score!")
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(.secondary.opacity(0.7))
            
            Spacer()
        }
    }
}

#Preview {
    LeaderboardView()
        .environmentObject(GameCenterService.shared)
}
