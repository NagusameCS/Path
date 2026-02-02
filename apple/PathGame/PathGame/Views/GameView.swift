//
//  GameView.swift
//  PathGame
//
//  Main game screen with grid and controls
//

import SwiftUI

struct GameView: View {
    @EnvironmentObject var gameViewModel: GameViewModel
    @EnvironmentObject var statsViewModel: StatsViewModel
    @State private var showingHelp = false
    @AppStorage("isDarkMode") private var isDarkMode = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background - Web: #1a1a1a (dark), #f5f5f5 (light)
                Color(isDarkMode ? 
                    Color(red: 0.1, green: 0.1, blue: 0.1) : 
                    Color(red: 0.96, green: 0.96, blue: 0.96))
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Date Display
                    Text(gameViewModel.dateDisplayString)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(Color(red: 0.53, green: 0.53, blue: 0.53))
                        .tracking(1.5)
                    
                    // Stats
                    StatsBar()
                    
                    // Grid
                    GridView()
                        .padding(.horizontal)
                    
                    // Action Buttons
                    ActionButtons()
                    
                    // Message
                    MessageView()
                    
                    Spacer()
                }
                .padding(.top)
                
                // Confetti overlay
                if gameViewModel.showConfetti {
                    ConfettiView()
                        .allowsHitTesting(false)
                }
                
                // Toast
                if let message = gameViewModel.toastMessage {
                    VStack {
                        Spacer()
                        ToastView(message: message)
                            .padding(.bottom, 30)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("PATH")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        isDarkMode.toggle()
                    } label: {
                        Image(systemName: isDarkMode ? "sun.max" : "moon")
                            .font(.system(size: 16))
                    }
                    .accessibilityLabel(L10n.settingsTheme)
                    .help(L10n.settingsTheme)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingHelp = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 16))
                    }
                    .accessibilityLabel(L10n.tooltipHelp)
                    .help(L10n.tooltipHelp)
                }
            }
            .sheet(isPresented: $showingHelp) {
                HelpView()
            }
            .alert(L10n.giveUpTitle, isPresented: $gameViewModel.showingGiveUpConfirmation) {
                Button(L10n.giveUpCancel, role: .cancel) { }
                Button(L10n.giveUpConfirm, role: .destructive) {
                    gameViewModel.giveUp()
                }
            } message: {
                Text(L10n.giveUpMessage)
            }
            .sheet(isPresented: $gameViewModel.showingUnlockModal) {
                UnlockModalView()
            }
            .sheet(isPresented: $gameViewModel.showingArchiveModal) {
                ArchiveModalView()
            }
        }
    }
}

// MARK: - Stats Bar
struct StatsBar: View {
    @EnvironmentObject var gameViewModel: GameViewModel
    
    var body: some View {
        HStack(spacing: 50) {
            StatItem(value: "\(gameViewModel.pathLength)", label: L10n.gamePathLength.uppercased())
            StatItem(
                value: gameViewModel.isGameOver ? "\(gameViewModel.optimalLength)" : "?",
                label: L10n.gameOptimal.uppercased()
            )
        }
    }
}

struct StatItem: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .regular, design: .monospaced))
                .foregroundColor(.white)
                .contentTransition(.numericText())
                .animation(.spring(duration: 0.3), value: value)
            
            Text(label)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                .tracking(1.5)
        }
    }
}

// MARK: - Action Buttons
struct ActionButtons: View {
    @EnvironmentObject var gameViewModel: GameViewModel
    @EnvironmentObject var statsViewModel: StatsViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Undo
            ActionButton(
                icon: "arrow.uturn.backward",
                tooltip: L10n.tooltipUndo,
                isDisabled: !gameViewModel.canUndo
            ) {
                gameViewModel.undo()
            }
            
            // Reset
            ActionButton(
                icon: "arrow.counterclockwise",
                tooltip: L10n.tooltipRestart,
                isDisabled: gameViewModel.gaveUp
            ) {
                gameViewModel.reset()
            }
            
