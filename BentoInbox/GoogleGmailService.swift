//
//  GoogleGmailService.swift
//  BentoInbox
//
//  Created by Bryce Barrand on 11/12/25.
//

import Foundation

/// Real implementation of GmailService using Gmail REST API
final class GoogleGmailService: GmailService {
    
    private let authService: AuthService
    private let baseURL = "https://gmail.googleapis.com/gmail/v1/users/me"
    
    init(authService: AuthService) {
        self.authService = authService
    }
    
    // MARK: - GmailService Protocol
    
    func listMessageIds(labelIds: [String], maxResults: Int, pageToken: String?) async throws -> (ids: [String], nextPageToken: String?) {
        let token = try await authService.validAccessToken()
        
        var components = URLComponents(string: "\(baseURL)/messages")!
        var queryItems = [URLQueryItem]()
        
        for labelId in labelIds {
            queryItems.append(URLQueryItem(name: "labelIds", value: labelId))
        }
        queryItems.append(URLQueryItem(name: "maxResults", value: "\(maxResults)"))
        
        if let pageToken = pageToken {
            queryItems.append(URLQueryItem(name: "pageToken", value: pageToken))
        }
        
        components.queryItems = queryItems
        
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GmailError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw GmailError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let result = try JSONDecoder().decode(MessageListResponse.self, from: data)
        let ids = result.messages?.map { $0.id } ?? []
        
        return (ids: ids, nextPageToken: result.nextPageToken)
    }
    
    func getMessageMetadata(id: String) async throws -> GmailMessageMetadata {
        let token = try await authService.validAccessToken()
        
        var components = URLComponents(string: "\(baseURL)/messages/\(id)")!
        components.queryItems = [
            URLQueryItem(name: "format", value: "metadata"),
            URLQueryItem(name: "metadataHeaders", value: "From"),
            URLQueryItem(name: "metadataHeaders", value: "To"),
            URLQueryItem(name: "metadataHeaders", value: "Subject"),
            URLQueryItem(name: "metadataHeaders", value: "Date")
        ]
        
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GmailError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw GmailError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let message = try JSONDecoder().decode(GmailMessage.self, from: data)
        return message.toMetadata()
    }
    
    func currentUserEmail() async -> String? {
        return await authService.accountEmail()
    }
}

// MARK: - Gmail Errors

enum GmailError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from Gmail API"
        case .httpError(let statusCode):
            return "Gmail API returned status code: \(statusCode)"
        case .decodingError:
            return "Failed to decode Gmail API response"
        }
    }
}

// MARK: - API Response Models

private struct MessageListResponse: Codable {
    let messages: [MessageStub]?
    let nextPageToken: String?
    let resultSizeEstimate: Int?
}

private struct MessageStub: Codable {
    let id: String
    let threadId: String
}

private struct GmailMessage: Codable {
    let id: String
    let threadId: String
    let labelIds: [String]?
    let snippet: String?
    let payload: MessagePayload?
    let internalDate: String?
    
    func toMetadata() -> GmailMessageMetadata {
        let headers = payload?.headers ?? []
        
        let from = headers.first(where: { $0.name.lowercased() == "from" })?.value
        let to = headers.first(where: { $0.name.lowercased() == "to" })?.value
        let subject = headers.first(where: { $0.name.lowercased() == "subject" })?.value
        let dateString = headers.first(where: { $0.name.lowercased() == "date" })?.value
        
        // Parse date from string or use internalDate
        var date: Date?
        if let dateString = dateString {
            date = parseEmailDate(dateString)
        } else if let internalDate = internalDate, let timestamp = Double(internalDate) {
            date = Date(timeIntervalSince1970: timestamp / 1000.0)
        }
        
        let labels = labelIds ?? []
        
        return GmailMessageMetadata(
            id: id,
            threadId: threadId,
            date: date,
            from: from,
            to: to,
            subject: subject,
            snippet: snippet,
            labelIds: labels
        )
    }
}

private struct MessagePayload: Codable {
    let headers: [MessageHeader]?
}

private struct MessageHeader: Codable {
    let name: String
    let value: String
}

// MARK: - Date Parsing Helpers

private func parseEmailDate(_ dateString: String) -> Date? {
    // Email dates can be in RFC 2822 format like: "Wed, 12 Nov 2025 10:30:00 -0800"
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "EEE, d MMM yyyy HH:mm:ss Z"
    
    if let date = formatter.date(from: dateString) {
        return date
    }
    
    // Try alternative format without day of week
    formatter.dateFormat = "d MMM yyyy HH:mm:ss Z"
    if let date = formatter.date(from: dateString) {
        return date
    }
    
    // Try ISO 8601
    if let date = ISO8601DateFormatter().date(from: dateString) {
        return date
    }
    
    return nil
}
