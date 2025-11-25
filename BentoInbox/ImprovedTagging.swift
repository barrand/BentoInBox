//
//  ImprovedTagging.swift
//  BentoInbox
//
//  Created by Bryce Barrand on 11/20/25.
//
//  Quick wins for improving AI tagging accuracy
//

import Foundation

// MARK: - Tag Validation Rules

struct TagValidationRules {
    
    /// Tags that cannot appear together
    static let mutuallyExclusive: [[String]] = [
        ["personal-sender", "newsletter"],
        ["personal-sender", "recruiting"],
        ["personal-sender", "spam-likely"],
        ["spam-likely", "work-project"],
        ["spam-likely", "meeting"],
        ["newsletter", "meeting"],
        ["newsletter", "question"]
    ]
    
    /// If first tag is present, second tag is likely incorrect
    static let incompatiblePairs: [(primary: String, incompatible: String)] = [
        ("newsletter", "personal-sender"),
        ("recruiting", "personal-sender"),
        ("cold-outreach", "personal-sender"),
        ("spam-likely", "work-project"),
        ("spam-likely", "financial")
    ]
    
    /// Tags that should almost never appear with specific keywords in sender
    static let senderKeywordExclusions: [(keyword: String, excludedTag: String)] = [
        ("noreply", "personal-sender"),
        ("no-reply", "personal-sender"),
        ("newsletter", "personal-sender"),
        ("automated", "personal-sender"),
        ("unsubscribe", "personal-sender")
    ]
    
    /// Validate and clean up tag list
    /// - Parameters:
    ///   - tags: Raw tags from LLM
    ///   - sender: Email sender string
    /// - Returns: Validated tag list
    static func validate(_ tags: [String], sender: String = "") -> [String] {
        var validatedTags = tags
        
        // 1. Remove mutually exclusive tags (keep the first/most specific one)
        for exclusiveSet in mutuallyExclusive {
            let matches = validatedTags.filter { exclusiveSet.contains($0) }
            if matches.count > 1 {
                // Keep only the first match, remove others
                let firstMatch = matches[0]
                validatedTags.removeAll { exclusiveSet.contains($0) && $0 != firstMatch }
            }
        }
        
        // 2. Check incompatible pairs (if primary exists, remove incompatible)
        for pair in incompatiblePairs {
            if validatedTags.contains(pair.primary) {
                validatedTags.removeAll { $0 == pair.incompatible }
            }
        }
        
        // 3. Check sender keywords
        let lowercasedSender = sender.lowercased()
        for exclusion in senderKeywordExclusions {
            if lowercasedSender.contains(exclusion.keyword) {
                validatedTags.removeAll { $0 == exclusion.excludedTag }
            }
        }
        
        // 4. Ensure at least one tag remains
        if validatedTags.isEmpty {
            validatedTags = ["general"]
        }
        
        // 5. Limit to 3 tags max
        if validatedTags.count > 3 {
            validatedTags = Array(validatedTags.prefix(3))
        }
        
        return validatedTags
    }
}

// MARK: - Few-Shot Examples for Prompts

struct FewShotExamples {
    
    /// Get example emails for few-shot learning
    static func getExamples() -> String {
        return """
        Here are example emails with their correct tags to help you understand the tagging system:
        
        EXAMPLE 1 - Recruiting Email:
        From: Krishna Vasamshetti <recruiter@mitchell-martin.com>
        Subject: Senior Python Developer - Jersey City
        Body: "This is Krishna, Sr. Technical Recruiter at Mitchell Martin. I am recruiting on behalf of a global client... We are seeking a Senior Python Developer... If you are interested, please apply to..."
        Correct Tags: ["recruiting", "cold-outreach"]
        Reasoning: Unsolicited job offer from recruiter, not a personal contact
        
        EXAMPLE 2 - Personal Meeting Request:
        From: Jane Smith <jane.smith@mycompany.com>
        Subject: Can we meet tomorrow at 2pm?
        Body: "Hey! Can we meet tomorrow to discuss the project deliverables? Let me know if 2pm works for you."
        Correct Tags: ["meeting", "question", "personal-sender"]
        Reasoning: Work colleague asking about a meeting, appears in contacts
        
        EXAMPLE 3 - Service Notification:
        From: GitHub <noreply@github.com>
        Subject: [Security] Dependabot alert in your repository
        Body: "A high severity security vulnerability was found in your repository 'my-project'. Update the dependency immediately..."
        Correct Tags: ["work-project", "urgent"]
        Reasoning: Automated service notification about work, time-sensitive
        
        EXAMPLE 4 - Newsletter:
        From: Tech Weekly <newsletter@techweekly.com>
        Subject: This Week in Tech - Issue #247
        Body: "Here's what's new this week in technology... [long article summaries]... Click here to unsubscribe"
        Correct Tags: ["newsletter"]
        Reasoning: Bulk email newsletter with unsubscribe link, not urgent or personal
        
        EXAMPLE 5 - Spam:
        From: crypto_master <invest@suspicious-domain.com>
        Subject: URGENT: Make $10,000 in 24 Hours!!!
        Body: "Invest in cryptocurrency today and become a millionaire tomorrow! Act now! Limited time offer!"
        Correct Tags: ["spam-likely", "cold-outreach"]
        Reasoning: Unsolicited investment scam with urgent clickbait language
        
        EXAMPLE 6 - Travel Confirmation:
        From: United Airlines <confirmation@united.com>
        Subject: Flight Confirmation - UA1234
        Body: "Your flight from SFO to JFK on Dec 25 is confirmed. Confirmation number: ABC123..."
        Correct Tags: ["travel", "receipt"]
        Reasoning: Transactional email confirming travel booking
        
        EXAMPLE 7 - Financial/Invoice:
        From: billing@aws.amazon.com
        Subject: Your AWS Invoice for November 2025
        Body: "Your total charges for November are $247.50. Payment will be processed on..."
        Correct Tags: ["financial", "receipt"]
        Reasoning: Invoice/billing statement, transactional
        
        EXAMPLE 8 - Urgent Question:
        From: Sarah Johnson <sarah@client-company.com>
        Subject: URGENT: Need clarification on proposal
        Body: "Hi, I need clarification on section 3 of your proposal ASAP. Can you respond by EOD?"
        Correct Tags: ["question", "urgent", "action-required"]
        Reasoning: Client asking urgent question that needs immediate response
        
        ---
        
        Now analyze the following email using these examples as a guide:
        """
    }
    