            // Grid Size Toggle
            GridSizeButton()
            
            // Share (when game over)
            if gameViewModel.isGameOver && !gameViewModel.gaveUp {
                ShareButton()
            }
            
            // Give Up
            if !gameViewModel.isGameOver {
                Button {
                    gameViewModel.showingGiveUpConfirmation = true
                } label: {
                    Text(L10n.actionGiveUp.uppercased())
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.red.opacity(0.8))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                }
            }
        }
        .padding(.horizontal)
    }
}

struct ActionButton: View {
    let icon: String
    var tooltip: String = ""
    var isDisabled: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isDisabled ? Color(red: 0.53, green: 0.53, blue: 0.53).opacity(0.3) : Color(red: 0.53, green: 0.53, blue: 0.53))
                .frame(width: 36, height: 36)
                .background(Color(red: 0.17, green: 0.17, blue: 0.17))
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color(red: 0.33, green: 0.33, blue: 0.33), lineWidth: 2)
                )
        }
        .disabled(isDisabled)
        .accessibilityLabel(tooltip)
        .help(tooltip)
    }
}

struct GridSizeButton: View {
    @EnvironmentObject var gameViewModel: GameViewModel
    
    var body: some View {
        Button {
            gameViewModel.toggleGridSize()
        } label: {
            VStack(spacing: 0) {
                Text("\(gameViewModel.size)")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(red: 0.67, green: 0.67, blue: 0.67))
                Text("×")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                Text("\(gameViewModel.size)")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(red: 0.67, green: 0.67, blue: 0.67))
            }
            .frame(width: 36, height: 44)
            .background(Color(red: 0.17, green: 0.17, blue: 0.17))
            .cornerRadius(3)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color(red: 0.27, green: 0.27, blue: 0.27), lineWidth: 1)
            )
        }
        .disabled(!gameViewModel.is7x7Unlocked && gameViewModel.gameState.gridSize == .small)
        .opacity(!gameViewModel.is7x7Unlocked && gameViewModel.gameState.gridSize == .small ? 0.4 : 1)
        .accessibilityLabel(L10n.tooltipGridToggle)
        .help(L10n.tooltipGridToggle)
    }
}

struct ShareButton: View {
    @EnvironmentObject var gameViewModel: GameViewModel
    @EnvironmentObject var statsViewModel: StatsViewModel
    
    var body: some View {
        Button {
            let shareText = gameViewModel.generateShareText()
            ShareService.copyToClipboard(shareText)
            gameViewModel.showToast("Copied to clipboard!")
            statsViewModel.recordShare()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "square.and.arrow.up")
                Text(L10n.actionShare.uppercased())
            }
            .font(.system(size: 11, design: .monospaced))
            .foregroundColor(Color(red: 0.53, green: 0.53, blue: 0.53))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(red: 0.17, green: 0.17, blue: 0.17))
            .cornerRadius(3)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color(red: 0.27, green: 0.27, blue: 0.27), lineWidth: 1)
            )
        }
        .accessibilityLabel(L10n.tooltipShare)
        .help(L10n.tooltipShare)
    }
}

// MARK: - Message View
struct MessageView: View {
    @EnvironmentObject var gameViewModel: GameViewModel
    
    var body: some View {
        Text(gameViewModel.statusMessage)
            .font(.system(size: 14, design: .monospaced))
            .foregroundColor(messageColor)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
            .animation(.easeInOut, value: gameViewModel.statusMessage)
    }
    
    var messageColor: Color {
        if gameViewModel.isPerfect {
            // Web success color: #9a9 (muted green-gray)
            return Color(red: 0.6, green: 0.67, blue: 0.6)
        } else if gameViewModel.isGameOver {
            return gameViewModel.percentage >= 90 ? Color(red: 0.6, green: 0.67, blue: 0.6) : Color(red: 0.53, green: 0.53, blue: 0.53)
        }
        return Color(red: 0.53, green: 0.53, blue: 0.53)
    }
}

