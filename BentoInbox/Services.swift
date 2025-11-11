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

protocol GmailService: AnyObject {
    func listMessageIds(labelIds: [String], maxResults: Int, pageToken: String?) async throws -> (ids: [String], nextPageToken: String?)
    func getMessageMetadata(id: String) async throws -> GmailMessageMetadata
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

    func currentUserEmail() async -> String? { "you@example.com" }
}

