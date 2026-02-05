//
//  AuthService.swift
//  Path
//
//  Authentication service using Firebase Auth with Sign in with Apple
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices
import CryptoKit

#if os(iOS)
import UIKit
#endif

// MARK: - User Model
struct PathUser: Codable, Identifiable {
    let id: String
    var displayName: String
    var email: String?
    var photoURL: String?
    var region: LeaderboardRegion
    var countryCode: String
    var createdAt: Date
    var lastActiveAt: Date
    var isAnonymous: Bool
    
    // Stats
    var currentStreak: Int
    var longestStreak: Int
    var totalPerfectGames: Int
    var totalGamesPlayed: Int
    var lastStreakRecoveryDate: Date?
    
    init(id: String, displayName: String, countryCode: String = "US", isAnonymous: Bool = false) {
        self.id = id
        self.displayName = displayName
        self.email = nil
        self.photoURL = nil
        self.countryCode = countryCode
        self.region = LeaderboardRegion.region(for: countryCode)
        self.createdAt = Date()
        self.lastActiveAt = Date()
        self.isAnonymous = isAnonymous
        self.currentStreak = 0
        self.longestStreak = 0
        self.totalPerfectGames = 0
        self.totalGamesPlayed = 0
        self.lastStreakRecoveryDate = nil
    }
}

// MARK: - Auth Service
class AuthService: NSObject, ObservableObject {
    static let shared = AuthService()
    
    @Published var currentUser: PathUser?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Computed property for view compatibility
    var isSignedIn: Bool { isAuthenticated }
    
    private var currentNonce: String?
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    override init() {
        super.init()
        setupAuthStateListener()
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    // MARK: - Auth State
    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if let user = user {
                    await self?.fetchUserData(userId: user.uid)
                } else {
                    self?.currentUser = nil
                    self?.isAuthenticated = false
                }
            }
        }
    }
    
    // MARK: - Sign in with Apple
    func signInWithApple() {
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.performRequests()
    }
    
    // MARK: - Anonymous Sign In (for users who don't want to create an account)
    func signInAnonymously() async {
        isLoading = true
        do {
            let result = try await Auth.auth().signInAnonymously()
            await createUserIfNeeded(userId: result.user.uid, displayName: "Player", isAnonymous: true)
            await MainActor.run {
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Sign Out
    func signOut() {
        do {
            try Auth.auth().signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Delete Account
    func deleteAccount() async {
        guard let user = Auth.auth().currentUser,
              let pathUser = currentUser else { return }
        
        isLoading = true
        
        do {
            // Delete user data from Firestore
            let db = FirebaseService.shared.db
            try await db.collection("users").document(pathUser.id).delete()
            try await db.collection("userStats").document(pathUser.id).delete()
            
            // Delete Firebase Auth account
            try await user.delete()
            
            await MainActor.run {
                self.currentUser = nil
                self.isAuthenticated = false
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    #if os(iOS)
    // MARK: - Handle Sign In With Apple Result (SwiftUI)
    func handleSignInWithApple(result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let nonce = currentNonce,
                  let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                await MainActor.run {
                    self.errorMessage = "Unable to fetch identity token"
                }
                return
            }
            
            let credential = OAuthProvider.appleCredential(
                withIDToken: idTokenString,
                rawNonce: nonce,
                fullName: appleIDCredential.fullName
            )
            
            do {
                let authResult = try await Auth.auth().signIn(with: credential)
                
                // Get display name from Apple credential
                var displayName = "Player"
                if let fullName = appleIDCredential.fullName {
                    let givenName = fullName.givenName ?? ""
                    let familyName = fullName.familyName ?? ""
                    displayName = "\(givenName) \(familyName)".trimmingCharacters(in: .whitespaces)
                    if displayName.isEmpty {
                        displayName = "Player"
                    }
                }
                
                await createUserIfNeeded(userId: authResult.user.uid, displayName: displayName)
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
            
        case .failure(let error):
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    // Prepare for Sign in with Apple
    func prepareSignInWithApple() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return sha256(nonce)
    }
    #endif
    
    // MARK: - User Data
    @MainActor
    private func fetchUserData(userId: String) async {
        let db = FirebaseService.shared.db
        
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            
            if document.exists, let data = document.data() {
                self.currentUser = try? Firestore.Decoder().decode(PathUser.self, from: data)
                self.isAuthenticated = true
            } else {
                // Create new user
                await createUserIfNeeded(userId: userId, displayName: Auth.auth().currentUser?.displayName ?? "Player")
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    private func createUserIfNeeded(userId: String, displayName: String, isAnonymous: Bool = false) async {
        let db = FirebaseService.shared.db
        
        // Get country code from locale
        let countryCode = Locale.current.region?.identifier ?? "US"
        
        let newUser = PathUser(id: userId, displayName: displayName, countryCode: countryCode, isAnonymous: isAnonymous)
        
        do {
            try db.collection("users").document(userId).setData(from: newUser)
            await MainActor.run {
                self.currentUser = newUser
                self.isAuthenticated = true
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    // MARK: - Update User
    func updateUser(_ user: PathUser) async {
        let db = FirebaseService.shared.db
        
        do {
            try db.collection("users").document(user.id).setData(from: user, merge: true)
            await MainActor.run {
                self.currentUser = user
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    // MARK: - Helpers
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AuthService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let nonce = currentNonce,
              let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            errorMessage = "Unable to fetch identity token"
            return
        }
        
        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )
        
        Task {
            do {
                let result = try await Auth.auth().signIn(with: credential)
                
                // Get display name from Apple credential
                var displayName = "Player"
                if let fullName = appleIDCredential.fullName {
                    let givenName = fullName.givenName ?? ""
                    let familyName = fullName.familyName ?? ""
                    displayName = "\(givenName) \(familyName)".trimmingCharacters(in: .whitespaces)
                    if displayName.isEmpty {
                        displayName = "Player"
                    }
                }
                
                await createUserIfNeeded(userId: result.user.uid, displayName: displayName)
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        errorMessage = error.localizedDescription
    }
}
