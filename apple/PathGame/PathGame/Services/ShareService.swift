//
//  ShareService.swift
//  PathGame
//
//  Sharing functionality for game results
//

import Foundation
import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct ShareService {
    
    // MARK: - Generate Share Image
    @MainActor
    static func generateShareImage(gameState: GameState, size: CGSize = CGSize(width: 400, height: 500)) -> Image? {
        let renderer = ImageRenderer(content: ShareCardView(gameState: gameState))
        renderer.scale = 2.0
        
        #if os(iOS)
        if let uiImage = renderer.uiImage {
            return Image(uiImage: uiImage)
        }
        #elseif os(macOS)
        if let nsImage = renderer.nsImage {
            return Image(nsImage: nsImage)
        }
        #endif
        
        return nil
    }
    
    // MARK: - Copy to Clipboard
    static func copyToClipboard(_ text: String) {
        #if os(iOS)
        UIPasteboard.general.string = text
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }
    
    // MARK: - Share Sheet
    @MainActor
    static func share(_ items: [Any]) {
        #if os(iOS)
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            
            // For iPad
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootViewController.view
                popover.sourceRect = CGRect(x: rootViewController.view.bounds.midX, y: rootViewController.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            rootViewController.present(activityVC, animated: true)
        }
        #elseif os(macOS)
        let sharingServicePicker = NSSharingServicePicker(items: items)
        if let window = NSApplication.shared.mainWindow,
           let contentView = window.contentView {
            sharingServicePicker.show(relativeTo: .zero, of: contentView, preferredEdge: .minY)
        }
        #endif
    }
    
    // MARK: - Generate Share Text
    static func generateShareText(gameState: GameState, archiveDate: Date? = nil) -> String {
        let date = archiveDate ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        let dateStr = formatter.string(from: date)
        
        let gridType = gameState.gridSize.displayName
        let totalCells = gameState.gridSize.totalCells
        let pathLength = gameState.pathLength
        let isPerfect = gameState.isPerfect
        let attempts = gameState.attempts
        let percentage = gameState.percentage
        
        var lines: [String] = []
        
        // Title
        if isPerfect {
            lines.append("🧩 Path \(gridType) 🏆")
        } else {
            lines.append("🧩 Path \(gridType)")
        }
        
        // Date
        lines.append("📅 \(dateStr)")
        lines.append("")
        
        // Score
        if isPerfect {
            lines.append("✨ Perfect: \(pathLength)/\(totalCells)")
        } else {
            lines.append("📊 Score: \(pathLength)/\(totalCells) (\(percentage)%)")
        }
        
        // Attempts
        if attempts == 1 {
            lines.append("🎯 First try!")
        } else {
            lines.append("🎯 Attempts: \(attempts)")
        }
        
        lines.append("")
        lines.append("https://nagusamecs.github.io/Path/")
        
        return lines.joined(separator: "\n")
    }
    
    // MARK: - Generate Grid Emoji
    static func generateGridEmoji(gameState: GameState) -> String {
        let size = gameState.size
        var lines: [String] = []
        
        for row in 0..<size {
            var rowStr = ""
            for col in 0..<size {
                let pos = Position(row: row, col: col)
                if gameState.path.contains(pos) {
                    if pos == gameState.path.first {
                        rowStr += "🟢"
                    } else if pos == gameState.path.last {
                        rowStr += "🔵"
                    } else {
                        rowStr += "⬜️"
                    }
                } else {
                    rowStr += "⬛️"
                }
            }
            lines.append(rowStr)
        }
        
        return lines.joined(separator: "\n")
    }
}

// MARK: - Share Card View
struct ShareCardView: View {
    let gameState: GameState
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("PATH")
                .font(.system(size: 32, weight: .light, design: .monospaced))
                .tracking(8)
            
            Text(gameState.gridSize.displayName)
                .font(.system(size: 16, design: .monospaced))
                .foregroundColor(.secondary)
            
            // Grid representation
            GridPreviewView(gameState: gameState)
                .frame(width: 200, height: 200)
            
            // Score
            HStack(spacing: 40) {
                VStack {
                    Text("\(gameState.pathLength)")
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                    Text("SCORE")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(gameState.optimalLength)")
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                    Text("GOAL")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            
            // Perfect badge
            if gameState.isPerfect {
                HStack {
                    Image(systemName: "star.fill")
                    Text("PERFECT")
                    Image(systemName: "star.fill")
                }
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.yellow)
            }
            
            // URL
            Text("nagusamecs.github.io/Path")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.secondary)
        }
        .padding(30)
        .background(Color(.systemBackground))
        .frame(width: 300, height: 400)
    }
}

// MARK: - Grid Preview View
struct GridPreviewView: View {
    let gameState: GameState
    
    var body: some View {
        GeometryReader { geometry in
            let cellSize = geometry.size.width / CGFloat(gameState.size)
            
            Canvas { context, size in
                // Draw cells
                for row in 0..<gameState.size {
                    for col in 0..<gameState.size {
                        let pos = Position(row: row, col: col)
                        let rect = CGRect(
                            x: CGFloat(col) * cellSize + 1,
                            y: CGFloat(row) * cellSize + 1,
                            width: cellSize - 2,
                            height: cellSize - 2
                        )
                        
                        let color: Color
                        if gameState.path.contains(pos) {
                            if pos == gameState.path.first {
                                color = .green.opacity(0.7)
                            } else if pos == gameState.path.last {
                                color = .blue.opacity(0.7)
                            } else {
                                color = .gray.opacity(0.5)
                            }
                        } else {
                            color = .gray.opacity(0.2)
                        }
                        
                        context.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(color))
                    }
                }
                
                // Draw path line
                if gameState.path.count > 1 {
                    var path = Path()
                    for (index, pos) in gameState.path.enumerated() {
                        let point = CGPoint(
                            x: CGFloat(pos.col) * cellSize + cellSize / 2,
                            y: CGFloat(pos.row) * cellSize + cellSize / 2
                        )
                        if index == 0 {
                            path.move(to: point)
                        } else {
                            path.addLine(to: point)
                        }
                    }
                    context.stroke(path, with: .color(.primary.opacity(0.5)), lineWidth: 2)
                }
            }
        }
    }
}
