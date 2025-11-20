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

// MARK: - LLM Analysis

struct LLMEmailAnalysis: Codable {
    let summary: String
    var tags: [String]  // Changed to var so we can validate/filter
    let intent: String
    let urgency: String
    let requiresResponse: Bool
    let isActionable: Bool
    let senderCategory: String
    let hasDeadline: Bool
    let mentionsMoney: Bool
    let mentionsYouDirectly: Bool
}

protocol LLMAnalysisService: AnyObject {
    func isAvailable() -> Bool
    func analyzeEmail(subject: String?, body: String, from: String) async throws -> LLMEmailAnalysis
}

protocol ContactsService: AnyObject {
    func isInContacts(email: String) async -> Bool
    func getContactName(for email: String) async -> String?
}

private struct LLMAnalysisServiceKey: EnvironmentKey {
    static let defaultValue: LLMAnalysisService = MockLLMAnalysisService()
}
extension EnvironmentValues {
    var llmAnalysisService: LLMAnalysisService {
        get { self[LLMAnalysisServiceKey.self] }
        set { self[LLMAnalysisServiceKey.self] = newValue }
    }
}

private struct ContactsServiceKey: EnvironmentKey {
    static let defaultValue: ContactsService = SystemContactsService()
}
extension EnvironmentValues {
    var contactsService: ContactsService {
        get { self[ContactsServiceKey.self] }
        set { self[ContactsServiceKey.self] = newValue }
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

final class MockLLMAnalysisService: LLMAnalysisService {
    private let contactsService: ContactsService
    
    init(contactsService: ContactsService = SystemContactsService()) {
        self.contactsService = contactsService
    }
    
    func isAvailable() -> Bool {
        return true  // Mock is always available
    }
    
    func analyzeEmail(subject: String?, body: String, from: String) async throws -> LLMEmailAnalysis {
        // Simulate processing delay
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        // Generate mock tags based on subject/body content
        let text = "\(subject ?? "") \(body)".lowercased()
        var tags: [String] = []
        
        // MOST IMPORTANT: Detect if sender is a real person (high priority signal!)
        let isPersonalSender = await detectPersonalSender(from: from, contactsService: contactsService)
        if isPersonalSender {
            tags.append("personal-sender")
        }
        
        // Content-based tags (using only our predefined tags!)
        if text.contains("meeting") || text.contains("calendar") || text.contains("schedule") {
            tags.append("meeting")
        }
        if text.contains("travel") || text.contains("flight") || text.contains("hotel") {
            tags.append("travel")
        }
        if text.contains("invoice") || text.contains("payment") || text.contains("$") || text.contains("paid") {
            tags.append("financial")
        }
        if text.contains("receipt") || text.contains("confirmation") || text.contains("order") {
            tags.append("receipt")
        }
        if text.contains("project") || text.contains("task") || text.contains("deadline") {
            tags.append("work-project")
        }
        if text.contains("newsletter") || text.contains("unsubscribe") {
            tags.append("newsletter")
        }
        if text.contains("urgent") || text.contains("asap") || text.contains("immediately") {
            tags.append("urgent")
        }
        if text.contains("?") {
            tags.append("question")
        }
        if text.contains("please") || text.contains("need") || text.contains("required") {
            tags.append("action-required")
        }
        if text.contains("facebook") || text.contains("twitter") || text.contains("instagram") || text.contains("linkedin") {
            tags.append("social")
        }
        
        // Add "general" if no content tags matched (excluding personal-sender which is metadata)
        let contentTags = tags.filter { $0 != "personal-sender" }
        if contentTags.isEmpty {
            tags.append("general")
        }
        
        // Limit to 3 tags max (keep most specific ones)
        if tags.count > 3 {
            tags = Array(tags.prefix(3))
        }
        
        // Intent classification
        let intent: String
        if text.contains("?") || text.contains("can you") || text.contains("could you") {
            intent = "question"
        } else if text.contains("please") || text.contains("need") || text.contains("required") {
            intent = "action-required"
        } else if text.contains("buy") || text.contains("offer") || text.contains("sale") || text.contains("discount") {
            intent = "promotional"
        } else if text.contains("receipt") || text.contains("confirmation") || text.contains("order") {
            intent = "transactional"
        } else {
            intent = "informational"
        }
        
        // Urgency
        let urgency: String
        if text.contains("urgent") || text.contains("asap") || text.contains("immediately") {
            urgency = "immediate"
        } else if text.contains("today") || text.contains("eod") || text.contains("this week") {
            urgency = "soon"
        } else if text.contains("whenever") || text.contains("no rush") {
            urgency = "low"
        } else {
            urgency = "normal"
        }
        
        // Sender category
        let senderCategory: String
        let domain = from.split(separator: "@").last?.lowercased() ?? ""
        if domain.contains("noreply") || domain.contains("no-reply") {
            senderCategory = "service"
        } else if domain.contains("marketing") || domain.contains("promo") {
            senderCategory = "marketing"
        } else if domain.contains("gmail") || domain.contains("yahoo") || domain.contains("hotmail") {
            senderCategory = "personal"
        } else {
            senderCategory = "colleague"
        }
        
        // Boolean flags
        let requiresResponse = intent == "question" || text.contains("please respond") || text.contains("let me know")
        let isActionable = intent == "action-required" || text.contains("please") || text.contains("need you to")
        let hasDeadline = text.contains("deadline") || text.contains("due") || text.contains("by ")
        let mentionsMoney = text.contains("$") || text.contains("payment") || text.contains("invoice") || text.contains("cost")
        let mentionsYouDirectly = text.contains("you ") || text.contains("your ")
        
        // Generate summary
        let summary: String
        if let subj = subject, !subj.isEmpty {
            summary = "Email about: \(subj.prefix(60))\(subj.count > 60 ? "..." : "")"
        } else {
            let bodyPreview = body.prefix(80).trimmingCharacters(in: .whitespacesAndNewlines)
            summary = bodyPreview.isEmpty ? "No content available" : "\(bodyPreview)..."
        }
        
        return LLMEmailAnalysis(
            summary: summary,
            tags: tags,
            intent: intent,
            urgency: urgency,
            requiresResponse: requiresResponse,
            isActionable: isActionable,
            senderCategory: senderCategory,
            hasDeadline: hasDeadline,
            mentionsMoney: mentionsMoney,
            mentionsYouDirectly: mentionsYouDirectly
        )
    }
    
    // MARK: - Helper: Detect Personal Sender (Enhanced with Contacts)
    
    /// Detects if an email comes from a real person (friend, family, colleague)
    /// vs. automated systems, marketing, or companies
    ///
    /// Priority order:
    /// 1. Check Contacts (highest confidence)
    /// 2. Check for disqualifying keywords
    /// 3. Check email patterns and domains
    private func detectPersonalSender(from: String, contactsService: ContactsService) async -> Bool {
        // Extract email address from "Name <email>" format
        let emailAddress = extractEmailAddress(from: from)
        
        // STEP 1: Check Contacts (HIGHEST CONFIDENCE)
        // If sender is in your contacts, they're definitely a personal sender
        let inContacts = await contactsService.isInContacts(email: emailAddress)
        if inContacts {
            return true  // ✅ In contacts = definitely personal!
        }
        
        let lowercased = from.lowercased()
        
        // STEP 2: Check for STRONG disqualifiers (immediate rejection)
        let strongDisqualifiers = [
            // Automated systems
            "noreply", "no-reply", "donotreply", "do-not-reply", "do_not_reply",
            "automated", "notification", "notifications", "notify",
            "bounce", "mailer-daemon", "postmaster",
            // Marketing
            "newsletter", "newsletters", "marketing", "promo", "promotions",
            "unsubscribe",  // Strong signal for newsletters
            // Support/team
            "support", "help", "info", "contact",
            "team@", "hello@", "hi@", "hey@",
            "sales", "accounts", "billing"
        ]
        
        for keyword in strongDisqualifiers {
            if lowercased.contains(keyword) {
                return false  // ❌ Definitely automated/marketing
            }
        }
        
        // STEP 3: Check for sender name patterns that suggest automation
        // e.g., "Company Name <email>" vs "John Doe <email>"
        let automatedNamePatterns = [
            "via ", "by ", "updates", "digest", "alert",
            "subscription", "service"
        ]
        
        for pattern in automatedNamePatterns {
            if lowercased.contains(pattern) {
                return false  // ❌ Likely automated
            }
        }
        
        // STEP 4: Check if sender has a REAL name format
        let hasRealName = hasPersonName(from: from)
        
        // STEP 5: Extract domain and check type
        let domain = emailAddress.split(separator: "@").last?.lowercased() ?? ""
        
        // Personal email domains (strong positive signal)
        let personalDomains = [
            "gmail.com", "googlemail.com",
            "yahoo.com", "ymail.com", "yahoo.co",
            "hotmail.com", "outlook.com", "live.com", "msn.com",
            "icloud.com", "me.com", "mac.com",
            "aol.com",
            "protonmail.com", "proton.me", "pm.me"
        ]
        
        let isPersonalDomain = personalDomains.contains(where: { domain.hasSuffix($0) })
        
        // STEP 6: Scoring logic with improved heuristics
        
        // ✅ Personal domain + real name = HIGH CONFIDENCE
        if isPersonalDomain && hasRealName {
            return true
        }
        
        // ✅ Personal domain + simple email (not too many dots/numbers)
        if isPersonalDomain && !emailAddress.contains("@") {
            let localPart = emailAddress.split(separator: "@").first ?? ""
            let isSimpleEmail = String(localPart).filter { $0 == "." }.count <= 2
            if isSimpleEmail {
                return true
            }
        }
        
        // ✅ Work colleague: real name + simple corporate domain
        if hasRealName && !domain.isEmpty {
            let domainParts = domain.split(separator: ".")
            // Simple domains like "company.com" or "startup.io"
            if domainParts.count == 2 {
                return true
            }
        }
        
        // ✅ Single letter first name (common pattern): "M. Smith <m.smith@company.com>"
        if from.matches(of: /^[A-Z]\.\s+[A-Z][a-z]+\s+</).count > 0 {
            return true
        }
        
        // Default: not detected as personal
        return false
    }
    
    /// Extract just the email address from "Name <email@domain.com>" format
    private func extractEmailAddress(from: String) -> String {
        if let emailStart = from.range(of: "<")?.upperBound,
           let emailEnd = from.range(of: ">")?.lowerBound {
            return String(from[emailStart..<emailEnd]).trimmingCharacters(in: .whitespaces)
        }
        return from.trimmingCharacters(in: .whitespaces)
    }
    
    /// Check if the sender has a real person name (not just an email address)
    private func hasPersonName(from: String) -> Bool {
        // Must have < and > to have a name
        guard from.contains("<") && from.contains(">") else {
            return false
        }
        
        // Extract the name part (before <)
        guard let nameEnd = from.range(of: "<")?.lowerBound else {
            return false
        }
        
        let name = String(from[from.startIndex..<nameEnd]).trimmingCharacters(in: .whitespaces)
        
        // Name must not be empty
        guard !name.isEmpty else {
            return false
        }
        
        // Name should have at least 2 characters
        guard name.count >= 2 else {
            return false
        }
        
        // Check for common automated patterns in names
        let automatedInName = [
            "update", "alert", "notification", "team",
            "newsletter", "digest", "service"
        ]
        
        let lowercasedName = name.lowercased()
        for pattern in automatedInName {
            if lowercasedName.contains(pattern) {
                return false
            }
        }
        
        // If name has letters and possibly spaces/dots, it's likely a person
        let hasLetters = name.rangeOfCharacter(from: .letters) != nil
        return hasLetters
    }
}

// MARK: - Contacts Service

#if os(macOS)
import Contacts

final class SystemContactsService: ContactsService {
    private let store = CNContactStore()
    
    func isInContacts(email: String) async -> Bool {
        // Request access if needed
        let status = CNContactStore.authorizationStatus(for: .contacts)
        
        guard status == .authorized || status == .notDetermined else {
            return false
        }
        
        // Request permission if not determined
        if status == .notDetermined {
            do {
                let granted = try await store.requestAccess(for: .contacts)
                guard granted else { return false }
            } catch {
                return false
            }
        }
        
        // Search for contact by email
        let predicate = CNContact.predicateForContacts(matchingEmailAddress: email)
        let keysToFetch = [CNContactEmailAddressesKey as CNKeyDescriptor]
        
        do {
            let contacts = try store.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)
            return !contacts.isEmpty
        } catch {
            return false
        }
    }
    
    func getContactName(for email: String) async -> String? {
        let predicate = CNContact.predicateForContacts(matchingEmailAddress: email)
        let keysToFetch = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor
        ]
        
        do {
            let contacts = try store.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)
            guard let contact = contacts.first else { return nil }
            return "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
        } catch {
            return nil
        }
    }
}
#else
import Contacts

