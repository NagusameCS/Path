//
//  HapticsService.swift
//  PathGame
//
//  Haptic feedback service for iOS
//

import Foundation
import SwiftUI

#if os(iOS)
import UIKit
#endif

class HapticsService {
    static let shared = HapticsService()
    
    #if os(iOS)
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let impactSoft = UIImpactFeedbackGenerator(style: .soft)
    private let impactRigid = UIImpactFeedbackGenerator(style: .rigid)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()
    #endif
    
    private init() {
        prepare()
    }
    
    // MARK: - Prepare
    func prepare() {
        #if os(iOS)
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        impactSoft.prepare()
        impactRigid.prepare()
        selectionFeedback.prepare()
        notificationFeedback.prepare()
        #endif
    }
    
    // MARK: - Impact Feedback
    enum ImpactStyle {
        case light
        case medium
        case heavy
        case soft
        case rigid
    }
    
    func impact(_ style: ImpactStyle) {
        #if os(iOS)
        switch style {
        case .light:
            impactLight.impactOccurred()
        case .medium:
            impactMedium.impactOccurred()
        case .heavy:
            impactHeavy.impactOccurred()
        case .soft:
            impactSoft.impactOccurred()
        case .rigid:
            impactRigid.impactOccurred()
        }
        #endif
    }
    
    func impact(_ style: ImpactStyle, intensity: CGFloat) {
        #if os(iOS)
        switch style {
        case .light:
            impactLight.impactOccurred(intensity: intensity)
        case .medium:
            impactMedium.impactOccurred(intensity: intensity)
        case .heavy:
            impactHeavy.impactOccurred(intensity: intensity)
        case .soft:
            impactSoft.impactOccurred(intensity: intensity)
        case .rigid:
            impactRigid.impactOccurred(intensity: intensity)
        }
        #endif
    }
    
    // MARK: - Selection Feedback
    func selection() {
        #if os(iOS)
        selectionFeedback.selectionChanged()
        #endif
    }
    
    // MARK: - Notification Feedback
    enum NotificationType {
        case success
        case warning
        case error
    }
    
    func notification(_ type: NotificationType) {
        #if os(iOS)
        switch type {
        case .success:
            notificationFeedback.notificationOccurred(.success)
        case .warning:
            notificationFeedback.notificationOccurred(.warning)
        case .error:
            notificationFeedback.notificationOccurred(.error)
        }
        #endif
    }
    
    // MARK: - Custom Patterns
    func patternSuccess() {
        #if os(iOS)
        impact(.light)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.impact(.medium)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.notification(.success)
        }
        #endif
    }
    
    func patternError() {
        #if os(iOS)
        impact(.rigid)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.impact(.rigid)
        }
        #endif
    }
    
    func patternCelebration() {
        #if os(iOS)
        for i in 0..<5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.1) {
                self.impact(.light, intensity: CGFloat(1.0 - Double(i) * 0.15))
            }
        }
        #endif
    }
}
