//
//  AccountView.swift
//  Path
//
//  User account management and streak display
//

import SwiftUI
import AuthenticationServices

struct AccountView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var streakService: StreakService
    @EnvironmentObject var adService: AdService
    @Environment(\.colorScheme) private var colorScheme
    
    private var isDarkMode: Bool { colorScheme == .dark }
    
    @State private var showingSignOut = false
    @State private var showingDeleteAccount = false
    @State private var showingRecoverySuccess = false
    
    private var backgroundColor: Color {
        isDarkMode ? Color(red: 0.1, green: 0.1, blue: 0.1) : Color(red: 0.96, green: 0.96, blue: 0.96)
    }
    
    private var primaryTextColor: Color {
        isDarkMode ? .white : Color(red: 0.1, green: 0.1, blue: 0.1)
    }
    
    private var secondaryTextColor: Color {
        isDarkMode ? Color(red: 0.53, green: 0.53, blue: 0.53) : Color(red: 0.53, green: 0.53, blue: 0.53)
    }
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    Text("ACCOUNT")
                        .font(.system(size: 20, weight: .light, design: .monospaced))
                        .foregroundColor(primaryTextColor)
                        .tracking(6)
                        .padding(.top, 16)
                    
                    // Profile Section
                    ProfileCard(isDarkMode: isDarkMode)
                    
                    // Streak Section
                    StreakCard(isDarkMode: isDarkMode)
                    
                    // Stats Summary
                    StatsSummaryCard(isDarkMode: isDarkMode)
                    
                    // Account Actions
                    AccountActionsCard(
                        showingSignOut: $showingSignOut,
                        showingDeleteAccount: $showingDeleteAccount,
                        isDarkMode: isDarkMode
                    )
                }
                .padding()
            }
        }
        .alert("Sign Out", isPresented: $showingSignOut) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                authService.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Delete Account", isPresented: $showingDeleteAccount) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await authService.deleteAccount()
                }
            }
        } message: {
            Text("This will permanently delete your account and all data. This action cannot be undone.")
        }
        .alert("Streak Recovered!", isPresented: $showingRecoverySuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your streak has been restored. Keep playing daily to maintain it!")
        }
    }
}

// MARK: - Profile Card
struct ProfileCard: View {
    @EnvironmentObject var authService: AuthService
    let isDarkMode: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            if authService.isSignedIn, let user = authService.currentUser {
                // Signed in state
                HStack(spacing: 16) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.2))
                            .frame(width: 60, height: 60)
                        
                        Text(String(user.displayName.prefix(1)).uppercased())
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(.accentColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.displayName)
                            .font(.system(size: 18, weight: .semibold, design: .monospaced))
                            .foregroundColor(primaryColor)
                        
                        Text(flag(for: user.countryCode))
                            .font(.system(size: 20))
                        
                        if user.isAnonymous {
                            Text("Anonymous Account")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Spacer()
                }
            } else {
                // Not signed in
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    
                    Text("Sign in to sync your progress")
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(.secondary)
                    
                    #if os(iOS)
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                        request.nonce = authService.prepareSignInWithApple()
                    } onCompletion: { result in
                        Task {
                            await authService.handleSignInWithApple(result: result)
                        }
                    }
                    .signInWithAppleButtonStyle(isDarkMode ? .white : .black)
                    .frame(height: 50)
                    .cornerRadius(8)
                    #else
                    // macOS: Use button to trigger Sign in with Apple
                    Button {
                        authService.signInWithApple()
                    } label: {
                        HStack {
                            Image(systemName: "applelogo")
                            Text("Sign in with Apple")
                        }
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.black)
                        .cornerRadius(8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.borderless)
                    #endif
                    
                    Button {
                        Task {
                            await authService.signInAnonymously()
                        }
                    } label: {
                        Text("Continue without account")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(12)
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

// MARK: - Streak Card
struct StreakCard: View {
    @EnvironmentObject var streakService: StreakService
    @EnvironmentObject var adService: AdService
    let isDarkMode: Bool
    
    @State private var showingRecoveryAlert = false
    @State private var isRecovering = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Streak display
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Streak")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.secondary)
                    
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(streakService.streakData?.currentStreak ?? 0)")
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundColor(.orange)
                        
                        Text("days")
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Fire icon
                VStack {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    
                    if streakService.streakData?.hasPlayedToday == true {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }
            
            Divider()
                .background(isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.1))
            
            // Streak stats
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("\(streakService.streakData?.longestStreak ?? 0)")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(.accentColor)
                    Text("Best")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("\(streakService.streakData?.totalDaysPlayed ?? 0)")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(.accentColor)
                    Text("Total Days")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Recovery info
                if streakService.canRecoverStreak {
                    VStack(spacing: 4) {
                        Text("Recovery")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                        Text("Available")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.green)
                    }
                } else if let nextRecovery = streakService.nextRecoveryAvailable {
                    VStack(spacing: 4) {
                        Text("Recovery in")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                        Text(daysUntil(nextRecovery))
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.orange)
                    }
                }
            }
            
            // Recovery button
            if streakService.canRecoverStreak && streakService.streakData?.currentStreak == 0 {
                Divider()
                    .background(isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.1))
                
                VStack(spacing: 8) {
                    Text("Lost your streak? Watch an ad to recover it!")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    #if os(iOS)
                    RewardedAdButton(
                        adService: adService,
                        buttonText: "Watch Ad to Recover Streak",
                        onReward: {
                            Task {
                                await streakService.recoverStreak()
                            }
                        }
                    )
                    #else
                    Text("Ad recovery available on iOS")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                    #endif
                }
            }
            
            // Shield section
            Divider()
                .background(isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.1))
            
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                    
                    Text("Streak Shields")
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(isDarkMode ? .white : .black)
                    
                    Spacer()
                    
                    // Shield count display
                    HStack(spacing: 4) {
                        ForEach(0..<StreakService.maxShields, id: \.self) { index in
                            Image(systemName: index < (streakService.streakData?.shields ?? 0) ? "shield.fill" : "shield")
                                .font(.system(size: 16))
                                .foregroundColor(index < (streakService.streakData?.shields ?? 0) ? .blue : .gray.opacity(0.4))
                        }
                    }
                }
                
                Text("Shields protect your streak if you miss a day. Earn shields by watching ads.")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                
                if streakService.shieldUsedToday {
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(.green)
                        Text("Shield protected your streak today!")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.green)
                    }
                }
                
                #if os(iOS)
                if streakService.canEarnShield {
                    RewardedAdButton(
                        adService: adService,
                        buttonText: "Watch Ad to Earn Shield",
                        onReward: {
                            Task {
                                await streakService.addShield()
                            }
                        }
                    )
                } else {
                    Text("Maximum shields reached (\(StreakService.maxShields)/\(StreakService.maxShields))")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                #else
                Text("Earn shields on iOS")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
                #endif
            }
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(12)
    }
    
    private var cardBackground: Color {
        isDarkMode ? Color(red: 0.15, green: 0.15, blue: 0.15) : Color.white
    }
    
    private func daysUntil(_ date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        if days <= 0 {
            return "Now"
        } else if days == 1 {
            return "1 day"
        } else {
            return "\(days) days"
        }
    }
}

