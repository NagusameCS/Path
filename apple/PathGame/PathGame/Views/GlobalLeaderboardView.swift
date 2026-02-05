//
//  GlobalLeaderboardView.swift
//  Path
//
//  Global and regional leaderboards
//

import SwiftUI

struct GlobalLeaderboardView: View {
    @EnvironmentObject var leaderboardService: LeaderboardService
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var gameViewModel: GameViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    private var isDarkMode: Bool { colorScheme == .dark }
    
    @State private var selectedType: LeaderboardType = .daily
    
    private var backgroundColor: Color {
        isDarkMode ? Color(red: 0.1, green: 0.1, blue: 0.1) : Color(red: 0.96, green: 0.96, blue: 0.96)
    }
    
    private var primaryTextColor: Color {
        isDarkMode ? .white : Color(red: 0.1, green: 0.1, blue: 0.1)
    }
    
    private var secondaryTextColor: Color {
        isDarkMode ? Color(red: 0.53, green: 0.53, blue: 0.53) : Color(red: 0.53, green: 0.53, blue: 0.53)
    }
    
    private var cardBackground: Color {
        isDarkMode ? Color(red: 0.14, green: 0.14, blue: 0.14) : Color.white
    }
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                Text("LEADERBOARD")
                    .font(.system(size: 20, weight: .light, design: .monospaced))
                    .foregroundColor(primaryTextColor)
                    .tracking(6)
                    .padding(.top, 16)
                
                // Type Picker (custom styled)
                HStack(spacing: 0) {
                    ForEach(LeaderboardType.allCases, id: \.self) { type in
                        Button {
                            selectedType = type
                        } label: {
                            Text(type.displayName.uppercased())
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(selectedType == type ? primaryTextColor : secondaryTextColor)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 12)
                                .background(selectedType == type ? cardBackground : Color.clear)
                                .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(4)
                .background(isDarkMode ? Color(red: 0.08, green: 0.08, blue: 0.08) : Color(red: 0.92, green: 0.92, blue: 0.92))
                .cornerRadius(6)
                
                // Leaderboard Content
                if leaderboardService.isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                    Spacer()
                } else {
                    LeaderboardList(
                        type: selectedType,
                        isDarkMode: isDarkMode
                    )
                }
            }
        }
        .onChange(of: selectedType) { _, newValue in
            Task {
                await leaderboardService.loadLeaderboard(type: newValue, region: .global)
            }
        }
        .task {
            // Submit any pending scores if user signed in after completing games
            if authService.isSignedIn {
                await gameViewModel.submitPendingScores()
            }
            await leaderboardService.loadLeaderboard(type: selectedType, region: .global)
        }
    }
}

// MARK: - Region Button
struct RegionButton: View {
    let region: LeaderboardRegion
    let isSelected: Bool
    let isDarkMode: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(region.displayName)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(isSelected ? .white : secondaryColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : buttonBackground)
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
    
    private var secondaryColor: Color {
        isDarkMode ? Color(red: 0.6, green: 0.6, blue: 0.6) : Color(red: 0.4, green: 0.4, blue: 0.4)
    }
    
    private var buttonBackground: Color {
        isDarkMode ? Color(red: 0.17, green: 0.17, blue: 0.17) : Color.white
    }
}

// MARK: - Leaderboard List
struct LeaderboardList: View {
    @EnvironmentObject var leaderboardService: LeaderboardService
    @EnvironmentObject var authService: AuthService
    let type: LeaderboardType
    let isDarkMode: Bool
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                // User's rank card (if applicable)
                if let rank = leaderboardService.userRank {
                    UserRankCard(rank: rank, isDarkMode: isDarkMode)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
                
                // Leaderboard entries
                switch type {
                case .daily:
                    ForEach(Array(leaderboardService.dailyLeaderboard.enumerated()), id: \.element.id) { index, entry in
                        DailyLeaderboardRow(entry: entry, rank: index + 1, isDarkMode: isDarkMode)
                    }
                case .weekly, .allTime:
                    let entries = type == .weekly ? leaderboardService.weeklyLeaderboard : leaderboardService.allTimeLeaderboard
                    ForEach(entries) { entry in
                        StatsLeaderboardRow(entry: entry, isDarkMode: isDarkMode)
                    }
                case .streak:
                    ForEach(leaderboardService.streakLeaderboard) { entry in
                        StreakLeaderboardRow(entry: entry, isDarkMode: isDarkMode)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
}

// MARK: - User Rank Card
struct UserRankCard: View {
    let rank: Int
    let isDarkMode: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Rank")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.secondary)
                
                Text("#\(rank)")
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(.accentColor)
            }
            
            Spacer()
            
            Image(systemName: rankIcon)
                .font(.system(size: 40))
                .foregroundColor(rankColor)
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var rankIcon: String {
        switch rank {
        case 1: return "crown.fill"
        case 2, 3: return "medal.fill"
        case 4...10: return "star.fill"
        default: return "person.fill"
        }
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return Color(white: 0.75)
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return .accentColor
        }
    }
    
    private var cardBackground: Color {
        isDarkMode ? Color(red: 0.15, green: 0.15, blue: 0.15) : Color.white
    }
}

// MARK: - Daily Leaderboard Row
struct DailyLeaderboardRow: View {
    let entry: LeaderboardEntry
    let rank: Int
    let isDarkMode: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank
            RankBadge(rank: rank)
            
