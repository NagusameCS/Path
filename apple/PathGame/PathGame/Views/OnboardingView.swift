//
//  OnboardingView.swift
//  PathGame
//
//  Beautiful onboarding experience for first-time users
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    @Binding var hasSeenOnboarding: Bool
    
    let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "arrow.triangle.turn.up.right.diamond",
            title: L10n.onboardingWelcome,
            subtitle: L10n.onboardingWelcomeDesc,
            color: .blue
        ),
        OnboardingPage(
            icon: "square.grid.3x3",
            title: L10n.helpPage1Title,
            subtitle: L10n.helpPage1Desc,
            color: .purple,
            details: [
                L10n.helpPage1Detail1,
                L10n.helpPage1Detail2,
                L10n.helpPage1Detail3
            ]
        ),
        OnboardingPage(
            icon: "arrow.up.left.and.arrow.down.right",
            title: L10n.helpPage2Title,
            subtitle: L10n.helpPage2Desc,
            color: .orange,
            details: [
                L10n.helpPage2Detail1,
                L10n.helpPage2Detail2,
                L10n.helpPage2Detail3
            ]
        ),
        OnboardingPage(
            icon: "star.fill",
            title: L10n.helpPage3Title,
            subtitle: L10n.helpPage3Desc,
            color: .yellow,
            details: [
                L10n.helpPage3Detail1,
                L10n.helpPage3Detail2,
                L10n.helpPage3Detail3
            ]
        ),
        OnboardingPage(
            icon: "person.2.fill",
            title: L10n.helpPage4Title,
            subtitle: L10n.helpPage4Desc,
            color: .green,
            details: [
                L10n.helpPage4Detail1,
                L10n.helpPage4Detail2,
                L10n.helpPage4Detail3
            ]
        )
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    pages[currentPage].color.opacity(0.15),
                    Color(uiColor: .systemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: currentPage)
            
            VStack {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button(L10n.onboardingSkip) {
                            completeOnboarding()
                        }
                        .foregroundColor(.secondary)
                        .padding()
                    }
                }
                
                Spacer()
                
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                
                Spacer()
                
                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? pages[currentPage].color : Color.secondary.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == currentPage ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 20)
                
                // Action button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        completeOnboarding()
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? L10n.onboardingNext : L10n.onboardingPlayNow)
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(pages[currentPage].color)
                        .cornerRadius(16)
                        .shadow(color: pages[currentPage].color.opacity(0.3), radius: 10, y: 5)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }
    
    private func completeOnboarding() {
        hasSeenOnboarding = true
        dismiss()
    }
}

struct OnboardingPage: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    var details: [String] = []
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: page.icon)
                    .font(.system(size: 50))
                    .foregroundColor(page.color)
            }
            
            // Title
            Text(page.title)
                .font(.title.bold())
                .multilineTextAlignment(.center)
            
            // Subtitle
            Text(page.subtitle)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            // Details
            if !page.details.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(page.details, id: \.self) { detail in
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(page.color)
                            Text(detail)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 8)
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    OnboardingView(hasSeenOnboarding: .constant(false))
}
