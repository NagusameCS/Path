//
//  SplashView.swift
//  PathGame
//
//  Animated splash/loading screen
//

import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false
    @State private var showTitle = false
    @State private var showTagline = false
    @State private var gridOpacity: Double = 0
    @State private var pathProgress: CGFloat = 0
    
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.15),
                    Color(red: 0.05, green: 0.05, blue: 0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Animated logo
                ZStack {
                    // Grid background
                    AnimatedGridBackground()
                        .opacity(gridOpacity)
                    
                    // App icon with path animation
                    ZStack {
                        // Outer glow
                        RoundedRectangle(cornerRadius: 32)
                            .fill(
                                LinearGradient(
                                    colors: [.blue.opacity(0.5), .purple.opacity(0.5)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 140, height: 140)
                            .blur(radius: 20)
                            .opacity(isAnimating ? 0.8 : 0.3)
                        
                        // Main icon
                        RoundedRectangle(cornerRadius: 32)
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .overlay(
                                // Animated path inside
                                PathAnimation(progress: pathProgress)
                                    .stroke(Color.white, lineWidth: 3)
                                    .padding(24)
                            )
                            .scaleEffect(isAnimating ? 1.0 : 0.8)
                    }
                }
                .frame(height: 200)
                
                // Title
                VStack(spacing: 12) {
                    Text("Path")
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .opacity(showTitle ? 1 : 0)
                        .offset(y: showTitle ? 0 : 20)
                    
                    Text(L10n.appTagline)
                        .font(.system(size: 18, design: .monospaced))
                        .foregroundColor(.gray)
                        .opacity(showTagline ? 1 : 0)
                        .offset(y: showTagline ? 0 : 10)
                }
                
                Spacer()
                
                // Loading indicator
                LoadingDots()
                    .opacity(showTagline ? 1 : 0)
                
                Spacer()
                    .frame(height: 60)
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Grid fade in
        withAnimation(.easeIn(duration: 0.5)) {
            gridOpacity = 0.3
        }
        
        // Icon animation
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            isAnimating = true
        }
        
        // Path drawing animation
        withAnimation(.easeInOut(duration: 1.5).delay(0.3)) {
            pathProgress = 1.0
        }
        
        // Title animation
        withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
            showTitle = true
        }
        
        // Tagline animation
        withAnimation(.easeOut(duration: 0.5).delay(0.8)) {
            showTagline = true
        }
        
        // Complete after animations
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                onComplete()
            }
        }
    }
}

// MARK: - Animated Grid Background
struct AnimatedGridBackground: View {
    let gridSize = 5
    @State private var cellOpacities: [[Double]] = Array(repeating: Array(repeating: 0.1, count: 5), count: 5)
    
    var body: some View {
        VStack(spacing: 4) {
            ForEach(0..<gridSize, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(0..<gridSize, id: \.self) { col in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(cellOpacities[row][col]))
                            .frame(width: 20, height: 20)
                    }
                }
            }
        }
        .onAppear {
            animateGrid()
        }
    }
    
    private func animateGrid() {
        Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { timer in
            let row = Int.random(in: 0..<gridSize)
            let col = Int.random(in: 0..<gridSize)
            
            withAnimation(.easeInOut(duration: 0.3)) {
                cellOpacities[row][col] = Double.random(in: 0.1...0.4)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    cellOpacities[row][col] = 0.1
                }
            }
        }
    }
}

// MARK: - Path Animation Shape
struct PathAnimation: Shape {
    var progress: CGFloat
    
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Create a winding path through the "grid"
        let points: [CGPoint] = [
            CGPoint(x: rect.midX, y: rect.midY),
            CGPoint(x: rect.midX + 15, y: rect.midY - 15),
            CGPoint(x: rect.maxX - 10, y: rect.minY + 15),
            CGPoint(x: rect.maxX - 10, y: rect.midY),
            CGPoint(x: rect.midX + 10, y: rect.midY + 10),
            CGPoint(x: rect.midX - 15, y: rect.maxY - 15),
            CGPoint(x: rect.minX + 10, y: rect.maxY - 10),
            CGPoint(x: rect.minX + 10, y: rect.midY - 10),
            CGPoint(x: rect.midX - 10, y: rect.minY + 10)
        ]
        
        guard !points.isEmpty else { return path }
        
        let totalPoints = Int(CGFloat(points.count) * progress)
        guard totalPoints > 0 else { return path }
        
        path.move(to: points[0])
        
        for i in 1..<min(totalPoints, points.count) {
            path.addLine(to: points[i])
        }
        
        // Add partial line for smooth animation
        if totalPoints < points.count {
            let fraction = (CGFloat(points.count) * progress) - CGFloat(totalPoints - 1)
            let fromPoint = points[totalPoints - 1]
            let toPoint = points[totalPoints]
            let partialPoint = CGPoint(
                x: fromPoint.x + (toPoint.x - fromPoint.x) * fraction,
                y: fromPoint.y + (toPoint.y - fromPoint.y) * fraction
            )
            path.addLine(to: partialPoint)
        }
        
        return path
    }
}

// MARK: - Loading Dots
struct LoadingDots: View {
    @State private var animatingDots = [false, false, false]
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 8, height: 8)
                    .offset(y: animatingDots[index] ? -8 : 0)
            }
        }
        .onAppear {
            for i in 0..<3 {
                withAnimation(
                    .easeInOut(duration: 0.4)
                    .repeatForever(autoreverses: true)
                    .delay(Double(i) * 0.15)
                ) {
                    animatingDots[i] = true
                }
            }
        }
    }
}

#Preview {
    SplashView(onComplete: {})
}
