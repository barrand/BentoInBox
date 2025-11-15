//
//  GoogleAuthService.swift
//  BentoInbox
//
//  Created by Bryce Barrand on 11/12/25.
//

import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import GoogleSignIn

/// Real implementation of AuthService using Google Sign-In SDK
final class GoogleAuthService: AuthService {
    
    // MARK: - Configuration
    
    private var clientID: String {
        GoogleConfig.clientID
    }
    
    // MARK: - Initialization
    
    init() {
        // Restore previous sign-in if available
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            if let error = error as NSError? {
                // Error -4 means no previous user, which is expected on first launch
                if error.code != -4 {
                    print("Failed to restore previous sign-in: \(error.localizedDescription)")
                }
            } else if user != nil {
                print("Successfully restored previous sign-in")
            }
        }
    }
    
    // MARK: - AuthService Protocol
    
    func isSignedIn() async -> Bool {
        return GIDSignIn.sharedInstance.currentUser != nil
    }
    
    func signIn() async throws {
        #if canImport(UIKit)
        guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = await windowScene.windows.first?.rootViewController else {
            throw AuthError.noRootViewController
        }
        
        let configuration = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = configuration
        
        return try await withCheckedThrowingContinuation { continuation in
            GIDSignIn.sharedInstance.signIn(
                withPresenting: rootViewController,
                hint: nil,
                additionalScopes: GoogleConfig.gmailScopes
            ) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if result != nil {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: AuthError.signInFailed)
                }
            }
        }
        #elseif canImport(AppKit)
        guard let window = NSApplication.shared.windows.first else {
            throw AuthError.noRootViewController
        }
        
        let configuration = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = configuration
        
        return try await withCheckedThrowingContinuation { continuation in
            GIDSignIn.sharedInstance.signIn(
                withPresenting: window,
                hint: nil,
                additionalScopes: GoogleConfig.gmailScopes
            ) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if result != nil {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: AuthError.signInFailed)
                }
            }
        }
        #else
        throw AuthError.noRootViewController
        #endif
    }
    
    func signOut() async throws {
        GIDSignIn.sharedInstance.signOut()
    }
    
    func validAccessToken() async throws -> String {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            throw AuthError.notSignedIn
        }
        
        // Check if token needs refresh
        if let expirationDate = user.accessToken.expirationDate,
           expirationDate < Date() {
            return try await refreshAccessToken(for: user)
        }
        
        return user.accessToken.tokenString
    }
    
    func accountEmail() async -> String? {
        return GIDSignIn.sharedInstance.currentUser?.profile?.email
    }
    
    // MARK: - Private Helpers
    
    private func refreshAccessToken(for user: GIDGoogleUser) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            user.refreshTokensIfNeeded { user, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let user = user {
                    continuation.resume(returning: user.accessToken.tokenString)
                } else {
                    continuation.resume(throwing: AuthError.tokenRefreshFailed)
                }
            }
        }
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case notSignedIn
    case signInFailed
    case tokenRefreshFailed
    case noRootViewController
    
    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "User is not signed in"
        case .signInFailed:
            return "Sign in failed"
        case .tokenRefreshFailed:
            return "Failed to refresh access token"
        case .noRootViewController:
            return "Could not find root view controller"
        }
    }
}
