//
//  HelpView.swift
//  PathGame
//
//  How to play tutorial
//

import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    
    var body: some View {
        NavigationStack {
            TabView(selection: $currentPage) {
                TutorialPage(
                    icon: "target",
                    iconColor: .blue,
                    title: L10n.helpPage1Title,
                    description: L10n.helpPage1Desc,
                    details: [
                        L10n.helpPage1Detail1,
                        L10n.helpPage1Detail2,
                        L10n.helpPage1Detail3
                    ]
                )
                .tag(0)
                
                TutorialPage(
                    icon: "arrow.up.and.down.and.arrow.left.and.right",
                    iconColor: .green,
                    title: L10n.helpPage2Title,
                    description: L10n.helpPage2Desc,
                    details: [
                        L10n.helpPage2Detail1,
                        L10n.helpPage2Detail2,
                        L10n.helpPage2Detail3
                    ],
                    showExample: true
                )
                .tag(1)
                
                TutorialPage(
                    icon: "star.fill",
                    iconColor: .yellow,
                    title: L10n.helpPage3Title,
                    description: L10n.helpPage3Desc,
                    details: [
                        L10n.helpPage3Detail1,
                        L10n.helpPage3Detail2,
                        L10n.helpPage3Detail3
                    ]
                )
                .tag(2)
                
                TutorialPage(
                    icon: "person.2.fill",
                    iconColor: .purple,
                    title: L10n.helpPage4Title,
                    description: L10n.helpPage4Desc,
                    details: [
                        L10n.helpPage4Detail1,
                        L10n.helpPage4Detail2,
                        L10n.helpPage4Detail3
                    ]
                )
                .tag(3)
                
                FinalTutorialPage()
                    .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .navigationTitle(L10n.helpTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.helpDone) {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TutorialPage: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let details: [String]
    var showExample: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Icon
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 44))
                            .foregroundColor(iconColor)
                    )
                    .padding(.top, 40)
                
                // Title
                Text(title)
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                
                // Description
                Text(description)
                    .font(.system(size: 16, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 40)
                
                // Example grid
                if showExample {
                    MovementExampleView()
                        .padding(.vertical, 10)
                }
                
                // Details
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(details, id: \.self) { detail in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 18))
                            
                            Text(detail)
                                .font(.system(size: 14, design: .monospaced))
                        }
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 10)
                
                Spacer(minLength: 100)
            }
        }
    }
}

struct MovementExampleView: View {
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                ExampleCell(value: 6, state: .selectable)
                ExampleCell(value: 8, state: .normal)
                ExampleCell(value: 2, state: .normal)
            }
            HStack(spacing: 4) {
                ExampleCell(value: 4, state: .normal)
                ExampleCell(value: 5, state: .current, label: L10n.helpExampleCurrent)
                ExampleCell(value: 6, state: .selectable)
            }
            HStack(spacing: 4) {
                ExampleCell(value: 3, state: .normal)
                ExampleCell(value: 4, state: .selectable)
                ExampleCell(value: 7, state: .normal)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondary.opacity(0.1))
        )
        
        HStack(spacing: 20) {
            LegendItem(color: .blue.opacity(0.3), label: L10n.helpLegendCurrent)
            LegendItem(color: .green.opacity(0.3), label: L10n.helpLegendValid)
        }
        .font(.system(size: 12, design: .monospaced))
        .foregroundColor(.secondary)
    }
}

struct ExampleCell: View {
    enum CellState {
        case normal, current, selectable
    }
    
    let value: Int
    let state: CellState
    var label: String? = nil
    
    var backgroundColor: Color {
        switch state {
        case .normal: return Color.secondary.opacity(0.1)
        case .current: return Color.blue.opacity(0.3)
        case .selectable: return Color.green.opacity(0.3)
        }
    }
    
    var borderColor: Color {
        switch state {
        case .current: return .blue
        case .selectable: return .green
        default: return .clear
        }
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
                .frame(width: 60, height: 60)
            
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: state != .normal ? 2 : 0)
                .frame(width: 60, height: 60)
            
            Text("\(value)")
                .font(.system(size: 24, weight: .bold, design: .monospaced))
        }
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: 16, height: 16)
            Text(label)
        }
    }
}

struct FinalTutorialPage: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.green, .mint],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text(L10n.helpReadyTitle)
                .font(.system(size: 28, weight: .bold, design: .monospaced))
            
            Text(L10n.helpReadyDesc)
                .font(.system(size: 16, design: .monospaced))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
            
            Button {
                dismiss()
            } label: {
                Text(L10n.helpStartPlaying)
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
            
            Spacer()
            Spacer()
        }
    }
}

#Preview {
    HelpView()
}