final class SystemContactsService: ContactsService {
    private let store = CNContactStore()
    
    func isInContacts(email: String) async -> Bool {
        // Request access if needed
        let status = CNContactStore.authorizationStatus(for: .contacts)
        
        guard status == .authorized || status == .notDetermined else {
            return false
        }
        
        // Request permission if not determined
        if status == .notDetermined {
            do {
                let granted = try await store.requestAccess(for: .contacts)
                guard granted else { return false }
            } catch {
                return false
            }
        }
        
        // Search for contact by email
        let predicate = CNContact.predicateForContacts(matchingEmailAddress: email)
        let keysToFetch = [CNContactEmailAddressesKey as CNKeyDescriptor]
        
        do {
            let contacts = try store.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)
            return !contacts.isEmpty
        } catch {
            return false
        }
    }
    
    func getContactName(for email: String) async -> String? {
        let predicate = CNContact.predicateForContacts(matchingEmailAddress: email)
        let keysToFetch = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor
        ]
        
        do {
            let contacts = try store.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)
            guard let contact = contacts.first else { return nil }
            return "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
        } catch {
            return nil
        }
    }
}
#endif

// MARK: - Ollama LLM Service

final class OllamaLLMAnalysisService: LLMAnalysisService {
    private let contactsService: ContactsService
    private let baseURL = "http://localhost:11434"
    private let model: String
    
