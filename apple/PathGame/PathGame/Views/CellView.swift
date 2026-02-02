//
//  CellView.swift
//  PathGame
//
//  Individual cell in the game grid
//

import SwiftUI

struct CellView: View {
    @EnvironmentObject var gameViewModel: GameViewModel
    
    let position: Position
    let value: Int
    let cellSize: CGFloat
    
    @State private var isPressed = false
    
    var isVisited: Bool { gameViewModel.isVisited(position) }
    var isCurrent: Bool { gameViewModel.isCurrent(position) }
    var isCenter: Bool { gameViewModel.isCenter(position) }
    var isValidMove: Bool { gameViewModel.isValidMove(position) }
    var isGameOver: Bool { gameViewModel.isGameOver }
    
    var body: some View {
        Button {
            gameViewModel.makeMove(to: position)
        } label: {
            Text("\(value)")
                .font(.system(size: cellSize * 0.4, weight: .medium, design: .monospaced))
                .foregroundColor(textColor)
                .frame(width: cellSize, height: cellSize)
                .background(backgroundColor)
                .cornerRadius(2)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(borderColor, lineWidth: borderWidth)
                )
                .shadow(color: shadowColor, radius: shadowRadius)
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(.spring(duration: 0.2), value: isPressed)
                .animation(.easeInOut(duration: 0.2), value: isVisited)
                .animation(.easeInOut(duration: 0.2), value: isCurrent)
        }
        .buttonStyle(.plain)
        .disabled(isGameOver && !isCurrent)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel("Cell \(value)")
        .accessibilityHint(accessibilityHint)
    }
    
    // MARK: - Styling
    // Web colors (dark mode): default #252525, visited #3a3a3a, current #4a4a4a, valid #2d2d2d
    // Text: default #999, valid #aaa, visited #ccc, current #fff
    
    private var backgroundColor: Color {
        if isCurrent {
            // #4a4a4a
            return Color(red: 0.29, green: 0.29, blue: 0.29)
        } else if isVisited {
            // #3a3a3a
            return Color(red: 0.23, green: 0.23, blue: 0.23)
        } else if isValidMove && !isGameOver {
            // #2d2d2d
            return Color(red: 0.18, green: 0.18, blue: 0.18)
        } else {
            // #252525
            return Color(red: 0.15, green: 0.15, blue: 0.15)
        }
    }
    
    private var textColor: Color {
        if isCurrent {
            // #ffffff
            return Color.white
        } else if isVisited {
            // #cccccc
            return Color(red: 0.8, green: 0.8, blue: 0.8)
        } else if isValidMove && !isGameOver {
            // #aaaaaa
            return Color(red: 0.67, green: 0.67, blue: 0.67)
        } else {
            // #999999
            return Color(red: 0.6, green: 0.6, blue: 0.6)
        }
    }
    
    private var borderColor: Color {
        if isCurrent {
            // Web: inset border #999
            return Color(red: 0.6, green: 0.6, blue: 0.6)
        } else if isValidMove && !isGameOver {
            // Web: inset border #555
            return Color(red: 0.33, green: 0.33, blue: 0.33)
        } else {
            return Color.clear
        }
    }
    
    private var borderWidth: CGFloat {
        if isCurrent {
            return 2
        } else if isValidMove && !isGameOver {
            return 1
        }
        return 0
    }
    
    private var shadowColor: Color {
        if isCurrent {
            // Web: box-shadow with rgba(255,255,255,0.25)
            return Color.white.opacity(0.25)
        } else if isValidMove && !isGameOver {
            // Web: box-shadow with rgba(255,255,255,0.15)
            return Color.white.opacity(0.15)
        }
        return .clear
    }
    
    private var shadowRadius: CGFloat {
        if isCurrent {
            return 10
        } else if isValidMove && !isGameOver {
            return 6
        }
        return 0
    }
    
    private var accessibilityHint: String {
        if isCurrent {
            return "Current position. Tap to undo."
        } else if isVisited {
            return "Already visited"
        } else if isValidMove {
            return "Valid move. Tap to move here."
        } else {
            return "Cannot move here"
        }
    }
}

// MARK: - Animated Cell Modifier
struct PulseAnimation: ViewModifier {
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.white.opacity(isPulsing ? 0.3 : 0.1), lineWidth: 1)
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}

extension View {
    func pulseAnimation() -> some View {
        modifier(PulseAnimation())
    }
}

#Preview {
    HStack {
        CellView(position: Position(row: 0, col: 0), value: 3, cellSize: 54)
        CellView(position: Position(row: 0, col: 1), value: 4, cellSize: 54)
        CellView(position: Position(row: 0, col: 2), value: 2, cellSize: 54)
    }
    .environmentObject(GameViewModel())
}
