//
//  GoogleConfig.swift
//  BentoInbox
//
//  Created by Bryce Barrand on 11/12/25.
//

import Foundation

/// Configuration for Google OAuth and Gmail API
enum GoogleConfig {
    
    /// Your OAuth 2.0 Client ID from Google Cloud Console
    /// Get this from: https://console.cloud.google.com/apis/credentials
    static let clientID = "497206286090-vn7nj9dn088g8ap8gr52tncj83v0b8be.apps.googleusercontent.com"
    
    /// Gmail API Scopes
    static let gmailScopes = [
        "https://www.googleapis.com/auth/gmail.readonly"
    ]
    
    /// URL Scheme for OAuth callback
    /// This should match the reversed client ID (e.g., "com.googleusercontent.apps.YOUR_CLIENT_ID")
    static var urlScheme: String {
        let parts = clientID.split(separator: ".")
        return parts.reversed().joined(separator: ".")
    }
}