    // MARK: - Predefined Tags
    // The AI can ONLY choose from these tags - no new tags allowed!
    static let allowedTags = [
        "personal-sender",  // Real person in contacts or clearly personal
        "urgent",           // Time-sensitive, immediate attention
        "question",         // Someone asking you something
        "action-required",  // You need to do something
        "meeting",          // Meeting invites, calendar events
        "travel",           // Travel, reservations, trips
        "financial",        // Money, invoices, payments, receipts
        "work-project",     // Work-related projects
        "newsletter",       // Newsletters, bulk emails
        "receipt",          // Purchase confirmations
        "social",           // Social media notifications
        "general"           // Everything else
    ]
    
    init(contactsService: ContactsService = SystemContactsService(), model: String = "llama3.1:8b") {
        self.contactsService = contactsService
        self.model = model
    }
    
    func isAvailable() -> Bool {
        // Check if Ollama is running
        guard let url = URL(string: "\(baseURL)/api/tags") else { return false }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 2.0
        
        let semaphore = DispatchSemaphore(value: 0)
        var isRunning = false
        
        URLSession.shared.dataTask(with: request) { _, response, _ in
            if let httpResponse = response as? HTTPURLResponse {
                isRunning = httpResponse.statusCode == 200
            }
            semaphore.signal()
        }.resume()
        
        _ = semaphore.wait(timeout: .now() + 2)
        return isRunning
    }
    
