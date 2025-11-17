//
//  Services.swift
//  BentoInbox
//
//  Created by Bryce Barrand on 11/11/25.
//

import Foundation
import SwiftUI

// MARK: - Auth

struct OAuthTokens {
    let accessToken: String
    let refreshToken: String
    let expiry: Date
}

protocol AuthService: AnyObject {
    func isSignedIn() async -> Bool
    func signIn() async throws
    func signOut() async throws
    func validAccessToken() async throws -> String
    func accountEmail() async -> String?
}

// Simple environment key to inject services
private struct AuthServiceKey: EnvironmentKey {
    static let defaultValue: AuthService = MockAuthService()
}
extension EnvironmentValues {
    var authService: AuthService {
        get { self[AuthServiceKey.self] }
        set { self[AuthServiceKey.self] = newValue }
    }
}

// MARK: - Gmail

struct GmailMessageMetadata {
    let id: String
    let threadId: String
    let date: Date?
    let from: String?
    let to: String?
    let subject: String?
    let snippet: String?
    let labelIds: [String]
    var isRead: Bool { !labelIds.contains("UNREAD") }
}

struct GmailMessageBody {
    let plain: String?
    let html: String?
    
    var hasHTML: Bool {
        html != nil && !(html?.isEmpty ?? true)
    }
    
    var hasPlainText: Bool {
        plain != nil && !(plain?.isEmpty ?? true)
    }
    
    var displayText: String {
        // Prefer plain text for fallback display
        if let plain = plain, !plain.isEmpty {
            return plain
        } else if let html = html, !html.isEmpty {
            // Simple HTML tag stripping (not perfect but works for basic cases)
            return html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        } else {
            return "No message content available"
        }
    }
}

protocol GmailService: AnyObject {
    func listMessageIds(labelIds: [String], maxResults: Int, pageToken: String?) async throws -> (ids: [String], nextPageToken: String?)
    func getMessageMetadata(id: String) async throws -> GmailMessageMetadata
    func getMessageBody(id: String) async throws -> GmailMessageBody
    func currentUserEmail() async -> String?
}

private struct GmailServiceKey: EnvironmentKey {
    static let defaultValue: GmailService = MockGmailService()
}
extension EnvironmentValues {
    var gmailService: GmailService {
        get { self[GmailServiceKey.self] }
        set { self[GmailServiceKey.self] = newValue }
    }
}

// MARK: - Mocks

final class MockAuthService: AuthService {
    private var signedIn = true // start signed-in for easier dev

    func isSignedIn() async -> Bool { signedIn }

    func signIn() async throws {
        signedIn = true
    }

    func signOut() async throws {
        signedIn = false
    }

    func validAccessToken() async throws -> String { "mock-token" }

    func accountEmail() async -> String? { "you@example.com" }
}

final class MockGmailService: GmailService {
    func listMessageIds(labelIds: [String], maxResults: Int, pageToken: String?) async throws -> (ids: [String], nextPageToken: String?) {
        let ids = (0..<25).map { "mock-\($0)" }
        return (ids, nil)
    }

    func getMessageMetadata(id: String) async throws -> GmailMessageMetadata {
        let now = Date()
        return GmailMessageMetadata(
            id: id,
            threadId: "thread-\(id)",
            date: now.addingTimeInterval(Double.random(in: -60_000...0)),
            from: "Sender \(Int.random(in: 1...50)) <sender@example.com>",
            to: "you@example.com",
            subject: "Subject for \(id)",
            snippet: "This is a snippet for \(id). It’s just mock data.",
            labelIds: Bool.random() ? ["INBOX"] : ["INBOX", "UNREAD"]
        )
    }
    
    func getMessageBody(id: String) async throws -> GmailMessageBody {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Return HTML for some messages, plain text for others
        let useHTML = Int(id.suffix(1), radix: 10).map { $0 % 2 == 0 } ?? false
        
        if useHTML {
            let mockHTML = """
            <div style="font-family: -apple-system, sans-serif;">
                <h2>Weekly Newsletter - Issue #\(id)</h2>
                <p>Hello there! 👋</p>
                
                <p>This is an <strong>HTML email</strong> with <em>formatting</em>.</p>
                
                <h3>This Week's Highlights</h3>
                <ul>
                    <li><strong>Feature Update:</strong> New dark mode support</li>
                    <li><strong>Bug Fix:</strong> Improved performance</li>
                    <li><strong>Coming Soon:</strong> Email templates</li>
                </ul>
                
                <blockquote>
                    "HTML emails can be beautifully formatted!"
                    <br>— BentoInbox Team
                </blockquote>
                
                <p>Here's a link to our website: <a href="https://example.com">Visit Example</a></p>
                
                <p><code>Code snippets</code> are also supported:</p>
                <pre>let greeting = "Hello, World!"</pre>
                <hr>
                <p style="color: #666; font-size: 12px;">
                    Best regards,<br>
                    The BentoInbox Team
                </p>
            </div>
            """
            return GmailMessageBody(plain: nil, html: mockHTML)
        } else {
            let mockPlainText = """
            Hello there!
            
            This is the full message body for message \(id).
            
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.
            
            Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
            
            Best regards,
            Mock Sender
            """
            return GmailMessageBody(plain: mockPlainText, html: nil)
        }
    }

    func currentUserEmail() async -> String? { "you@example.com" }
}

