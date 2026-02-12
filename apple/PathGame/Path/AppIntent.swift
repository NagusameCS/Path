//
//  PathWidgets.swift
//  PathWidgets
//
//  Widget extension for streak and leaderboard tracking
//

import WidgetKit
import SwiftUI

// MARK: - Shared Data
struct WidgetData: Codable {
    var currentStreak: Int
    var longestStreak: Int
    var hasPlayedToday: Bool
    var leaderboardRank: Int?
    var totalScore: Int
    var shields: Int
    var lastUpdated: Date
    
    static var placeholder: WidgetData {
        WidgetData(
            currentStreak: 7,
            longestStreak: 14,
            hasPlayedToday: true,
            leaderboardRank: 42,
            totalScore: 1250,
            shields: 2,
            lastUpdated: Date()
        )
    }
    
    static func load() -> WidgetData {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.nagusamecs.pathgame"),
              let data = sharedDefaults.data(forKey: "widgetData"),
              let widgetData = try? JSONDecoder().decode(WidgetData.self, from: data) else {
            return .placeholder
        }
        return widgetData
    }
}

// MARK: - Timeline Provider
struct PathTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> PathEntry {
        PathEntry(date: Date(), data: .placeholder)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (PathEntry) -> Void) {
        let entry = PathEntry(date: Date(), data: WidgetData.load())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<PathEntry>) -> Void) {
        let currentDate = Date()
        let entry = PathEntry(date: currentDate, data: WidgetData.load())
        
        // Update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct PathEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

// MARK: - Streak Widget
struct StreakWidget: Widget {
    let kind: String = "StreakWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PathTimelineProvider()) { entry in
            StreakWidgetView(entry: entry)
        }
        .configurationDisplayName("Path Streak")
        .description("Track your daily puzzle streak")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct StreakWidgetView: View {
    var entry: PathEntry
    
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallStreakView(data: entry.data)
        case .systemMedium:
            MediumStreakView(data: entry.data)
        default:
            SmallStreakView(data: entry.data)
        }
    }
}

struct SmallStreakView: View {
    let data: WidgetData
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.orange)
                Spacer()
                
                // Shields display
                if data.shields > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                        Text("\(data.shields)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.blue)
                    }
                }
                
                if data.hasPlayedToday {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 16))
                } else {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 16))
                }
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text("\(data.currentStreak)")
                    .font(.system(size: 44, weight: .bold, design: .monospaced))
                    .foregroundColor(.orange)
                
                Text("day streak")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("Best: \(data.longestStreak)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct MediumStreakView: View {
    let data: WidgetData
    
    var body: some View {
        HStack(spacing: 16) {
            // Streak section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(data.currentStreak)")
                            .font(.system(size: 36, weight: .bold, design: .monospaced))
                            .foregroundColor(.orange)
                        
                        Text("day streak")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Best")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                        Text("\(data.longestStreak)")
                            .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Shields")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                        HStack(spacing: 2) {
                            Image(systemName: "shield.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.blue)
                            Text("\(data.shields)")
                                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Today status
            VStack {
                Spacer()
                
                if data.hasPlayedToday {
                    VStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.green)
                        
                        Text("Played!")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.green)
                    }
                } else {
                    VStack(spacing: 4) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.accentColor)
                        
                        Text("Play now")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.accentColor)
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Leaderboard Widget
struct LeaderboardWidget: Widget {
    let kind: String = "LeaderboardWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PathTimelineProvider()) { entry in
            LeaderboardWidgetView(entry: entry)
        }
        .configurationDisplayName("Path Rank")
        .description("See your leaderboard ranking")
        .supportedFamilies([.systemSmall])
    }
}

struct LeaderboardWidgetView: View {
    var entry: PathEntry
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 18))
                
                Spacer()
                
                Text("Global")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let rank = entry.data.leaderboardRank {
                VStack(spacing: 2) {
                    Text("#\(rank)")
                        .font(.system(size: 40, weight: .bold, design: .monospaced))
                        .foregroundColor(.accentColor)
                    
                    Text("your rank")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(spacing: 4) {
                    Text("—")
                        .font(.system(size: 40, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                    
                    Text("Not ranked")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text("\(entry.data.totalScore) pts")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Widget Bundle
@main
struct PathWidgetBundle: WidgetBundle {
    var body: some Widget {
        StreakWidget()
        LeaderboardWidget()
    }
}

#Preview(as: .systemSmall) {
    StreakWidget()
} timeline: {
    PathEntry(date: Date(), data: .placeholder)
}

#Preview(as: .systemMedium) {
    StreakWidget()
} timeline: {
    PathEntry(date: Date(), data: .placeholder)
}

#Preview(as: .systemSmall) {
    LeaderboardWidget()
} timeline: {
    PathEntry(date: Date(), data: .placeholder)
}