    /// Get examples filtered by type
    static func getRelevantExamples(forSender sender: String, subject: String?) -> String {
        // In the future, we could dynamically select most relevant examples
        // For now, just return all examples
        return getExamples()
    }
}

// MARK: - Enhanced Prompt Builder

struct EnhancedPromptBuilder {
    
    /// Build an improved prompt with few-shot examples and better instructions
    static func buildPrompt(
        from: String,
        subject: String?,
        body: String,
        inContacts: Bool,
        allowedTags: [String]
    ) -> String {
        let truncatedBody = String(body.prefix(2000))
        let allowedTagsList = allowedTags.map { "  - \"\($0)\"" }.joined(separator: "\n")
        
        return """
        \(FewShotExamples.getExamples())
        
        Email to analyze:
        From: \(from)
        Subject: \(subject ?? "No subject")
        Body: \(truncatedBody)
        
        Additional context:
        - Sender is\(inContacts ? "" : " NOT") in user's contacts
        
        TASK: Analyze this email and return ONLY valid JSON with these EXACT fields:
        {
          "summary": "One sentence summary",
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
        
        IMPORTANT TAG RULES:
        You MUST choose tags ONLY from this list (do NOT make up new tags):
        \(allowedTagsList)
        
        Tag selection guidelines:
        1. Choose 1-3 tags maximum (most emails need 1-2 tags)
        2. Think step-by-step:
           a) First, identify if sender is personal, automated, or marketing
           b) Then, identify the main topic/purpose
           c) Finally, select the most specific applicable tags
        3. Use "personal-sender" ONLY if:
           - Sender is in contacts, OR
           - Clearly a real person (not automated/marketing)
           - Does NOT contain: "newsletter", "unsubscribe", "noreply", "no-reply"
        4. Use "recruiting" for job offers, NOT "personal-sender"
        5. Use "spam-likely" for obvious scams, phishing, or suspicious content
        6. Use "general" ONLY if no other tags fit
        7. Prioritize specific tags over "general"
        
        Intent options (choose ONE):
        - "question": Sender is asking you something
        - "action-required": You need to do something
        - "informational": FYI, no action needed
        - "promotional": Marketing, sales, offers
        - "transactional": Receipts, confirmations, automated
        
        Urgency options (choose ONE):
        - "immediate": Urgent, ASAP, time-sensitive
        - "soon": Within a day or two
        - "normal": Normal priority
        - "low": Can wait, FYI
        
        SenderCategory options (choose ONE):
        - "colleague": Work colleague
        - "client": External business contact
        - "service": Automated service (GitHub, AWS, etc.)
        - "marketing": Promotional emails, newsletters
        - "personal": Friends and family
        - "unknown": First-time sender
        
        CRITICAL: Return ONLY the JSON object. No markdown, no code blocks, no explanations.
        """
    }
}

// MARK: - Model Parameter Optimizer

struct ModelParameterOptimizer {
    
    /// Get optimized parameters for classification tasks
    static func optimizedOptions() -> OllamaOptions {
        return OllamaOptions(
            temperature: 0.1,        // Very low for consistent classification
            num_predict: 512
        )
    }
    
    /// Get parameters for reasoning tasks (when using chain-of-thought)
    static func reasoningOptions() -> OllamaOptions {
        return OllamaOptions(
            temperature: 0.2,        // Slightly higher for reasoning
            num_predict: 768         // More tokens for explanations
        )
    }
}
