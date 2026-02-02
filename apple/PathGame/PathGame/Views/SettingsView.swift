//
//  SettingsView.swift
//  PathGame
//
//  App settings and preferences
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var gameCenterService: GameCenterService
    @AppStorage("hapticFeedback") private var hapticFeedback = true
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("dailyReminder") private var dailyReminder = false
    @AppStorage("reminderTime") private var reminderTimeData = Date().timeIntervalSince1970
    @AppStorage("defaultGridSize") private var defaultGridSize = "5x5"
    @AppStorage("showOptimalHint") private var showOptimalHint = true
    @AppStorage("colorTheme") private var colorTheme = "system"
    @AppStorage("highContrastMode") private var highContrastMode = false
    
    @State private var showingResetAlert = false
    @State private var showingAbout = false
    @State private var showingHelp = false
    
    private var reminderTime: Binding<Date> {
        Binding(
            get: { Date(timeIntervalSince1970: reminderTimeData) },
            set: { reminderTimeData = $0.timeIntervalSince1970 }
        )
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Game Center Section
                Section {
                    if gameCenterService.isAuthenticated {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(L10n.settingsSignedIn(gameCenterService.playerName))
                                .font(.system(size: 14, design: .monospaced))
                        }
                        
                        Button {
                            gameCenterService.showGameCenterDashboard()
                        } label: {
                            HStack {
                                Text(L10n.settingsGameCenterDashboard)
                                    .font(.system(size: 14, design: .monospaced))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        HStack {
                            Image(systemName: "exclamationmark.circle")
                                .foregroundColor(.yellow)
                            Text(L10n.settingsNotSignedIn)
                                .font(.system(size: 14, design: .monospaced))
                        }
                        
                        Button {
                            gameCenterService.authenticatePlayer()
                        } label: {
                            Text(L10n.friendsSignIn)
                                .font(.system(size: 14, design: .monospaced))
                        }
                    }
                } header: {
                    Label(L10n.settingsGameCenter, systemImage: "gamecontroller.fill")
                }
                
                // Game Preferences Section
                Section {
                    Picker(L10n.settingsDefaultGrid, selection: $defaultGridSize) {
                        Text("5×5").tag("5x5")
                        Text("7×7").tag("7x7")
                    }
                    .font(.system(size: 14, design: .monospaced))
                    
                    Toggle(isOn: $showOptimalHint) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L10n.settingsShowOptimal)
                                .font(.system(size: 14, design: .monospaced))
                            Text(L10n.settingsShowOptimalDesc)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Label(L10n.settingsGame, systemImage: "puzzlepiece.fill")
                }
                
                // Feedback Section
                Section {
                    Toggle(isOn: $hapticFeedback) {
                        HStack {
                            Image(systemName: "hand.tap.fill")
                                .foregroundColor(.blue)
                            Text(L10n.settingsHaptic)
                                .font(.system(size: 14, design: .monospaced))
                        }
                    }
                    
                    Toggle(isOn: $soundEnabled) {
                        HStack {
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundColor(.blue)
                            Text(L10n.settingsSound)
                                .font(.system(size: 14, design: .monospaced))
                        }
                    }
                } header: {
                    Label(L10n.settingsFeedback, systemImage: "bell.fill")
                }
                
                // Notifications Section
                Section {
                    Toggle(isOn: $dailyReminder) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L10n.settingsDailyReminder)
                                .font(.system(size: 14, design: .monospaced))
                            Text(L10n.settingsDailyReminderDesc)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                    .onChange(of: dailyReminder) { _, newValue in
                        if newValue {
                            NotificationService.shared.requestPermission()
                            NotificationService.shared.scheduleReminder(at: reminderTime.wrappedValue)
                        } else {
                            NotificationService.shared.cancelAllNotifications()
                        }
                    }
                    
                    if dailyReminder {
                        DatePicker(L10n.settingsReminderTime, selection: reminderTime, displayedComponents: .hourAndMinute)
                            .font(.system(size: 14, design: .monospaced))
                            .onChange(of: reminderTimeData) { _, _ in
                                NotificationService.shared.scheduleReminder(at: reminderTime.wrappedValue)
                            }
                    }
                } header: {
                    Label(L10n.settingsNotifications, systemImage: "bell.badge.fill")
                }
                
                // Appearance Section
                Section {
                    Picker(L10n.settingsTheme, selection: $colorTheme) {
                        Text(L10n.settingsThemeSystem).tag("system")
                        Text(L10n.settingsThemeLight).tag("light")
                        Text(L10n.settingsThemeDark).tag("dark")
                    }
                    .font(.system(size: 14, design: .monospaced))
                    
                    Toggle(isOn: $highContrastMode) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L10n.settingsHighContrast)
                                .font(.system(size: 14, design: .monospaced))
                            Text(L10n.settingsHighContrastDesc)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Label(L10n.settingsAppearance, systemImage: "paintbrush.fill")
                }
                
                // Data Section
                Section {
                    Button {
                        // Sync now
                    } label: {
                        HStack {
                            Text(L10n.settingsSyncNow)
                                .font(.system(size: 14, design: .monospaced))
                            Spacer()
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(role: .destructive) {
                        showingResetAlert = true
                    } label: {
                        HStack {
                            Text(L10n.settingsResetStats)
                                .font(.system(size: 14, design: .monospaced))
                            Spacer()
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                } header: {
                    Label(L10n.settingsData, systemImage: "externaldrive.fill")
                }
                
                // About Section
                Section {
                    Button {
                        showingHelp = true
                    } label: {
                        HStack {
                            Text(L10n.settingsHowToPlay)
                                .font(.system(size: 14, design: .monospaced))
                            Spacer()
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button {
                        showingAbout = true
                    } label: {
                        HStack {
                            Text(L10n.settingsAboutPath)
                                .font(.system(size: 14, design: .monospaced))
                            Spacer()
                            Image(systemName: "info.circle")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Link(destination: URL(string: "https://nagusamecs.com")!) {
                        HStack {
                            Text(L10n.settingsVisitWebsite)
                                .font(.system(size: 14, design: .monospaced))
                            Spacer()
                            Image(systemName: "safari")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Label(L10n.settingsAbout, systemImage: "info.circle.fill")
                }
                
                // Footer
                Section {
                    VStack(spacing: 8) {
                        Text(L10n.appName)
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                        Text(L10n.settingsVersion("1.0.0"))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                        Text("© 2024 Nagusamecs")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle(L10n.navSettings)
            .navigationBarTitleDisplayMode(.large)
            .alert(L10n.resetTitle, isPresented: $showingResetAlert) {
                Button(L10n.resetCancel, role: .cancel) {}
                Button(L10n.resetConfirm, role: .destructive) {
                    // Reset stats
                }
            } message: {
                Text(L10n.resetMessage)
            }
            .sheet(isPresented: $showingAbout) {
                AboutSheet()
            }
            .sheet(isPresented: $showingHelp) {
                HelpView()
            }
        }
    }
}

// MARK: - About Sheet
struct AboutSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    // App Icon
                    RoundedRectangle(cornerRadius: 24)
                        .fill(LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Text("P")
                                .font(.system(size: 48, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                        )
                    
                    VStack(spacing: 8) {
                        Text("Path")
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                        
                        Text("A Daily Puzzle Game")
                            .font(.system(size: 16, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                        .padding(.horizontal, 60)
                    
                    VStack(spacing: 16) {
                        Text("Find the longest path through the grid, starting from the center. Move to adjacent cells with values within ±1 of your current cell.")
                            .font(.system(size: 14, design: .monospaced))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                        
                        Text("A new puzzle every day!")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.blue)
                    }
                    
                    Divider()
                        .padding(.horizontal, 60)
                    
                    VStack(spacing: 12) {
                        InfoRow(icon: "person.fill", title: "Created by", value: "Nagusamecs")
                        InfoRow(icon: "swift", title: "Built with", value: "SwiftUI")
                        InfoRow(icon: "globe", title: "Website", value: "nagusamecs.com")
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer(minLength: 50)
                }
                .padding(.top, 30)
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, design: .monospaced))
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(GameCenterService.shared)
}