// MARK: - Toast View
struct ToastView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.system(size: 14, design: .monospaced))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(red: 0.13, green: 0.13, blue: 0.13).opacity(0.95))
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color(red: 0.27, green: 0.27, blue: 0.27), lineWidth: 1)
            )
    }
}

// MARK: - Unlock Modal
struct UnlockModalView: View {
    @EnvironmentObject var gameViewModel: GameViewModel
    @EnvironmentObject var statsViewModel: StatsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            Text("🎉")
                .font(.system(size: 60))
            
            Text(L10n.unlockCongrats)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .tracking(2)
            
            Text(L10n.unlockMastered5x5)
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            // Share button
            Button {
                let shareText = gameViewModel.generateShareText()
                ShareService.copyToClipboard(shareText)
                gameViewModel.showToast("Copied to clipboard!")
                statsViewModel.recordShare()
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text(L10n.unlockShareResults)
                }
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(red: 0.17, green: 0.17, blue: 0.17))
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color(red: 0.27, green: 0.27, blue: 0.27), lineWidth: 1)
                )
            }
            .padding(.horizontal, 30)
            
            HStack(spacing: 16) {
                Button {
                    dismiss()
                } label: {
                    Text(L10n.unlockNotNow)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(12)
                }
                
                Button {
                    dismiss()
                    gameViewModel.toggleGridSize()
                } label: {
                    Text(L10n.unlockLetsGo)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 30)
        }
        .padding(.vertical, 40)
        .presentationDetents([.medium])
    }
}

// MARK: - Archive Modal
struct ArchiveModalView: View {
    @EnvironmentObject var gameViewModel: GameViewModel
    @EnvironmentObject var statsViewModel: StatsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("⭐")
                    .font(.system(size: 40))
                
                Text(L10n.archiveCompletedToday)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                // Share button
                Button {
                    let shareText = gameViewModel.generateShareText()
                    ShareService.copyToClipboard(shareText)
                    gameViewModel.showToast("Copied to clipboard!")
                    statsViewModel.recordShare()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text(L10n.unlockShareResults)
                    }
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 30)
                
                // Archive list
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(gameViewModel.archivePuzzles) { puzzle in
                            Button {
                                gameViewModel.loadArchivePuzzle(puzzle)
                            } label: {
                                HStack {
                                    Text(puzzle.displayDate)
                                        .font(.system(size: 14, design: .monospaced))
                                    Spacer()
                                    Text(puzzle.status.rawValue)
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 30)
                }
                .frame(maxHeight: 250)
            }
            .padding(.vertical)
            .navigationTitle(L10n.archiveTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.archiveClose) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                gameViewModel.loadArchive()
            }
        }
        .presentationDetents([.large])
    }
}

// MARK: - Confetti View
struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                for particle in particles {
                    let rect = CGRect(
                        x: particle.x,
                        y: particle.y,
                        width: particle.size,
                        height: particle.size * 0.6
                    )
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(particle.color)
                    )
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            createParticles()
            animateParticles()
        }
    }
    
    private func createParticles() {
        let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange, .pink]
        let screenWidth = UIScreen.main.bounds.width
        
        particles = (0..<60).map { _ in
            ConfettiParticle(
                x: CGFloat.random(in: 0...screenWidth),
                y: CGFloat.random(in: -500...0),
                size: CGFloat.random(in: 6...12),
                color: colors.randomElement()!,
                speed: CGFloat.random(in: 2...5)
            )
        }
    }
    
    private func animateParticles() {
        Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { timer in
            for i in particles.indices {
                particles[i].y += particles[i].speed
                particles[i].x += sin(particles[i].y * 0.02) * 2
            }
            
            particles.removeAll { $0.y > UIScreen.main.bounds.height + 50 }
            
            if particles.isEmpty {
                timer.invalidate()
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var color: Color
    var speed: CGFloat
}

#Preview {
    GameView()
        .environmentObject(GameViewModel())
        .environmentObject(StatsViewModel())
}
