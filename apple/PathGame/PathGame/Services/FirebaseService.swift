//
//  FirebaseService.swift
//  Path
//
//  Main Firebase configuration and initialization
//

import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseDatabase

#if os(iOS)
import UIKit
#endif

// MARK: - Firebase Service
class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    
    @Published var isConfigured = false
    
    let db: Firestore
    let realtimeDB: DatabaseReference
    
    private init() {
        // Firestore for user data, leaderboards
        self.db = Firestore.firestore()
        
        // Realtime Database for live leaderboard updates
        self.realtimeDB = Database.database().reference()
        
        isConfigured = true
    }
    
    // MARK: - Configuration
    static func configure() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }
}

// MARK: - Region Enum
enum LeaderboardRegion: String, CaseIterable, Codable {
    case global = "global"
    case americas = "americas"
    case europe = "europe"
    case asia = "asia"
    case africa = "africa"
    case oceania = "oceania"
    
    var displayName: String {
        switch self {
        case .global: return "🌍 Global"
        case .americas: return "🌎 Americas"
        case .europe: return "🌍 Europe"
        case .asia: return "🌏 Asia"
        case .africa: return "🌍 Africa"
        case .oceania: return "🌏 Oceania"
        }
    }
    
    // Map country codes to regions
    static func region(for countryCode: String) -> LeaderboardRegion {
        let americas = ["US", "CA", "MX", "BR", "AR", "CL", "CO", "PE", "VE", "EC", "BO", "PY", "UY", "GY", "SR", "GT", "HN", "SV", "NI", "CR", "PA", "CU", "DO", "HT", "JM", "TT", "BS", "BB", "PR"]
        let europe = ["GB", "DE", "FR", "IT", "ES", "PT", "NL", "BE", "AT", "CH", "SE", "NO", "DK", "FI", "PL", "CZ", "SK", "HU", "RO", "BG", "GR", "HR", "RS", "UA", "RU", "IE", "LU", "IS"]
        let asia = ["CN", "JP", "KR", "IN", "ID", "TH", "VN", "PH", "MY", "SG", "TW", "HK", "MO", "PK", "BD", "LK", "NP", "MM", "KH", "LA", "MN", "KZ", "UZ", "AE", "SA", "IL", "TR", "IR", "IQ"]
        let africa = ["ZA", "EG", "NG", "KE", "GH", "TZ", "UG", "ET", "MA", "DZ", "TN", "LY", "SD", "SS", "CM", "CI", "SN", "ML", "NE", "TD", "MG", "MZ", "ZW", "ZM", "BW", "NA", "RW"]
        let oceania = ["AU", "NZ", "FJ", "PG", "NC", "VU", "WS", "TO", "FM", "PW", "MH", "KI", "NR", "TV", "SB"]
        
        if americas.contains(countryCode) { return .americas }
        if europe.contains(countryCode) { return .europe }
        if asia.contains(countryCode) { return .asia }
        if africa.contains(countryCode) { return .africa }
        if oceania.contains(countryCode) { return .oceania }
        return .global
    }
}
