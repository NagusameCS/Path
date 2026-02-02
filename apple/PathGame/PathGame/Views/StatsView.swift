//
//  StatsView.swift
//  PathGame
//
//  Statistics and achievements display
//

import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject var statsViewModel: StatsViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Tab Picker
                    Picker(L10n.navStats, selection: $selectedTab) {
                        Text(L10n.statsOverview).tag(0)
                        Text(L10n.statsAchievements).tag(1)
                        Text(L10n.statsHistory).tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    switch selectedTab {
                    case 0:
                        OverviewTab()
                    case 1:
                        AchievementsTab()
                    case 2:
                        HistoryTab()
                    default:
                        EmptyView()
                    }
                }
                .padding(.top)
            }
            .navigationTitle(L10n.navStats)
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Overview Tab
struct OverviewTab: View {
    @EnvironmentObject var statsViewModel: StatsViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Main Stats Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                StatCard(title: L10n.statsGamesPlayed, value: "\(statsViewModel.totalGamesPlayed)", icon: "gamecontroller.fill", color: .blue)
                StatCard(title: L10n.statsPerfectGames, value: "\(statsViewModel.totalPerfectGames)", icon: "star.fill", color: .yellow)
                StatCard(title: L10n.statsCurrentStreak, value: "\(statsViewModel.currentStreak)", icon: "flame.fill", color: .orange)
                StatCard(title: L10n.statsBestStreak, value: "\(statsViewModel.longestStreak)", icon: "crown.fill", color: .purple)
            }
            .padding(.horizontal)
            
            // Performance Chart
            if !statsViewModel.scoreDistribution.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.statsScoreDistribution.uppercased())
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    DistributionChart(data: statsViewModel.scoreDistribution)
                        .frame(height: 200)
                        .padding(.horizontal)
                }
            }
            
            // Grid-specific stats
            VStack(spacing: 16) {
                GridStatsCard(title: L10n.gameSize5x5, stats: statsViewModel.stats.stats5x5)
                GridStatsCard(title: L10n.gameSize7x7, stats: statsViewModel.stats.stats7x7)
            }
            .padding(.horizontal)
            
            // Average Score
            VStack(spacing: 8) {
                Text(L10n.statsAverageScore.uppercased())
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.secondary)
                
                Text(String(format: "%.1f%%", statsViewModel.averageScore))
                    .font(.system(size: 48, weight: .light, design: .monospaced))
                
                ProgressView(value: statsViewModel.averageScore / 100)
                    .tint(.blue)
                    .padding(.horizontal, 50)
            }
            .padding(.vertical)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            HStack {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                Spacer()
            }
            
            HStack {
                Text(title)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
}

struct GridStatsCard: View {
    let title: String
    let stats: GridStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
            
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("\(stats.gamesPlayed)")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                    Text(L10n.statsGames)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading) {
                    Text("\(stats.perfectGames)")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                    Text(L10n.statsPerfect)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading) {
                    Text(String(format: "%.0f%%", stats.averagePercentage))
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                    Text(L10n.statsAvg)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
}

struct DistributionChart: View {
    let data: [String: Int]
    
    var sortedData: [(String, Int)] {
        let order = ["Perfect", "90-99%", "70-89%", "50-69%", "<50%"]
        return order.compactMap { key in
            data[key].map { (key, $0) }
        }
    }
    
    var body: some View {
        Chart {
            ForEach(sortedData, id: \.0) { item in
                BarMark(
                    x: .value("Category", item.0),
                    y: .value("Count", item.1)
                )
                .foregroundStyle(colorForCategory(item.0))
                .cornerRadius(4)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }
    
    func colorForCategory(_ category: String) -> Color {
        switch category {
        case "Perfect": return .green
        case "90-99%": return .blue
        case "70-89%": return .yellow
        case "50-69%": return .orange
        default: return .red
        }
    }
}

// MARK: - Achievements Tab
struct AchievementsTab: View {
    @EnvironmentObject var statsViewModel: StatsViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Progress
            VStack(spacing: 8) {
                Text(L10n.statsAchievementProgress.uppercased())
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("\(statsViewModel.unlockedAchievements.count)")
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                    Text("/")
                        .font(.system(size: 24, design: .monospaced))
                        .foregroundColor(.secondary)
                    Text("\(statsViewModel.achievements.count)")
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: statsViewModel.achievementProgress / 100)
                    .tint(.purple)
                    .padding(.horizontal, 50)
            }
            .padding(.bottom)
            
            // Category filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    CategoryButton(title: L10n.statsAll, isSelected: statsViewModel.selectedCategory == nil) {
                        statsViewModel.selectedCategory = nil
                    }
                    
                    ForEach(AchievementCategory.allCases, id: \.self) { category in
                        CategoryButton(title: category.rawValue, isSelected: statsViewModel.selectedCategory == category) {
                            statsViewModel.selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Achievements list
            LazyVStack(spacing: 12) {
                ForEach(statsViewModel.filteredAchievements) { achievement in
                    AchievementRow(achievement: achievement)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.purple : Color.secondary.opacity(0.1))
                .cornerRadius(20)
        }
    }
}

struct AchievementRow: View {
    let achievement: Achievement
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? Color.yellow.opacity(0.2) : Color.secondary.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 20))
                    .foregroundColor(achievement.isUnlocked ? .yellow : .secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(achievement.isUnlocked ? .primary : .secondary)
                
                Text(achievement.description)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.secondary)
                
                if !achievement.isUnlocked && achievement.requirement > 1 {
                    ProgressView(value: achievement.progressPercentage / 100)
                        .tint(.purple)
                }
            }
            
            Spacer()
            
            if achievement.isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(12)
        .opacity(achievement.isUnlocked ? 1 : 0.7)
    }
}

// MARK: - History Tab
struct HistoryTab: View {
    @EnvironmentObject var statsViewModel: StatsViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            if statsViewModel.stats.dailyHistory.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text(L10n.statsNoHistory)
                        .font(.system(size: 16, design: .monospaced))
                        .foregroundColor(.secondary)
                    
                    Text(L10n.statsCompleteToSeeHistory)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .padding(.top, 50)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(statsViewModel.stats.dailyHistory) { result in
                        HistoryRow(result: result)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct HistoryRow: View {
    let result: DailyResult
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(result.dateString)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                
                Text(result.gridSize.displayName)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    if result.isPerfect {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 12))
                    }
                    
                    Text("\(result.score)/\(result.optimal)")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                }
                
                Text("\(result.percentage)%")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(colorForPercentage(result.percentage))
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }
    
    func colorForPercentage(_ percentage: Int) -> Color {
        switch percentage {
        case 100: return .green
        case 90...99: return .blue
        case 70...89: return .yellow
        default: return .secondary
        }
    }
}

#Preview {
    StatsView()
        .environmentObject(StatsViewModel())
}
