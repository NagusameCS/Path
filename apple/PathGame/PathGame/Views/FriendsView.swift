//
//  FriendsView.swift
//  PathGame
//
//  Friends list and social features
//

import SwiftUI

struct FriendsView: View {
    @EnvironmentObject var friendsViewModel: FriendsViewModel
    @EnvironmentObject var gameCenterService: GameCenterService
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("Friends", selection: $selectedTab) {
                    Text("Friends").tag(0)
                    Text("Activity").tag(1)
                    Text("Challenges").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()
                
                switch selectedTab {
                case 0:
                    FriendsListTab()
                case 1:
                    ActivityTab()
                case 2:
                    ChallengesTab()
                default:
                    EmptyView()
                }
            }
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        friendsViewModel.showingAddFriend = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await friendsViewModel.refresh()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .sheet(isPresented: $friendsViewModel.showingAddFriend) {
                AddFriendSheet()
            }
            .onAppear {
                if gameCenterService.isAuthenticated {
                    Task {
                        await friendsViewModel.loadGameCenterFriends()
                    }
                }
            }
        }
    }
}

// MARK: - Friends List Tab
struct FriendsListTab: View {
    @EnvironmentObject var friendsViewModel: FriendsViewModel
    @EnvironmentObject var gameCenterService: GameCenterService
    
    var body: some View {
        ScrollView {
            if !gameCenterService.isAuthenticated {
                GameCenterPrompt()
            } else if friendsViewModel.friends.isEmpty {
                EmptyFriendsView()
            } else {
                LazyVStack(spacing: 12) {
                    // Today's Leaderboard
                    if !friendsViewModel.todaysFriendScores.isEmpty {
                        TodaysLeaderboardSection()
                    }
                    
                    // All Friends
                    Section {
                        ForEach(friendsViewModel.activeFriends) { friend in
                            FriendRow(friend: friend)
                        }
                    } header: {
                        HStack {
                            Text("ALL FRIENDS")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct TodaysLeaderboardSection: View {
    @EnvironmentObject var friendsViewModel: FriendsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TODAY'S LEADERBOARD")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                ForEach(Array(friendsViewModel.todaysFriendScores.enumerated()), id: \.element.friend.id) { index, item in
                    HStack {
                        Text("\(index + 1)")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(index == 0 ? .yellow : .secondary)
                            .frame(width: 30)
                        
                        if index == 0 {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                                .font(.system(size: 12))
                        }
                        
                        Text(item.friend.displayName)
                            .font(.system(size: 14, design: .monospaced))
                        
                        Spacer()
                        
                        if item.score.isPerfect {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.system(size: 12))
                        }
                        
                        Text("\(item.score.percentage)%")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                    }
                    .padding()
                    .background(index == 0 ? Color.yellow.opacity(0.1) : Color.secondary.opacity(0.05))
                    .cornerRadius(8)
                }
            }
        }
        .padding(.top)
    }
}

struct FriendRow: View {
    let friend: Friend
    @EnvironmentObject var friendsViewModel: FriendsViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.secondary.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(String(friend.displayName.prefix(1)))
                        .font(.system(size: 18, weight: .medium, design: .monospaced))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.displayName)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                
                if let score = friend.lastScore {
                    Text("\(score.dateString) · \(score.percentage)%")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.secondary)
                } else {
                    Text("No recent games")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Status indicator
            Circle()
                .fill(friend.isOnline ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(12)
        .contextMenu {
            Button {
                // Challenge friend
            } label: {
                Label("Challenge", systemImage: "flag.fill")
            }
            
            Button(role: .destructive) {
                friendsViewModel.removeFriend(friend)
            } label: {
                Label("Remove", systemImage: "person.badge.minus")
            }
        }
    }
}

struct EmptyFriendsView: View {
    @EnvironmentObject var friendsViewModel: FriendsViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No friends yet")
                .font(.system(size: 18, weight: .medium, design: .monospaced))
            
            Text("Add friends to compare scores and compete on the leaderboard")
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                friendsViewModel.showingAddFriend = true
            } label: {
                Text("Add Friends")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
        .padding(.top, 50)
    }
}

struct GameCenterPrompt: View {
    @EnvironmentObject var gameCenterService: GameCenterService
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("Sign in to Game Center")
                .font(.system(size: 18, weight: .medium, design: .monospaced))
            
            Text("Connect with Game Center to add friends and compare scores")
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                gameCenterService.authenticatePlayer()
            } label: {
                Text("Sign In")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
        .padding(.top, 50)
    }
}

// MARK: - Activity Tab
struct ActivityTab: View {
    @EnvironmentObject var friendsViewModel: FriendsViewModel
    
    var body: some View {
        ScrollView {
            if friendsViewModel.friendActivities.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "bell.badge")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No recent activity")
                        .font(.system(size: 16, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 50)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(friendsViewModel.friendActivities) { activity in
                        ActivityRow(activity: activity)
                    }
                }
                .padding()
            }
        }
    }
}

struct ActivityRow: View {
    let activity: FriendActivity
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activity.icon)
                .foregroundColor(colorForActivity(activity.activityType))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.message)
                    .font(.system(size: 14, design: .monospaced))
                
                Text(timeAgo(from: activity.timestamp))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }
    
    func colorForActivity(_ type: FriendActivity.ActivityType) -> Color {
        switch type {
        case .completedPuzzle: return .blue
        case .perfectScore: return .yellow
        case .newStreak: return .orange
        case .achievement: return .purple
        }
    }
    
    func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Challenges Tab
struct ChallengesTab: View {
    @EnvironmentObject var friendsViewModel: FriendsViewModel
    
    var body: some View {
        ScrollView {
            if friendsViewModel.pendingChallenges.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No pending challenges")
                        .font(.system(size: 16, design: .monospaced))
                        .foregroundColor(.secondary)
                    
                    Text("Challenge friends after completing a puzzle")
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .padding(.top, 50)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(friendsViewModel.pendingChallenges, id: \.id) { challenge in
                        ChallengeRow(challenge: challenge)
                    }
                }
                .padding()
            }
        }
    }
}

struct ChallengeRow: View {
    let challenge: FriendChallenge
    @EnvironmentObject var friendsViewModel: FriendsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "flag.fill")
                    .foregroundColor(.orange)
                
                Text("\(challenge.fromPlayerName) challenged you!")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                
                Spacer()
            }
            
            HStack {
                Text(challenge.gridSize.displayName)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.secondary)
                
                Text("•")
                    .foregroundColor(.secondary)
                
                Text("Their score: \(challenge.challengerScore)/\(challenge.challengerOptimal)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 12) {
                Button {
                    // Accept challenge
                } label: {
                    Text("Accept")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                
                Button {
                    friendsViewModel.declineChallenge(challenge)
                } label: {
                    Text("Decline")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Add Friend Sheet
struct AddFriendSheet: View {
    @EnvironmentObject var friendsViewModel: FriendsViewModel
    @EnvironmentObject var gameCenterService: GameCenterService
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if gameCenterService.isAuthenticated {
                    Text("Friends from Game Center will appear automatically")
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                    
                    Button {
                        gameCenterService.showGameCenterDashboard()
                    } label: {
                        HStack {
                            Image(systemName: "gamecontroller.fill")
                            Text("Open Game Center")
                        }
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 30)
                } else {
                    GameCenterPrompt()
                }
                
                Spacer()
            }
            .padding(.top, 30)
            .navigationTitle("Add Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    FriendsView()
        .environmentObject(FriendsViewModel())
        .environmentObject(GameCenterService.shared)
}
