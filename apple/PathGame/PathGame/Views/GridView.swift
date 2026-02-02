//
//  GridView.swift
//  PathGame
//
//  Interactive game grid with path visualization
//

import SwiftUI

struct GridView: View {
    @EnvironmentObject var gameViewModel: GameViewModel
    @State private var cellSize: CGFloat = 54
    
    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width - 20
            let calculatedCellSize = (availableWidth - CGFloat(gameViewModel.size - 1) * 3) / CGFloat(gameViewModel.size)
            let finalCellSize = min(calculatedCellSize, 60)
            
            ZStack {
                // Grid background - Web: #333 (dark mode)
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
                    .frame(
                        width: CGFloat(gameViewModel.size) * finalCellSize + CGFloat(gameViewModel.size - 1) * 3 + 6,
                        height: CGFloat(gameViewModel.size) * finalCellSize + CGFloat(gameViewModel.size - 1) * 3 + 6
                    )
                
                VStack(spacing: 3) {
                    ForEach(0..<gameViewModel.size, id: \.self) { row in
                        HStack(spacing: 3) {
                            ForEach(0..<gameViewModel.size, id: \.self) { col in
                                let position = Position(row: row, col: col)
                                CellView(
                                    position: position,
                                    value: gameViewModel.grid[row][col],
                                    cellSize: finalCellSize
                                )
                            }
                        }
                    }
                }
                
                // Path lines overlay
                PathLinesView(cellSize: finalCellSize)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Path Lines View
struct PathLinesView: View {
    @EnvironmentObject var gameViewModel: GameViewModel
    let cellSize: CGFloat
    let gap: CGFloat = 3
    
    var body: some View {
        Canvas { context, size in
            guard gameViewModel.path.count > 1 else { return }
            
            let gridSize = gameViewModel.size
            let totalWidth = CGFloat(gridSize) * cellSize + CGFloat(gridSize - 1) * gap
            let offsetX = (size.width - totalWidth) / 2
            let offsetY = (size.height - totalWidth) / 2
            
            // Draw glow - subtle web-style
            var glowPath = Path()
            for (index, pos) in gameViewModel.path.enumerated() {
                let x = offsetX + CGFloat(pos.col) * (cellSize + gap) + cellSize / 2
                let y = offsetY + CGFloat(pos.row) * (cellSize + gap) + cellSize / 2
                
                if index == 0 {
                    glowPath.move(to: CGPoint(x: x, y: y))
                } else {
                    glowPath.addLine(to: CGPoint(x: x, y: y))
                }
            }
            context.stroke(glowPath, with: .color(.white.opacity(0.1)), lineWidth: 6)
            
            // Draw main line - gray to match web
            var mainPath = Path()
            for (index, pos) in gameViewModel.path.enumerated() {
                let x = offsetX + CGFloat(pos.col) * (cellSize + gap) + cellSize / 2
                let y = offsetY + CGFloat(pos.row) * (cellSize + gap) + cellSize / 2
                
                if index == 0 {
                    mainPath.move(to: CGPoint(x: x, y: y))
                } else {
                    mainPath.addLine(to: CGPoint(x: x, y: y))
                }
            }
            context.stroke(mainPath, with: .color(Color(red: 0.4, green: 0.4, blue: 0.4)), lineWidth: 2)
            
            // Draw dots
            for pos in gameViewModel.path {
                let x = offsetX + CGFloat(pos.col) * (cellSize + gap) + cellSize / 2
                let y = offsetY + CGFloat(pos.row) * (cellSize + gap) + cellSize / 2
                
                // Glow
                let glowRect = CGRect(x: x - 8, y: y - 8, width: 16, height: 16)
                context.fill(Path(ellipseIn: glowRect), with: .color(.white.opacity(0.2)))
                
                // Dot
                let dotRect = CGRect(x: x - 4, y: y - 4, width: 8, height: 8)
                context.fill(Path(ellipseIn: dotRect), with: .color(.gray.opacity(0.8)))
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    GridView()
        .environmentObject(GameViewModel())
        .padding()
}