    func analyzeEmail(subject: String?, body: String, from: String) async throws -> LLMEmailAnalysis {
        let emailAddress = extractEmailAddress(from: from)
        let inContacts = await contactsService.isInContacts(email: emailAddress)
        
        // Truncate body to avoid token limits
        let truncatedBody = String(body.prefix(2000))
        
        let allowedTagsList = Self.allowedTags.map { "  - \"\($0)\"" }.joined(separator: "\n")
        
        let prompt = """
        Analyze this email and extract structured information. You MUST return ONLY valid JSON with no other text.
        
        Email:
        From: \(from)
        Subject: \(subject ?? "No subject")
        Body: \(truncatedBody)
        
        Additional context:
        - Sender is\(inContacts ? "" : " NOT") in user's contacts
        
        Return JSON with these EXACT fields:
        {
          "summary": "One sentence summary of the email",
          "tags": ["tag1", "tag2"],
          "intent": "question",
          "urgency": "normal",
          "requiresResponse": false,
          "isActionable": false,
          "senderCategory": "colleague",
          "hasDeadline": false,
          "mentionsMoney": false,
          "mentionsYouDirectly": false
        }
        
        IMPORTANT - Tag Rules:
        You MUST choose tags ONLY from this list (do NOT make up new tags):
\(allowedTagsList)
        
        Tag selection guidelines:
        - Choose 1-3 tags maximum (most emails need 1-2 tags)
        - Use "personal-sender" ONLY if: sender is in contacts OR clearly a real person (not automated/marketing)
        - Exclude "personal-sender" if email contains: "newsletter", "unsubscribe", "noreply", "no-reply", "automated", "team@", "support@"
        - Use "general" for emails that don't fit other categories
        - Prioritize more specific tags over "general"
        
        Intent options (choose ONE):
        - "question": Sender is asking you something
        - "action-required": You need to do something
        - "informational": FYI, no action needed
        - "promotional": Marketing, sales, offers
        - "transactional": Receipts, confirmations, automated
        
        Urgency options (choose ONE):
        - "immediate": Urgent, ASAP
        - "soon": Within a day or two
        - "normal": Normal priority
        - "low": Can wait, FYI
        
        SenderCategory options (choose ONE):
        - "colleague": Work colleague
        - "client": External business contact
        - "service": Automated service (GitHub, AWS, etc.)
        - "marketing": Promotional emails
        - "personal": Friends and family
        - "unknown": First-time sender
        
        Return ONLY the JSON object, no markdown, no code blocks, no explanations.
        """
        
        let request = OllamaRequest(
            model: model,
            prompt: prompt,
            stream: false,
            format: "json",
            options: OllamaOptions(temperature: 0.3, num_predict: 512)
        )
        
        let response = try await sendOllamaRequest(request)
        
        // Clean up response (remove markdown code blocks if present)
        var cleanedResponse = response.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanedResponse.hasPrefix("```json") {
            cleanedResponse = cleanedResponse.replacingOccurrences(of: "```json", with: "")
        }
        if cleanedResponse.hasPrefix("```") {
            cleanedResponse = cleanedResponse.replacingOccurrences(of: "```", with: "")
        }
        if cleanedResponse.hasSuffix("```") {
            cleanedResponse = String(cleanedResponse.dropLast(3))
        }
        cleanedResponse = cleanedResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Parse JSON response
        guard let data = cleanedResponse.data(using: .utf8) else {
            throw NSError(domain: "OllamaService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to convert response to data"
            ])
        }
        