// MARK: - Stats Summary Card
struct StatsSummaryCard: View {
    @EnvironmentObject var authService: AuthService
    let isDarkMode: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Statistics")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(primaryColor)
                
                Spacer()
            }
            
            if let user = authService.currentUser {
                HStack(spacing: 16) {
                    StatBox(
                        value: "\(user.totalGamesPlayed)",
                        label: "Games",
                        isDarkMode: isDarkMode
                    )
                    
                    StatBox(
                        value: "\(user.totalPerfectGames)",
                        label: "Perfect",
                        isDarkMode: isDarkMode
                    )
                    
                    StatBox(
                        value: "\(user.longestStreak)",
                        label: "Best Streak",
                        isDarkMode: isDarkMode
                    )
                }
            } else {
                Text("Sign in to track your statistics")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(12)
    }
    
    private var primaryColor: Color {
        isDarkMode ? .white : Color(red: 0.1, green: 0.1, blue: 0.1)
    }
    
    private var cardBackground: Color {
        isDarkMode ? Color(red: 0.15, green: 0.15, blue: 0.15) : Color.white
    }
}

// MARK: - Stat Box
struct StatBox: View {
    let value: String
    let label: String
    let isDarkMode: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(.accentColor)
            
            Text(label)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(statBackground)
        .cornerRadius(8)
    }
    
    private var statBackground: Color {
        isDarkMode ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color(red: 0.95, green: 0.95, blue: 0.95)
    }
}

// MARK: - Account Actions Card
struct AccountActionsCard: View {
    @EnvironmentObject var authService: AuthService
    @Binding var showingSignOut: Bool
    @Binding var showingDeleteAccount: Bool
    let isDarkMode: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            if authService.isSignedIn {
                // Sign out button
                Button(action: { showingSignOut = true }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Sign Out")
                        Spacer()
                    }
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.primary)
                    .padding()
                    .background(cardBackground)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                
                // Delete account button
                Button(action: { showingDeleteAccount = true }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete Account")
                        Spacer()
                    }
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.red)
                    .padding()
                    .background(cardBackground)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var cardBackground: Color {
        isDarkMode ? Color(red: 0.15, green: 0.15, blue: 0.15) : Color.white
    }
}

#Preview {
    AccountView()
        .environmentObject(AuthService.shared)
        .environmentObject(StreakService.shared)
        .environmentObject(AdService.shared)
}