            // Country flag
            Text(flag(for: entry.countryCode))
                .font(.system(size: 20))
            
            // Name
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayName)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(primaryColor)
                
                HStack(spacing: 4) {
                    Text("\(entry.pathLength) moves")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                    
                    if entry.isPerfect {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                    }
                }
            }
            
            Spacer()
            
            // Score
            Text("\(entry.score)")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(.accentColor)
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(8)
    }
    
    private var primaryColor: Color {
        isDarkMode ? .white : Color(red: 0.1, green: 0.1, blue: 0.1)
    }
    
    private var cardBackground: Color {
        isDarkMode ? Color(red: 0.15, green: 0.15, blue: 0.15) : Color.white
    }
    
    private func flag(for countryCode: String) -> String {
        let base: UInt32 = 127397
        var flag = ""
        for scalar in countryCode.uppercased().unicodeScalars {
            if let scalar = UnicodeScalar(base + scalar.value) {
                flag.append(Character(scalar))
            }
        }
        return flag
    }
}

// MARK: - Stats Leaderboard Row
struct StatsLeaderboardRow: View {
    let entry: LeaderboardStats
    let isDarkMode: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank
            if let rank = entry.rank {
                RankBadge(rank: rank)
            }
            
            // Country flag
            Text(flag(for: entry.countryCode))
                .font(.system(size: 20))
            
            // Name
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayName)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(primaryColor)
                
                Text("\(entry.gamesPlayed) games • \(entry.perfectGames) perfect")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Total Score
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.totalScore)")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.accentColor)
                
                Text("total")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(8)
    }
    
    private var primaryColor: Color {
        isDarkMode ? .white : Color(red: 0.1, green: 0.1, blue: 0.1)
    }
    
    private var cardBackground: Color {
        isDarkMode ? Color(red: 0.15, green: 0.15, blue: 0.15) : Color.white
    }
    
    private func flag(for countryCode: String) -> String {
        let base: UInt32 = 127397
        var flag = ""
        for scalar in countryCode.uppercased().unicodeScalars {
            if let scalar = UnicodeScalar(base + scalar.value) {
                flag.append(Character(scalar))
            }
        }
        return flag
    }
}

// MARK: - Streak Leaderboard Row
struct StreakLeaderboardRow: View {
    let entry: LeaderboardStats
    let isDarkMode: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank
            if let rank = entry.rank {
                RankBadge(rank: rank)
            }
            
            // Fire icon for streaks
            Image(systemName: "flame.fill")
                .font(.system(size: 20))
                .foregroundColor(.orange)
            
            // Name
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayName)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(primaryColor)
                
                Text(flag(for: entry.countryCode))
                    .font(.system(size: 14))
            }
            
            Spacer()
            
            // Streak
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.longestStreak)")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(.orange)
                
                Text("longest streak")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(8)
    }
    
    private var primaryColor: Color {
        isDarkMode ? .white : Color(red: 0.1, green: 0.1, blue: 0.1)
    }
    
    private var cardBackground: Color {
        isDarkMode ? Color(red: 0.15, green: 0.15, blue: 0.15) : Color.white
    }
    
    private func flag(for countryCode: String) -> String {
        let base: UInt32 = 127397
        var flag = ""
        for scalar in countryCode.uppercased().unicodeScalars {
            if let scalar = UnicodeScalar(base + scalar.value) {
                flag.append(Character(scalar))
            }
        }
        return flag
    }
}

// MARK: - Rank Badge
struct RankBadge: View {
    let rank: Int
    
    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: 32, height: 32)
            
            if rank <= 3 {
                Image(systemName: iconName)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
            } else {
                Text("\(rank)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
        }
    }
    
    private var backgroundColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return Color(white: 0.7)
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return Color(red: 0.3, green: 0.3, blue: 0.3)
        }
    }
    
    private var iconName: String {
        rank == 1 ? "crown.fill" : "medal.fill"
    }
    
    private var iconColor: Color {
        rank == 1 ? .orange : .white
    }
}

#Preview {
    GlobalLeaderboardView()
        .environmentObject(LeaderboardService.shared)
        .environmentObject(AuthService.shared)
}
