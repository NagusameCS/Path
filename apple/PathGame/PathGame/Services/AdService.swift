//
//  AdService.swift
//  Path
//
//  Google AdMob integration for rewarded ads (streak recovery)
//

import Foundation
import SwiftUI

#if os(iOS)
import GoogleMobileAds
import UIKit
import AppTrackingTransparency

// MARK: - Ad Service
class AdService: NSObject, ObservableObject {
    static let shared = AdService()
    
    // AdMob App ID: ca-app-pub-3483128058944289~7545769631 (set in Info.plist)
    // Production Rewarded Ad Unit ID:
    private let productionAdUnitID = "ca-app-pub-3483128058944289/3474371103"
    // Test Ad Unit ID (always works for testing):
    private let testAdUnitID = "ca-app-pub-3940256099942544/1712485313"
    
    // Use test ads in DEBUG, production in release
    private var rewardedAdUnitID: String {
        #if DEBUG
        return testAdUnitID
        #else
        return productionAdUnitID
        #endif
    }
    
    @Published var isRewardedAdReady = false
    @Published var isLoading = false
    @Published var rewardEarned = false
    @Published var errorMessage: String?
    @Published var trackingAuthorizationStatus: ATTrackingManager.AuthorizationStatus = .notDetermined
    
    private var rewardedAd: RewardedAd?
    
    override init() {
        super.init()
        // Don't load ads automatically - wait for tracking permission
    }
    
    // MARK: - Initialize Mobile Ads SDK
    static func configure() {
        MobileAds.shared.start { _ in
            // AdMob initialized
        }
    }
    
    // MARK: - Request Tracking Authorization
    func requestTrackingAuthorization(completion: @escaping () -> Void = {}) {
        // Only request if not determined yet
        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            ATTrackingManager.requestTrackingAuthorization { [weak self] status in
                DispatchQueue.main.async {
                    self?.trackingAuthorizationStatus = status
                    // Load ads after permission decision (regardless of choice)
                    self?.loadRewardedAd()
                    completion()
                }
            }
        } else {
            trackingAuthorizationStatus = ATTrackingManager.trackingAuthorizationStatus
            loadRewardedAd()
            completion()
        }
    }
    
    // MARK: - Load Rewarded Ad
    func loadRewardedAd() {
        guard !isLoading else { return }  // Prevent duplicate loads
        
        isLoading = true
        errorMessage = nil
        
        let request = Request()
        
        RewardedAd.load(with: rewardedAdUnitID, request: request) { [weak self] ad, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Ad load failed: \(error.localizedDescription)"
                    self?.isRewardedAdReady = false
                    return
                }
                
                self?.rewardedAd = ad
                self?.rewardedAd?.fullScreenContentDelegate = self
                self?.isRewardedAdReady = true
            }
        }
    }
    
    // MARK: - Show Rewarded Ad
    func showRewardedAd(from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        guard let rewardedAd = rewardedAd else {
            errorMessage = "Ad not ready"
            completion(false)
            return
        }
        
        rewardedAd.present(from: viewController) { [weak self] in
            // User earned reward
            _ = rewardedAd.adReward
            
            DispatchQueue.main.async {
                self?.rewardEarned = true
                completion(true)
            }
        }
    }
    
    // MARK: - Get Root View Controller
    static func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return nil
        }
        return rootViewController
    }
}

// MARK: - FullScreenContentDelegate
extension AdService: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        // Reload ad for next time
        loadRewardedAd()
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        errorMessage = error.localizedDescription
        loadRewardedAd()
    }
}

// MARK: - SwiftUI View for Showing Ads
struct RewardedAdButton: View {
    @ObservedObject var adService: AdService
    let buttonText: String
    let onReward: () -> Void
    
    @State private var showingError = false
    
    var body: some View {
        VStack(spacing: 8) {
            Button {
                if adService.isRewardedAdReady {
                    if let rootVC = AdService.getRootViewController() {
                        adService.showRewardedAd(from: rootVC) { success in
                            if success {
                                onReward()
                            }
                        }
                    }
                } else {
                    // Try loading again
                    adService.loadRewardedAd()
                    showingError = true
                }
            } label: {
                HStack {
                    if adService.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: adService.isRewardedAdReady ? "play.circle.fill" : "arrow.clockwise")
                    }
                    Text(adService.isRewardedAdReady ? buttonText : "Load Ad")
                }
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(.white)
                .padding()
                .background(adService.isRewardedAdReady ? Color.green : Color.orange)
                .cornerRadius(8)
            }
            .disabled(adService.isLoading)
            
            if let error = adService.errorMessage, showingError {
                Text(error)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

#else
// macOS stub - no ads on Mac
class AdService: ObservableObject {
    static let shared = AdService()
    
    @Published var isRewardedAdReady = false
    @Published var isLoading = false
    @Published var rewardEarned = false
    @Published var errorMessage: String?
    
    static func configure() {}
    func loadRewardedAd() {}
}

struct RewardedAdButton: View {
    let adService: AdService
    let buttonText: String
    let onReward: () -> Void
    
    var body: some View {
        Text("Ads not available on macOS")
            .foregroundColor(.secondary)
    }
}
#endif