        do {
            var analysis = try JSONDecoder().decode(LLMEmailAnalysis.self, from: data)
            
            // ✅ Validate and filter tags to only allowed ones
            let allowedTagsSet = Set(Self.allowedTags)
            let validTags = analysis.tags.filter { allowedTagsSet.contains($0.lowercased()) }
            
            // If AI made up tags, log them and use valid ones only
            if validTags.count < analysis.tags.count {
                let invalidTags = analysis.tags.filter { !allowedTagsSet.contains($0.lowercased()) }
                print("⚠️ LLM used invalid tags (ignored): \(invalidTags.joined(separator: ", "))")
            }
            
            // Ensure at least "general" tag if no valid tags
            analysis.tags = validTags.isEmpty ? ["general"] : validTags
            
            return analysis
        } catch {
            print("❌ Failed to parse Ollama response:")
            print(cleanedResponse)
            throw NSError(domain: "OllamaService", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "Failed to parse LLM response: \(error.localizedDescription)"
            ])
        }
    }
    
    private func sendOllamaRequest(_ request: OllamaRequest) async throws -> String {
        guard let url = URL(string: "\(baseURL)/api/generate") else {
            throw NSError(domain: "OllamaService", code: 3, userInfo: [
                NSLocalizedDescriptionKey: "Invalid URL"
            ])
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        urlRequest.timeoutInterval = 60
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "OllamaService", code: 4, userInfo: [
                NSLocalizedDescriptionKey: "Invalid response"
            ])
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NSError(domain: "OllamaService", code: 5, userInfo: [
                NSLocalizedDescriptionKey: "Ollama request failed with status \(httpResponse.statusCode)"
            ])
        }
        
        let ollamaResponse = try JSONDecoder().decode(OllamaResponse.self, from: data)
        return ollamaResponse.response
    }
    
    private func extractEmailAddress(from: String) -> String {
        if let emailStart = from.range(of: "<")?.upperBound,
           let emailEnd = from.range(of: ">")?.lowerBound {
            return String(from[emailStart..<emailEnd]).trimmingCharacters(in: .whitespaces)
        }
        return from.trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - Ollama API Models

struct OllamaRequest: Codable {
    let model: String
    let prompt: String
    let stream: Bool
    let format: String?
    let options: OllamaOptions?
}

struct OllamaOptions: Codable {
    let temperature: Double
    let num_predict: Int?
    
    enum CodingKeys: String, CodingKey {
        case temperature
        case num_predict = "num_predict"
    }
}

struct OllamaResponse: Codable {
    let response: String
    let done: Bool
}

struct OllamaModel: Codable, Identifiable {
    let name: String
    let size: Int64
    let modifiedAt: String
    
    var id: String { name }
    
    enum CodingKeys: String, CodingKey {
        case name
        case size
        case modifiedAt = "modified_at"
    }
}

struct OllamaModelsResponse: Codable {
    let models: [OllamaModel]
}

// MARK: - Ollama Model Manager

final class OllamaModelManager: ObservableObject {
    @Published var availableModels: [OllamaModel] = []
    @Published var selectedModel: String = "llama3.1:8b"
    @Published var isLoading = false
    @Published var error: String?
    
    private let baseURL = "http://localhost:11434"
    
    func fetchAvailableModels() async {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        guard let url = URL(string: "\(baseURL)/api/tags") else {
            await MainActor.run {
                error = "Invalid URL"
                isLoading = false
            }
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                await MainActor.run {
                    error = "Failed to fetch models"
                    isLoading = false
                }
                return
            }
            
            let modelsResponse = try JSONDecoder().decode(OllamaModelsResponse.self, from: data)
            
            await MainActor.run {
                availableModels = modelsResponse.models
                isLoading = false
                
                // If selected model doesn't exist, pick the first one
                if !modelsResponse.models.contains(where: { $0.name == selectedModel }),
                   let firstModel = modelsResponse.models.first {
                    selectedModel = firstModel.name
                }
            }
        } catch {
            await MainActor.run {
                self.error = "Error: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    func isOllamaRunning() async -> Bool {
        guard let url = URL(string: "\(baseURL)/api/tags") else { return false }
        
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
        } catch {}
        
        return false
    }
}

